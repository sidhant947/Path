package com.sidhant.path.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import com.sidhant.path.data.StepRepository
import com.sidhant.path.service.StepTrackingService

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON" ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val repository = StepRepository(context)
            if (repository.isOnboardingComplete()) {
                val serviceIntent = Intent(context, StepTrackingService::class.java)
                try {
                    ContextCompat.startForegroundService(context, serviceIntent)
                } catch (_: Exception) {
                }
            }
        }
    }
}
