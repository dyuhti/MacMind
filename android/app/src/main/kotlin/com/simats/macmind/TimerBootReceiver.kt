package com.simats.macmind

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimerBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Boot completed, rescheduling timers")
        val persistence = TimerPersistence(context)
        val alarms = TimerAlarms(context)
        val notifications = TimerNotifications(context)
        val now = System.currentTimeMillis()

        val allTimers = persistence.loadAllActiveTimers()

        for (timer in allTimers) {
            if (timer.isRunning()) {
                if (timer.finishTimestamp <= now) {
                    Log.d(TAG, "Timer ${timer.timerId} already expired during reboot")
                    notifications.showTimerFinishedNotification(
                        notificationId = timer.notificationId,
                        timerId = timer.timerId,
                        cylinderType = timer.cylinderType,
                        flowRate = timer.flowRate
                    )
                    persistence.updateTimerStatus(timer.timerId, TimerModel.STATUS_COMPLETED)
                } else {
                    val warningTime = timer.finishTimestamp - TimerAlarms.WARNING_LEAD_MS
                    if (warningTime <= now) {
                        Log.d(TAG, "Timer ${timer.timerId} warning time already passed during reboot, showing warning")
                        notifications.showTimerWarningNotification(
                            notificationId = timer.notificationId,
                            timerId = timer.timerId,
                            cylinderType = timer.cylinderType,
                            flowRate = timer.flowRate
                        )
                    } else {
                        Log.d(TAG, "Rescheduling warning for timer ${timer.timerId}")
                        alarms.scheduleWarningAlarm(timer)
                    }
                    Log.d(TAG, "Rescheduling finish for timer ${timer.timerId} at ${timer.finishTimestamp}")
                    alarms.scheduleFinishAlarm(timer)
                }
            } else {
                Log.d(TAG, "Timer ${timer.timerId} is ${timer.status}, skipping reschedule")
            }
        }

        Log.d(TAG, "Boot reschedule complete: ${allTimers.size} timers processed")
    }

    companion object {
        private const val TAG = "TimerBootReceiver"
    }
}
