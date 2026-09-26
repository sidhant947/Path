package com.sidhant.path.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import androidx.core.app.NotificationCompat
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.updateAll
import com.sidhant.path.MainActivity
import com.sidhant.path.R
import com.sidhant.path.data.StepRepository
import com.sidhant.path.health.HealthConnectManager
import com.sidhant.path.widget.PathWidget
import com.sidhant.path.widget.PathWidgetReceiver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.sqrt

class StepTrackingService : Service(), SensorEventListener {

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val binder = LocalBinder()
    private lateinit var repository: StepRepository
    private lateinit var healthConnectManager: HealthConnectManager
    private lateinit var motionDetector: MotionDetector
    private lateinit var sensorManager: SensorManager

    private var stepCounterSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null

    private var isUsingAccelerometer = false
    private var lastAccStepTime = 0L

    var onStepsUpdatedListener: (() -> Unit)? = null

    inner class LocalBinder : Binder() {
        fun getService(): StepTrackingService = this@StepTrackingService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        repository = StepRepository(this)
        healthConnectManager = HealthConnectManager(this)
        motionDetector = MotionDetector(this)
        motionDetector.setSensitivity(repository.getMotionSensitivity())
        motionDetector.start()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        if (stepCounterSensor != null) {
            sensorManager.registerListener(this, stepCounterSensor, SensorManager.SENSOR_DELAY_UI)
        } else {
            isUsingAccelerometer = true
            accelerometerSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            accelerometerSensor?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
        }

        createNotificationChannel()
        startForegroundServiceInternal()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundServiceInternal()
        updateNotification()
        updateWidget()
        syncHealthConnect()
        return START_STICKY
    }

    private fun startForegroundServiceInternal() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        repository.handleDateChangeIfNeeded()

        if (event.sensor.type == Sensor.TYPE_STEP_COUNTER) {
            val totalSteps = event.values[0].toInt()
            val lastTotal = repository.getLastSensorTotal()

            if (lastTotal <= 0) {
                repository.setLastSensorTotal(totalSteps)
            } else if (totalSteps > lastTotal) {
                val delta = totalSteps - lastTotal
                if (!motionDetector.isInVehicle) {
                    val isRunning = motionDetector.currentActivity == ActivityType.RUNNING
                    repository.recordStepDelta(delta, isRunning)
                    repository.checkAndSaveStreakPb()
                    updateNotification()
                    updateWidget()
                    syncHealthConnect()
                    onStepsUpdatedListener?.invoke()
                }
                repository.setLastSensorTotal(totalSteps)
            } else if (totalSteps < lastTotal) {
                if (totalSteps < 100 || totalSteps < lastTotal / 2) {
                    if (!motionDetector.isInVehicle) {
                        val isRunning = motionDetector.currentActivity == ActivityType.RUNNING
                        repository.recordStepDelta(totalSteps, isRunning)
                        repository.checkAndSaveStreakPb()
                        updateNotification()
                        updateWidget()
                        syncHealthConnect()
                        onStepsUpdatedListener?.invoke()
                    }
                    repository.setLastSensorTotal(totalSteps)
                }
            }
        } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER && isUsingAccelerometer) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]
            val mag = sqrt((x * x + y * y + z * z).toDouble())
            val now = System.currentTimeMillis()

            if (mag > 11.5 && (now - lastAccStepTime) > 350) {
                lastAccStepTime = now
                if (!motionDetector.isInVehicle) {
                    val isRunning = motionDetector.currentActivity == ActivityType.RUNNING
                    repository.recordStepDelta(1, isRunning)
                    repository.checkAndSaveStreakPb()
                    updateNotification()
                    updateWidget()
                    syncHealthConnect()
                    onStepsUpdatedListener?.invoke()
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    fun updateNotification() {
        if (!repository.isNotificationEnabled()) return
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    fun updateWidget() {
        serviceScope.launch {
            try {
                val glanceManager = GlanceAppWidgetManager(applicationContext)
                val glanceIds = glanceManager.getGlanceIds(PathWidget::class.java)
                val widget = PathWidget()
                if (glanceIds.isNotEmpty()) {
                    for (glanceId in glanceIds) {
                        widget.update(applicationContext, glanceId)
                    }
                } else {
                    widget.updateAll(applicationContext)
                }
            } catch (e: Exception) {
                try {
                    PathWidget().updateAll(applicationContext)
                } catch (_: Exception) {}
            }

            try {
                val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                val component = ComponentName(applicationContext, PathWidgetReceiver::class.java)
                val ids = appWidgetManager.getAppWidgetIds(component)
                if (ids != null && ids.isNotEmpty()) {
                    val intent = Intent(applicationContext, PathWidgetReceiver::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    }
                    applicationContext.sendBroadcast(intent)
                }
            } catch (_: Exception) {}
        }
    }

    fun syncHealthConnect() {
        if (healthConnectManager.isNativeAndroid14Available() && repository.isHealthConnectEnabled()) {
            val todaySteps = repository.getTodaySteps()
            serviceScope.launch {
                healthConnectManager.writeTodaySteps(todaySteps)
            }
        }
    }

    private fun buildNotification(): Notification {
        val steps = repository.getTodaySteps()
        val goal = repository.getCurrentGoal()
        val progress = if (goal > 0) ((steps.toFloat() / goal.toFloat()) * 100).toInt().coerceIn(0, 100) else 0

        val title: String
        val content: String

        if (steps >= goal) {
            title = "Goal Achieved! 🎉"
            content = "Amazing! ${formatNumber(steps)} steps today!"
        } else {
            title = "Path - Step Tracker"
            content = "${formatNumber(steps)} / ${formatNumber(goal)} steps ($progress%)"
        }

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Step Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun formatNumber(num: Int): String {
        return String.format("%,d", num)
    }

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        motionDetector.stop()
        serviceScope.cancel()
        super.onDestroy()
    }

    companion object {
        const val CHANNEL_ID = "path_step_tracking"
        const val NOTIFICATION_ID = 888
    }
}
