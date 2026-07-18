package com.simats.macmind

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TimerBridge(context: Context, flutterEngine: FlutterEngine) {

    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL_NAME
    )

    fun register() {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "startTimer" -> handleStartTimer(call.arguments as Map<String, Any?>, result)
                    "cancelTimer" -> handleCancelTimer(call.arguments as Map<String, Any?>, result)
                    "pauseTimer" -> handlePauseTimer(call.arguments as Map<String, Any?>, result)
                    "resumeTimer" -> handleResumeTimer(call.arguments as Map<String, Any?>, result)
                    "getAllTimers" -> handleGetAllTimers(result)
                    "deleteTimer" -> handleDeleteTimer(call.arguments as Map<String, Any?>, result)
                    "markStopped" -> handleMarkStopped(call.arguments as Map<String, Any?>, result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Method call failed: ${call.method}", e)
                result.success(null)
            }
        }
    }

    private val persistence = TimerPersistence(context)
    private val alarms = TimerAlarms(context)
    private val notifications = TimerNotifications(context)

    private fun handleStartTimer(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        val finishTimestamp = (args["finishTimestamp"] as Number).toLong()
        val cylinderType = args["cylinderType"] as String
        val flowRate = (args["flowRate"] as Number).toInt()
        val durationSeconds = (args["durationSeconds"] as Number).toInt()
        val startTimestamp = (args["startTimestamp"] as Number).toLong()
        val activeRowIndex = (args["activeRowIndex"] as? Number)?.toInt() ?: 0

        val notificationId = persistence.getNextNotificationId()
        val requestCode = persistence.getNextRequestCode()

        val timer = TimerModel(
            timerId = timerId,
            startTimestamp = startTimestamp,
            finishTimestamp = finishTimestamp,
            durationSeconds = durationSeconds,
            remainingSeconds = durationSeconds,
            cylinderType = cylinderType,
            flowRate = flowRate,
            status = TimerModel.STATUS_RUNNING,
            notificationId = notificationId,
            requestCode = requestCode,
            activeRowIndex = activeRowIndex
        )

        persistence.saveTimer(timer)
        alarms.scheduleWarningAlarm(timer)
        alarms.scheduleFinishAlarm(timer)

        result.success(mapOf(
            "notificationId" to notificationId,
            "requestCode" to requestCode
        ))
    }

    private fun handleCancelTimer(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        cancelTimerById(timerId)
        result.success(true)
    }

    private fun handlePauseTimer(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        val remainingSeconds = (args["remainingSeconds"] as Number).toInt()

        val timer = persistence.loadTimer(timerId)
        if (timer != null) {
            alarms.cancelAllAlarms(timer)
            notifications.cancelNotification(timer.notificationId)
            persistence.updateTimerStatus(timerId, TimerModel.STATUS_PAUSED, remainingSeconds)
        }
        result.success(true)
    }

    private fun handleResumeTimer(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        val newFinishTimestamp = (args["newFinishTimestamp"] as Number).toLong()

        val timer = persistence.loadTimer(timerId)
        if (timer != null) {
            val remainingSeconds =
                ((newFinishTimestamp - System.currentTimeMillis()) / 1000).toInt()
            val updated = timer.copy(
                status = TimerModel.STATUS_RUNNING,
                finishTimestamp = newFinishTimestamp,
                remainingSeconds = remainingSeconds
            )
            persistence.saveTimer(updated)
            alarms.scheduleWarningAlarm(updated)
            alarms.scheduleFinishAlarm(updated)
        }
        result.success(true)
    }

    private fun handleGetAllTimers(result: MethodChannel.Result) {
        val timers = persistence.loadAllActiveTimers()
        val list = timers.map { timer ->
            mapOf(
                "timerId" to timer.timerId,
                "startTimestamp" to timer.startTimestamp,
                "finishTimestamp" to timer.finishTimestamp,
                "durationSeconds" to timer.durationSeconds,
                "remainingSeconds" to timer.remainingSeconds,
                "cylinderType" to timer.cylinderType,
                "flowRate" to timer.flowRate,
                "status" to timer.status,
                "notificationId" to timer.notificationId,
                "requestCode" to timer.requestCode,
                "activeRowIndex" to timer.activeRowIndex
            )
        }
        result.success(list)
    }

    private fun handleDeleteTimer(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        cancelTimerById(timerId)
        persistence.deleteTimer(timerId)
        result.success(true)
    }

    private fun handleMarkStopped(args: Map<String, Any?>, result: MethodChannel.Result) {
        val timerId = args["timerId"] as String
        cancelTimerById(timerId)
        persistence.updateTimerStatus(timerId, TimerModel.STATUS_STOPPED)
        result.success(true)
    }

    private fun cancelTimerById(timerId: String) {
        val timer = persistence.loadTimer(timerId)
        if (timer != null) {
            alarms.cancelAllAlarms(timer)
            notifications.cancelNotification(timer.notificationId)
        }
    }

    companion object {
        private const val TAG = "TimerBridge"
        const val CHANNEL_NAME = "com.simats.macmind/timer_bridge"
    }
}
