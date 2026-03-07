import 'dart:async';
import 'dart:io';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

class DailyStepRecord extends Equatable {
  final DateTime date;
  final int steps;

  const DailyStepRecord({required this.date, required this.steps});

  @override
  List<Object?> get props => [date, steps];
}

class StepService {
  final SharedPreferences prefs;

  StepService(this.prefs);

  String _currentDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  Stream<int> _rawStepStream() async* {
    if (!Platform.isLinux &&
        await Permission.activityRecognition.request().isGranted) {
      yield* Pedometer.stepCountStream.map((event) => event.steps);
    } else {
      // Return empty stream if not supported/granted
      return;
    }
  }

  Future<void> _storeStepInHistory(String date, int steps) async {
    final history = prefs.getStringList('step_history') ?? [];
    // Format: "YYYY-MM-DD:STEPS"
    final record = "$date:$steps";

    // Check if we already have a record for this date (updating it)
    int existingIndex = history.indexWhere((e) => e.startsWith("$date:"));
    if (existingIndex != -1) {
      history[existingIndex] = record;
    } else {
      history.insert(0, record);
    }

    // Limit to 14 days for safety
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    await prefs.setStringList('step_history', history);
  }

  Stream<int> getTodayStepsStream() async* {
    // 1. Initialize from cache
    int todaySteps = prefs.getInt('today_steps') ?? 0;
    int lastSensorTotal = prefs.getInt('last_sensor_total') ?? 0;
    String lastSavedDate = prefs.getString('last_saved_date') ?? _currentDate();

    final now = _currentDate();
    if (lastSavedDate != now) {
      // If we haven't opened the app since yesterday, flush yesterday's steps
      await _storeStepInHistory(lastSavedDate, todaySteps);

      todaySteps = 0;
      lastSavedDate = now;
      await prefs.setInt('today_steps', 0);
      await prefs.setString('last_saved_date', lastSavedDate);
    }

    yield todaySteps;

    // 2. Listen for real-time sensor updates
    await for (final sensorTotal in _rawStepStream()) {
      final currentDay = _currentDate();

      if (currentDay != lastSavedDate) {
        // Daylight transition happened while app is open
        await _storeStepInHistory(lastSavedDate, todaySteps);
        todaySteps = 0;
        lastSavedDate = currentDay;
        lastSensorTotal = sensorTotal;
      } else {
        if (lastSensorTotal == 0) {
          lastSensorTotal = sensorTotal;
        } else {
          int delta = sensorTotal - lastSensorTotal;
          if (delta > 0) {
            todaySteps += delta;
          } else if (delta < 0) {
            // Sensor reset (e.g. reboot)
            todaySteps += sensorTotal;
          }
          lastSensorTotal = sensorTotal;
        }
      }

      // 3. Persist
      await prefs.setInt('today_steps', todaySteps);
      await prefs.setInt('last_sensor_total', lastSensorTotal);
      await prefs.setString('last_saved_date', lastSavedDate);

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
}
