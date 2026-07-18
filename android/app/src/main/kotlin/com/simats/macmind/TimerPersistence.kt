package com.simats.macmind

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

class TimerPersistence(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("oxygen_timers", Context.MODE_PRIVATE)

    fun saveTimer(timer: TimerModel) {
        prefs.edit().putString("timer_${timer.timerId}", timer.toJson().toString()).apply()
        val ids = getActiveTimerIds().toMutableList()
        if (!ids.contains(timer.timerId)) {
            ids.add(timer.timerId)
            saveActiveTimerIds(ids)
        }
    }

    fun getActiveTimerIds(): List<String> {
        val raw = prefs.getString("active_timer_ids", "[]") ?: "[]"
        val arr = JSONArray(raw)
        return (0 until arr.length()).map { arr.getString(it) }
    }

    fun loadTimer(timerId: String): TimerModel? {
        val raw = prefs.getString("timer_$timerId", null) ?: return null
        return fromJson(JSONObject(raw))
    }

    fun loadAllActiveTimers(): List<TimerModel> {
        return getActiveTimerIds().mapNotNull { loadTimer(it) }
    }

    fun deleteTimer(timerId: String) {
        prefs.edit().remove("timer_$timerId").apply()
        val ids = getActiveTimerIds().toMutableList()
        ids.remove(timerId)
        saveActiveTimerIds(ids)
    }

    fun updateTimerStatus(timerId: String, status: String, remainingSeconds: Int? = null) {
        val timer = loadTimer(timerId) ?: return
        val updated = timer.copy(
            status = status,
            remainingSeconds = if (remainingSeconds != null) remainingSeconds else timer.remainingSeconds
        )
        saveTimer(updated)
    }

    fun getNextNotificationId(): Int {
        val id = prefs.getInt("next_notification_id", 10000)
        val next = if (id >= 99999) 10000 else id + 1
        prefs.edit().putInt("next_notification_id", next).apply()
        return id
    }

    fun getNextRequestCode(): Int {
        val code = prefs.getInt("next_request_code", 1000)
        val next = if (code >= 9999) 1000 else code + 1
        prefs.edit().putInt("next_request_code", next).apply()
        return code
    }

    private fun saveActiveTimerIds(ids: List<String>) {
        val arr = JSONArray(ids)
        prefs.edit().putString("active_timer_ids", arr.toString()).apply()
    }

    private fun TimerModel.toJson(): JSONObject {
        return JSONObject().apply {
            put("timerId", timerId)
            put("startTimestamp", startTimestamp)
            put("finishTimestamp", finishTimestamp)
            put("durationSeconds", durationSeconds)
            put("remainingSeconds", remainingSeconds)
            put("cylinderType", cylinderType)
            put("flowRate", flowRate)
            put("status", status)
            put("notificationId", notificationId)
            put("requestCode", requestCode)
            put("activeRowIndex", activeRowIndex)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): TimerModel {
            return TimerModel(
                timerId = json.getString("timerId"),
                startTimestamp = json.getLong("startTimestamp"),
                finishTimestamp = json.getLong("finishTimestamp"),
                durationSeconds = json.getInt("durationSeconds"),
                remainingSeconds = json.getInt("remainingSeconds"),
                cylinderType = json.getString("cylinderType"),
                flowRate = json.getInt("flowRate"),
                status = json.getString("status"),
                notificationId = json.getInt("notificationId"),
                requestCode = json.getInt("requestCode"),
                activeRowIndex = json.optInt("activeRowIndex", 0)
            )
        }
    }
}
