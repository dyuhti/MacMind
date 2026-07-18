package com.simats.macmind

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class TimerAlarms(private val context: Context) {

    private val alarmManager: AlarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun scheduleFinishAlarm(timer: TimerModel) {
        val intent = buildAlarmIntent(timer, TimerAlarmReceiver.ALARM_TYPE_FINISH)
        val requestCode = timer.requestCode + 10000
        val pendingIntent = buildPendingIntent(intent, requestCode)
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            timer.finishTimestamp,
            pendingIntent
        )
    }

    fun scheduleWarningAlarm(timer: TimerModel) {
        val warningTimestamp = timer.finishTimestamp - WARNING_LEAD_MS
        val now = System.currentTimeMillis()

        if (warningTimestamp <= now || timer.durationSeconds <= 300) return

        val intent = buildAlarmIntent(timer, TimerAlarmReceiver.ALARM_TYPE_WARNING)
        val requestCode = timer.requestCode + 20000
        val pendingIntent = buildPendingIntent(intent, requestCode)
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            warningTimestamp,
            pendingIntent
        )
    }

    fun cancelFinishAlarm(timer: TimerModel) {
        val intent = buildAlarmIntent(timer, TimerAlarmReceiver.ALARM_TYPE_FINISH)
        val requestCode = timer.requestCode + 10000
        cancelPendingIntent(intent, requestCode)
    }

    fun cancelWarningAlarm(timer: TimerModel) {
        val intent = buildAlarmIntent(timer, TimerAlarmReceiver.ALARM_TYPE_WARNING)
        val requestCode = timer.requestCode + 20000
        cancelPendingIntent(intent, requestCode)
    }

    fun cancelAllAlarms(timer: TimerModel) {
        cancelFinishAlarm(timer)
        cancelWarningAlarm(timer)
    }

    private fun buildAlarmIntent(timer: TimerModel, alarmType: String): Intent {
        return Intent(context, TimerAlarmReceiver::class.java).apply {
            putExtra(TimerAlarmReceiver.EXTRA_TIMER_ID, timer.timerId)
            putExtra(TimerAlarmReceiver.EXTRA_NOTIFICATION_ID, timer.notificationId)
            putExtra(TimerAlarmReceiver.EXTRA_CYLINDER_TYPE, timer.cylinderType)
            putExtra(TimerAlarmReceiver.EXTRA_FLOW_RATE, timer.flowRate)
            putExtra(TimerAlarmReceiver.EXTRA_ALARM_TYPE, alarmType)
        }
    }

    private fun buildPendingIntent(intent: Intent, requestCode: Int): PendingIntent {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun cancelPendingIntent(intent: Intent, requestCode: Int) {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    companion object {
        const val WARNING_LEAD_MS = 300_000L
    }
}
