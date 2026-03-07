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

  Stream<int> getTodayStepsStream() async* {
    // 1. Initialize from cache immediately for responsive UI
    int todaySteps = prefs.getInt('today_steps') ?? 0;
    int lastSensorTotal = prefs.getInt('last_sensor_total') ?? 0;
    String lastSavedDate = prefs.getString('last_saved_date') ?? _currentDate();

    final now = _currentDate();
    if (lastSavedDate != now) {
      // New day reset
      todaySteps = 0;
      lastSavedDate = now;
      await prefs.setInt('today_steps', 0);
      await prefs.setString('last_saved_date', lastSavedDate);
      // Wait for first sensor event to set lastSensorTotal for the new day
    }

    yield todaySteps;

    // 2. Listen for real-time sensor updates
    await for (final sensorTotal in _rawStepStream()) {
      final currentDay = _currentDate();

      if (currentDay != lastSavedDate) {
        // Handle day change while stream is running
        todaySteps = 0;
        lastSavedDate = currentDay;
        lastSensorTotal = sensorTotal;
      } else {
        if (lastSensorTotal == 0) {
          // Initialize sensor baseline for this session if it's new
          lastSensorTotal = sensorTotal;
        } else {
          int delta = sensorTotal - lastSensorTotal;
          if (delta > 0) {
            todaySteps += delta;
          } else if (delta < 0) {
            // Reboot case: sensor value is smaller than last recorded total.
            // We assume the sensor started from 0 again.
            todaySteps += sensorTotal;
          }
          lastSensorTotal = sensorTotal;
        }
      }

      // 3. Persist and broadcast the updated count
      await prefs.setInt('today_steps', todaySteps);
      await prefs.setInt('last_sensor_total', lastSensorTotal);
      await prefs.setString('last_saved_date', lastSavedDate);

      yield todaySteps;
    }
  }

  Future<List<DailyStepRecord>> getHistoricalSteps(int days) async {
    // Current implementation returns empty list.
    // Real data should be fetched from storage (e.g. SQLite or SharedPreferences).
    return [];
  }

  Future<int?> getGoal() async {
    return prefs.getInt('daily_goal');
  }

  Future<void> saveGoal(int goal) async {
    await prefs.setInt('daily_goal', goal);
  }
}
