package com.sidhant.path.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.rounded.Folder
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
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sidhant.path.R
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import android.widget.Toast
import androidx.health.connect.client.PermissionController
import androidx.compose.material.icons.rounded.Backup
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
    val cardColor = MaterialTheme.colorScheme.surface
    val primaryTextColor = MaterialTheme.colorScheme.onSurface

    var selectedAccent by remember { mutableStateOf(repository.getAccentColorName()) }
    var hexInput by remember { mutableStateOf(if (selectedAccent.startsWith("#")) selectedAccent else "") }
    var selectedTheme by remember { mutableStateOf(repository.getThemeMode()) }

    var flexibleGoals by remember { mutableStateOf(repository.isFlexibleGoalsEnabled()) }
    var weekdayGoalText by remember { mutableStateOf(repository.getGoalWeekday().toString()) }
    var weekendGoalText by remember { mutableStateOf(repository.getGoalWeekend().toString()) }

    var motionSensitivity by remember { mutableStateOf(repository.getMotionSensitivity()) }

    val healthConnectManager = remember { HealthConnectManager(context) }
    val isHcAvailable = remember { healthConnectManager.isNativeAndroid14Available() }
    var healthConnectEnabled by remember { mutableStateOf(repository.isHealthConnectEnabled()) }
    var autoBackupEnabled by remember { mutableStateOf(repository.isAutoBackupEnabled()) }
    var autoBackupDirUri by remember { mutableStateOf(repository.getAutoBackupDirectoryUri()) }
    var lastAutoBackupDate by remember { mutableStateOf(repository.getLastAutoBackupDate()) }
    val coroutineScope = rememberCoroutineScope()

    val permissionContract = PermissionController.createRequestPermissionResultContract()
    val permissionLauncher = rememberLauncherForActivityResult(permissionContract) { grantedPermissions ->
        val hasAll = grantedPermissions.containsAll(healthConnectManager.requiredPermissions)
        healthConnectEnabled = hasAll
        repository.setHealthConnectEnabled(hasAll)
        if (hasAll) {
            coroutineScope.launch {
                healthConnectManager.writeTodaySteps(repository.getTodaySteps())
            }
        }
    }

    val exportLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/json")
    ) { uri ->
        if (uri != null) {
            val success = try {
                context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                    repository.exportBackup(outputStream)
                }
                true
            } catch (e: Exception) {
                false
            }
            val msg = if (success) context.getString(R.string.toast_backup_exported) else context.getString(R.string.toast_backup_export_failed)
            Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
        }
    }

    val folderPickerLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { uri ->
        if (uri != null) {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try {
                context.contentResolver.takePersistableUriPermission(uri, flags)
            } catch (_: Exception) {}
            val uriStr = uri.toString()
            repository.setAutoBackupDirectoryUri(uriStr)
            autoBackupDirUri = uriStr
            autoBackupEnabled = true
            repository.setAutoBackupEnabled(true)
            repository.performAutoBackup()
            lastAutoBackupDate = repository.getLastAutoBackupDate()
        }
    }

    val importLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri != null) {
            val success = try {
                context.contentResolver.openInputStream(uri)?.use { inputStream ->
                    repository.importBackup(inputStream)
                } ?: false
            } catch (e: Exception) {
                false
            }
            if (success) {
                selectedAccent = repository.getAccentColorName()
                hexInput = if (selectedAccent.startsWith("#")) selectedAccent else ""
                selectedTheme = repository.getThemeMode()
                flexibleGoals = repository.isFlexibleGoalsEnabled()
                weekdayGoalText = repository.getGoalWeekday().toString()
                weekendGoalText = repository.getGoalWeekend().toString()
                motionSensitivity = repository.getMotionSensitivity()
                healthConnectEnabled = repository.isHealthConnectEnabled()
                autoBackupEnabled = repository.isAutoBackupEnabled()
                autoBackupDirUri = repository.getAutoBackupDirectoryUri()
                lastAutoBackupDate = repository.getLastAutoBackupDate()
                onThemeOrAccentChanged()
                Toast.makeText(context, context.getString(R.string.toast_backup_restored), Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(context, context.getString(R.string.toast_backup_restore_failed), Toast.LENGTH_SHORT).show()
            }
        }
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
                text = stringResource(R.string.title_settings),
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
            SectionHeader(stringResource(R.string.section_appearance), Icons.Rounded.Palette, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = stringResource(R.string.label_accent_color),
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
                                        hexInput = ""
                                        repository.setAccentColorName(name)
                                        onThemeOrAccentChanged()
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                if (isSelected) {
                                    Icon(
                                        imageVector = Icons.Rounded.Check,
                                        contentDescription = null,
                                        tint = if (color.luminance() < 0.5f) Color.White else Color.Black,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = stringResource(R.string.label_custom_hex_color),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        letterSpacing = 1.0.sp
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    val hexDigits = hexInput.filter { it.isDigit() || it in 'a'..'f' || it in 'A'..'F' }
                    val customColor = runCatching {
                        if (hexDigits.length == 6) Color(android.graphics.Color.parseColor("#$hexDigits")) else null
                    }.getOrNull()
                    val isCustomSelected = customColor != null && selectedAccent.equals("#$hexDigits", ignoreCase = true)

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        BasicTextField(
                            value = hexInput,
                            onValueChange = { input ->
                                val hasHash = input.startsWith("#")
                                val digitsOnly = input.filter { it.isDigit() || it in 'a'..'f' || it in 'A'..'F' }.take(6).uppercase()
                                val cleaned = if (hasHash) "#$digitsOnly" else digitsOnly
                                hexInput = cleaned
                                if (digitsOnly.length == 6) {
                                    val formatted = "#$digitsOnly"
                                    runCatching {
                                        android.graphics.Color.parseColor(formatted)
                                        selectedAccent = formatted
                                        repository.setAccentColorName(formatted)
                                        onThemeOrAccentChanged()
                                    }
                                }
                            },
                            textStyle = TextStyle(
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                fontFamily = SpaceGroteskFontFamily,
                                color = primaryTextColor,
                                textAlign = TextAlign.Start
                            ),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii),
                            cursorBrush = SolidColor(primaryTextColor),
                            singleLine = true,
                            decorationBox = { innerTextField ->
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .background(MaterialTheme.colorScheme.surfaceVariant, shape = RoundedCornerShape(12.dp))
                                        .padding(horizontal = 16.dp, vertical = 12.dp)
                                ) {
                                    if (hexInput.isEmpty()) {
                                        Text(
                                            text = stringResource(R.string.placeholder_hex),
                                            fontSize = 16.sp,
                                            fontWeight = FontWeight.Bold,
                                            fontFamily = SpaceGroteskFontFamily,
                                            color = Color.Gray
                                        )
                                    }
                                    innerTextField()
                                }
                            },
                            modifier = Modifier.weight(1f)
                        )

                        Spacer(modifier = Modifier.width(12.dp))

                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .background(
                                    color = customColor ?: MaterialTheme.colorScheme.surfaceVariant,
                                    shape = CircleShape
                                )
                                .border(
                                    width = if (isCustomSelected) 3.dp else 0.dp,
                                    color = if (isCustomSelected) primaryTextColor else Color.Transparent,
                                    shape = CircleShape
                                )
                                .clickable(enabled = customColor != null) {
                                    val formatted = "#$hexDigits"
                                    selectedAccent = formatted
                                    repository.setAccentColorName(formatted)
                                    onThemeOrAccentChanged()
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            if (customColor != null && isCustomSelected) {
                                Icon(
                                    imageVector = Icons.Rounded.Check,
                                    contentDescription = null,
                                    tint = if (customColor.luminance() < 0.5f) Color.White else Color.Black,
                                    modifier = Modifier.size(20.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = stringResource(R.string.label_theme_mode),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        letterSpacing = 1.0.sp
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(modifier = Modifier.fillMaxWidth()) {
                        listOf(
                            "system" to R.string.theme_system,
                            "light" to R.string.theme_light,
                            "dark" to R.string.theme_dark
                        ).forEach { (mode, stringRes) ->
                            val selected = selectedTheme == mode
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(horizontal = 4.dp)
                                    .background(
                                        color = if (selected) currentAccentColor else MaterialTheme.colorScheme.surfaceVariant,
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
                                    text = stringResource(stringRes),
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

            SectionHeader(stringResource(R.string.section_daily_targets), Icons.Rounded.Radar, currentAccentColor)
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
                            text = stringResource(R.string.label_flexible_daily_goals),
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
                                    label = stringResource(R.string.label_weekday_goal),
                                    value = weekdayGoalText,
                                    onValueChange = {
                                        weekdayGoalText = it
                                        repository.setGoalWeekday(it.toIntOrNull() ?: 10000)
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                                InputField(
                                    label = stringResource(R.string.label_weekend_goal),
                                    value = weekendGoalText,
                                    onValueChange = {
                                        weekendGoalText = it
                                        repository.setGoalWeekend(it.toIntOrNull() ?: 6000)
                                    },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            SectionHeader(stringResource(R.string.section_motion_calibration), Icons.Rounded.Tune, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = stringResource(R.string.label_vehicle_accuracy_sensitivity),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = primaryTextColor
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = stringResource(R.string.desc_vehicle_accuracy_sensitivity),
                        fontSize = 12.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(modifier = Modifier.fillMaxWidth()) {
                        listOf(
                            "off" to R.string.sensitivity_off,
                            "low" to R.string.sensitivity_low,
                            "medium" to R.string.sensitivity_medium,
                            "high" to R.string.sensitivity_high
                        ).forEach { (sensitivity, stringRes) ->
                            val selected = motionSensitivity == sensitivity
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .padding(horizontal = 4.dp)
                                    .background(
                                        color = if (selected) currentAccentColor else MaterialTheme.colorScheme.surfaceVariant,
                                        shape = RoundedCornerShape(12.dp)
                                    )
                                    .clickable {
                                        motionSensitivity = sensitivity
                                        repository.setMotionSensitivity(sensitivity)
                                        onThemeOrAccentChanged()
                                    }
                                    .padding(vertical = 12.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = stringResource(stringRes),
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
                SectionHeader(stringResource(R.string.section_health_connect), Icons.Rounded.Favorite, currentAccentColor)
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
                                    text = stringResource(R.string.label_sync_health_connect),
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = SpaceGroteskFontFamily,
                                    color = primaryTextColor
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = stringResource(R.string.desc_sync_health_connect),
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
                                                healthConnectManager.writeTodaySteps(repository.getTodaySteps())
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

            SectionHeader(stringResource(R.string.section_backup_restore), Icons.Rounded.Backup, currentAccentColor)
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
                                text = stringResource(R.string.label_daily_auto_backup),
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                fontFamily = SpaceGroteskFontFamily,
                                color = primaryTextColor
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = if (autoBackupEnabled && lastAutoBackupDate.isNotEmpty()) {
                                    stringResource(R.string.desc_daily_auto_backup_last, lastAutoBackupDate)
                                } else {
                                    stringResource(R.string.desc_daily_auto_backup)
                                },
                                fontSize = 12.sp,
                                fontFamily = SpaceGroteskFontFamily,
                                color = Color.Gray,
                                lineHeight = 16.sp
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        Switch(
                            checked = autoBackupEnabled,
                            onCheckedChange = { checked ->
                                if (checked) {
                                    if (autoBackupDirUri.isEmpty()) {
                                        folderPickerLauncher.launch(null)
                                    } else {
                                        autoBackupEnabled = true
                                        repository.setAutoBackupEnabled(true)
                                        repository.checkAndPerformAutoBackup()
                                        lastAutoBackupDate = repository.getLastAutoBackupDate()
                                    }
                                } else {
                                    autoBackupEnabled = false
                                    repository.setAutoBackupEnabled(false)
                                }
                            },
                            colors = SwitchDefaults.colors(checkedThumbColor = currentAccentColor)
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    val folderDisplayName = remember(autoBackupDirUri) {
                        if (autoBackupDirUri.isNotEmpty()) {
                            runCatching {
                                DocumentFile.fromTreeUri(context, Uri.parse(autoBackupDirUri))?.name
                            }.getOrNull() ?: context.getString(R.string.folder_custom)
                        } else {
                            context.getString(R.string.folder_select)
                        }
                    }

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(MaterialTheme.colorScheme.surfaceVariant, shape = RoundedCornerShape(12.dp))
                            .clickable { folderPickerLauncher.launch(null) }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = stringResource(R.string.label_backup_directory),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                fontFamily = SpaceGroteskFontFamily,
                                color = Color.Gray,
                                letterSpacing = 1.0.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = folderDisplayName,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                fontFamily = SpaceGroteskFontFamily,
                                color = primaryTextColor
                            )
                        }
                        Icon(
                            imageVector = Icons.Rounded.Folder,
                            contentDescription = null,
                            tint = currentAccentColor,
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = stringResource(R.string.label_manual_backup),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = primaryTextColor
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = stringResource(R.string.desc_manual_backup),
                        fontSize = 12.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Row(modifier = Modifier.fillMaxWidth()) {
                        OutlinedButton(
                            onClick = {
                                exportLauncher.launch("path_backup_${repository.getCurrentDateString()}.json")
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = stringResource(R.string.btn_export),
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                fontFamily = SpaceGroteskFontFamily,
                                letterSpacing = 1.0.sp,
                                color = primaryTextColor
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        OutlinedButton(
                            onClick = {
                                importLauncher.launch(arrayOf("application/json", "*/*"))
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text(
                                text = stringResource(R.string.btn_import),
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                fontFamily = SpaceGroteskFontFamily,
                                letterSpacing = 1.0.sp,
                                color = primaryTextColor
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(28.dp))

            SectionHeader(stringResource(R.string.section_background_diagnostics), Icons.Rounded.DeveloperMode, currentAccentColor)
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(cardColor, shape = RoundedCornerShape(20.dp))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = stringResource(R.string.label_aggressive_battery_saving),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = primaryTextColor
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.desc_aggressive_battery_saving),
                        fontSize = 12.sp,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    DiagnosticItem(
                        stringResource(R.string.device_google_pixel),
                        stringResource(R.string.desc_google_pixel),
                        primaryTextColor
                    )
                    DiagnosticItem(
                        stringResource(R.string.device_samsung),
                        stringResource(R.string.desc_samsung),
                        primaryTextColor
                    )
                    DiagnosticItem(
                        stringResource(R.string.device_xiaomi),
                        stringResource(R.string.desc_xiaomi),
                        primaryTextColor
                    )
                    DiagnosticItem(
                        stringResource(R.string.device_oneplus),
                        stringResource(R.string.desc_oneplus),
                        primaryTextColor
                    )
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
                            text = stringResource(R.string.btn_dontkillmyapp_guide),
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
    modifier: Modifier = Modifier
) {
    val textColor = MaterialTheme.colorScheme.onSurface
    val bg = MaterialTheme.colorScheme.surfaceVariant

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
