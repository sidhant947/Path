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

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure we have latest data across isolates
    final stepService = StepService(prefs);

    // Read initial values
    int goal = prefs.getInt('daily_goal') ?? 10000;
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
      stepSubscription = stepService.getTodayStepsStream().listen((steps) {
        currentSteps = steps;
        _updateNotification(service, currentSteps, goal);
        
        // Notify main app if it's running
        service.invoke('steps_updated_in_background', {
          'steps': currentSteps,
          'goal': goal,
        });
      });
    }

    startTracking();

    // Periodically refresh notification to keep it visible
    int lastDay = DateTime.now().day;
    final refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (DateTime.now().day != lastDay) {
        lastDay = DateTime.now().day;
        startTracking(); // Re-trigger StepService to handle date change and reset to 0
      } else {
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
    updateSubscription = service.on('steps_update').listen((event) {
      final data = event;
      final newGoal = data?['goal'] as int?;
      if (newGoal != null) {
        goal = newGoal;
        debugPrint("Background service: Goal updated to $goal");
      }

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
