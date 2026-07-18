package com.example.med_calci_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class TimerNotifications(private val context: Context) {

    private val notificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESC
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showTimerFinishedNotification(
        notificationId: Int,
        timerId: String,
        cylinderType: String,
        flowRate: Int
    ) {
        val openIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("timer_id", timerId)
            }
            ?: Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("timer_id", timerId)
            }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            openIntent,
            pendingFlags
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, CHANNEL_ID)
        } else {
            android.app.Notification.Builder(context)
        }.apply {
            setContentTitle("Oxygen Cylinder Alert")
            setContentText(
                "Oxygen consumption timer finished.\n" +
                "Cylinder: $cylinderType\n" +
                "Flow Rate: $flowRate L/min\n" +
                "Oxygen supply exhausted."
            )
            setSmallIcon(android.R.drawable.ic_dialog_alert)
            setPriority(android.app.Notification.PRIORITY_MAX)
            setAutoCancel(true)
            setContentIntent(pendingIntent)
            setDefaults(android.app.Notification.DEFAULT_ALL)
            setCategory(android.app.Notification.CATEGORY_ALARM)
            setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
        }.build()

        notificationManager.notify(notificationId, notification)
    }

    fun showTimerWarningNotification(
        notificationId: Int,
        timerId: String,
        cylinderType: String,
        flowRate: Int
    ) {
        val openIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("timer_id", timerId)
            }
            ?: Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("timer_id", timerId)
            }

        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId + 50000,
            openIntent,
            pendingFlags
        )

        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, CHANNEL_ID)
        } else {
            android.app.Notification.Builder(context)
        }.apply {
            setContentTitle("⚠️ Oxygen Running Low")
            setContentText(
                "Oxygen supply is running low.\n" +
                "Cylinder: $cylinderType\n" +
                "Flow Rate: $flowRate L/min\n" +
                "Please prepare a replacement cylinder."
            )
            setSmallIcon(android.R.drawable.ic_dialog_alert)
            setPriority(android.app.Notification.PRIORITY_HIGH)
            setAutoCancel(true)
            setContentIntent(pendingIntent)
            setDefaults(android.app.Notification.DEFAULT_ALL)
            setCategory(android.app.Notification.CATEGORY_ALARM)
            setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
        }.build()

        notificationManager.notify(notificationId, notification)
    }

    fun cancelNotification(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }

    fun cancelWarningNotification(notificationId: Int) {
        notificationManager.cancel(notificationId)
    }

    companion object {
        const val CHANNEL_ID = "oxygen_timer_channel"
        const val CHANNEL_NAME = "Oxygen Cylinder Alert"
        const val CHANNEL_DESC = "Alerts when the oxygen timer reaches zero"
    }
}
