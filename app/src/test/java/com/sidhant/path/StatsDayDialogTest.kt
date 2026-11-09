package com.sidhant.path

import android.graphics.Bitmap
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.sidhant.path.data.DailyStepRecord
import com.sidhant.path.MainActivity
import com.sidhant.path.ui.screens.StatsScreen
import com.sidhant.path.ui.theme.PathTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Verifies the step-history day dialog by rendering the real StatsScreen:
 * captures the stats page, taps a previous-day row, captures the dialog,
 * and asserts the day's step count is shown.
 */
@RunWith(AndroidJUnit4::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w411dp-h891dp-xxhdpi")
class StatsDayDialogTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<MainActivity>()

    private fun dateAt(daysAgo: Int): Date {
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -daysAgo)
        return cal.time
    }

    private fun savePng(bitmap: Bitmap, name: String) {
        val dir = File("build/verification").apply { mkdirs() }
        File(dir, name).outputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        }
    }

    // Renders the real view hierarchy with the real framework (works headless under Robolectric
    // native graphics, unlike captureToImage which waits for vsync frames). Dialog windows are
    // separate windows attached to WindowManagerGlobal, so `dialog = true` draws the last attached view.
    private fun screenshot(name: String, dialog: Boolean = false) {
        composeRule.activityRule.scenario.onActivity { activity: MainActivity ->
            val view = if (dialog) {
                val wmgClass = Class.forName("android.view.WindowManagerGlobal")
                val wmg = wmgClass.getMethod("getInstance").invoke(null)
                val views = wmgClass.getDeclaredField("mViews").apply { isAccessible = true }
                    .get(wmg) as List<android.view.View>
                views.last()
            } else {
                activity.window.decorView
            }
            val w = if (view.width > 0) view.width else 1080
            val h = if (view.height > 0) view.height else 2400
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            view.draw(android.graphics.Canvas(bmp))
            savePng(bmp, name)
        }
    }

    private fun scrollToText(text: String) {
        // The stats content lives in a verticalScroll Column; drive it via the scroll
        // semantics action rather than swipes so the target lands inside the window.
        composeRule.onNode(hasScrollAction()).performScrollToNode(hasText(text))
        composeRule.waitForIdle()
        composeRule.onNodeWithText(text).assertExists()
    }

    @Test
    fun tappingActivityChartBarOpensDayDialog() {
        val iso = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val history = listOf(
            DailyStepRecord(iso.format(dateAt(1)), dateAt(1), 8240),
            DailyStepRecord(iso.format(dateAt(2)), dateAt(2), 5320),
            DailyStepRecord(iso.format(dateAt(3)), dateAt(3), 2310),
            DailyStepRecord(iso.format(dateAt(4)), dateAt(4), 15450),
            DailyStepRecord(iso.format(dateAt(5)), dateAt(5), 980),
            DailyStepRecord(iso.format(dateAt(6)), dateAt(6), 6400),
        )

        composeRule.activityRule.scenario.onActivity { activity: MainActivity ->
            val frame = activity.findViewById<android.view.ViewGroup>(android.R.id.content)
            frame?.removeAllViews()
        }
        composeRule.waitForIdle()

        composeRule.setContent {
            PathTheme(themeMode = "dark", accentColorName = "Lime") {
                StatsScreen(
                    todaySteps = 4012,
                    goal = 10000,
                    streak = 7,
                    walkingSteps = 3100,
                    runningSteps = 912,
                    hourlyStepsJson = "{}",
                    history = history,
                    pbSteps = 15450,
                    pbStepsDate = iso.format(dateAt(4)),
                    pbStreak = 12,
                    lifetimeSteps = 234567,
                    totalDistanceKm = 165.4f,
                    accentColorName = "Lime",
                    onOpenSettings = {},
                    onNavigateToToday = {}
                )
            }
        }

        // Both chart's leftmost bar ("T", 6 days ago) and today's bar are labelled "T";
        // the first occurrence in the tree belongs to the 6-day-ago column (6,400 steps).
        composeRule.onAllNodesWithText("T")[0].performClick()
        composeRule.waitForIdle()

        composeRule.onNodeWithText("STEPS").assertExists()
        composeRule.onNodeWithText("GOAL 64%").assertExists()

        screenshot("chart_dialog_after_tap.png", dialog = true)
    }

    @Test
    fun tappingHistoryRowShowsPreviousDayStepCount() {
        val iso = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val history = listOf(
            DailyStepRecord(iso.format(dateAt(1)), dateAt(1), 8240),
            DailyStepRecord(iso.format(dateAt(2)), dateAt(2), 5320),
            DailyStepRecord(iso.format(dateAt(3)), dateAt(3), 2310),
            DailyStepRecord(iso.format(dateAt(4)), dateAt(4), 15450),
            DailyStepRecord(iso.format(dateAt(5)), dateAt(5), 980),
            DailyStepRecord(iso.format(dateAt(6)), dateAt(6), 6400),
        )
        val dayLabels = history.map {
            SimpleDateFormat("EEEE", Locale.US).format(it.date).uppercase(Locale.US)
        }
        val yesterdayLabel = dayLabels[0]

        // MainActivity set its own Compose content; empty the content frame so the
        // test rule can host the StatsScreen composition.
        composeRule.activityRule.scenario.onActivity { activity: MainActivity ->
            val frame = activity.findViewById<android.view.ViewGroup>(android.R.id.content)
            frame?.removeAllViews()
        }
        composeRule.waitForIdle()

        composeRule.setContent {
            PathTheme(themeMode = "dark", accentColorName = "Lime") {
                StatsScreen(
                    todaySteps = 4012,
                    goal = 10000,
                    streak = 7,
                    walkingSteps = 3100,
                    runningSteps = 912,
                    hourlyStepsJson = "{}",
                    history = history,
                    pbSteps = 15450,
                    pbStepsDate = iso.format(dateAt(4)),
                    pbStreak = 12,
                    lifetimeSteps = 234567,
                    totalDistanceKm = 165.4f,
                    accentColorName = "Lime",
                    onOpenSettings = {},
                    onNavigateToToday = {}
                )
            }
        }

        // Stats page, before
        screenshot("stats_before_tap.png")

        scrollToText(yesterdayLabel)
        composeRule.onNodeWithText(yesterdayLabel).performClick()
        composeRule.waitForIdle()

        // Dialog must show the exact step count for that day. "8,240" appears in
        // both the history row and the dialog, so check existence on all nodes.
        composeRule.onAllNodesWithText("8,240").fetchSemanticsNodes().isNotEmpty().let { assertTrue(it) }
        composeRule.onNodeWithText("STEPS").assertExists()
        composeRule.onNodeWithText("GOAL 82%").assertExists()

        // Dialog, after (dialog renders in its own window)
        screenshot("day_dialog_after_tap.png", dialog = true)
    }
}
