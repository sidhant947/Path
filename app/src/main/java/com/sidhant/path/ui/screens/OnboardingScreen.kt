package com.sidhant.path.ui.screens

import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BatterySaver
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.DirectionsRun
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sidhant.path.ui.theme.getAccentColor

data class OnboardingStepData(
    val icon: ImageVector,
    val title: String,
    val description: String,
    val buttonLabel: String
)

@Composable
fun OnboardingScreen(
    accentColorName: String,
    onCompleteOnboarding: () -> Unit
) {
    val context = LocalContext.current
    val accentColor = getAccentColor(accentColorName)
    var currentStep by remember { mutableIntStateOf(0) }

    var activityGranted by remember { mutableStateOf(false) }
    var batteryGranted by remember {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        mutableStateOf(pm.isIgnoringBatteryOptimizations(context.packageName))
    }
    var notificationGranted by remember { mutableStateOf(false) }

    val activityLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        activityGranted = isGranted
        if (isGranted) currentStep = 1
    }

    val notificationLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        notificationGranted = isGranted
        onCompleteOnboarding()
    }

    val steps = listOf(
        OnboardingStepData(
            icon = Icons.Rounded.DirectionsRun,
            title = "Activity Access",
            description = "Path needs activity recognition to track your steps accurately and help you reach your fitness goals.",
            buttonLabel = "GRANT ACCESS"
        ),
        OnboardingStepData(
            icon = Icons.Rounded.BatterySaver,
            title = "Unrestricted Access",
            description = "To track steps even when the app is closed, please disable battery optimization for Path.",
            buttonLabel = "REMOVE RESTRICTIONS"
        ),
        OnboardingStepData(
            icon = Icons.Rounded.NotificationsActive,
            title = "Stay Updated",
            description = "Get real-time step count updates in your notification bar so you always know your progress.",
            buttonLabel = "ENABLE NOTIFICATIONS"
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 32.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(32.dp))

            Row(
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.fillMaxWidth()
            ) {
                steps.indices.forEach { index ->
                    val isActive = index == currentStep
                    val isCompleted = index < currentStep
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .height(8.dp)
                            .width(if (isActive) 32.dp else 8.dp)
                            .background(
                                color = if (isActive || isCompleted) accentColor else Color.Gray.copy(alpha = 0.2f),
                                shape = RoundedCornerShape(4.dp)
                            )
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            val step = steps[currentStep]

            Box(
                modifier = Modifier
                    .size(120.dp)
                    .background(accentColor.copy(alpha = 0.15f), shape = CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = step.icon,
                    contentDescription = null,
                    modifier = Modifier.size(60.dp),
                    tint = accentColor
                )
            }

            Spacer(modifier = Modifier.height(48.dp))

            Text(
                text = step.title,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = step.description,
                fontSize = 16.sp,
                color = Color.Gray,
                textAlign = TextAlign.Center,
                lineHeight = 24.sp
            )

            Spacer(modifier = Modifier.weight(1f))

            val isCurrentGranted = when (currentStep) {
                0 -> activityGranted
                1 -> batteryGranted
                2 -> notificationGranted
                else -> false
            }

            if (isCurrentGranted) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(vertical = 20.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.CheckCircle,
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(28.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Granted",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                }
            } else {
                Button(
                    onClick = {
                        when (currentStep) {
                            0 -> {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    activityLauncher.launch(Manifest.permission.ACTIVITY_RECOGNITION)
                                } else {
                                    activityGranted = true
                                    currentStep = 1
                                }
                            }
                            1 -> {
                                try {
                                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                        data = Uri.parse("package:${context.packageName}")
                                    }
                                    context.startActivity(intent)
                                } catch (e: Exception) {
                                    batteryGranted = true
                                }
                                currentStep = 2
                            }
                            2 -> {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                } else {
                                    notificationGranted = true
                                    onCompleteOnboarding()
                                }
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp),
                    shape = RoundedCornerShape(30.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = accentColor,
                        contentColor = Color.Black
                    ),
                    elevation = ButtonDefaults.buttonElevation(0.dp)
                ) {
                    Text(
                        text = step.buttonLabel,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}
