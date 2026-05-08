import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Lightweight motion classifier using accelerometer + gyroscope to detect
/// vehicle / bicycle states without Google Play Services or location.
class MotionDetectionService {
  static const _windowSize = 50; // samples per window (at ~50Hz -> ~1s)
  static const _vehicleVarThreshold = 0.6; // m/s^2 variance
  static const _vehicleSpikeThreshold = 3.0; // occasional spike allowed
  static const _bikeVarMin = 0.6;
  static const _bikeVarMax = 2.5;

  final StreamController<bool> _isInVehicleController =
      StreamController<bool>.broadcast();
  Stream<bool> get isInVehicleStream => _isInVehicleController.stream;

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
  }
}
