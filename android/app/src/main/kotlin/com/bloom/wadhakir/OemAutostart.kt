package com.bloom.wadhakir

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log

/**
 * The vendor screens that decide whether this app is allowed to keep running —
 * and the probe that refuses to mention one that is not there.
 *
 * ## Why this exists
 *
 * On Xiaomi, Oppo, Vivo, Huawei, Realme and Transsion handsets the battery
 * exemption Android offers is not the switch that matters. Each vendor runs its
 * own task killer with its own allowlist, kept on a screen the platform knows
 * nothing about, and an app left off that list is force-stopped — which on
 * Android cancels every alarm it had armed. That is the single most common way
 * this app's core promise fails on the hardware most of its users own, and it
 * is invisible from inside the app: [PrayerAlarmScheduler] arms correctly, the
 * OS accepts the alarms, and then the vendor takes them away.
 *
 * ## Why every target is probed
 *
 * These components are undocumented, renamed between OS versions, and absent
 * entirely on the same brand's other models. Firing one blind gives an
 * `ActivityNotFoundException` at best; at worst it opens nothing and the user is
 * left believing they fixed something.
 *
 * **Sending someone to a screen that does not exist on their phone is worse
 * than offering nothing at all** — it is a broken app that also blames their
 * device. So nothing here is decided from `Build.MANUFACTURER`. A target is
 * offered only when [resolve] has found a real, exported, enabled activity that
 * can handle it on *this* device.
 *
 * ## Package visibility
 *
 * From Android 11 a package this app has no relationship with is invisible to
 * `PackageManager` unless it is declared in `<queries>`. Every package named
 * below is declared in `AndroidManifest.xml`; **a target added here without its
 * `<queries>` entry silently never resolves**, which looks exactly like a device
 * that does not have it.
 */
object OemAutostart {

    private const val TAG = "PrayerAlarms"

    /**
     * A vendor screen worth offering.
     *
     * [key] is what Dart localises — never a label composed here. The rule is
     * the same one [PrayerAlarm]'s wire format follows: a second author of
     * Arabic copy on the native side is drift waiting to happen.
     */
    data class Target(val key: String, val component: ComponentName)

    /**
     * Candidates in probe order, most specific first.
     *
     * Several vendors ship two or three generations of the same screen under
     * different names; they are all listed, and the first that resolves wins.
     * Ordering within a vendor is newest-first, because an old component name
     * that still resolves on a new OS usually opens a stub.
     */
    private val candidates: List<Target> = listOf(
        // Xiaomi / Redmi / POCO — MIUI and HyperOS.
        Target("xiaomi", cmp("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
        Target("xiaomi", cmp("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity")),

        // Huawei / Honor — EMUI and Magic UI.
        Target("huawei", cmp("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
        Target("huawei", cmp("com.huawei.systemmanager", "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity")),
        Target("huawei", cmp("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")),

        // Oppo / Realme / OnePlus on ColorOS.
        Target("oppo", cmp("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
        Target("oppo", cmp("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
        Target("oppo", cmp("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
        Target("oneplus", cmp("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity")),

        // Vivo / iQOO.
        Target("vivo", cmp("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
        Target("vivo", cmp("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
        Target("vivo", cmp("com.iqoo.secure", "com.iqoo.secure.safeguard.PurviewTabActivity")),

        // Transsion — Tecno, Infinix, itel. Heavily used across Egypt and West
        // Africa, and almost never handled by apps that ship this kind of list.
        Target("transsion", cmp("com.transsion.phonemaster", "com.cyin.himgr.autostart.AutoStartActivity")),
        Target("transsion", cmp("com.transsion.phonemaster", "com.transsion.phonemaster.autostart.AutoStartActivity")),

        // Samsung — no autostart list, but the per-app sleep setting lives here
        // and is what puts an app "into deep sleep".
        Target("samsung", cmp("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")),
        Target("samsung", cmp("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity")),

        // Meizu, Asus and HMD/Nokia, in descending order of how likely this app
        // is to meet one.
        Target("meizu", cmp("com.meizu.safe", "com.meizu.safe.permission.SmartBGActivity")),
        Target("asus", cmp("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity")),
        Target("nokia", cmp("com.evenwell.powersaving.g3", "com.evenwell.powersaving.g3.exception.PowerSaverExceptionActivity")),
    )

    private fun cmp(pkg: String, cls: String) = ComponentName(pkg, cls)

    /**
     * The first candidate this device can actually open, or null.
     *
     * Four conditions, and all four are load-bearing:
     *
     *  * it **resolves** — the component exists on this build;
     *  * it is **exported** — otherwise launching it throws `SecurityException`
     *    from outside the vendor's own app, and `resolveActivity` happily
     *    returns components that are not;
     *  * it is **enabled** — several vendors ship the activity disabled on
     *    models where the feature was dropped, and it still resolves;
     *  * this app **holds any permission guarding it** — see [isLaunchable].
     */
    fun resolve(context: Context): Target? {
        val pm = context.packageManager
        for (target in candidates) {
            try {
                val info = pm.resolveActivity(intentFor(target), 0)?.activityInfo ?: continue
                if (isLaunchable(context, info)) return target
            } catch (e: Exception) {
                Log.w(TAG, "Probe failed for ${target.component.flattenToShortString()}", e)
            }
        }
        return null
    }

    /**
     * Whether `startActivity` on [info] would actually work.
     *
     * `exported` alone is not enough, and that gap is the difference between
     * this feature working and it being worse than useless. Several vendors
     * export their security-centre activities — so they resolve, and so other
     * system surfaces can reach them — while guarding them with a signature- or
     * privileged-level custom permission that keeps third-party apps out.
     * Launching one of those throws `SecurityException`.
     *
     * The failure that produces is precisely the one this whole item exists to
     * prevent, only worse: the screen renders a real button, the user presses
     * it, and nothing happens except an error — every time, on every launch,
     * forever. A button that reliably fails blames the user's device for the
     * app's mistake.
     *
     * So a guarded component is only offered if this app actually holds the
     * permission. It holds none of them, which is the point — the check is
     * written the general way rather than as a flat "skip anything guarded" so
     * that it stays correct if one is ever declared.
     */
    private fun isLaunchable(context: Context, info: android.content.pm.ActivityInfo): Boolean {
        if (!info.exported) return false
        if (!info.enabled || !info.applicationInfo.enabled) return false
        val permission = info.permission ?: return true
        return context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Opens the resolved screen.
     *
     * Re-probes rather than trusting a key handed back from Dart: the user can
     * disable the vendor's own security app between the screen rendering its
     * button and the button being pressed, and an unhandled
     * `ActivityNotFoundException` from a diagnostics screen would be a crash in
     * the one place a user has gone *because* something is already wrong.
     */
    fun open(context: Context): Boolean {
        val target = resolve(context) ?: return false
        return try {
            context.startActivity(
                intentFor(target).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (e: Exception) {
            Log.w(TAG, "Could not open ${target.component.flattenToShortString()}", e)
            false
        }
    }

    private fun intentFor(target: Target) = Intent().setComponent(target.component)

    /**
     * The packages `<queries>` must declare for [resolve] to see anything.
     *
     * Exposed so the manifest and this list can be checked against each other —
     * when they drift apart the feature fails silently, and identically to
     * "this device does not have it".
     */
    val queriedPackages: Set<String>
        get() = candidates.map { it.component.packageName }.toSet()
}
