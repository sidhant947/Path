import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/step_service.dart';
import '../utils/step_store_file.dart';

class StepProvider with ChangeNotifier {
  final StepService _service;
  int _todaySteps = 0;
  List<DailyStepRecord> _history = [];
  int _goal = 10000;
  bool _isPermissionGranted = true;
  bool _isBatteryOptimizationIgnored = true;
  StreamSubscription? _backgroundSubscription;
  Timer? _pollTimer;

  // Profile settings
  double _height = 170.0;
  double _weight = 70.0;
  String _gender = 'Other';

  // Flexible goal settings
  bool _flexibleGoalsEnabled = false;
  int _goalWeekday = 10000;
  int _goalWeekend = 6000;

  // Theme settings
  String _themeModeName = 'system';
  String _accentColorName = 'Lime';

  // Sensitivity settings
  String _motionSensitivity = 'medium';

  // Cached achievement & tracking metrics
  int _walkingSteps = 0;
  int _runningSteps = 0;
  int _lifetimeSteps = 0;
  int _pbSteps = 0;
  String _pbStepsDate = '';
  int _pbStreak = 0;
  String _hourlyStepsString = '{}';

  StepProvider(this._service) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final prefs = _service.prefs;
    _todaySteps = prefs.getInt('today_steps') ?? 0;
    _goal = prefs.getInt('daily_goal') ?? 10000;
    _history = _service.getHistoricalStepsSync(14);

    _height = prefs.getDouble('height') ?? 170.0;
    _weight = prefs.getDouble('weight') ?? 70.0;
    _gender = prefs.getString('gender') ?? 'Other';

    _flexibleGoalsEnabled = prefs.getBool('flexible_goals_enabled') ?? false;
    _goalWeekday = prefs.getInt('goal_weekday') ?? 10000;
    _goalWeekend = prefs.getInt('goal_weekend') ?? 6000;

    _themeModeName = prefs.getString('theme_mode') ?? 'system';
    _accentColorName = prefs.getString('accent_color') ?? 'Lime';
    _motionSensitivity = prefs.getString('motion_sensitivity') ?? 'medium';

    _walkingSteps = prefs.getInt('today_walking_steps') ?? 0;
    _runningSteps = prefs.getInt('today_running_steps') ?? 0;
    _lifetimeSteps = prefs.getInt('lifetime_steps') ?? 0;
    _pbSteps = prefs.getInt('pb_steps') ?? 0;
    _pbStepsDate = prefs.getString('pb_steps_date') ?? '';
    _pbStreak = prefs.getInt('pb_streak') ?? 0;
    _hourlyStepsString = prefs.getString('today_hourly_steps') ?? '{}';
  }

  /// Must be called after the widget is built
  Future<void> init() async {
    await _init();
  }

  Future<void> refresh() async {
    final prefs = _service.prefs;
    await prefs.reload();

    final int newSteps = prefs.getInt('today_steps') ?? 0;

    // Only update if it's a significant jump or it's lower (potential reset/new day)
    // If the difference is small, we trust the real-time _todaySteps from the event
    if (newSteps > _todaySteps || (newSteps == 0 && _todaySteps > 10)) {
      _todaySteps = newSteps;
    }

    _goal = await _service.getGoal() ?? 10000;
    _history = await _service.getHistoricalSteps(14);

    _height = prefs.getDouble('height') ?? 170.0;
    _weight = prefs.getDouble('weight') ?? 70.0;
    _gender = prefs.getString('gender') ?? 'Other';

    _flexibleGoalsEnabled = prefs.getBool('flexible_goals_enabled') ?? false;
    _goalWeekday = prefs.getInt('goal_weekday') ?? 10000;
    _goalWeekend = prefs.getInt('goal_weekend') ?? 6000;

    _themeModeName = prefs.getString('theme_mode') ?? 'system';
    _accentColorName = prefs.getString('accent_color') ?? 'Lime';
    _motionSensitivity = prefs.getString('motion_sensitivity') ?? 'medium';

    _walkingSteps = prefs.getInt('today_walking_steps') ?? 0;
    _runningSteps = prefs.getInt('today_running_steps') ?? 0;
    _lifetimeSteps = prefs.getInt('lifetime_steps') ?? 0;
    _pbSteps = prefs.getInt('pb_steps') ?? 0;
    _pbStepsDate = prefs.getString('pb_steps_date') ?? '';
    _pbStreak = prefs.getInt('pb_streak') ?? 0;
    _hourlyStepsString = prefs.getString('today_hourly_steps') ?? '{}';

    _checkAndSaveStreakPB();
    notifyListeners();
  }

  int get todaySteps => _todaySteps;
  List<DailyStepRecord> get history => _history;

  bool get isPermissionGranted => _isPermissionGranted;
  bool get isBatteryOptimizationIgnored => _isBatteryOptimizationIgnored;

  // Getters for settings
  double get height => _height;
  double get weight => _weight;
  String get gender => _gender;

  bool get flexibleGoalsEnabled => _flexibleGoalsEnabled;
  int get goalWeekday => _goalWeekday;
  int get goalWeekend => _goalWeekend;

  String get themeModeName => _themeModeName;
  String get accentColorName => _accentColorName;
  String get motionSensitivity => _motionSensitivity;

  int get goal {
    if (_flexibleGoalsEnabled) {
      final day = DateTime.now().weekday;
      if (day == DateTime.saturday || day == DateTime.sunday) {
        return _goalWeekend;
      } else {
        return _goalWeekday;
      }
    }
    return _goal;
  }

  Color get accentColor {
    switch (_accentColorName) {
      case 'Pink':
        return const Color(0xFFFF007F);
      case 'Blue':
        return const Color(0xFF007BFF);
      case 'Green':
        return const Color(0xFF2ECC71);
      case 'Orange':
        return const Color(0xFFE67E22);
      default:
        return const Color(0xFFC7F900);
    }
  }

  ThemeMode get themeMode {
    switch (_themeModeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Getters for achievements & tracking metrics
  int get walkingSteps => _walkingSteps;
  int get runningSteps => _runningSteps;
  int get lifetimeSteps => _lifetimeSteps;
  int get pbSteps => _pbSteps;
  String get pbStepsDate => _pbStepsDate;
  int get pbStreak => _pbStreak;

  // Estimator Getters
  double getDistanceKmForSteps(int stepsCount) {
    double factor = 0.414;
    if (_gender == 'Male') {
      factor = 0.415;
    } else if (_gender == 'Female') {
      factor = 0.413;
    }
    final strideM = (_height * factor) / 100.0;
    return (stepsCount * strideM) / 1000.0;
  }

  double get todayDistanceKm => getDistanceKmForSteps(_todaySteps);

  double getCaloriesForSteps(int stepsCount) {
    // Scientific estimate: steps * 0.0006125 * weight
    return stepsCount * 0.0006125 * _weight;
  }

  double get todayCalories => getCaloriesForSteps(_todaySteps);

  double get todayActiveMinutes => _todaySteps / 100.0;

  // Getters for hourly breakdown
  String get hourlyStepsString => _hourlyStepsString;

  int get streak {
    int currentStreak = _todaySteps > 0 ? 1 : 0;

    if (_history.isEmpty) return currentStreak;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime dayToLookFor = today.subtract(const Duration(days: 1));

    // Look back through history
    for (var record in _history) {
      final recordDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      if (recordDate == dayToLookFor) {
        if (record.steps > 0) {
          currentStreak++;
          dayToLookFor = dayToLookFor.subtract(const Duration(days: 1));
        } else {
          break; // Gap in activity
        }
      } else if (recordDate.isBefore(dayToLookFor)) {
        break; // Gap in data
      }
    }

    return currentStreak;
  }

  // Setters/Updaters
  Future<void> updateProfile(
    double height,
    double weight,
    String gender,
  ) async {
    _height = height;
    _weight = weight;
    _gender = gender;
    await _service.prefs.setDouble('height', height);
    await _service.prefs.setDouble('weight', weight);
    await _service.prefs.setString('gender', gender);
    notifyListeners();
  }

  Future<void> updateFlexibleGoals({
    required bool enabled,
    required int weekday,
    required int weekend,
  }) async {
    _flexibleGoalsEnabled = enabled;
    _goalWeekday = weekday;
    _goalWeekend = weekend;
    await _service.prefs.setBool('flexible_goals_enabled', enabled);
    await _service.prefs.setInt('goal_weekday', weekday);
    await _service.prefs.setInt('goal_weekend', weekend);
    _syncGoalToBackground();
    notifyListeners();
  }

  Future<void> updateThemeMode(String mode) async {
    _themeModeName = mode;
    await _service.prefs.setString('theme_mode', mode);
    notifyListeners();
  }

  Future<void> updateAccentColor(String name) async {
    _accentColorName = name;
    await _service.prefs.setString('accent_color', name);
    notifyListeners();
  }

  Future<void> updateMotionSensitivity(String sensitivity) async {
    _motionSensitivity = sensitivity;
    await _service.prefs.setString('motion_sensitivity', sensitivity);
    _service.updateSensitivity(sensitivity);
    notifyListeners();
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
    // We already loaded data in constructor, but let's refresh permission statuses
    final activityStatus = await Permission.activityRecognition.status;
    _isPermissionGranted = activityStatus.isGranted;

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    _isBatteryOptimizationIgnored = batteryStatus.isGranted;

    _checkAndSaveStreakPB();
    _startStepStream();
    _startPolling();
  }

  void _checkAndSaveStreakPB() async {
    int currentStreak = streak;
    int storedPbStreak = pbStreak;
    if (currentStreak > storedPbStreak) {
      await _service.prefs.setInt('pb_streak', currentStreak);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final data = await StepStoreFile.load();
      final storedSteps = data['today_steps'] as int? ?? 0;
      if (storedSteps != _todaySteps) {
        _todaySteps = storedSteps;
        _walkingSteps = data['today_walking_steps'] as int? ?? 0;
        _runningSteps = data['today_running_steps'] as int? ?? 0;
        _lifetimeSteps = data['lifetime_steps'] as int? ?? 0;
        _pbSteps = data['pb_steps'] as int? ?? 0;
        _pbStepsDate = data['pb_steps_date'] as String? ?? '';
        _pbStreak = data['pb_streak'] as int? ?? 0;
        _hourlyStepsString = data['today_hourly_steps'] as String? ?? '{}';
        _checkAndSaveStreakPB();
        notifyListeners();
      }
    });
  }

  /// Request immediate sync from background service and refresh from step store file
  Future<void> requestSync() async {
    // Restart the background service to ensure its Dart isolate is alive.
    // The native Service can outlive its Dart isolate; restarting forces a
    // fresh isolate that will reconnect the sensor and write to the file.
    final service = FlutterBackgroundService();
    try {
      if (await service.isRunning()) {
        service.invoke('stopService');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {}
    try {
      await service.startService();
    } catch (_) {}
    // Request immediate sync in case the isolate was already alive
    service.invoke('sync_request');

    final data = await StepStoreFile.load();
    final storedSteps = data['today_steps'] as int? ?? 0;
    if (storedSteps != _todaySteps) {
      _todaySteps = storedSteps;
    }
    _walkingSteps = data['today_walking_steps'] as int? ?? 0;
    _runningSteps = data['today_running_steps'] as int? ?? 0;
    _lifetimeSteps = data['lifetime_steps'] as int? ?? 0;
    _pbSteps = data['pb_steps'] as int? ?? 0;
    _pbStepsDate = data['pb_steps_date'] as String? ?? '';
    _pbStreak = data['pb_streak'] as int? ?? 0;
    _hourlyStepsString = data['today_hourly_steps'] as String? ?? '{}';
    _checkAndSaveStreakPB();
    notifyListeners();
  }

  void _startStepStream() {
    _backgroundSubscription?.cancel();

    _todaySteps = _service.prefs.getInt('today_steps') ?? 0;

    _backgroundSubscription = FlutterBackgroundService()
        .on('steps_updated_in_background')
        .listen((event) async {
          if (event != null) {
            final steps = event['steps'] as int? ?? _todaySteps;

            // Reload prefs to get latest walking/running/hourly steps and PB
            final prefs = _service.prefs;
            await prefs.reload();

            // Update cached values
            _walkingSteps = prefs.getInt('today_walking_steps') ?? 0;
            _runningSteps = prefs.getInt('today_running_steps') ?? 0;
            _lifetimeSteps = prefs.getInt('lifetime_steps') ?? 0;
            _pbSteps = prefs.getInt('pb_steps') ?? 0;
            _pbStepsDate = prefs.getString('pb_steps_date') ?? '';
            _pbStreak = prefs.getInt('pb_streak') ?? 0;
            _hourlyStepsString = prefs.getString('today_hourly_steps') ?? '{}';

            if (steps != _todaySteps) {
              _todaySteps = steps;
              _checkAndSaveStreakPB();
              notifyListeners();
            } else {
              notifyListeners();
            }
          }
        });
  }

  Future<void> updateGoal(int newGoal) async {
    await _service.saveGoal(newGoal);
    _goal = newGoal;

    // Broadcast updated goal to background service
    _syncGoalToBackground();

    notifyListeners();
  }

  void _syncGoalToBackground() {
    final service = FlutterBackgroundService();
    service.invoke('steps_update', {'steps': _todaySteps, 'goal': goal});
  }

  @override
  void dispose() {
    _backgroundSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
