package com.sidhant.path.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.sidhant.path.MainActivity
import com.sidhant.path.data.StepRepository
import com.sidhant.path.ui.theme.getAccentColor
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Locale

class PathWidget : GlanceAppWidget() {
    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repository = StepRepository(context)

        provideContent {
            val prefs = currentState<Preferences>()
            val todaySteps = prefs[prefsKeySteps] ?: repository.getTodaySteps()
            val goal = prefs[prefsKeyGoal] ?: repository.getCurrentGoal()
            val accentColorName = prefs[prefsKeyAccent] ?: repository.getAccentColorName()

            WidgetContent(
                todaySteps = todaySteps,
                goal = goal,
                accentColor = getAccentColor(accentColorName)
            )
        }
    }

    @Composable
    private fun WidgetContent(
        todaySteps: Int,
        goal: Int,
        accentColor: Color
    ) {
        val progress = if (goal > 0) (todaySteps.toFloat() / goal.toFloat()).coerceIn(0f, 1f) else 0f
        val remaining = goal - todaySteps
        val remainingText = if (remaining <= 0) "ACHIEVED" else "${formatNumber(remaining)} REMAINING"

        val size = LocalSize.current
        val fillHeight = (size.height.value * progress).dp

        val textColor = if (progress >= 0.55f) Color.Black else Color.White
        val subTextColor = if (progress >= 0.55f) Color(0xFF333333) else Color.Gray
        val headerTextColor = if (progress >= 0.85f) Color.Black else Color.Gray

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color(0xFF141414))
                .cornerRadius(20.dp)
                .clickable(actionStartActivity<MainActivity>()),
            contentAlignment = Alignment.BottomCenter
        ) {
            if (progress > 0f) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .height(fillHeight)
                        .background(accentColor)
                ) {}
            }

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "GOAL ${formatNumber(goal)}",
                        style = TextStyle(
                            color = ColorProvider(headerTextColor),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    Text(
                        text = remainingText,
                        style = TextStyle(
                            color = ColorProvider(headerTextColor),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }

                Spacer(modifier = GlanceModifier.defaultWeight())

                Text(
                    text = formatNumber(todaySteps),
                    style = TextStyle(
                        color = ColorProvider(textColor),
                        fontSize = 36.sp,
                        fontWeight = FontWeight.Bold
                    )
                )

                Spacer(modifier = GlanceModifier.height(2.dp))

                Text(
                    text = "Daily Steps",
                    style = TextStyle(
                        color = ColorProvider(subTextColor),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )
                )

                Spacer(modifier = GlanceModifier.defaultWeight())
            }
        }
    }

    private fun formatNumber(num: Int): String {
        return String.format(Locale.US, "%,d", num)
    }

    companion object {
        val prefsKeySteps = intPreferencesKey("widget_today_steps")
        val prefsKeyGoal = intPreferencesKey("widget_goal")
        val prefsKeyAccent = stringPreferencesKey("widget_accent_color")

        suspend fun updateWidget(context: Context) {
            try {
                val repository = StepRepository(context)
                val todaySteps = repository.getTodaySteps()
                val goal = repository.getCurrentGoal()
                val accentColorName = repository.getAccentColorName()

                val manager = GlanceAppWidgetManager(context)
                val glanceIds = manager.getGlanceIds(PathWidget::class.java)
                val widget = PathWidget()
                for (glanceId in glanceIds) {
                    updateAppWidgetState(context, glanceId) { prefs ->
                        prefs[prefsKeySteps] = todaySteps
                        prefs[prefsKeyGoal] = goal
                        prefs[prefsKeyAccent] = accentColorName
                    }
                    widget.update(context, glanceId)
                }
            } catch (_: Exception) {}
        }
    }
}

class PathWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PathWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        CoroutineScope(Dispatchers.IO).launch {
            PathWidget.updateWidget(context)
        }
    }
}
