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
  StreamSubscription<int>? _subscription;

  StepProvider(this._service) {
    _init();
  }

  int get todaySteps => _todaySteps;
  List<DailyStepRecord> get history => _history;
  int get goal => _goal;
  bool get isPermissionGranted => _isPermissionGranted;

  int get streak {
    if (_history.isEmpty) return 0;

    int currentStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_todaySteps >= _goal) {
      currentStreak = 1;
    }

    for (int i = 0; i < _history.length; i++) {
      final record = _history[i];
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      final expectedDate = today.subtract(Duration(days: currentStreak));

      if (recordDate == expectedDate && record.steps >= _goal) {
        currentStreak++;
      } else if (recordDate.isBefore(expectedDate)) {
        break;
      }
    }

    return currentStreak > 7 ? 7 : currentStreak;
  }

  Future<void> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    _isPermissionGranted = status.isGranted;

    if (_isPermissionGranted) {
      _startStepStream();

      // Request ignore battery optimization for unrestricted background
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      // Request notification permission for foreground service on Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    notifyListeners();
  }

  Future<void> _init() async {
    _goal = await _service.getGoal() ?? 10000;
    _history = await _service.getHistoricalSteps(7);

    final status = await Permission.activityRecognition.status;
    _isPermissionGranted = status.isGranted;

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
