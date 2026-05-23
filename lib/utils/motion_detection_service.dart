import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum ActivityType { stationary, walking, running, vehicle }

/// Lightweight motion classifier using accelerometer + gyroscope to detect
/// vehicle / bicycle states without Google Play Services or location.
class MotionDetectionService {
  static const _windowSize = 50; // samples per window (at ~50Hz -> ~1s)
  
  double _vehicleVarThreshold = 0.6; // m/s^2 variance
  double _vehicleSpikeThreshold = 3.0; // occasional spike allowed
  static const _bikeVarMin = 0.6;
  static const _bikeVarMax = 2.5;

  final StreamController<bool> _isInVehicleController =
      StreamController<bool>.broadcast();
  Stream<bool> get isInVehicleStream => _isInVehicleController.stream;

  final StreamController<ActivityType> _activityTypeController =
      StreamController<ActivityType>.broadcast();
  Stream<ActivityType> get activityTypeStream => _activityTypeController.stream;

  ActivityType _currentActivity = ActivityType.stationary;
  ActivityType get currentActivity => _currentActivity;

  // Use fixed-length lists as circular buffers for O(1) insertion
  final List<double> _accMagWindow = List.filled(_windowSize, 0.0);
  final List<double> _gyroMagWindow = List.filled(_windowSize, 0.0);
  int _accIndex = 0;
  int _gyroIndex = 0;
  int _accCount = 0;
  int _gyroCount = 0;

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _isVehicle = false;
  DateTime _lastEvaluation = DateTime.now();

  void setSensitivity(String sensitivity) {
    if (sensitivity == 'high') {
      _vehicleVarThreshold = 0.8;
      _vehicleSpikeThreshold = 4.0;
    } else if (sensitivity == 'low') {
      _vehicleVarThreshold = 0.4;
      _vehicleSpikeThreshold = 2.0;
    } else {
      _vehicleVarThreshold = 0.6;
      _vehicleSpikeThreshold = 3.0;
    }
  }

  void start() {
    _accSub = accelerometerEventStream().listen(_onAcc);
    _gyroSub = gyroscopeEventStream().listen(_onGyro);
  }

  void _onAcc(AccelerometerEvent e) {
    final mag = _magnitude(e.x, e.y, e.z) - 9.81;
    _accMagWindow[_accIndex] = mag.abs();
    _accIndex = (_accIndex + 1) % _windowSize;
    if (_accCount < _windowSize) _accCount++;
    _evaluate();
  }

  void _onGyro(GyroscopeEvent e) {
    final mag = _magnitude(e.x, e.y, e.z);
    _gyroMagWindow[_gyroIndex] = mag.abs();
    _gyroIndex = (_gyroIndex + 1) % _windowSize;
    if (_gyroCount < _windowSize) _gyroCount++;
    _evaluate();
  }

  void _evaluate() {
    // Throttling: only evaluate at most 5 times per second (200ms)
    final now = DateTime.now();
    if (now.difference(_lastEvaluation).inMilliseconds < 200) {
      return;
    }
    
    if (_accCount < _windowSize || _gyroCount < 10) {
      return;
    }

    _lastEvaluation = now;

    // Direct iteration is efficient for small windows (N=50)
    double accSum = 0;
    double maxAcc = 0;
    for (int i = 0; i < _accCount; i++) {
      final v = _accMagWindow[i];
      accSum += v;
      if (v > maxAcc) maxAcc = v;
    }
    final accMean = accSum / _accCount;
    
    double accVarSum = 0;
    for (int i = 0; i < _accCount; i++) {
      accVarSum += pow(_accMagWindow[i] - accMean, 2);
    }
    final accVar = accVarSum / _accCount;

    double gyroSum = 0;
    for (int i = 0; i < _gyroCount; i++) {
      gyroSum += _gyroMagWindow[i];
    }
    final gyroMean = gyroSum / _gyroCount;

    bool vehicleLike =
        accVar < _vehicleVarThreshold && maxAcc < _vehicleSpikeThreshold;
    bool bikeLike =
        accVar >= _bikeVarMin && accVar <= _bikeVarMax && gyroMean > 0.4;

    final newState = vehicleLike || bikeLike;
    if (newState != _isVehicle) {
      _isVehicle = newState;
      _isInVehicleController.add(_isVehicle);
    }

    // Classify activity type
    ActivityType activity;
    if (newState) {
      activity = ActivityType.vehicle;
    } else if (accVar < 0.05) {
      activity = ActivityType.stationary;
    } else if (accVar >= 3.0) {
      activity = ActivityType.running;
    } else {
      activity = ActivityType.walking;
    }

    if (activity != _currentActivity) {
      _currentActivity = activity;
      _activityTypeController.add(_currentActivity);
    }
  }

  double _magnitude(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z);

  void stop() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _accSub = null;
    _gyroSub = null;
    _accCount = 0;
    _gyroCount = 0;
  }

  void dispose() {
    stop();
    _isInVehicleController.close();
    _activityTypeController.close();
  }
}

