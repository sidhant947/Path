import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/step_service.dart';

class StepProvider with ChangeNotifier {
  final StepService _service;
  int _todaySteps = 0;
  List<DailyStepRecord> _history = [];
  int _goal = 10000;
  bool _isPermissionGranted = true;
  bool _isBatteryOptimizationIgnored = true;
  StreamSubscription<int>? _subscription;
  StreamSubscription? _backgroundSubscription;
  DateTime _lastBackgroundUpdate = DateTime.fromMillisecondsSinceEpoch(0);

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

  StepProvider(this._service);

  /// Must be called after the widget is built (e.g., via addPostFrameCallback)
  Future<void> init() async {
    await _init();
  }

  Future<void> refresh() async {
    final prefs = _service.prefs;
    await prefs.reload();

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
  int get walkingSteps => _service.prefs.getInt('today_walking_steps') ?? 0;
  int get runningSteps => _service.prefs.getInt('today_running_steps') ?? 0;
  int get lifetimeSteps => _service.prefs.getInt('lifetime_steps') ?? 0;
  int get pbSteps => _service.prefs.getInt('pb_steps') ?? 0;
  String get pbStepsDate => _service.prefs.getString('pb_steps_date') ?? '';
  int get pbStreak => _service.prefs.getInt('pb_streak') ?? 0;

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
  String get hourlyStepsString => _service.prefs.getString('today_hourly_steps') ?? '{}';

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

  // Setters/Updaters
  Future<void> updateProfile(double height, double weight, String gender) async {
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
    final prefs = _service.prefs;

    _goal = await _service.getGoal() ?? 10000;
    _history = await _service.getHistoricalSteps(14); // Fetch more for safety

    // Load profile
    _height = prefs.getDouble('height') ?? 170.0;
    _weight = prefs.getDouble('weight') ?? 70.0;
    _gender = prefs.getString('gender') ?? 'Other';

    // Load flexible goals
    _flexibleGoalsEnabled = prefs.getBool('flexible_goals_enabled') ?? false;
    _goalWeekday = prefs.getInt('goal_weekday') ?? 10000;
    _goalWeekend = prefs.getInt('goal_weekend') ?? 6000;

    // Load theme
    _themeModeName = prefs.getString('theme_mode') ?? 'system';
    _accentColorName = prefs.getString('accent_color') ?? 'Lime';

    // Load sensitivity
    _motionSensitivity = prefs.getString('motion_sensitivity') ?? 'medium';

    final activityStatus = await Permission.activityRecognition.status;
    _isPermissionGranted = activityStatus.isGranted;

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    _isBatteryOptimizationIgnored = batteryStatus.isGranted;

    _checkAndSaveStreakPB();

    // Always start stream, StepService now handles waiting for permission
    _startStepStream();
  }

  void _checkAndSaveStreakPB() async {
    int currentStreak = streak;
    int storedPbStreak = pbStreak;
    if (currentStreak > storedPbStreak) {
      await _service.prefs.setInt('pb_streak', currentStreak);
    }
  }

  void _startStepStream() {
    _subscription?.cancel();
    _backgroundSubscription?.cancel();

    // 1. Listen to real-time step count from the main app's StepService
    _subscription = _service.getTodayStepsStream().listen((steps) {
      // Prioritize background service steps if it's active
      if (DateTime.now().difference(_lastBackgroundUpdate).inSeconds > 5) {
        if (_todaySteps != steps) {
          _todaySteps = steps;
          _checkAndSaveStreakPB();
          notifyListeners();
        }
      }

      // Broadcast steps to background service if it needs manual updates
      final service = FlutterBackgroundService();
      service.invoke('steps_update', {'steps': steps, 'goal': goal});
    });

    // 2. Also listen for updates FROM the background service
    // This ensures UI stays in sync even if the main stream has issues
    _backgroundSubscription = FlutterBackgroundService().on('steps_updated_in_background').listen((event) {
      if (event != null) {
        _lastBackgroundUpdate = DateTime.now();
        final steps = event['steps'] as int? ?? _todaySteps;
        if (steps != _todaySteps) {
          _todaySteps = steps;
          _checkAndSaveStreakPB();
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
    _subscription?.cancel();
    _backgroundSubscription?.cancel();
    super.dispose();
  }
}

