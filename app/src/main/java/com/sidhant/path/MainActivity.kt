package com.sidhant.path

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.sidhant.path.data.StepRepository
import com.sidhant.path.service.StepTrackingService
import com.sidhant.path.ui.screens.GoalSetupScreen
import com.sidhant.path.ui.screens.OnboardingScreen
import com.sidhant.path.ui.screens.SettingsScreen
import com.sidhant.path.ui.screens.StatsScreen
import com.sidhant.path.ui.screens.TodayScreen
import com.sidhant.path.ui.screens.WelcomeScreen
import com.sidhant.path.ui.theme.PathTheme
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.sidhant.path.widget.PathWidget

import androidx.activity.compose.BackHandler

enum class ScreenState { WELCOME, ONBOARDING, GOAL_SETUP, MAIN, SETTINGS }
enum class MainTab { TODAY, STATS }

class MainActivity : ComponentActivity() {

    private lateinit var repository: StepRepository
    private var trackingService: StepTrackingService? = null
    private var isBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as StepTrackingService.LocalBinder
            trackingService = binder.getService()
            isBound = true
            trackingService?.onStepsUpdatedListener = {
                runOnUiThread { refreshUiTrigger++ }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            trackingService?.onStepsUpdatedListener = null
            trackingService = null
            isBound = false
        }
    }

    private var refreshUiTrigger by mutableIntStateOf(0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = StepRepository(this)
        repository.handleDateChangeIfNeeded()

        if (repository.isOnboardingComplete()) {
            startStepService()
        }

        setContent {
            var themeMode by remember { mutableStateOf(repository.getThemeMode()) }
            var accentColorName by remember { mutableStateOf(repository.getAccentColorName()) }

            var currentScreen by remember {
                mutableStateOf(
                    if (!repository.isOnboardingComplete()) ScreenState.WELCOME
                    else ScreenState.MAIN
                )
            }

            var currentTab by remember { mutableStateOf(MainTab.TODAY) }

            @Suppress("UNUSED_VARIABLE")
            val dummyTrigger = refreshUiTrigger

            PathTheme(themeMode = themeMode) {
                when (currentScreen) {
                    ScreenState.WELCOME -> {
                        WelcomeScreen(
                            accentColorName = accentColorName,
                            onGetStarted = { currentScreen = ScreenState.ONBOARDING }
                        )
                    }

                    ScreenState.ONBOARDING -> {
                        OnboardingScreen(
                            accentColorName = accentColorName,
                            onCompleteOnboarding = {
                                repository.setOnboardingComplete(true)
                                startStepService()
                                currentScreen = ScreenState.GOAL_SETUP
                            }
                        )
                    }

                    ScreenState.GOAL_SETUP -> {
                        if (repository.isOnboardingComplete()) {
                            BackHandler { currentScreen = ScreenState.MAIN }
                        }
                        GoalSetupScreen(
                            currentGoal = repository.getCurrentGoal(),
                            onSaveGoal = { newGoal ->
                                repository.setDailyGoal(newGoal)
                                trackingService?.updateNotification()
                                trackingService?.updateWidget()
                                currentScreen = ScreenState.MAIN
                            }
                        )
                    }

                    ScreenState.MAIN -> {
                        when (currentTab) {
                            MainTab.TODAY -> {
                                TodayScreen(
                                    todaySteps = repository.getTodaySteps(),
                                    goal = repository.getCurrentGoal(),
                                    distanceKm = repository.getDistanceKm(repository.getTodaySteps()),
                                    calories = repository.getCalories(repository.getTodaySteps()),
                                    activeMinutes = repository.getActiveMinutes(repository.getTodaySteps()),
                                    accentColorName = accentColorName,
                                    onOpenGoalSetup = { currentScreen = ScreenState.GOAL_SETUP },
                                    onNavigateToStats = { currentTab = MainTab.STATS }
                                )
                            }

                            MainTab.STATS -> {
                                BackHandler { currentTab = MainTab.TODAY }
                                StatsScreen(
                                    todaySteps = repository.getTodaySteps(),
                                    goal = repository.getCurrentGoal(),
                                    streak = repository.getStreak(),
                                    walkingSteps = repository.getTodayWalkingSteps(),
                                    runningSteps = repository.getTodayRunningSteps(),
                                    hourlyStepsJson = repository.getTodayHourlyStepsJson(),
                                    history = repository.getHistoricalSteps(14),
                                    pbSteps = repository.getPbSteps(),
                                    pbStepsDate = repository.getPbStepsDate(),
                                    pbStreak = repository.getPbStreak(),
                                    lifetimeSteps = repository.getLifetimeSteps(),
                                    totalDistanceKm = repository.getDistanceKm(repository.getLifetimeSteps()),
                                    accentColorName = accentColorName,
                                    onOpenSettings = { currentScreen = ScreenState.SETTINGS },
                                    onNavigateToToday = { currentTab = MainTab.TODAY }
                                )
                            }
                        }
                    }

                    ScreenState.SETTINGS -> {
                        SettingsScreen(
                            repository = repository,
                            onBack = { currentScreen = ScreenState.MAIN },
                            onThemeOrAccentChanged = {
                                themeMode = repository.getThemeMode()
                                accentColorName = repository.getAccentColorName()
                                trackingService?.updateWidget()
                            }
                        )
                    }
                }
            }
        }
    }

    private fun startStepService() {
        val serviceIntent = Intent(this, StepTrackingService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun onResume() {
        super.onResume()
        repository.handleDateChangeIfNeeded()
        trackingService?.updateWidget()
        lifecycleScope.launch(Dispatchers.IO) {
            PathWidget.updateWidget(applicationContext)
        }
        refreshUiTrigger++
    }

    override fun onDestroy() {
        trackingService?.onStepsUpdatedListener = null
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
        super.onDestroy()
    }
}
