package com.bloom.wadhakir

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.File

/**
 * The append-only record of what actually happened to this device's reminders.
 *
 * ## Why this is in Kotlin at all
 *
 * Everything else about the ledger could have lived in Dart. This could not.
 * [PrayerAlarmReceiver] fires with the app closed and no Flutter engine alive,
 * and the row it writes — *an alarm arrived, and this is how late it was* — is
 * the single most valuable row in the file and the one Dart can never write.
 * A ledger that only records what a running app can see would be blind to
 * exactly the failure the health screen exists to diagnose: a device that stops
 * the app and then stops its alarms.
 *
 * So the file is owned here, and Dart appends through [PrayerAlarmBridge]
 * rather than opening it itself. Two writers, one lock, one document.
 *
 * ## Why device-protected storage
 *
 * Same reason as [PrayerAlarmStore]: `LOCKED_BOOT_COMPLETED` re-arms the window
 * before the user has unlocked the phone, and an alarm can fire in that window
 * too. Credential-encrypted storage cannot be opened there — a writer that
 * threw would take the adhan down with it, since this runs inside the fire path.
 *
 * Unlike [PrayerAlarmStore] there is no `moveSharedPreferencesFrom` migration:
 * this file is new in R3 and has never existed anywhere else.
 *
 * ## The wire format is shared with Dart
 *
 * The field names below are a contract with `reminder_ledger_entry.dart`.
 * **Changing one means changing that file in the same commit** — and rows
 * written by the previous build are still in this one.
 */
object ReminderLedgerStore {

    private const val TAG = "PrayerAlarms"

    private const val FILE_NAME = "reminder_ledger.ndjson"

    /**
     * How many rows survive a trim.
     *
     * Bounded by **count only, never by date**. Pruning a ledger against `now`
     * is the trap that already cost this project a defect in Stage 1: a device
     * whose clock jumps forward deletes every row it skipped, permanently, and
     * the evidence is gone precisely when something was wrong enough to move
     * the clock. See the deliberately absent `PrayerAlarmStore.pruneExpired`.
     */
    private const val MAX_ROWS = 2000

    /**
     * A floor on how small one NDJSON row can be.
     *
     * `{"t":"armed","at":1757800000000}` is 32 bytes with its newline, and
     * every row carries at least those two fields. Used only as a fast path:
     * below `MAX_ROWS * this` the file cannot hold [MAX_ROWS] rows, so there is
     * nothing to count and the trim can skip a read.
     *
     * Deliberately an under-estimate. An earlier draft used an *average* row
     * size as the sole trigger, which was cheaper and quietly wrong — the row
     * count it actually enforced depended on how long the rows happened to be,
     * so a ledger of short rows would have held twice the retention the owner's
     * decision names. A cap nobody can state in one number is not a cap.
     *
     * Counting the rest of the time is affordable: appends happen about six
     * times a day — five prayers and a re-plan — on a background thread.
     */
    private const val MIN_ROW_BYTES = 30L

    /**
     * Serialises appends against trims.
     *
     * The receiver's `goAsync` thread and the platform thread both reach this,
     * and a trim that rewrites the file while an append is mid-write would lose
     * the appended row or duplicate the tail.
     */
    private val lock = Any()

    /**
     * Longest string any single field may carry.
     *
     * Must match `ReminderLedgerEntry._maxDetailLength` in
     * `reminder_ledger_entry.dart`, and truncate from the same end. A ring
     * buffer whose row size is unbounded has unknown retention.
     */
    private const val MAX_STRING_LENGTH = 64

    private fun file(context: Context): File =
        File(context.applicationContext.createDeviceProtectedStorageContext().filesDir, FILE_NAME)

    // --- the writers ---------------------------------------------------------

    /**
     * Records that an alarm fired, and how late.
     *
     * [dueMs] is the instant the alarm was armed for and [atMs] the instant it
     * actually arrived. Their difference is the measurement; storing a
     * pre-computed lateness instead would freeze today's idea of what counts as
     * late into rows a later build has to re-read.
     */
    fun recordFired(context: Context, id: Int, dueMs: Long, outcome: String, atMs: Long = System.currentTimeMillis()) {
        append(
            context,
            JSONObject()
                .put("t", "fired")
                .put("at", atMs)
                .put("id", id)
                .put("due", dueMs)
                .put("o", outcome),
        )
    }

    /**
     * Records an alarm that was armed, whose moment passed, and which never
     * fired.
     *
     * Written from the re-arm sweep — see [PrayerAlarmScheduler.rearmWindow],
     * which is the only place holding both halves of the evidence: the set the
     * OS was asked to keep, and a clock.
     */
    fun recordLapsed(context: Context, id: Int, dueMs: Long, atMs: Long = System.currentTimeMillis()) {
        append(
            context,
            JSONObject()
                .put("t", "lapsed")
                .put("at", atMs)
                .put("id", id)
                .put("due", dueMs),
        )
    }

    /** Records a system event that rebuilt the chain. Explains gaps. */
    fun recordTrigger(context: Context, action: String, atMs: Long = System.currentTimeMillis()) {
        append(
            context,
            JSONObject()
                .put("t", "trigger")
                .put("at", atMs)
                .put("d", action.take(MAX_STRING_LENGTH)),
        )
    }

    /**
     * Appends one already-shaped row. The Dart writer's entry point, via
     * [PrayerAlarmBridge].
     */
    fun appendRaw(context: Context, row: Map<String, Any?>) {
        val json = JSONObject()
        // Only the keys the format defines, so a malformed call from Dart can
        // never grow the row size the ring buffer is sized against.
        for (key in listOf("t", "at", "id", "due", "o", "n", "u", "d")) {
            val value = row[key] ?: continue
            // `take`, not `takeLast`: keep the leading characters, which is what
            // `ReminderLedgerEntry`'s constructor keeps (`substring(0, 64)`).
            // Two sides agreeing on a length but disagreeing on which half
            // survives is a difference that only ever shows up as "this row
            // reads differently depending on who wrote it".
            json.put(key, if (value is String) value.take(MAX_STRING_LENGTH) else value)
        }
        if (!json.has("t") || !json.has("at")) {
            Log.w(TAG, "Dropped a ledger row with no type or timestamp")
            return
        }
        append(context, json)
    }

    private fun append(context: Context, row: JSONObject) {
        synchronized(lock) {
            try {
                val target = file(context)
                // `JSONObject.toString()` escapes newlines inside strings, so a
                // row can never become two lines on the way back in.
                target.appendText(row.toString() + "\n")
                trimIfNeeded(target)
            } catch (e: Exception) {
                // Diagnostics must never take a reminder down with them. This
                // runs inside the fire path; an adhan is worth more than the
                // record of it.
                Log.w(TAG, "Could not append to the reminder ledger", e)
            }
        }
    }

    /**
     * Rewrites the file down to [MAX_ROWS] once it holds more than that.
     *
     * Through a temp file and a rename, which is atomic within a directory. An
     * in-place rewrite interrupted by the 10-second receiver budget would leave
     * a ledger that is half one generation and half another — and the only
     * thing worse than no evidence is evidence that lies.
     *
     * Caller holds [lock].
     */
    private fun trimIfNeeded(target: File) {
        if (target.length() <= MAX_ROWS * MIN_ROW_BYTES) return
        try {
            val lines = target.readLines().filter { it.isNotBlank() }
            if (lines.size <= MAX_ROWS) return
            val temp = File(target.parentFile, "$FILE_NAME.tmp")
            temp.writeText(lines.takeLast(MAX_ROWS).joinToString("\n", postfix = "\n"))
            if (!temp.renameTo(target)) {
                Log.w(TAG, "Could not swap the trimmed reminder ledger into place")
                temp.delete()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not trim the reminder ledger", e)
        }
    }

    // --- the reader ----------------------------------------------------------

    /** The whole document, or an empty string when there is nothing to read. */
    fun readAll(context: Context): String = synchronized(lock) {
        try {
            val target = file(context)
            if (target.exists()) target.readText() else ""
        } catch (e: Exception) {
            Log.w(TAG, "Could not read the reminder ledger", e)
            ""
        }
    }

    fun clear(context: Context) {
        synchronized(lock) {
            try {
                file(context).delete()
            } catch (e: Exception) {
                Log.w(TAG, "Could not clear the reminder ledger", e)
            }
        }
    }
}
