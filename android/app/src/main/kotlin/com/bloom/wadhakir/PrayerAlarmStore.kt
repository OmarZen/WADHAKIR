package com.bloom.wadhakir

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject

/**
 * The native ledger of prayer alarms: what Dart last planned, and which of
 * those are currently armed with the OS.
 *
 * ## Why its own SharedPreferences file
 *
 * Not `FlutterSharedPreferences`. That file is owned by the shared_preferences
 * plugin, which reads and writes it wholesale from the Dart isolate; a native
 * write landing between the plugin's read and its write is simply lost. This
 * ledger is written from a BroadcastReceiver with no Flutter engine alive, so
 * it needs a file nothing else rewrites.
 *
 * ## Why the ledger is longer than the armed set
 *
 * Dart hands over sixty days. Only the next few are armed with AlarmManager —
 * hundreds of live exact alarms is not a thing to do to a device, and OEM
 * alarm tables have limits nobody documents. The rest sit here, and every alarm
 * that fires re-arms the window from this list. That is the self-healing chain:
 * as long as one alarm survives, the next is armed without any app process ever
 * running.
 */
object PrayerAlarmStore {
    private const val TAG = "PrayerAlarms"

    private const val PREFS_NAME = "wadhakir_prayer_alarms"
    private const val KEY_LEDGER = "ledger"
    private const val KEY_ARMED_IDS = "armed_ids"
    private const val KEY_PENDING_TAP = "pending_tap"
    private const val KEY_LOCATION_STALE = "location_stale"
    private const val KEY_DEFAULT_SOUND_URI = "default_sound_uri"
    private const val KEY_PERSISTENT_ENABLED = "persistent_enabled"
    private const val KEY_PERSISTENT_TITLE_FORMAT = "persistent_title_format"

    /** Whether this process has already tried the one-time migration. */
    @Volatile
    private var migrated = false

    /**
     * Device-protected storage, so the ledger is readable **before the user
     * unlocks the phone**.
     *
     * Normal app storage is credential-encrypted: after a reboot it cannot be
     * opened until the first unlock. That is why re-arming used to have to wait
     * for `BOOT_COMPLETED`, and why a prayer falling between the reboot and the
     * unlock was simply missed. From here, `LOCKED_BOOT_COMPLETED` can re-arm
     * the whole window while the lock screen is still up.
     *
     * The trade was made deliberately: this file holds prayer instants and the
     * Arabic notification copy. It stays app-private either way, but before the
     * first unlock it is not encrypted with the user's credential — and prayer
     * times do imply an approximate location. Nothing else about the user is in
     * here, and no other feature's data was moved.
     */
    private fun prefs(context: Context): SharedPreferences {
        val app = context.applicationContext
        val protected = app.createDeviceProtectedStorageContext()

        if (!migrated) {
            migrated = true
            try {
                // A no-op when there is nothing to move, which is every launch
                // after the first. Must happen before either copy is opened in
                // this process, hence the flag rather than a lazy field.
                protected.moveSharedPreferencesFrom(app, PREFS_NAME)
            } catch (e: Exception) {
                Log.w(TAG, "Could not migrate the alarm ledger to device-protected storage", e)
            }
        }

        return protected.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /** The whole plan Dart last handed over, earliest first. */
    fun all(context: Context): List<PrayerAlarm> =
        PrayerAlarm.listFromJson(prefs(context).getString(KEY_LEDGER, null))
            .sortedBy { it.fireAtEpochMs }

    fun replaceAll(context: Context, alarms: List<PrayerAlarm>) {
        prefs(context).edit()
            .putString(KEY_LEDGER, PrayerAlarm.listToJson(alarms.sortedBy { it.fireAtEpochMs }))
            .apply()
    }

    fun clear(context: Context) {
        prefs(context).edit()
            .remove(KEY_LEDGER)
            .remove(KEY_ARMED_IDS)
            .apply()
    }

    // There is deliberately no pruneExpired(). Dropping rows by comparing them
    // against "now" hands the whole stored plan to the device clock: a time that
    // jumps forward — a bad network time, a user checking something by setting
    // the date — would delete every row it skipped past, permanently, leaving
    // the self-healing chain with nothing to heal from. The ledger is replaced
    // wholesale on every commit and bounded at sixty days, so it never needs
    // trimming. See PrayerAlarmScheduler.rearmWindow.

    /**
     * Ids currently armed with AlarmManager.
     *
     * Tracked because AlarmManager offers no way to enumerate what an app has
     * armed. Without this, shrinking the window or dropping a disabled prayer
     * would leave orphaned alarms nothing ever cancels — which is exactly the
     * defect R1 found on the plugin path, where a disabled prayer stayed armed
     * for six future days.
     */
    fun armedIds(context: Context): Set<Int> =
        prefs(context).getStringSet(KEY_ARMED_IDS, emptySet())
            ?.mapNotNull { it.toIntOrNull() }
            ?.toSet()
            ?: emptySet()

    fun setArmedIds(context: Context, ids: Set<Int>) {
        prefs(context).edit()
            // A defensive copy: SharedPreferences does not copy the set it is
            // handed, and mutating it afterwards corrupts the stored value.
            .putStringSet(KEY_ARMED_IDS, ids.map { it.toString() }.toSet())
            .apply()
    }

    /**
     * A notification tap that arrived while no Flutter engine was running.
     *
     * The tap launches MainActivity, but Dart cannot be called until the engine
     * is up, and on a cold start that is well after the intent is delivered. So
     * the payload waits here and Dart collects it once, when it is ready.
     */
    fun setPendingTap(context: Context, payload: Map<String, String>) {
        prefs(context).edit()
            .putString(KEY_PENDING_TAP, JSONObject(payload as Map<*, *>).toString())
            .apply()
    }

    /**
     * Set when the device's timezone changes under an armed schedule.
     *
     * The alarms stay armed — going silent on a traveller is the failure this
     * whole release exists to prevent — but their instants were computed for
     * wherever the user was before, and no broadcast receiver can fix that:
     * prayer times are geodetic as well as zone-dependent, `adhan_dart` lives
     * in Dart, and the cached location is now the wrong city.
     *
     * So the flag says "the plan is stale", the user is told once, and Dart
     * re-plans against a fresh location the next time the app is opened.
     */
    fun setLocationStale(context: Context, stale: Boolean) {
        prefs(context).edit().putBoolean(KEY_LOCATION_STALE, stale).apply()
    }

    fun isLocationStale(context: Context): Boolean =
        prefs(context).getBoolean(KEY_LOCATION_STALE, false)

    /**
     * The user's system notification tone, resolved while the device was
     * unlocked.
     *
     * `RingtoneManager` reads the per-user settings provider, which is
     * credential-encrypted: before the first unlock after a reboot it returns
     * null or throws. [AdhanPlaybackService] runs in exactly that window, so
     * the URI is resolved at commit time — when a Flutter engine is alive and
     * therefore the user certainly is unlocked — and kept here in
     * device-protected storage.
     *
     * Only the "الصوت الافتراضي" option needs it. Every bundled adhan is an APK
     * resource, which is readable before unlock like the rest of the APK.
     */
    fun setDefaultSoundUri(context: Context, uri: String?) {
        prefs(context).edit().apply {
            if (uri.isNullOrEmpty()) remove(KEY_DEFAULT_SOUND_URI) else putString(KEY_DEFAULT_SOUND_URI, uri)
        }.apply()
    }

    fun defaultSoundUri(context: Context): String? =
        prefs(context).getString(KEY_DEFAULT_SOUND_URI, null)

    /**
     * What the persistent "next prayer" notification needs to rebuild itself
     * with no Flutter engine alive.
     *
     * [PrayerAlarmReceiver] rolls that notification forward to the following
     * prayer as each alarm fires, which is what keeps its countdown honest
     * while the app is closed. It reads the prayer's name, instant and body
     * straight off the ledger row; the only thing not in the ledger is whether
     * the feature is on and how its title reads, so Dart leaves both here.
     *
     * [titleFormat] carries a `{prayer}` token. Kotlin substitutes, and never
     * composes: a second author of Arabic copy on the native side is the drift
     * this whole wire format exists to prevent.
     */
    fun setPersistentConfig(context: Context, enabled: Boolean, titleFormat: String?) {
        prefs(context).edit()
            .putBoolean(KEY_PERSISTENT_ENABLED, enabled)
            .apply {
                if (titleFormat.isNullOrEmpty()) {
                    remove(KEY_PERSISTENT_TITLE_FORMAT)
                } else {
                    putString(KEY_PERSISTENT_TITLE_FORMAT, titleFormat)
                }
            }
            .apply()
    }

    fun isPersistentEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PERSISTENT_ENABLED, false)

    fun persistentTitleFormat(context: Context): String? =
        prefs(context).getString(KEY_PERSISTENT_TITLE_FORMAT, null)

    fun consumePendingTap(context: Context): Map<String, String>? {
        val raw = prefs(context).getString(KEY_PENDING_TAP, null) ?: return null
        prefs(context).edit().remove(KEY_PENDING_TAP).apply()
        return try {
            val json = JSONObject(raw)
            buildMap {
                json.keys().forEach { key -> put(key, json.optString(key)) }
            }
        } catch (_: Exception) {
            null
        }
    }
}
