import 'dart:async';
import 'dart:convert';
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

  /// Active Activity classification
  ActivityType _currentActivity = ActivityType.stationary;

  /// Battery saver power throttling fields
  Timer? _throttleTimer;
  bool _isMotionServiceRunning = true;

  StepService(this.prefs, {MotionDetectionService? motionDetection})
    : _motionDetection = motionDetection ?? MotionDetectionService() {
    final sensitivity = prefs.getString('motion_sensitivity') ?? 'medium';
    _motionDetection.setSensitivity(sensitivity);
    _initMotionDetection();
  }

  void _initMotionDetection() {
    _motionDetection.isInVehicleStream.listen((inVehicle) {
      _isInVehicle = inVehicle;
    });
    _motionDetection.activityTypeStream.listen((activity) {
      _currentActivity = activity;
    });
    _resetThrottleTimer();
  }

  void _resetThrottleTimer() {
    _throttleTimer?.cancel();
    if (!_isMotionServiceRunning) {
      _motionDetection.start();
      _isMotionServiceRunning = true;
      debugPrint("StepService: Waking up motion detection sensors.");
    }
    _throttleTimer = Timer(const Duration(minutes: 2), () {
      _motionDetection.stop();
      _isMotionServiceRunning = false;
      debugPrint("StepService: Throttling motion detection sensors to save battery.");
    });
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
  void _recordStepDelta(int delta, int currentTodaySteps) async {
    _resetThrottleTimer(); // Reset battery saver throttling timer when steps are recorded

    // 1. Walking vs Running
    int walkingSteps = prefs.getInt('today_walking_steps') ?? 0;
    int runningSteps = prefs.getInt('today_running_steps') ?? 0;
    if (_currentActivity == ActivityType.running) {
      runningSteps += delta;
      await prefs.setInt('today_running_steps', runningSteps);
    } else {
      walkingSteps += delta;
      await prefs.setInt('today_walking_steps', walkingSteps);
    }

    // 2. Hourly Steps Map
    final currentHour = DateTime.now().hour.toString();
    final hourlyString = prefs.getString('today_hourly_steps') ?? '{}';
    Map<String, dynamic> hourlyMap = {};
    try {
      hourlyMap = jsonDecode(hourlyString);
    } catch (_) {}
    hourlyMap[currentHour] = (hourlyMap[currentHour] ?? 0) + delta;
    await prefs.setString('today_hourly_steps', jsonEncode(hourlyMap));

    // 3. Lifetime steps
    int lifetime = prefs.getInt('lifetime_steps') ?? 0;
    lifetime += delta;
    await prefs.setInt('lifetime_steps', lifetime);

    // 4. Personal Best (Compare today steps with PB steps)
    int pbSteps = prefs.getInt('pb_steps') ?? 0;
    if (currentTodaySteps > pbSteps) {
      await prefs.setInt('pb_steps', currentTodaySteps);
      await prefs.setString('pb_steps_date', _currentDate());
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

      // Reset daily counts for the new day
      await prefs.setInt('today_walking_steps', 0);
      await prefs.setInt('today_running_steps', 0);
      await prefs.setString('today_hourly_steps', '{}');
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

        // Reset daily counts for the new day
        await prefs.setInt('today_steps', 0);
        await prefs.setInt('today_walking_steps', 0);
        await prefs.setInt('today_running_steps', 0);
        await prefs.setString('today_hourly_steps', '{}');
      } else {
        if (lastSensorTotal <= 0) {
          lastSensorTotal = sensorTotal;
        } else {
          int delta = sensorTotal - lastSensorTotal;
          if (delta > 0) {
            if (!_isInVehicle) {
              todaySteps += delta;
              _recordStepDelta(delta, todaySteps);
            }
          } else if (delta < 0) {
            if (!_isInVehicle) {
              todaySteps += sensorTotal;
              _recordStepDelta(sensorTotal, todaySteps);
            }
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

  void updateSensitivity(String sensitivity) {
    _motionDetection.setSensitivity(sensitivity);
  }

  void stop() {
    _throttleTimer?.cancel();
    _motionDetection.stop();
  }
}

