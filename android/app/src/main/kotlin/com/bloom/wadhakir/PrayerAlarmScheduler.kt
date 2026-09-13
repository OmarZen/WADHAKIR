package com.bloom.wadhakir

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import java.util.Calendar

/**
 * Owns the OS alarm table for the five fard.
 *
 * ## The chain
 *
 * Dart hands over sixty days; [PrayerAlarmStore] keeps all of them. This arms
 * only the next [ARM_WINDOW_DAYS], and re-arms that window from three places:
 *
 *  1. **Every alarm that fires.** The window slides forward by one slot each
 *     time, so day+7 for that prayer is armed the moment day 0 rings. As long
 *     as a single alarm survives, the chain re-creates itself — with no Flutter
 *     engine, no app launch and no user action. This is the fix for C1.
 *  2. **A daily anchor at 00:05.** Repairs the window if a day passed with every
 *     alarm suppressed, and prunes what has expired.
 *  3. **[PrayerAlarmReconcileWorker], every six hours.** Compares the armed set
 *     against the ledger and re-arms the difference. Reconciliation only — it is
 *     never the thing that delivers an adhan, because periodic work is exactly
 *     what aggressive OEMs defer.
 *
 * Three independent repair paths, because each one is defeatable on its own.
 *
 * ## Why setAlarmClock
 *
 * It is the only alarm class fully exempt from Doze, App Standby buckets and
 * Battery Saver. `setExactAndAllowWhileIdle` — what the plugin path uses — is
 * rate-limited to roughly one firing per app per nine minutes while dozing, and
 * is still subject to standby buckets, which is how a rarely-opened app ends up
 * with a late adhan even when its alarm was armed.
 *
 * The visible cost is real and worth naming: `setAlarmClock` puts the alarm icon
 * in the status bar and the next prayer in the lock screen's "next alarm" slot.
 * For an app whose entire promise is an alert at an exact astronomical instant,
 * that is the honest presentation — and it is what Play's alarm-clock exemption
 * expects the permission to be used for.
 */
object PrayerAlarmScheduler {

    /**
     * How many days of the ledger are live with the OS at any moment.
     *
     * Not the whole sixty. Hundreds of exact alarms is not a thing to do to a
     * device, and several OEMs silently cap an app's alarm count with no error
     * on the call that gets dropped.
     */
    const val ARM_WINDOW_DAYS = 7

    private const val TAG = "PrayerAlarms"

    private const val ANCHOR_REQUEST_CODE = 950_000
    private const val ANCHOR_HOUR = 0
    private const val ANCHOR_MINUTE = 5

    /**
     * Ignore anything due within this much of now.
     *
     * An alarm armed for an instant already in the past fires immediately, which
     * would sound the adhan for a prayer that has been and gone.
     */
    private const val MIN_LEAD_MS = 1_000L

    /**
     * Re-arms the window from the ledger and re-anchors the daily rebuild.
     *
     * Idempotent by construction: it computes the set that *should* be armed,
     * cancels everything armed that is not in it, and arms the rest. Calling it
     * twice changes nothing, which is what lets three repair paths all end in
     * the same function without coordinating.
     *
     * [firedId] is the alarm whose firing triggered this call, when one did. It
     * is excluded from the lapse detection below: an alarm that the OS delivered
     * late is still an alarm the OS delivered, and counting it as never having
     * arrived would report every deferred adhan twice — once as late, once as
     * missing.
     *
     * [observeLapses] is false when the sweep was caused by the environment
     * changing rather than by time passing normally — see [recordLapses].
     */
    fun rearmWindow(
        context: Context,
        nowMs: Long,
        firedId: Int? = null,
        observeLapses: Boolean = true,
    ) = synchronized(sweepLock) {
        rearmWindowLocked(context, nowMs, firedId, observeLapses)
    }

    /**
     * Serialises every sweep.
     *
     * A sweep is a read-modify-write over the armed set: read `armedIds`, decide,
     * write `setArmedIds`. [PrayerAlarmReceiver.onFire] starts a **new, unsynchronised
     * thread for every firing**, and Android delivers backlogged alarms in quick
     * succession after a Doze stretch — so two sweeps genuinely overlap.
     *
     * Interleaved, they do two kinds of damage. The older one predates this
     * release: the second thread's `setArmedIds` can be computed from a set read
     * before the first thread's write, leaving an alarm armed with the OS that
     * the ledger no longer lists, which nothing ever cancels. The newer one is
     * the lapse detector's: `firedId` excludes only the *calling* thread's own
     * alarm, so thread A, still seeing B's id in a stale `armedIds`, will write a
     * `lapsed` row for an alarm that fired successfully in thread B a moment ago
     * — a false accusation against a healthy device, which is the one thing the
     * health screen must never produce.
     *
     * `recordLapses`'s "cannot report twice, for free" guarantee assumes single
     * -threaded execution. This is what makes that assumption true.
     */
    private val sweepLock = Any()

    private fun rearmWindowLocked(
        context: Context,
        nowMs: Long,
        firedId: Int?,
        observeLapses: Boolean,
    ) {
        val manager = context.getSystemService(AlarmManager::class.java)
        if (manager == null) {
            Log.w(TAG, "No AlarmManager; cannot arm prayer alarms")
            return
        }

        // Deliberately NOT pruning the ledger here.
        //
        // Pruning by "now" makes the stored plan a hostage to the clock. A
        // device whose time jumps forward — a bad NTP sync, a user setting the
        // date to check something, a dual-SIM handset taking a wrong network
        // time — would drop every row it had just walked past, permanently.
        // Coming back to the right time then leaves an empty ledger, no alarms,
        // and no way to notice: the self-healing chain has nothing left to heal
        // from, and only opening the app would restore it.
        //
        // Nothing needs pruning anyway. The ledger is replaced wholesale on
        // every commit and is bounded at sixty days, and the filter below
        // already ignores anything in the past.
        val horizonMs = nowMs + ARM_WINDOW_DAYS * 24L * 60L * 60L * 1000L
        val ledger = PrayerAlarmStore.all(context)
        val due = ledger.filter {
            it.fireAtEpochMs > nowMs + MIN_LEAD_MS && it.fireAtEpochMs <= horizonMs
        }
        val desiredIds = due.map { it.id }.toSet()

        val armedIds = PrayerAlarmStore.armedIds(context)
        if (observeLapses) {
            recordLapses(context, manager, ledger, armedIds, nowMs, firedId)
        }

        // Cancel first. An id that dropped out of the plan — a prayer the user
        // switched off, a day that rolled out of the window — has no other way
        // of being taken back: AlarmManager cannot be enumerated, so an alarm
        // nobody cancels rings forever.
        val stale = armedIds - desiredIds
        stale.forEach { cancelById(context, manager, it) }

        due.forEach { arm(context, manager, it) }
        PrayerAlarmStore.setArmedIds(context, desiredIds)

        scheduleAnchor(context, manager, nowMs)

        Log.i(TAG, "Armed ${due.size} alarms, cancelled ${stale.size}, ledger=${PrayerAlarmStore.all(context).size}")
    }

    /**
     * Writes a `lapsed` row for every alarm that was armed, whose moment came
     * and went, and which never fired.
     *
     * ## Why this is the right place, and the only one
     *
     * Nobody is present at the moment of a miss — that is what makes it a miss.
     * It can only ever be *detected afterwards*, by something holding both
     * halves of the evidence: the set the OS was asked to keep, and a clock.
     * This sweep is the only code in the app that holds both.
     *
     * The inference is sound because firing re-arms. When an alarm fires,
     * [PrayerAlarmReceiver] calls this function, and the write of [desiredIds]
     * at the end drops that id from the armed set at a moment when its instant
     * is roughly now. So an id that is *still* armed with an instant well in the
     * past is an id whose alarm was never delivered — there is no other way for
     * it to have survived.
     *
     * ## Why it cannot report the same lapse twice
     *
     * For free, and deliberately. `setArmedIds(desiredIds)` at the end of the
     * sweep contains only future instants, so every id reported here is gone
     * from the armed set by the time the next sweep runs. No "already reported"
     * state is kept, which means there is none to get out of step.
     *
     * Only ids still present in [ledger] are reported: the row is worthless
     * without the instant it was armed for, and an id with no row is already
     * handled as a stale cancel.
     *
     * ## What must NOT reach here, and why
     *
     * The inference only holds while "this instant is in the past" means time
     * passed normally. Two situations break that, and both were found producing
     * a false accusation:
     *
     *  * **The environment changed.** [PrayerSystemEventsReceiver] sweeps on
     *    `TIME_SET`, `BOOT_COMPLETED` and their siblings. A clock corrected
     *    forward by three days makes every armed alarm "overdue" at once — up
     *    to [ARM_WINDOW_DAYS] × 5 rows from one sweep — and a phone that spent
     *    the night switched off crosses Isha and Fajr. Neither is the device
     *    killing the app; one is NTP and the other is a power button. Those
     *    callers pass `observeLapses = false`.
     *  * **Exact alarms are revoked.** [arm] then degrades to
     *    `setAndAllowWhileIdle`, which is inexact by design and routinely runs
     *    minutes late while dozing. A sweep landing in that gap would record a
     *    lapse for an adhan that is merely deferred. The permission is
     *    diagnosed on its own, ahead of any of this, so nothing is lost by
     *    staying quiet here — and the rows are permanent, so a false one would
     *    go on accusing the device for a fortnight after the user fixed the
     *    real problem.
     */
    private fun recordLapses(
        context: Context,
        manager: AlarmManager,
        ledger: List<PrayerAlarm>,
        armedIds: Set<Int>,
        nowMs: Long,
        firedId: Int?,
    ) {
        if (armedIds.isEmpty()) return
        if (!canScheduleExact(manager)) return
        try {
            ledger.asSequence()
                // The predicate itself lives in ReminderRules, which has no
                // Android types and is therefore the only part of this file a
                // JUnit test can reach. It is also the part whose failure is
                // silent — see ReminderRulesTest.
                .filter {
                    ReminderRules.isLapsed(
                        id = it.id,
                        fireAtEpochMs = it.fireAtEpochMs,
                        nowMs = nowMs,
                        firedId = firedId,
                        armedIds = armedIds,
                    )
                }
                .forEach { ReminderLedgerStore.recordLapsed(context, it.id, it.fireAtEpochMs, nowMs) }
        } catch (e: Exception) {
            // Diagnostics never get to break the re-arm they are observing.
            Log.w(TAG, "Could not record lapsed alarms", e)
        }
    }

    /**
     * Records lapses against the ledger **as it stands right now**, without
     * arming anything.
     *
     * Exists for one caller — [PrayerAlarmBridge]'s `commit` — and for a reason
     * that made the whole detector a no-op on the single path that matters most.
     *
     * A commit does `replaceAll` then `rearmWindow`. `replaceAll` overwrites the
     * ledger with Dart's freshly computed plan, and `PrayerSchedulePlanner` drops
     * everything not still in the future. So by the time the sweep looks for
     * "armed, and its instant has passed", the rows it needs are already gone —
     * `armedIds` still holds ids from days ago, and the ledger has nothing to
     * match them against.
     *
     * What that erased is exactly the evidence worth having. A force-stop —
     * whether the user's or an OEM's — kills the alarm chain, the 00:05 anchor
     * and WorkManager together, so nothing runs again until the app is opened.
     * That reopen IS the commit. Every multi-day silence therefore recorded
     * nothing at all, at the precise moment someone had opened the app to find
     * out why they had missed their prayers.
     *
     * So: observe first, against the old ledger, then replace.
     */
    fun observeLapses(context: Context, nowMs: Long) = synchronized(sweepLock) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return@synchronized
        recordLapses(
            context,
            manager,
            PrayerAlarmStore.all(context),
            PrayerAlarmStore.armedIds(context),
            nowMs,
            firedId = null,
        )
    }

    /** Takes back every alarm this app owns and empties the ledger. */
    fun cancelAll(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java) ?: return
        PrayerAlarmStore.armedIds(context).forEach { cancelById(context, manager, it) }
        cancelAnchor(context, manager)
        PrayerAlarmStore.clear(context)
    }

    private fun arm(context: Context, manager: AlarmManager, alarm: PrayerAlarm) {
        val operation = firePendingIntent(context, alarm.id)
        try {
            if (canScheduleExact(manager)) {
                manager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(alarm.fireAtEpochMs, showPendingIntent(context)),
                    operation,
                )
            } else {
                // Exact alarms revoked. Degrade rather than drop: an adhan a few
                // minutes late is a worse product, a missing one is a broken
                // promise. The same trade the plugin path makes.
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    alarm.fireAtEpochMs,
                    operation,
                )
            }
        } catch (e: SecurityException) {
            // Some OEM builds throw here even with the permission held.
            Log.w(TAG, "Refused alarm ${alarm.id}, retrying inexact", e)
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.fireAtEpochMs, operation)
        }
    }

    private fun cancelById(context: Context, manager: AlarmManager, id: Int) {
        manager.cancel(firePendingIntent(context, id))
    }

    private fun canScheduleExact(manager: AlarmManager): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()

    /**
     * The alarm's own PendingIntent.
     *
     * Both the request code and the intent's data carry the id. Extras do not
     * participate in `Intent.filterEquals`, so without distinct data two alarms
     * would resolve to the SAME PendingIntent and each new one would silently
     * replace the last — five prayers collapsing into one.
     */
    private fun firePendingIntent(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_FIRE
            data = Uri.parse("wadhakir://prayer-alarm-fire/$id")
            putExtra(PrayerAlarmReceiver.EXTRA_ALARM_ID, id)
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Where the system's "next alarm" chip goes when tapped. */
    private fun showPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return PendingIntent.getActivity(
            context,
            ANCHOR_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    // --- the daily anchor ----------------------------------------------------

    /**
     * Arms the next 00:05 rebuild.
     *
     * Deliberately NOT `setAlarmClock`: this is maintenance, and putting it in
     * the lock screen's next-alarm slot would tell the user their next prayer is
     * at five past midnight.
     */
    private fun scheduleAnchor(context: Context, manager: AlarmManager, nowMs: Long) {
        val next = Calendar.getInstance().apply {
            timeInMillis = nowMs
            set(Calendar.HOUR_OF_DAY, ANCHOR_HOUR)
            set(Calendar.MINUTE, ANCHOR_MINUTE)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= nowMs) add(Calendar.DAY_OF_YEAR, 1)
        }.timeInMillis

        val operation = anchorPendingIntent(context)
        try {
            if (canScheduleExact(manager)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Anchor refused, falling back to inexact", e)
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
        }
    }

    private fun cancelAnchor(context: Context, manager: AlarmManager) {
        manager.cancel(anchorPendingIntent(context))
    }

    private fun anchorPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_ANCHOR
            data = Uri.parse("wadhakir://prayer-alarm-anchor")
        }
        return PendingIntent.getBroadcast(
            context,
            ANCHOR_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
