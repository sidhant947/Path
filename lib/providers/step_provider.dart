import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../utils/step_service.dart';

class StepProvider with ChangeNotifier {
  final StepService _service;
  int _todaySteps = 0;
  List<DailyStepRecord> _history = [];
  int _goal = 10000;
  bool _isPermissionGranted = true;
  bool _isBatteryOptimizationIgnored = true;
  StreamSubscription<int>? _subscription;

  StepProvider(this._service) {
    _init();
  }

  int get todaySteps => _todaySteps;
  List<DailyStepRecord> get history => _history;
  int get goal => _goal;
  bool get isPermissionGranted => _isPermissionGranted;
  bool get isBatteryOptimizationIgnored => _isBatteryOptimizationIgnored;

  int get streak {
    int currentStreak = 0;

    // Check if user was active today (at least 1 step)
    if (_todaySteps > 0) {
      currentStreak = 1;
    }

    if (_history.isEmpty) return currentStreak;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Look back through history
    for (int i = 0; i < _history.length; i++) {
      final record = _history[i];
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      // Expected date for the current streak count
      final expectedDate = today.subtract(Duration(days: currentStreak));

      // If user was active on this day, increment streak
      if (recordDate == expectedDate && record.steps > 0) {
        currentStreak++;
      } else if (recordDate.isBefore(expectedDate)) {
        // We found a gap in the streak
        break;
      }
    }

    return currentStreak;
  }

  Future<void> requestPermission() async {
    // 1. Activity Permission
    final activityStatus = await Permission.activityRecognition.request();
    _isPermissionGranted = activityStatus.isGranted;

    if (_isPermissionGranted) {
      _startStepStream();

      // 2. Battery Optimization
      final batteryStatus = await Permission.ignoreBatteryOptimizations
          .request();
      _isBatteryOptimizationIgnored = batteryStatus.isGranted;

      // 3. Notification (Android 13+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } else if (activityStatus.isPermanentlyDenied) {
      await openAppSettings();
    }
    notifyListeners();
  }

  Future<void> _init() async {
    _goal = await _service.getGoal() ?? 10000;
    _history = await _service.getHistoricalSteps(14); // Fetch more for safety

    final activityStatus = await Permission.activityRecognition.status;
    _isPermissionGranted = activityStatus.isGranted;

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    _isBatteryOptimizationIgnored = batteryStatus.isGranted;

    if (_isPermissionGranted) {
      _startStepStream();
    } else {
      notifyListeners();
    }
  }

  void _startStepStream() {
    _subscription?.cancel();

    // Initial fetch from service logic
    _subscription = _service.getTodayStepsStream().listen((steps) {
      _todaySteps = steps;
      notifyListeners();
    });

    // Also listen for updates from the background service isolate
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null && event.containsKey('steps')) {
        _todaySteps = event['steps'];
        notifyListeners();
      }
    });
  }

  Future<void> syncWithHealth() async {
    await _service.syncWithHealth();
    // After syncing, we can optionally refresh history too
    _history = await _service.getHistoricalSteps(14);
    notifyListeners();
  }

  Future<void> updateGoal(int newGoal) async {
    await _service.saveGoal(newGoal);
    _goal = newGoal;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
