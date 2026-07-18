package com.example.med_calci_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val timerId = intent.getStringExtra(EXTRA_TIMER_ID) ?: return
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
        val cylinderType = intent.getStringExtra(EXTRA_CYLINDER_TYPE) ?: "Unknown"
        val flowRate = intent.getIntExtra(EXTRA_FLOW_RATE, 0)
        val alarmType = intent.getStringExtra(EXTRA_ALARM_TYPE) ?: ALARM_TYPE_FINISH

        Log.d(TAG, "Alarm fired for timer: $timerId, type: $alarmType")

        val persistence = TimerPersistence(context)
        val timer = persistence.loadTimer(timerId)

        if (timer == null) {
            Log.w(TAG, "Timer $timerId not found in persistence")
            return
        }

        if (!timer.isRunning()) {
            Log.d(TAG, "Timer $timerId is not running (status: ${timer.status}), skipping")
            return
        }

        val notifications = TimerNotifications(context)

        when (alarmType) {
            ALARM_TYPE_WARNING -> {
                notifications.showTimerWarningNotification(
                    notificationId = notificationId,
                    timerId = timerId,
                    cylinderType = cylinderType,
                    flowRate = flowRate
                )
                Log.d(TAG, "Warning notification shown for timer: $timerId")
            }
            ALARM_TYPE_FINISH -> {
                notifications.showTimerFinishedNotification(
                    notificationId = notificationId,
                    timerId = timerId,
                    cylinderType = cylinderType,
                    flowRate = flowRate
                )
                persistence.updateTimerStatus(timerId, TimerModel.STATUS_COMPLETED)
                Log.d(TAG, "Timer $timerId marked as completed, notification shown")
            }
        }
    }

    companion object {
        const val EXTRA_TIMER_ID = "timer_id"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_CYLINDER_TYPE = "cylinder_type"
        const val EXTRA_FLOW_RATE = "flow_rate"
        const val EXTRA_ALARM_TYPE = "alarm_type"
        const val ALARM_TYPE_WARNING = "warning"
        const val ALARM_TYPE_FINISH = "finish"
        private const val TAG = "TimerAlarmReceiver"
    }
}
