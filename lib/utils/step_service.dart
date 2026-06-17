import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  }

  void startMotionDetection() {
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

    int pedometerFailCount = 0;

    while (true) {
      try {
        if (await Permission.activityRecognition.isGranted) {
          if (pedometerFailCount < 3) {
            try {
              await for (final entry in Pedometer.stepCountStream) {
                pedometerFailCount = 0;
                yield entry.steps;
              }
            } catch (e) {
              pedometerFailCount++;
              debugPrint('StepService: Pedometer error ($pedometerFailCount/3): $e');
            }
            if (pedometerFailCount < 3) {
              await Future.delayed(const Duration(seconds: 5));
              continue;
            }
          }

          // Fallback to accelerometer
          debugPrint('StepService: Using accelerometer fallback');
          int accTotal = 0;
          await for (final delta in _accelerometerStepStream()) {
            accTotal += delta;
            // We yield a value that looks like a sensor total
            // When switching back to pedometer, getTodayStepsStream will handle the "reset"
            yield accTotal;
          }
          pedometerFailCount = 0;
        }
      } catch (e) {
        debugPrint('StepService: _rawStepStream error: $e');
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Stream<int> _accelerometerStepStream() async* {
    bool wasAboveThreshold = false;
    const double threshold = 11.5;
    const Duration cooldown = Duration(milliseconds: 350);
    DateTime lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);
    final startTime = DateTime.now();

    await for (final event in accelerometerEventStream()) {
      // Periodic check back for hardware pedometer
      if (DateTime.now().difference(startTime).inMinutes >= 5) break;

      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final above = mag > threshold;

      if (above && !wasAboveThreshold) {
        final now = DateTime.now();
        if (now.difference(lastStepTime) > cooldown) {
          lastStepTime = now;
          yield 1; // Yield a delta of 1 step
        }
      }
      wasAboveThreshold = above;
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
  Map<String, int>? _hourlyCache;

  void _recordStepDelta(int delta, int currentTodaySteps) async {
    _resetThrottleTimer();

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

    // 2. Hourly Steps Map - Optimized with Cache
    final currentHour = DateTime.now().hour.toString();
    if (_hourlyCache == null) {
      final hourlyString = prefs.getString('today_hourly_steps') ?? '{}';
      try {
        final Map<String, dynamic> decoded = jsonDecode(hourlyString);
        _hourlyCache = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (_) {
        _hourlyCache = {};
      }
    }
    
    _hourlyCache![currentHour] = (_hourlyCache![currentHour] ?? 0) + delta;
    await prefs.setString('today_hourly_steps', jsonEncode(_hourlyCache));

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
        } else if (sensorTotal > lastSensorTotal) {
          int delta = sensorTotal - lastSensorTotal;
          if (!_isInVehicle) {
            todaySteps += delta;
            _recordStepDelta(delta, todaySteps);
          }
          lastSensorTotal = sensorTotal;
        } else if (sensorTotal < lastSensorTotal) {
          // Significant drop suggests a reboot or reset of the pedometer
          // Only process if it looks like a real reset (near zero or large drop)
          if (sensorTotal < 100 || sensorTotal < lastSensorTotal / 2) {
            if (!_isInVehicle) {
              todaySteps += sensorTotal;
              _recordStepDelta(sensorTotal, todaySteps);
            }
            lastSensorTotal = sensorTotal;
          }
          // Minor dips are ignored as noise
        }
      }

      // Persist immediately on every step to keep isolates in sync
      if (todaySteps != lastPersistedSteps) {
        await prefs.setInt('today_steps', todaySteps);
        await prefs.setInt('last_sensor_total', lastSensorTotal);
        await prefs.setString('last_saved_date', lastSavedDate);
        
        lastPersistedSteps = todaySteps;
      }

      yield todaySteps;
    }
  }

  List<DailyStepRecord> getHistoricalStepsSync(int days) {
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

  Future<List<DailyStepRecord>> getHistoricalSteps(int days) async {
    return getHistoricalStepsSync(days);
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

