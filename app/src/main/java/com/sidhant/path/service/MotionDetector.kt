package com.sidhant.path.service

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.sqrt

enum class ActivityType { STATIONARY, WALKING, RUNNING, VEHICLE }

class MotionDetector(context: Context) : SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)

    private val windowSize = 50
    private var vehicleVarThreshold = 0.6
    private var vehicleSpikeThreshold = 3.0
    private val bikeVarMin = 0.6
    private val bikeVarMax = 2.5

    private val accMagWindow = DoubleArray(windowSize)
    private val gyroMagWindow = DoubleArray(windowSize)
    private var accIndex = 0
    private var gyroIndex = 0
    private var accCount = 0
    private var gyroCount = 0

    private var lastEvaluation = System.currentTimeMillis()
    var isInVehicle: Boolean = false
        private set
    var currentActivity: ActivityType = ActivityType.STATIONARY
        private set

    fun setSensitivity(sensitivity: String) {
        when (sensitivity) {
            "high" -> {
                vehicleVarThreshold = 0.8
                vehicleSpikeThreshold = 4.0
            }
            "low" -> {
                vehicleVarThreshold = 0.4
                vehicleSpikeThreshold = 2.0
            }
            else -> {
                vehicleVarThreshold = 0.6
                vehicleSpikeThreshold = 3.0
            }
        }
    }

    fun start() {
        accelerometer?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
        gyroscope?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME) }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        accCount = 0
        gyroCount = 0
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                val mag = abs(magnitude(event.values[0], event.values[1], event.values[2]) - 9.81)
                accMagWindow[accIndex] = mag
                accIndex = (accIndex + 1) % windowSize
                if (accCount < windowSize) accCount++
                evaluate()
            }
            Sensor.TYPE_GYROSCOPE -> {
                val mag = abs(magnitude(event.values[0], event.values[1], event.values[2]))
                gyroMagWindow[gyroIndex] = mag
                gyroIndex = (gyroIndex + 1) % windowSize
                if (gyroCount < windowSize) gyroCount++
                evaluate()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun evaluate() {
        val now = System.currentTimeMillis()
        if (now - lastEvaluation < 200) return
        if (accCount < windowSize || gyroCount < 10) return

        lastEvaluation = now

        var accSum = 0.0
        var maxAcc = 0.0
        for (i in 0 until accCount) {
            val v = accMagWindow[i]
            accSum += v
            if (v > maxAcc) maxAcc = v
        }
        val accMean = accSum / accCount

        var accVarSum = 0.0
        for (i in 0 until accCount) {
            accVarSum += (accMagWindow[i] - accMean).pow(2.0)
        }
        val accVar = accVarSum / accCount

        var gyroSum = 0.0
        for (i in 0 until gyroCount) {
            gyroSum += gyroMagWindow[i]
        }
        val gyroMean = gyroSum / gyroCount

        val vehicleLike = accVar < vehicleVarThreshold && maxAcc < vehicleSpikeThreshold
        val bikeLike = accVar in bikeVarMin..bikeVarMax && gyroMean > 0.4

        isInVehicle = vehicleLike || bikeLike

        currentActivity = when {
            isInVehicle -> ActivityType.VEHICLE
            accVar < 0.05 -> ActivityType.STATIONARY
            accVar >= 3.0 -> ActivityType.RUNNING
            else -> ActivityType.WALKING
        }
    }

    private fun magnitude(x: Float, y: Float, z: Float): Double {
        return sqrt((x * x + y * y + z * z).toDouble())
    }
}
