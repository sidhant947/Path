package com.sidhant.path.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.DarkMode
import androidx.compose.material.icons.rounded.DirectionsRun
import androidx.compose.material.icons.rounded.DirectionsWalk
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.NightsStay
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.StackedLineChart
import androidx.compose.material.icons.rounded.WbSunny
import androidx.compose.material.icons.rounded.WbTwilight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sidhant.path.data.DailyStepRecord
import com.sidhant.path.ui.theme.SpaceGroteskFontFamily
import com.sidhant.path.ui.theme.getAccentColor
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun StatsScreen(
    todaySteps: Int,
    goal: Int,
    streak: Int,
    walkingSteps: Int,
    runningSteps: Int,
    hourlyStepsJson: String,
    history: List<DailyStepRecord>,
    pbSteps: Int,
    pbStepsDate: String,
    pbStreak: Int,
    lifetimeSteps: Int,
    totalDistanceKm: Float,
    accentColorName: String,
    onOpenSettings: () -> Unit,
    onNavigateToToday: () -> Unit
) {
    val accentColor = getAccentColor(accentColorName)
    val isDark = isSystemInDarkTheme()
    val cardBg = if (isDark) Color(0xFF1A1A1A) else Color(0xFFF2F2F2)
    val textColor = if (isDark) Color.White else Color.Black

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            HeaderRow(
                streak = streak,
                accentColor = accentColor,
                textColor = textColor,
                onOpenSettings = onOpenSettings
            )

            Spacer(modifier = Modifier.height(24.dp))

            EncouragementSection(
                todaySteps = todaySteps,
                goal = goal,
                cardBg = cardBg,
                textColor = textColor,
                accentColor = accentColor
            )

            Spacer(modifier = Modifier.height(16.dp))

            ActivityChartSection(
                todaySteps = todaySteps,
                goal = goal,
                history = history,
                cardBg = cardBg,
                accentColor = accentColor,
                isDark = isDark
            )

            Spacer(modifier = Modifier.height(24.dp))

            BreakdownSection(
                walkingSteps = walkingSteps,
                runningSteps = runningSteps,
                cardBg = cardBg,
                textColor = textColor,
                accentColor = accentColor
            )

            Spacer(modifier = Modifier.height(24.dp))

            HourlySection(
                hourlyStepsJson = hourlyStepsJson,
                cardBg = cardBg,
                textColor = textColor,
                accentColor = accentColor,
                isDark = isDark
            )

            Spacer(modifier = Modifier.height(24.dp))

            AchievementsSection(
                pbSteps = pbSteps,
                pbStepsDate = pbStepsDate,
                pbStreak = pbStreak,
                lifetimeSteps = lifetimeSteps,
                totalDistanceKm = totalDistanceKm,
                cardBg = cardBg,
                textColor = textColor,
                accentColor = accentColor,
                isDark = isDark
            )

            Spacer(modifier = Modifier.height(24.dp))

            HistoryListSection(
                todaySteps = todaySteps,
                history = history,
                accentColor = accentColor,
                textColor = textColor
            )

            Spacer(modifier = Modifier.height(40.dp))
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(80.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .clickable { onNavigateToToday() }
                    .padding(horizontal = 32.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Today",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = textColor.copy(alpha = 0.5f)
                )
            }
            Box(
                modifier = Modifier
                    .padding(horizontal = 32.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Stats",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = textColor
                )
            }
        }
    }
}

@Composable
private fun HeaderRow(
    streak: Int,
    accentColor: Color,
    textColor: Color,
    onOpenSettings: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "STREAK",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = 1.2.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                repeat(7) { index ->
                    val active = index < streak
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(6.dp)
                            .padding(horizontal = 2.dp)
                            .background(
                                color = if (active) accentColor else Color.Gray.copy(alpha = 0.2f),
                                shape = RoundedCornerShape(3.dp)
                            )
                    )
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "$streak DAY STREAK",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                color = textColor
            )
        }
        Spacer(modifier = Modifier.width(16.dp))
        IconButton(onClick = onOpenSettings) {
            Icon(
                imageVector = Icons.Rounded.Settings,
                contentDescription = null,
                tint = textColor
            )
        }
    }
}

@Composable
private fun EncouragementSection(
    todaySteps: Int,
    goal: Int,
    cardBg: Color,
    textColor: Color,
    accentColor: Color
) {
    val message = when {
        todaySteps >= goal -> "Amazing work! Goal smashed."
        todaySteps >= goal * 0.7 -> "Almost there! Keep pushing."
        else -> "Go for a walk! You can do it."
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(cardBg, shape = RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = Icons.Rounded.DirectionsWalk,
                contentDescription = null,
                tint = accentColor
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = message,
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                fontFamily = SpaceGroteskFontFamily,
                color = textColor
            )
        }
    }
}

@Composable
private fun ActivityChartSection(
    todaySteps: Int,
    goal: Int,
    history: List<DailyStepRecord>,
    cardBg: Color,
    accentColor: Color,
    isDark: Boolean
) {
    val todayRecord = DailyStepRecord("Today", Date(), todaySteps)
    val displayRecords = (listOf(todayRecord) + history).take(7).reversed()

    val maxSteps = (displayRecords.maxOfOrNull { it.steps } ?: goal).coerceAtLeast(goal)
    val maxY = maxSteps * 1.2f

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(280.dp)
            .background(cardBg, shape = RoundedCornerShape(24.dp))
            .padding(16.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "ACTIVITY",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    letterSpacing = 1.2.sp,
                    color = Color.Gray
                )
                Text(
                    text = "Goal: ${formatNumber(goal)}",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = Color.Gray
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                displayRecords.forEachIndexed { index, record ->
                    val isToday = index == displayRecords.lastIndex
                    val stepHeightRatio = (record.steps.toFloat() / maxY).coerceIn(0.05f, 1f)

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.weight(1f)
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxWidth(0.5f),
                            contentAlignment = Alignment.BottomCenter
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(
                                        color = if (isDark) Color.White.copy(alpha = 0.05f) else Color.Black.copy(alpha = 0.05f),
                                        shape = RoundedCornerShape(topStart = 6.dp, topEnd = 6.dp)
                                    )
                            )
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .fillMaxHeight(stepHeightRatio)
                                    .background(
                                        color = if (isToday) accentColor else accentColor.copy(alpha = 0.4f),
                                        shape = RoundedCornerShape(topStart = 6.dp, topEnd = 6.dp)
                                    )
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        val dayLabel = if (isToday) "T" else SimpleDateFormat("E", Locale.US).format(record.date).take(1)
                        Text(
                            text = dayLabel,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = SpaceGroteskFontFamily,
                            color = Color.Gray
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun BreakdownSection(
    walkingSteps: Int,
    runningSteps: Int,
    cardBg: Color,
    textColor: Color,
    accentColor: Color
) {
    val total = walkingSteps + runningSteps
    val walkPercent = if (total > 0) (walkingSteps.toFloat() / total.toFloat()) else 1.0f
    val runPercent = if (total > 0) (runningSteps.toFloat() / total.toFloat()) else 0.0f

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(cardBg, shape = RoundedCornerShape(24.dp))
            .padding(16.dp)
    ) {
        Column {
            Text(
                text = "TODAY BREAKDOWN",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = 1.2.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp))
            ) {
                if (walkPercent > 0) {
                    Box(
                        modifier = Modifier
                            .weight(walkPercent.coerceAtLeast(0.01f))
                            .fillMaxHeight()
                            .background(accentColor)
                    )
                }
                if (runPercent > 0) {
                    Box(
                        modifier = Modifier
                            .weight(runPercent.coerceAtLeast(0.01f))
                            .fillMaxHeight()
                            .background(Color(0xFFE67E22))
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Rounded.DirectionsWalk,
                        contentDescription = null,
                        tint = accentColor,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Walk: ${formatNumber(walkingSteps)} (${(walkPercent * 100).toInt()}%)",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = textColor
                    )
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Rounded.DirectionsRun,
                        contentDescription = null,
                        tint = Color(0xFFE67E22),
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Run: ${formatNumber(runningSteps)} (${(runPercent * 100).toInt()}%)",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = textColor
                    )
                }
            }
        }
    }
}

@Composable
private fun HourlySection(
    hourlyStepsJson: String,
    cardBg: Color,
    textColor: Color,
    accentColor: Color,
    isDark: Boolean
) {
    var night = 0
    var morning = 0
    var afternoon = 0
    var evening = 0

    try {
        val json = JSONObject(hourlyStepsJson)
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val hour = key.toIntOrNull() ?: 0
            val steps = json.optInt(key, 0)
            when (hour) {
                in 0..5 -> night += steps
                in 6..11 -> morning += steps
                in 12..17 -> afternoon += steps
                else -> evening += steps
            }
        }
    } catch (e: Exception) {}

    val maxSteps = maxOf(night, morning, afternoon, evening).coerceAtLeast(1)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(cardBg, shape = RoundedCornerShape(24.dp))
            .padding(16.dp)
    ) {
        Column {
            Text(
                text = "HOURLY DISTRIBUTION",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = 1.2.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                HourlyBar("NIGHT", night, maxSteps, Icons.Rounded.NightsStay, textColor, accentColor, isDark)
                HourlyBar("MORNING", morning, maxSteps, Icons.Rounded.WbSunny, textColor, accentColor, isDark)
                HourlyBar("AFTERNOON", afternoon, maxSteps, Icons.Rounded.WbTwilight, textColor, accentColor, isDark)
                HourlyBar("EVENING", evening, maxSteps, Icons.Rounded.DarkMode, textColor, accentColor, isDark)
            }
        }
    }
}

@Composable
private fun HourlyBar(
    label: String,
    steps: Int,
    maxSteps: Int,
    icon: ImageVector,
    textColor: Color,
    accentColor: Color,
    isDark: Boolean
) {
    val barHeightRatio = (steps.toFloat() / maxSteps.toFloat()).coerceIn(0.1f, 1f)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(60.dp)
    ) {
        Text(
            text = formatNumber(steps),
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            color = textColor
        )
        Spacer(modifier = Modifier.height(6.dp))
        Box(
            modifier = Modifier
                .height(100.dp)
                .width(14.dp)
                .background(
                    color = if (isDark) Color(0xFF2A2A2A) else Color(0xFFE0E0E0),
                    shape = RoundedCornerShape(7.dp)
                ),
            contentAlignment = Alignment.BottomCenter
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(barHeightRatio)
                    .background(accentColor, shape = RoundedCornerShape(7.dp))
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Icon(imageVector = icon, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            color = Color.Gray
        )
    }
}

@Composable
private fun AchievementsSection(
    pbSteps: Int,
    pbStepsDate: String,
    pbStreak: Int,
    lifetimeSteps: Int,
    totalDistanceKm: Float,
    cardBg: Color,
    textColor: Color,
    accentColor: Color,
    isDark: Boolean
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(cardBg, shape = RoundedCornerShape(24.dp))
            .padding(16.dp)
    ) {
        Column {
            Text(
                text = "PERSONAL RECORDS & BADGES",
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = 1.2.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(16.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                AchievementCard(
                    label = "ALL-TIME BEST",
                    value = formatNumber(pbSteps),
                    sub = pbStepsDate,
                    icon = Icons.Rounded.EmojiEvents,
                    iconTint = Color(0xFFFFC107),
                    textColor = textColor,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                AchievementCard(
                    label = "BEST STREAK",
                    value = "$pbStreak DAYS",
                    sub = "Active Days",
                    icon = Icons.Rounded.LocalFireDepartment,
                    iconTint = Color(0xFFFF9800),
                    textColor = textColor,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                AchievementCard(
                    label = "LIFETIME STEPS",
                    value = formatNumber(lifetimeSteps),
                    sub = "",
                    icon = Icons.Rounded.StackedLineChart,
                    iconTint = accentColor,
                    textColor = textColor,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                AchievementCard(
                    label = "TOTAL DISTANCE",
                    value = "${String.format("%.1f", totalDistanceKm)} km",
                    sub = "",
                    icon = Icons.Rounded.Map,
                    iconTint = Color(0xFF2196F3),
                    textColor = textColor,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun AchievementCard(
    label: String,
    value: String,
    sub: String,
    icon: ImageVector,
    iconTint: Color,
    textColor: Color,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val cardInnerBg = if (isDark) Color(0xFF0D0D0D) else Color.White

    Box(
        modifier = modifier
            .background(cardInnerBg, shape = RoundedCornerShape(16.dp))
            .padding(12.dp)
    ) {
        Column {
            Icon(imageVector = icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(24.dp))
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = value,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                color = textColor
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = SpaceGroteskFontFamily,
                color = Color.Gray
            )
            if (sub.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = sub,
                    fontSize = 8.sp,
                    fontFamily = SpaceGroteskFontFamily,
                    color = Color.Gray
                )
            }
        }
    }
}

@Composable
private fun HistoryListSection(
    todaySteps: Int,
    history: List<DailyStepRecord>,
    accentColor: Color,
    textColor: Color
) {
    val todayRecord = DailyStepRecord("Today", Date(), todaySteps)
    val displayRecords = (listOf(todayRecord) + history).take(7)

    val sdfDay = SimpleDateFormat("EEEE", Locale.US)
    val sdfDate = SimpleDateFormat("dd MMMM", Locale.US)

    Column {
        displayRecords.forEachIndexed { index, record ->
            val isToday = index == 0
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = if (isToday) "TODAY" else sdfDay.format(record.date).uppercase(Locale.US),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = Color.Gray
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = sdfDate.format(record.date),
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = SpaceGroteskFontFamily,
                        color = textColor
                    )
                }
                Text(
                    text = formatNumber(record.steps),
                    fontSize = 22.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = accentColor
                )
            }
        }
    }
}

private fun formatNumber(num: Int): String {
    return String.format("%,d", num)
}
