import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';
import 'motion_detection_service.dart';

class DailyStepRecord extends Equatable {
  final DateTime date;
  final int steps;

  const DailyStepRecord({required this.date, required this.steps});

  @override
  List<Object?> get props => [date, steps];
}

class StepService {
  final SharedPreferences prefs;
  final MotionDetectionService _motionDetection;

  /// Whether motion pattern suggests vehicle/bicycle
  bool _isInVehicle = false;

  StepService(this.prefs, {MotionDetectionService? motionDetection})
    : _motionDetection = motionDetection ?? MotionDetectionService() {
    _initMotionDetection();
  }

  void _initMotionDetection() {
    _motionDetection.isInVehicleStream.listen((inVehicle) {
      _isInVehicle = inVehicle;
    });
    _motionDetection.start();
  }

  String _currentDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Stream<int> _rawStepStream() async* {
    if (Platform.isLinux) return;

    while (true) {
      if (await Permission.activityRecognition.isGranted) {
        try {
          yield* Pedometer.stepCountStream.map((event) => event.steps);
        } catch (e) {
          debugPrint('StepService: Pedometer stream error: $e');
        }
      }
      // Wait before checking again if stream closed or permission not granted
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _storeStepInHistory(String date, int steps) async {
    final history = prefs.getStringList('step_history') ?? [];
    final record = "$date:$steps";

    int existingIndex = history.indexWhere((e) => e.startsWith("$date:"));
    if (existingIndex != -1) {
      history[existingIndex] = record;
    } else {
      history.insert(0, record);
    }

    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    await prefs.setStringList('step_history', history);
  }

  Future<void> _handleDateChange(String oldDate, String newDate, int steps) async {
    await _storeStepInHistory(oldDate, steps);

    try {
      DateTime oldDT = _parseDate(oldDate);
      DateTime newDT = _parseDate(newDate);
      int daysGap = newDT.difference(oldDT).inDays;

      if (daysGap > 1) {
        for (int i = 1; i < daysGap; i++) {
          final gapDate = oldDT.add(Duration(days: i));
          final gapDateStr = "${gapDate.year}-${gapDate.month}-${gapDate.day}";
          await _storeStepInHistory(gapDateStr, 0);
        }
      }
    } catch (e) {
      debugPrint('StepService: Error filling history gaps: $e');
    }
  }

  Stream<int> getTodayStepsStream() async* {
    int todaySteps = prefs.getInt('today_steps') ?? 0;
    int lastSensorTotal = prefs.getInt('last_sensor_total') ?? -1;
    String lastSavedDate = prefs.getString('last_saved_date') ?? _currentDate();

    final now = _currentDate();
    if (lastSavedDate != now) {
      await _handleDateChange(lastSavedDate, now, todaySteps);
      todaySteps = 0;
      lastSavedDate = now;
      lastSensorTotal = -1;
      
      await prefs.setInt('today_steps', 0);
      await prefs.setString('last_saved_date', lastSavedDate);
      await prefs.setInt('last_sensor_total', -1);
    }

    yield todaySteps;

    // Debouncing persistence to avoid excessive disk I/O
    DateTime lastPersistTime = DateTime.now();
    int lastPersistedSteps = todaySteps;

    await for (final sensorTotal in _rawStepStream()) {
      final currentDay = _currentDate();

      if (currentDay != lastSavedDate) {
        await _handleDateChange(lastSavedDate, currentDay, todaySteps);
        todaySteps = 0;
        lastSavedDate = currentDay;
        lastSensorTotal = sensorTotal;
      } else {
        if (lastSensorTotal <= 0) {
          lastSensorTotal = sensorTotal;
        } else {
          int delta = sensorTotal - lastSensorTotal;
          if (delta > 0) {
            if (!_isInVehicle) {
              todaySteps += delta;
            }
          } else if (delta < 0) {
            todaySteps += sensorTotal;
          }
          lastSensorTotal = sensorTotal;
        }
      }

      // Persist only if steps changed significantly or enough time has passed
      final nowTime = DateTime.now();
      if (todaySteps != lastPersistedSteps && 
          (todaySteps - lastPersistedSteps >= 10 || 
           nowTime.difference(lastPersistTime).inSeconds >= 15)) {
        
        await prefs.setInt('today_steps', todaySteps);
        await prefs.setInt('last_sensor_total', lastSensorTotal);
        await prefs.setString('last_saved_date', lastSavedDate);
        
        lastPersistedSteps = todaySteps;
        lastPersistTime = nowTime;
      }

      yield todaySteps;
    }
  }

  Future<List<DailyStepRecord>> getHistoricalSteps(int days) async {
    final history = prefs.getStringList('step_history') ?? [];
    return history
        .map((item) {
          final parts = item.split(':');
          final dateParts = parts[0].split('-');
          return DailyStepRecord(
            date: DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            ),
            steps: int.parse(parts[1]),
          );
        })
        .take(days)
        .toList();
  }

  Future<int?> getGoal() async {
    return prefs.getInt('daily_goal');
  }

  Future<void> saveGoal(int goal) async {
    await prefs.setInt('daily_goal', goal);
  }

  void stop() {
    _motionDetection.stop();
  }
}
