import 'dart:async';
import 'dart:ui';

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
      isForegroundMode: false, // Disables the persistent notification
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
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Step Tracking Logic
  final prefs = await SharedPreferences.getInstance();
  final stepService = StepService(prefs);

  // Start the pedometer listener in the background isolate
  _startStepTracking(stepService, service);
}

void _startStepTracking(StepService stepService, ServiceInstance service) {
  stepService.getTodayStepsStream().listen((steps) {
    // This will update the SharedPreferences in the background isolate
    // and broadcast the change via 'update' event
    service.invoke('update', {"steps": steps});
  });
}
