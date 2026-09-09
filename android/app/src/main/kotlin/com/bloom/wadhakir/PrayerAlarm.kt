package com.bloom.wadhakir

import org.json.JSONArray
import org.json.JSONObject

/**
 * One prayer notification, already decided and already rendered by Dart.
 *
 * Nothing here is computed on the native side. Dart's [PrayerSchedulePlanner]
 * chose the instant and the id; Dart's PrayerNotificationContent chose the
 * channel, the Arabic copy and the tap payload. This class only carries them
 * and hands them back to [PrayerAlarmReceiver] when the alarm fires.
 *
 * That split is deliberate. Two renderers — one in Dart for the plugin path and
 * one in Kotlin — would drift, and a notification posted to a channel key that
 * was never created is dropped by Android with no error anywhere.
 *
 * [fireAtEpochMs] is an absolute instant, never wall-clock components plus a
 * zone name. The plugin path stores the latter and re-resolves it natively,
 * which is why a DST transition or a flight moves the whole armed horizon.
 */
data class PrayerAlarm(
    val id: Int,
    val fireAtEpochMs: Long,
    val prayerKey: String,
    val dayIndex: Int,
    val channelId: String,
    val groupKey: String,
    val title: String,
    val body: String,
    val vibrate: Boolean,
    /**
     * `res/raw` name of the chosen adhan, or null for the system beep.
     *
     * Only Android 24/25 reads it — from Oreo the channel owns the sound. See
     * [PrayerNotifier].
     */
    val soundRes: String?,
    val payload: Map<String, String>,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put(KEY_ID, id)
        put(KEY_FIRE_AT, fireAtEpochMs)
        put(KEY_PRAYER, prayerKey)
        put(KEY_DAY_INDEX, dayIndex)
        put(KEY_CHANNEL, channelId)
        put(KEY_GROUP, groupKey)
        put(KEY_TITLE, title)
        put(KEY_BODY, body)
        put(KEY_VIBRATE, vibrate)
        // JSONObject.put(String, null) REMOVES the key rather than storing a
        // null, so the reader must tolerate its absence — optString does.
        put(KEY_SOUND_RES, soundRes)
        put(KEY_PAYLOAD, JSONObject(payload as Map<*, *>))
    }

    companion object {
        private const val KEY_ID = "id"
        private const val KEY_FIRE_AT = "fireAtEpochMs"
        private const val KEY_PRAYER = "prayerKey"
        private const val KEY_DAY_INDEX = "dayIndex"
        private const val KEY_CHANNEL = "channelId"
        private const val KEY_GROUP = "groupKey"
        private const val KEY_TITLE = "title"
        private const val KEY_BODY = "body"
        private const val KEY_VIBRATE = "vibrate"
        private const val KEY_SOUND_RES = "soundRes"
        private const val KEY_PAYLOAD = "payload"

        /**
         * Reads one alarm off the method channel.
         *
         * Returns null rather than throwing on a malformed entry: one bad row
         * must cost one adhan, not the whole reschedule. The Dart side would
         * otherwise see a PlatformException, degrade to the plugin path, and
         * strand the user on the old behaviour for the rest of the session.
         */
        @Suppress("UNCHECKED_CAST")
        fun fromChannel(args: Map<String, Any?>): PrayerAlarm? {
            val id = (args["id"] as? Number)?.toInt() ?: return null
            val fireAt = (args["fireAtEpochMs"] as? Number)?.toLong() ?: return null
            val payload = (args["payload"] as? Map<String, Any?>)
                ?.mapNotNull { (k, v) -> v?.let { k to it.toString() } }
                ?.toMap()
                ?: emptyMap()

            return PrayerAlarm(
                id = id,
                fireAtEpochMs = fireAt,
                prayerKey = args["prayerKey"] as? String ?: "",
                dayIndex = (args["dayIndex"] as? Number)?.toInt() ?: 0,
                channelId = args["channelId"] as? String ?: return null,
                groupKey = args["groupKey"] as? String ?: "",
                title = args["title"] as? String ?: "",
                body = args["body"] as? String ?: "",
                vibrate = args["vibrate"] as? Boolean ?: true,
                soundRes = (args["soundRes"] as? String)?.takeIf { it.isNotEmpty() },
                payload = payload,
            )
        }

        fun fromJson(json: JSONObject): PrayerAlarm? {
            val id = json.optInt(KEY_ID, -1).takeIf { it >= 0 } ?: return null
            val fireAt = json.optLong(KEY_FIRE_AT, -1L).takeIf { it > 0 } ?: return null
            val payloadJson = json.optJSONObject(KEY_PAYLOAD)
            val payload = buildMap {
                payloadJson?.keys()?.forEach { key ->
                    payloadJson.optString(key)?.let { put(key, it) }
                }
            }

            return PrayerAlarm(
                id = id,
                fireAtEpochMs = fireAt,
                prayerKey = json.optString(KEY_PRAYER, ""),
                dayIndex = json.optInt(KEY_DAY_INDEX, 0),
                channelId = json.optString(KEY_CHANNEL, "").ifEmpty { return null },
                groupKey = json.optString(KEY_GROUP, ""),
                title = json.optString(KEY_TITLE, ""),
                body = json.optString(KEY_BODY, ""),
                vibrate = json.optBoolean(KEY_VIBRATE, true),
                soundRes = json.optString(KEY_SOUND_RES, "").takeIf { it.isNotEmpty() },
                payload = payload,
            )
        }

        fun listToJson(alarms: List<PrayerAlarm>): String {
            val array = JSONArray()
            alarms.forEach { array.put(it.toJson()) }
            return array.toString()
        }

        /** Skips rows it cannot read; see [fromChannel] for why. */
        fun listFromJson(raw: String?): List<PrayerAlarm> {
            if (raw.isNullOrEmpty()) return emptyList()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).mapNotNull { index ->
                    array.optJSONObject(index)?.let { fromJson(it) }
                }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }
}
