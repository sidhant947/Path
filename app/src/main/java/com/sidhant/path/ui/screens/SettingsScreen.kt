package com.sidhant.path.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBackIos
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.DeveloperMode
import androidx.compose.material.icons.rounded.Palette
import androidx.compose.material.icons.rounded.Radar
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.health.connect.client.PermissionController
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.runtime.rememberCoroutineScope
import kotlinx.coroutines.launch
import com.sidhant.path.health.HealthConnectManager
import com.sidhant.path.data.StepRepository
import com.sidhant.path.ui.theme.SpaceGroteskFontFamily
import com.sidhant.path.ui.theme.getAccentColor

@Composable
fun SettingsScreen(
    repository: StepRepository,
    onBack: () -> Unit,
    onThemeOrAccentChanged: () -> Unit
) {
    BackHandler(onBack = onBack)
    val context = LocalContext.current
    val isDark = isSystemInDarkTheme()
    val cardColor = if (isDark) Color(0xFF1A1A1A) else Color(0xFFF2F2F2)
    val primaryTextColor = if (isDark) Color.White else Color.Black

    var selectedAccent by remember { mutableStateOf(repository.getAccentColorName()) }
    var selectedTheme by remember { mutableStateOf(repository.getThemeMode()) }

    var flexibleGoals by remember { mutableStateOf(repository.isFlexibleGoalsEnabled()) }
    var weekdayGoalText by remember { mutableStateOf(repository.getGoalWeekday().toString()) }
    var weekendGoalText by remember { mutableStateOf(repository.getGoalWeekend().toString()) }

    var motionSensitivity by remember { mutableStateOf(repository.getMotionSensitivity()) }

    val healthConnectManager = remember { HealthConnectManager(context) }
    val isHcAvailable = remember { healthConnectManager.isNativeAndroid14Available() }
    var healthConnectEnabled by remember { mutableStateOf(repository.isHealthConnectEnabled()) }
    val coroutineScope = rememberCoroutineScope()

    val permissionContract = PermissionController.createRequestPermissionResultContract()
    val permissionLauncher = rememberLauncherForActivityResult(permissionContract) { grantedPermissions ->
        val hasAll = grantedPermissions.containsAll(healthConnectManager.requiredPermissions)
        healthConnectEnabled = hasAll
        repository.setHealthConnectEnabled(hasAll)
    }

    val currentAccentColor = getAccentColor(selectedAccent)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.align(Alignment.CenterStart)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Rounded.ArrowBackIos,
                    contentDescription = null,
                    tint = primaryTextColor
                )
            }
            Text(
                text = "SETTINGS",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = 1.5.sp,
                color = primaryTextColor,
                modifier = Modifier.align(Alignment.Center)
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp)
        ) {
            SectionHeader("APPEARANCE", Icons.Rounded.Palette, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = "ACCENT COLOR",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        letterSpacing = 1.0.sp
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceAround
                    ) {
                        listOf("Lime", "Pink", "Blue", "Green", "Orange").forEach { name ->
                            val color = getAccentColor(name)
                            val isSelected = selectedAccent == name
                            Box(
                                modifier = Modifier
                                    .size(44.dp)
                                    .background(color, shape = CircleShape)
                                    .border(
                                        width = if (isSelected) 3.dp else 0.dp,
                                        color = if (isSelected) primaryTextColor else Color.Transparent,
                                        shape = CircleShape
                                    )
                                    .clickable {
                                        selectedAccent = name
                                        repository.setAccentColorName(name)
                                        onThemeOrAccentChanged()
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Rounded.Check,
                                        contentDescription = null,
                                        tint = Color.Black,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = "THEME MODE",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        letterSpacing = 1.0.sp
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(modifier = Modifier.fillMaxWidth()) {
                        listOf("system", "light", "dark").forEach { mode ->
                            val selected = selectedTheme == mode
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(horizontal = 4.dp)
                                    .background(
                                        color = if (selected) currentAccentColor else if (isDark) Color(0xFF2C2C2C) else Color(0xFFE0E0E0),
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    .clickable {
                                        selectedTheme = mode
                                        repository.setThemeMode(mode)
                                        onThemeOrAccentChanged()
                                    }
                                    .padding(vertical = 12.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = mode.uppercase(),
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = SpaceGroteskFontFamily,
                                    color = if (selected) Color.Black else primaryTextColor
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            SectionHeader("DAILY TARGETS", Icons.Rounded.Radar, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "FLEXIBLE DAILY GOALS",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = SpaceGroteskFontFamily,
                            color = primaryTextColor
                        )
                        Switch(
                            checked = flexibleGoals,
                            onCheckedChange = {
                                flexibleGoals = it
                                repository.setFlexibleGoalsEnabled(it)
                            },
                            colors = SwitchDefaults.colors(checkedThumbColor = currentAccentColor)
                        )
                    }

                    AnimatedVisibility(visible = flexibleGoals) {
                        Column {
                            Spacer(modifier = Modifier.height(12.dp))
                            Row(modifier = Modifier.fillMaxWidth()) {
                                InputField(
                                    label = "WEEKDAY GOAL",
                                    value = weekdayGoalText,
                                    onValueChange = {
                                        weekdayGoalText = it
                                        repository.setGoalWeekday(it.toIntOrNull() ?: 10000)
                                    },
                                    isDark = isDark,
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                InputField(
                                    label = "WEEKEND GOAL",
                                    value = weekendGoalText,
                                    onValueChange = {
                                        weekendGoalText = it
                                        repository.setGoalWeekend(it.toIntOrNull() ?: 6000)
                                    },
                                    isDark = isDark,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            SectionHeader("MOTION CALIBRATION", Icons.Rounded.Tune, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = "VEHICLE ACCURACY SENSITIVITY",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = primaryTextColor
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "High sensitivity counts fewer false steps in buses/trains but might miss light footsteps. Low sensitivity counts more active steps but may register transport steps.",
                        fontSize = 12.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(modifier = Modifier.fillMaxWidth()) {
                        listOf("low", "medium", "high").forEach { sensitivity ->
                            val selected = motionSensitivity == sensitivity
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(horizontal = 4.dp)
                                    .background(
                                        color = if (selected) currentAccentColor else if (isDark) Color(0xFF2C2C2C) else Color(0xFFE0E0E0),
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    .clickable {
                                        motionSensitivity = sensitivity
                                        repository.setMotionSensitivity(sensitivity)
                                    }
                                    .padding(vertical = 12.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = sensitivity.uppercase(),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = SpaceGroteskFontFamily,
                                    color = if (selected) Color.Black else primaryTextColor
                                )
                            }
                        }
                    }
                }
            }

            if (isHcAvailable) {
                Spacer(modifier = Modifier.height(28.dp))
                SectionHeader("HEALTH CONNECT", Icons.Rounded.Favorite, currentAccentColor)
                Spacer(modifier = Modifier.height(12.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(cardColor, shape = RoundedCornerShape(20.dp))
                        .padding(16.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "SYNC TO HEALTH CONNECT",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = SpaceGroteskFontFamily,
                                    color = primaryTextColor
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "AOSP Native sync (Android 14+). Requires no Google Play Services.",
                                    fontSize = 12.sp,
                                    fontFamily = SpaceGroteskFontFamily,
                                    color = Color.Gray,
                                    lineHeight = 16.sp
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Switch(
                                checked = healthConnectEnabled,
                                onCheckedChange = { checked ->
                                    if (checked) {
                                        coroutineScope.launch {
                                            if (healthConnectManager.hasAllPermissions()) {
                                                healthConnectEnabled = true
                                                repository.setHealthConnectEnabled(true)
                                            } else {
                                                permissionLauncher.launch(healthConnectManager.requiredPermissions)
                                            }
                                        }
                                    } else {
                                        healthConnectEnabled = false
                                        repository.setHealthConnectEnabled(false)
                                    }
                                },
                                colors = SwitchDefaults.colors(checkedThumbColor = currentAccentColor)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            SectionHeader("BACKGROUND DIAGNOSTICS", Icons.Rounded.DeveloperMode, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = "AGGRESSIVE BATTERY SAVING",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = primaryTextColor
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Android manufacturers frequently shut down background pedometers. Follow these steps for your device to ensure continuous tracking:",
                        fontSize = 12.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    DiagnosticItem("Google Pixel", "Settings > Apps > Path > Battery > Select 'Unrestricted'.", primaryTextColor)
                    DiagnosticItem("Samsung", "Settings > Battery > Background usage limits > Ensure Path is not in sleeping apps list.", primaryTextColor)
                    DiagnosticItem("Xiaomi / Redmi", "App Info > Battery Saver > Select 'No restrictions'.", primaryTextColor)
                    DiagnosticItem("OnePlus", "Settings > Apps > App management > Path > Battery usage > Enable 'Allow background activity'.", primaryTextColor)
                    Spacer(modifier = Modifier.height(16.dp))
                    OutlinedButton(
                        onClick = {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://dontkillmyapp.com"))
                            context.startActivity(intent)
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Text(
                            text = "DONTKILLMYAPP.COM GUIDE",
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            fontFamily = SpaceGroteskFontFamily,
                            letterSpacing = 1.0.sp,
                            color = primaryTextColor
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

@Composable
private fun SectionHeader(title: String, icon: ImageVector, accentColor: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(imageVector = icon, contentDescription = null, tint = accentColor, modifier = Modifier.size(20.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = title,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            letterSpacing = 1.5.sp,
            color = Color.Gray
        )
    }
}

@Composable
private fun InputField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val textColor = if (isDark) Color.White else Color.Black
    val bg = if (isDark) Color(0xFF2C2C2C) else Color(0xFFE0E0E0)

    Column(modifier = modifier) {
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            color = Color.Gray,
            letterSpacing = 1.0.sp
        )
        Spacer(modifier = Modifier.height(8.dp))
        BasicTextField(
            value = value,
            onValueChange = {
                if (it.all { char -> char.isDigit() } && it.length <= 6) {
                    onValueChange(it)
                }
            },
            textStyle = TextStyle(
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                color = textColor,
                textAlign = TextAlign.Start
            ),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            cursorBrush = SolidColor(textColor),
            singleLine = true,
            decorationBox = { innerTextField ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(bg, shape = RoundedCornerShape(12.dp))
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                ) {
                    innerTextField()
                }
            }
        )
    }
}

@Composable
private fun DiagnosticItem(device: String, instruction: String, primaryColor: Color) {
    Column(modifier = Modifier.padding(bottom = 12.dp)) {
        Text(
            text = device,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            color = primaryColor
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = instruction,
            fontSize = 12.sp,
            fontFamily = SpaceGroteskFontFamily,
            color = Color.Gray,
            lineHeight = 16.sp
        )
    }
}
