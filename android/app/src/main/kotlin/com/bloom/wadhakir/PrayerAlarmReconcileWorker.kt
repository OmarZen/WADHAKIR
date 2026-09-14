package com.bloom.wadhakir

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * The third repair path: every six hours, re-arm the window from the ledger.
 *
 * ## Reconciliation only
 *
 * This is explicitly NOT how an adhan gets delivered. Periodic work is deferred,
 * batched and coalesced by the OS, and it is the first thing aggressive OEM
 * power managers stop — the exact conditions under which a prayer app must still
 * work. Delivery is [PrayerAlarmScheduler]'s `setAlarmClock` chain.
 *
 * What this catches is the case the chain cannot: every armed alarm dropped at
 * once, with no alarm left to re-arm the next. A force-stop clears the app's
 * alarms; so does a restore onto a new device. The chain is broken and has no
 * way to notice. This notices, because [PrayerAlarmScheduler.rearmWindow] is
 * idempotent — it re-arms whatever the ledger says should be armed, whether or
 * not anything already is.
 *
 * (A force-stop also stops WorkManager until the user opens the app again. That
 * is why this is the third path and not the first.)
 */
class PrayerAlarmReconcileWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        return try {
            PrayerAlarmScheduler.rearmWindow(applicationContext, System.currentTimeMillis())
            Result.success()
        } catch (_: Exception) {
            // Retried with WorkManager's backoff. The alarm chain is unaffected
            // either way — this only ever repairs.
            Result.retry()
        }
    }

    companion object {
        private const val UNIQUE_NAME = "wadhakir_prayer_alarm_reconcile"

        /**
         * Six hours, which is well inside the seven-day armed window. Even if
         * several runs in a row are dropped, the window has not expired by the
         * time one lands.
         */
        private const val INTERVAL_HOURS = 6L

        fun enqueue(context: Context) {
            val request = PeriodicWorkRequestBuilder<PrayerAlarmReconcileWorker>(
                INTERVAL_HOURS,
                TimeUnit.HOURS,
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_NAME,
                // KEEP, not UPDATE: replacing the request on every reschedule
                // would reset its period, and a user who opens the app often
                // would never let it run at all.
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_NAME)
        }
    }
}
