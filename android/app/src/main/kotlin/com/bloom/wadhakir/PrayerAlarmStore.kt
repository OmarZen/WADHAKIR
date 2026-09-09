package com.bloom.wadhakir

import android.content.Context
import android.content.SharedPreferences
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
    private const val PREFS_NAME = "wadhakir_prayer_alarms"
    private const val KEY_LEDGER = "ledger"
    private const val KEY_ARMED_IDS = "armed_ids"
    private const val KEY_PENDING_TAP = "pending_tap"

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

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
