package com.sidhant.path.data

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

data class DailyStepRecord(
    val dateStr: String,
    val date: Date,
    val steps: Int
)

class StepRepository(private val context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("path_prefs", Context.MODE_PRIVATE)

    fun isNotificationEnabled(): Boolean = prefs.getBoolean("notification_enabled", true)
    fun setNotificationEnabled(enabled: Boolean) = prefs.edit().putBoolean("notification_enabled", enabled).apply()

    fun isHealthConnectEnabled(): Boolean = prefs.getBoolean("health_connect_enabled", false)
    fun setHealthConnectEnabled(enabled: Boolean) = prefs.edit().putBoolean("health_connect_enabled", enabled).apply()

    fun isOnboardingComplete(): Boolean = prefs.getBoolean("onboarding_complete", false)
    fun setOnboardingComplete(complete: Boolean) = prefs.edit().putBoolean("onboarding_complete", complete).apply()

    fun getTodaySteps(): Int = prefs.getInt("today_steps", 0)
    fun setTodaySteps(steps: Int) = prefs.edit().putInt("today_steps", steps).apply()

    fun getTodayWalkingSteps(): Int = prefs.getInt("today_walking_steps", 0)
    fun setTodayWalkingSteps(steps: Int) = prefs.edit().putInt("today_walking_steps", steps).apply()

    fun getTodayRunningSteps(): Int = prefs.getInt("today_running_steps", 0)
    fun setTodayRunningSteps(steps: Int) = prefs.edit().putInt("today_running_steps", steps).apply()

    fun getLifetimeSteps(): Int = prefs.getInt("lifetime_steps", 0)
    fun setLifetimeSteps(steps: Int) = prefs.edit().putInt("lifetime_steps", steps).apply()

    fun getPbSteps(): Int = prefs.getInt("pb_steps", 0)
    fun setPbSteps(steps: Int) = prefs.edit().putInt("pb_steps", steps).apply()

    fun getPbStepsDate(): String = prefs.getString("pb_steps_date", "") ?: ""
    fun setPbStepsDate(dateStr: String) = prefs.edit().putString("pb_steps_date", dateStr).apply()

    fun getPbStreak(): Int = prefs.getInt("pb_streak", 0)
    fun setPbStreak(streak: Int) = prefs.edit().putInt("pb_streak", streak).apply()

    fun getTodayHourlyStepsJson(): String = prefs.getString("today_hourly_steps", "{}") ?: "{}"
    fun setTodayHourlyStepsJson(json: String) = prefs.edit().putString("today_hourly_steps", json).apply()

    fun getDailyGoal(): Int = prefs.getInt("daily_goal", 10000)
    fun setDailyGoal(goal: Int) = prefs.edit().putInt("daily_goal", goal).apply()

    fun isFlexibleGoalsEnabled(): Boolean = prefs.getBoolean("flexible_goals_enabled", false)
    fun setFlexibleGoalsEnabled(enabled: Boolean) = prefs.edit().putBoolean("flexible_goals_enabled", enabled).apply()

    fun getGoalWeekday(): Int = prefs.getInt("goal_weekday", 10000)
    fun setGoalWeekday(goal: Int) = prefs.edit().putInt("goal_weekday", goal).apply()

    fun getGoalWeekend(): Int = prefs.getInt("goal_weekend", 6000)
    fun setGoalWeekend(goal: Int) = prefs.edit().putInt("goal_weekend", goal).apply()

    fun getThemeMode(): String = prefs.getString("theme_mode", "system") ?: "system"
    fun setThemeMode(mode: String) = prefs.edit().putString("theme_mode", mode).apply()

    fun getAccentColorName(): String = prefs.getString("accent_color", "Lime") ?: "Lime"
    fun setAccentColorName(name: String) = prefs.edit().putString("accent_color", name).apply()

    fun getMotionSensitivity(): String = prefs.getString("motion_sensitivity", "medium") ?: "medium"
    fun setMotionSensitivity(sens: String) = prefs.edit().putString("motion_sensitivity", sens).apply()

    fun getLastSensorTotal(): Int = prefs.getInt("last_sensor_total", -1)
    fun setLastSensorTotal(total: Int) = prefs.edit().putInt("last_sensor_total", total).apply()

    fun getLastSavedDate(): String = prefs.getString("last_saved_date", "") ?: ""
    fun setLastSavedDate(dateStr: String) = prefs.edit().putString("last_saved_date", dateStr).apply()

    fun getCurrentGoal(): Int {
        if (isFlexibleGoalsEnabled()) {
            val dayOfWeek = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
            return if (dayOfWeek == Calendar.SATURDAY || dayOfWeek == Calendar.SUNDAY) {
                getGoalWeekend()
            } else {
                getGoalWeekday()
            }
        }
        return getDailyGoal()
    }

    fun getCurrentDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return sdf.format(Date())
    }

    private fun parseDate(dateStr: String): Date? {
        val isoFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val legacyFormat = SimpleDateFormat("yyyy-M-d", Locale.US)
        return try {
            isoFormat.parse(dateStr)
        } catch (_: Exception) {
            try {
                legacyFormat.parse(dateStr)
            } catch (_: Exception) {
                null
            }
        }
    }

    fun getHistoricalSteps(days: Int = 14): List<DailyStepRecord> {
        val historySet = prefs.getStringSet("step_history_list", null) ?: emptySet()
        val records = historySet.mapNotNull { entry ->
            val parts = entry.split(":")
            if (parts.size == 2) {
                val dateStr = parts[0]
                val steps = parts[1].toIntOrNull() ?: 0
                val date = parseDate(dateStr)
                if (date != null) DailyStepRecord(dateStr, date, steps) else null
            } else null
        }.sortedByDescending { it.date }

        return records.take(days)
    }

    fun storeStepInHistory(dateStr: String, steps: Int) {
        val historySet = prefs.getStringSet("step_history_list", null)?.toMutableSet() ?: mutableSetOf()
        historySet.removeAll { it.startsWith("$dateStr:") }
        historySet.add("$dateStr:$steps")

        val sortedList = historySet.mapNotNull { entry ->
            val parts = entry.split(":")
            if (parts.size == 2) {
                val d = parseDate(parts[0])
                if (d != null) Triple(parts[0], d, parts[1]) else null
            } else null
        }.sortedByDescending { it.second }.take(60)

        val newSet = sortedList.map { "${it.first}:${it.third}" }.toSet()
        prefs.edit().putStringSet("step_history_list", newSet).apply()
    }

    fun recordStepDelta(delta: Int, isRunning: Boolean) {
        val currentToday = getTodaySteps() + delta
        setTodaySteps(currentToday)

        if (isRunning) {
            setTodayRunningSteps(getTodayRunningSteps() + delta)
        } else {
            setTodayWalkingSteps(getTodayWalkingSteps() + delta)
        }

        val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY).toString()
        val jsonStr = getTodayHourlyStepsJson()
        val json = try { JSONObject(jsonStr) } catch (_: Exception) { JSONObject() }
        val currentHourSteps = json.optInt(currentHour, 0)
        json.put(currentHour, currentHourSteps + delta)
        setTodayHourlyStepsJson(json.toString())

        val newLifetime = getLifetimeSteps() + delta
        setLifetimeSteps(newLifetime)

        val currentPb = getPbSteps()
        if (currentToday > currentPb) {
            setPbSteps(currentToday)
            setPbStepsDate(getCurrentDateString())
        }
    }

    fun handleDateChangeIfNeeded(): Boolean {
        val lastDate = getLastSavedDate()
        val todayStr = getCurrentDateString()
        if (lastDate.isEmpty()) {
            setLastSavedDate(todayStr)
            return false
        }
        if (lastDate != todayStr) {
            val prevSteps = getTodaySteps()
            if (prevSteps > 0) {
                storeStepInHistory(lastDate, prevSteps)
            }

            setTodaySteps(0)
            setTodayWalkingSteps(0)
            setTodayRunningSteps(0)
            setTodayHourlyStepsJson("{}")
            setLastSavedDate(todayStr)
            return true
        }
        return false
    }

    fun getDistanceKm(steps: Int): Float {
        return (steps * 0.705f) / 1000.0f
    }

    fun getCalories(steps: Int): Float {
        return steps * 0.042f
    }

    fun getActiveMinutes(steps: Int): Float {
        return steps / 100.0f
    }

    fun getStreak(): Int {
        val todaySteps = getTodaySteps()
        var currentStreak = if (todaySteps > 0) 1 else 0
        val history = getHistoricalSteps(60)
        if (history.isEmpty()) return currentStreak

        val isoSdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val historyMap = history.associateBy { isoSdf.format(it.date) }
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -1)

        while (true) {
            val targetStr = isoSdf.format(cal.time)
            val record = historyMap[targetStr]
            if (record != null && record.steps > 0) {
                currentStreak++
                cal.add(Calendar.DAY_OF_YEAR, -1)
            } else {
                break
            }
        }
        return currentStreak
    }

    fun checkAndSaveStreakPb() {
        val currentStreak = getStreak()
        if (currentStreak > getPbStreak()) {
            setPbStreak(currentStreak)
        }
    }
}
