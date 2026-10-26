package com.bloom.wadhakir

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager

/**
 * What the phone is doing right now that an adhan has to defer to.
 *
 * Read with no permission at all. [AudioManager.getMode] reports a call —
 * cellular or VoIP, ringing or answered — where `TelephonyManager.getCallState`
 * needs READ_PHONE_STATE from Android 12, a permission this app has no other
 * use for and Play would ask about.
 *
 * Every reader defaults to the loud answer when it throws: these run in
 * [PrayerAlarmReceiver] before the first unlock, and a reader that took the
 * fire path down with it would turn into the silence this whole path exists to
 * prevent.
 */
object PhoneQuiet {

    /**
     * A call is ringing or connected, including WhatsApp-style VoIP calls
     * (`MODE_IN_COMMUNICATION`) and call screening.
     *
     * Every mode above `MODE_NORMAL` is some kind of call, so this does not
     * list them: the ones added in later releases (`MODE_CALL_SCREENING`,
     * `MODE_CALL_REDIRECT`, `MODE_COMMUNICATION_REDIRECT`) are covered without
     * naming constants older releases do not have.
     */
    fun isInCall(context: Context): Boolean = try {
        val mode = context.getSystemService(AudioManager::class.java)?.mode
        mode != null && mode > AudioManager.MODE_NORMAL
    } catch (_: Exception) {
        false
    }

    /**
     * The ringer is on silent or vibrate, or Do Not Disturb is on.
     *
     * Do Not Disturb counts in every flavour — priority only, alarms only, total
     * silence. "Respect the phone's rules" is the promise, and someone who
     * turned on DND for a meeting has said as much as someone who flipped the
     * ringer switch.
     */
    fun isSilenced(context: Context): Boolean = isRingerOff(context) || isDndOn(context)

    private fun isRingerOff(context: Context): Boolean = try {
        when (context.getSystemService(AudioManager::class.java)?.ringerMode) {
            AudioManager.RINGER_MODE_SILENT, AudioManager.RINGER_MODE_VIBRATE -> true
            else -> false
        }
    } catch (_: Exception) {
        false
    }

    private fun isDndOn(context: Context): Boolean = try {
        when (context.getSystemService(NotificationManager::class.java)?.currentInterruptionFilter) {
            NotificationManager.INTERRUPTION_FILTER_PRIORITY,
            NotificationManager.INTERRUPTION_FILTER_ALARMS,
            NotificationManager.INTERRUPTION_FILTER_NONE -> true
            else -> false
        }
    } catch (_: Exception) {
        false
    }
}
