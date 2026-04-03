import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'path_step_tracking',
      initialNotificationTitle: 'Path',
      initialNotificationContent: 'Tracking your steps...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    final prefs = await SharedPreferences.getInstance();

    // Read initial values
    int goal = prefs.getInt('daily_goal') ?? 10000;
    int steps = prefs.getInt('today_steps') ?? 0;

    // Show initial notification
    _updateNotification(service, steps, goal);
    debugPrint("Background service started: $steps steps, goal: $goal");

    // Listen for step updates broadcasted from the main app
    service.on('steps_update').listen((event) {
      final data = event;
      final newSteps = data?['steps'] as int? ?? 0;
      final newGoal = data?['goal'] as int? ?? 10000;

      steps = newSteps;
      goal = newGoal;

      _updateNotification(service, steps, goal);
      debugPrint("Notification updated (broadcast): $steps steps, goal: $goal");
    });
  } catch (e) {
    debugPrint("Background service onStart error: $e");
  }
}

void _updateNotification(ServiceInstance service, int steps, int goal) {
  if (service is AndroidServiceInstance) {
    try {
      final remaining = goal - steps;

      String title;
      String content;

      if (steps >= goal) {
        title = 'Goal Achieved!';
        content = 'Amazing work! You hit ${_numberFormat(steps)} steps today!';
      } else {
        title = 'You can do it!';
        content =
            '${_numberFormat(steps)} / ${_numberFormat(goal)} steps • ${_numberFormat(remaining < 0 ? 0 : remaining)} more to go';
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
