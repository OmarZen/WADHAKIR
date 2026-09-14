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
     * **Load-bearing on every API level since Stage 3.** It used to matter only
     * on 24/25, because from Oreo the notification channel owned the sound.
     * [AdhanPlaybackService] now owns the sound on all versions, and this is
     * what it plays; a null means "the user chose الصوت الافتراضي", which the
     * service resolves to the system tone.
     */
    val soundRes: String?,
    /**
     * The prayer's own instant, as opposed to [fireAtEpochMs] which is this
     * minus any "before X minutes" lead.
     *
     * Carried for the persistent next-prayer notification, whose countdown must
     * target the prayer itself. The receiver rolls that notification forward
     * from the ledger with no Flutter engine alive, so it cannot recompute it.
     *
     * Zero when absent — rows written before Stage 3 have no such key.
     */
    val prayerAtEpochMs: Long,
    /**
     * The prayer's Arabic name, e.g. `الفجر`.
     *
     * Also for the persistent notification. Kotlin could map it from
     * [prayerKey], but that would put a second copy of user-facing Arabic on
     * the native side — the exact drift this wire format exists to prevent.
     */
    val prayerName: String,
    /**
     * Whether the adhan should sound while the ringer is silent.
     *
     * True — the default — makes it behave like an alarm clock, which is what
     * `AudioAttributes.USAGE_ALARM` gives it. False makes it respect a silenced
     * phone: the card still posts and the channel still vibrates, but no audio
     * plays and no playback service is started.
     */
    val overrideSilent: Boolean,
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
        put(KEY_PRAYER_AT, prayerAtEpochMs)
        put(KEY_PRAYER_NAME, prayerName)
        put(KEY_OVERRIDE_SILENT, overrideSilent)
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
        private const val KEY_PRAYER_AT = "prayerAtEpochMs"
        private const val KEY_PRAYER_NAME = "prayerName"
        private const val KEY_OVERRIDE_SILENT = "overrideSilent"
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
                // Falls back to the fire instant, which is the same value
                // whenever the user is on the default "on time" lead. See
                // [prayerAtEpochMs].
                prayerAtEpochMs = (args["prayerAtEpochMs"] as? Number)?.toLong() ?: fireAt,
                prayerName = args["prayerName"] as? String ?: "",
                overrideSilent = args["overrideSilent"] as? Boolean ?: true,
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

            val prayerKey = json.optString(KEY_PRAYER, "")

            return PrayerAlarm(
                id = id,
                fireAtEpochMs = fireAt,
                prayerKey = prayerKey,
                dayIndex = json.optInt(KEY_DAY_INDEX, 0),
                channelId = migrateChannel(
                    json.optString(KEY_CHANNEL, "").ifEmpty { return null },
                    prayerKey,
                ),
                groupKey = json.optString(KEY_GROUP, ""),
                title = json.optString(KEY_TITLE, ""),
                body = json.optString(KEY_BODY, ""),
                vibrate = json.optBoolean(KEY_VIBRATE, true),
                soundRes = json.optString(KEY_SOUND_RES, "").takeIf { it.isNotEmpty() },
                // A ledger written before Stage 3 has none of the three keys
                // below. It is replaced wholesale by the first reschedule after
                // the update, so these defaults only have to survive the gap
                // between installing the update and the app next opening:
                // the countdown target degrades to the fire instant, the
                // persistent roll-forward skips rows with no Arabic name rather
                // than rendering "Fajr", and the adhan keeps the alarm-clock
                // behaviour that is the new default.
                prayerAtEpochMs = json.optLong(KEY_PRAYER_AT, 0L).takeIf { it > 0L } ?: fireAt,
                prayerName = json.optString(KEY_PRAYER_NAME, ""),
                overrideSilent = json.optBoolean(KEY_OVERRIDE_SILENT, true),
                payload = payload,
            )
        }

        /**
         * Forces a stored row onto one of the two silent Stage 3 channels.
         *
         * **This is not cosmetic — without it the adhan plays twice.** A ledger
         * written before Stage 3 names a sounding `adhan_<key>_v1` channel, and
         * those channels still exist on an upgraded install until the app is
         * next opened. Nothing rewrites the ledger in between: `MY_PACKAGE_
         * REPLACED` re-arms from the rows already stored. So the first prayer
         * after a Play update — a Fajr, typically, hours before anyone opens the
         * app — would post to a channel that still has the mp3 baked in *and*
         * start the service that plays the same mp3. Two adhans, a fraction of a
         * second apart, on two volume sliders, with a stop button that reaches
         * only one of them.
         *
         * This is the same defect class as Stage 1 review findings #1 and #2,
         * where handing the table between owners doubled every adhan for a week.
         *
         * Any unrecognised channel maps to the Stage 3 pair as well: every
         * prayer alarm belongs on one of these two now, and a row naming a
         * channel that no longer exists would be dropped by Android in silence.
         */
        private fun migrateChannel(channelId: String, prayerKey: String): String = when {
            channelId == PrayerNotifier.ADHAN_CHANNEL_ID -> channelId
            channelId == PrayerNotifier.FAJR_ADHAN_CHANNEL_ID -> channelId
            prayerKey.equals("Fajr", ignoreCase = true) -> PrayerNotifier.FAJR_ADHAN_CHANNEL_ID
            else -> PrayerNotifier.ADHAN_CHANNEL_ID
        }

        /**
         * Reads one alarm back out of an Intent extra.
         *
         * [AdhanPlaybackService] is handed the row the receiver already loaded
         * rather than looking it up again; this is the other half of that.
         */
        fun fromJsonString(raw: String): PrayerAlarm? = try {
            fromJson(JSONObject(raw))
        } catch (_: Exception) {
            null
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
