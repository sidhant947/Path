import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'step_service.dart';
import 'activity_detection_service.dart';

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

    // Step Tracking Logic
    final prefs = await SharedPreferences.getInstance();
    final activityDetection = ActivityDetectionService();
    final stepService = StepService(
      prefs,
      activityDetection: activityDetection,
    );
    final goal = prefs.getInt('daily_goal') ?? 10000;

    // Start the pedometer listener in the background isolate
    _startStepTracking(stepService, service, prefs, goal);

    // Periodic sync with Health storage (to pick up smartwatch steps)
    Timer.periodic(const Duration(minutes: 10), (timer) async {
      try {
        await stepService.syncWithHealth();
        final steps = prefs.getInt('today_steps') ?? 0;
        service.invoke('update', {"steps": steps});
        _updateNotification(service, steps, goal);
      } catch (e) {
        debugPrint("Background service periodic sync error: $e");
      }
    });
  } catch (e) {
    debugPrint("Background service onStart error: $e");
  }
}

void _startStepTracking(
  StepService stepService,
  ServiceInstance service,
  SharedPreferences prefs,
  int goal,
) {
  stepService.getTodayStepsStream().listen((steps) {
    // This will update the SharedPreferences in the background isolate
    // and broadcast the change via 'update' event
    service.invoke('update', {"steps": steps});

    // Update the foreground notification with current progress
    _updateNotification(service, steps, goal);
  });
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
        title = 'Path';
        content =
            '${_numberFormat(steps)} / ${_numberFormat(goal)} steps • ${_numberFormat(remaining < 0 ? 0 : remaining)} to go';
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
