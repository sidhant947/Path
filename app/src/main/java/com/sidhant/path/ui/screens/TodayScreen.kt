package com.sidhant.path.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.Straighten
import androidx.compose.material.icons.rounded.Timer
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sidhant.path.ui.theme.SpaceGroteskFontFamily
import com.sidhant.path.ui.theme.getAccentColor

class BottomFillShape(private val progress: Float) : Shape {
    override fun createOutline(
        size: Size,
        layoutDirection: LayoutDirection,
        density: Density
    ): Outline {
        val fillHeight = size.height * progress
        val top = size.height - fillHeight
        return Outline.Rectangle(
            Rect(0f, top, size.width, size.height)
        )
    }
}

@Composable
fun TodayScreen(
    todaySteps: Int,
    goal: Int,
    distanceKm: Float,
    calories: Float,
    activeMinutes: Float,
    accentColorName: String,
    onOpenGoalSetup: () -> Unit,
    onNavigateToStats: () -> Unit
) {
    val accentColor = getAccentColor(accentColorName)
    val isDark = isSystemInDarkTheme()
    val defaultTextColor = if (isDark) Color.White else Color.Black
    val progress = if (goal > 0) (todaySteps.toFloat() / goal.toFloat()).coerceIn(0f, 1f) else 0f
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = tween(700),
        label = "progressAnim"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .fillMaxHeight(animatedProgress)
                .background(accentColor)
        )

        TodayForegroundContent(
            todaySteps = todaySteps,
            goal = goal,
            distanceKm = distanceKm,
            calories = calories,
            activeMinutes = activeMinutes,
            textColor = defaultTextColor,
            onOpenGoalSetup = onOpenGoalSetup,
            onNavigateToStats = onNavigateToStats
        )

        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    clip = true
                    shape = BottomFillShape(animatedProgress)
                }
        ) {
            TodayForegroundContent(
                todaySteps = todaySteps,
                goal = goal,
                distanceKm = distanceKm,
                calories = calories,
                activeMinutes = activeMinutes,
                textColor = Color.Black,
                onOpenGoalSetup = onOpenGoalSetup,
                onNavigateToStats = onNavigateToStats
            )
        }
    }
}

@Composable
private fun TodayForegroundContent(
    todaySteps: Int,
    goal: Int,
    distanceKm: Float,
    calories: Float,
    activeMinutes: Float,
    textColor: Color,
    onOpenGoalSetup: () -> Unit,
    onNavigateToStats: () -> Unit
) {
    val remaining = goal - todaySteps
    val remainingLabel = if (remaining <= 0) "ACHIEVED" else "REMAINING"
    val remainingValue = if (remaining <= 0) formatNumber(todaySteps - goal) else formatNumber(remaining)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp)
    ) {
        Spacer(modifier = Modifier.height(48.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.clickable { onOpenGoalSetup() }
            ) {
                Text(
                    text = "GOAL",
                    color = textColor,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    letterSpacing = 1.2.sp
                )
                Text(
                    text = formatNumber(goal),
                    color = textColor,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = remainingLabel,
                    color = textColor,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    letterSpacing = 1.2.sp
                )
                Text(
                    text = remainingValue,
                    color = textColor,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = formatNumber(todaySteps),
                color = textColor,
                fontSize = 88.sp,
                fontWeight = FontWeight.ExtraBold,
                fontFamily = SpaceGroteskFontFamily,
                letterSpacing = (-2.0).sp,
                lineHeight = 88.sp
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Daily Steps",
                color = textColor,
                fontSize = 22.sp,
                fontWeight = FontWeight.Medium,
                fontFamily = SpaceGroteskFontFamily
            )
        }

        Spacer(modifier = Modifier.height(36.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            MetricItem(
                icon = Icons.Rounded.Straighten,
                value = "${String.format("%.2f", distanceKm)} km",
                label = "DISTANCE",
                color = textColor
            )
            MetricItem(
                icon = Icons.Rounded.LocalFireDepartment,
                value = "${calories.toInt()} kcal",
                label = "CALORIES",
                color = textColor
            )
            MetricItem(
                icon = Icons.Rounded.Timer,
                value = "${activeMinutes.toInt()}m",
                label = "ACTIVE",
                color = textColor
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(80.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .padding(horizontal = 32.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Today",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = textColor
                )
            }
            Box(
                modifier = Modifier
                    .clickable { onNavigateToStats() }
                    .padding(horizontal = 32.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Stats",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = SpaceGroteskFontFamily,
                    color = textColor.copy(alpha = 0.5f)
                )
            }
        }
    }
}

@Composable
private fun MetricItem(
    icon: ImageVector,
    value: String,
    label: String,
    color: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color.copy(alpha = 0.8f),
            modifier = Modifier.size(24.dp)
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = value,
            color = color,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = label,
            color = color.copy(alpha = 0.5f),
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = SpaceGroteskFontFamily,
            letterSpacing = 0.8.sp
        )
    }
}

private fun formatNumber(num: Int): String {
    return String.format("%,d", num)
}
