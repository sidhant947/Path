import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StepStoreFile {
  static Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/path_step_data.json');
  }

  static Future<void> save({
    required int todaySteps,
    int walkingSteps = 0,
    int runningSteps = 0,
    int lifetimeSteps = 0,
    int pbSteps = 0,
    String pbStepsDate = '',
    int pbStreak = 0,
    String hourlyStepsString = '{}',
  }) async {
    final data = {
      'today_steps': todaySteps,
      'today_walking_steps': walkingSteps,
      'today_running_steps': runningSteps,
      'lifetime_steps': lifetimeSteps,
      'pb_steps': pbSteps,
      'pb_steps_date': pbStepsDate,
      'pb_streak': pbStreak,
      'today_hourly_steps': hourlyStepsString,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final file = await _file;
    await file.writeAsString(jsonEncode(data));
  }

  static Future<Map<String, dynamic>> load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
}
