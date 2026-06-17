import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'step_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: 'path_step_tracking',
      initialNotificationTitle: 'Path',
      initialNotificationContent: 'Step tracking is active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Start the service if it's not already running
  if (!await service.isRunning()) {
    await service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

int _getCurrentGoal(SharedPreferences prefs) {
  final flexibleEnabled = prefs.getBool('flexible_goals_enabled') ?? false;
  if (flexibleEnabled) {
    final day = DateTime.now().weekday;
    if (day == DateTime.saturday || day == DateTime.sunday) {
      return prefs.getInt('goal_weekend') ?? 6000;
    } else {
      return prefs.getInt('goal_weekday') ?? 10000;
    }
  }
  return prefs.getInt('daily_goal') ?? 10000;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure we have latest data across isolates
    final stepService = StepService(prefs);
    stepService.startMotionDetection();

    // Read initial values
    int goal = _getCurrentGoal(prefs);
    int currentSteps = prefs.getInt('today_steps') ?? 0;

    // Show initial notification immediately
    _updateNotification(service, currentSteps, goal);
    debugPrint("Background service started: $currentSteps steps, goal: $goal");

    // Listen to real-time step count via StepService
    // This handles the background counting and persistence
    StreamSubscription? stepSubscription;
    StreamSubscription? stopSubscription;
    StreamSubscription? updateSubscription;

    void startTracking() {
      stepSubscription?.cancel();
      stepSubscription = stepService.getTodayStepsStream().listen(
        (steps) {
          currentSteps = steps;
          _updateNotification(service, currentSteps, goal);

          service.invoke('steps_updated_in_background', {
            'steps': currentSteps,
            'goal': goal,
          });
        },
        onError: (error) {
          debugPrint("Background service: Step stream error: $error");
          Future.delayed(const Duration(seconds: 5), () => startTracking());
        },
        onDone: () {
          debugPrint("Background service: Step stream closed, restarting...");
          Future.delayed(const Duration(seconds: 3), () => startTracking());
        },
      );
    }

    startTracking();

    // Periodically refresh notification to keep it visible
    int lastDay = DateTime.now().day;
    final refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (DateTime.now().day != lastDay) {
        lastDay = DateTime.now().day;
        await prefs.reload();
        goal = _getCurrentGoal(prefs); // Recalculate goal on day change
        startTracking(); // Re-trigger StepService to handle date change and reset to 0
      } else {
        await prefs.reload();
        goal = _getCurrentGoal(prefs);
        _updateNotification(service, currentSteps, goal);
      }
    });

    stopSubscription = service.on('stopService').listen((event) {
      stepSubscription?.cancel();
      stopSubscription?.cancel();
      updateSubscription?.cancel();
      refreshTimer.cancel();
      stepService.stop();
      service.stopSelf();
    });

    // Listen for step updates broadcasted from the main app (e.g. goal changes)
    updateSubscription = service.on('steps_update').listen((event) async {
      await prefs.reload();
      final data = event;
      final newGoal = data?['goal'] as int?;
      if (newGoal != null) {
        goal = newGoal;
      } else {
        goal = _getCurrentGoal(prefs);
      }
      debugPrint("Background service: Goal updated to $goal");

      _updateNotification(service, currentSteps, goal);
    });
  } catch (e) {
    debugPrint("Background service onStart error: $e");
  }
}

void _updateNotification(ServiceInstance service, int steps, int goal) {
  if (service is AndroidServiceInstance) {
    try {
      final progress = (steps / goal * 100).clamp(0, 100).toInt();

      String title;
      String content;

      if (steps >= goal) {
        title = 'Goal Achieved! 🎉';
        content = 'Amazing! ${_numberFormat(steps)} steps today!';
      } else {
        title = 'Path - Step Tracker';
        content =
            '${_numberFormat(steps)} / ${_numberFormat(goal)} steps ($progress%)';
      }

      service.setForegroundNotificationInfo(title: title, content: content);
    } catch (e) {
      debugPrint("Error updating notification: $e");
    }
  }
}

String _numberFormat(int number) {
  if (number >= 1000) {
    final thousands = number ~/ 1000;
    final remainder = number % 1000;
    if (remainder == 0) {
      return '${thousands}k';
    }
    return '$thousands,${remainder.toString().padLeft(3, '0')}';
  }
  return number.toString();
}
