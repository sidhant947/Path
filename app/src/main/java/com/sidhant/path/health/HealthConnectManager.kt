package com.sidhant.path.health

import android.content.Context
import android.os.Build
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

class HealthConnectManager(private val context: Context) {

    fun isNativeAndroid14Available(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
        }
        return false
    }

    private fun getClient(): HealthConnectClient? {
        if (isNativeAndroid14Available()) {
            return HealthConnectClient.getOrCreate(context)
        }
        return null
    }

    val requiredPermissions = setOf(
        HealthPermission.getWritePermission(StepsRecord::class),
        HealthPermission.getReadPermission(StepsRecord::class)
    )

    suspend fun hasAllPermissions(): Boolean {
        val client = getClient() ?: return false
        val granted = client.permissionController.getGrantedPermissions()
        return granted.containsAll(requiredPermissions)
    }

    suspend fun writeTodaySteps(stepsCount: Int) {
        val client = getClient() ?: return
        if (!hasAllPermissions()) return

        val zoneId = ZoneId.systemDefault()
        val now = Instant.now()
        val startOfDay = ZonedDateTime.now(zoneId).toLocalDate().atStartOfDay(zoneId).toInstant()

        if (stepsCount <= 0 || startOfDay.isAfter(now)) return

        val record = StepsRecord(
            count = stepsCount.toLong(),
            startTime = startOfDay,
            startZoneOffset = zoneId.rules.getOffset(startOfDay),
            endTime = now,
            endZoneOffset = zoneId.rules.getOffset(now)
        )

        try {
            client.insertRecords(listOf(record))
        } catch (e: Exception) {}
    }
}
