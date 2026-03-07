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
    int baseline = prefs.getInt('step_baseline') ?? 0;
    String lastSavedDate = prefs.getString('last_saved_date') ?? _currentDate();

    if (lastSavedDate != _currentDate()) {
      baseline = 0;
    }

    await for (final totalSteps in _rawStepStream()) {
      final currentDate = _currentDate();
      if (lastSavedDate != currentDate || baseline == 0) {
        baseline = totalSteps;
        lastSavedDate = currentDate;
        await prefs.setInt('step_baseline', baseline);
        await prefs.setString('last_saved_date', lastSavedDate);
      }

      int steps = totalSteps - baseline;
      if (steps < 0) {
        baseline = totalSteps;
        await prefs.setInt('step_baseline', baseline);
        steps = 0;
      }
      yield steps;
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
