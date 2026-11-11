package com.sidhant.path.health

import android.content.Context
import android.os.Build
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class HealthConnectManager(private val context: Context) {

    private val syncMutex = Mutex()

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
        val today = LocalDate.now(zoneId)
        val startOfDay = today.atStartOfDay(zoneId).toInstant()
        val endOfDay = today.plusDays(1).atStartOfDay(zoneId).toInstant()

        if (stepsCount <= 0 || !now.isAfter(startOfDay)) return

        val safeEndTime = if (now.isAfter(endOfDay)) endOfDay else now

        val record = StepsRecord(
            count = stepsCount.toLong(),
            startTime = startOfDay,
            startZoneOffset = zoneId.rules.getOffset(startOfDay),
            endTime = safeEndTime,
            endZoneOffset = zoneId.rules.getOffset(safeEndTime),
            metadata = Metadata(
                clientRecordId = "path_steps_$today",
                clientRecordVersion = System.currentTimeMillis()
            )
        )

        syncMutex.withLock {
            try {
                client.deleteRecords(
                    StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startOfDay, endOfDay)
                )
            } catch (_: Exception) {}
            try {
                client.insertRecords(listOf(record))
            } catch (_: Exception) {}
        }
    }
}
