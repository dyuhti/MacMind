package com.simats.macmind

data class TimerModel(
    val timerId: String,
    val startTimestamp: Long,
    val finishTimestamp: Long,
    val durationSeconds: Int,
    val remainingSeconds: Int,
    val cylinderType: String,
    val flowRate: Int,
    val status: String,
    val notificationId: Int,
    val requestCode: Int,
    val activeRowIndex: Int = 0
) {
    companion object {
        const val STATUS_RUNNING = "running"
        const val STATUS_PAUSED = "paused"
        const val STATUS_COMPLETED = "completed"
        const val STATUS_STOPPED = "stopped"
    }

    fun isRunning(): Boolean = status == STATUS_RUNNING
    fun isPaused(): Boolean = status == STATUS_PAUSED
    fun isActive(): Boolean = isRunning() || isPaused()
}
