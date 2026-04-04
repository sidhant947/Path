import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Lightweight motion classifier using accelerometer + gyroscope to detect
/// vehicle / bicycle states without Google Play Services or location.
/// Heuristic: sustained low-variance linear acceleration with occasional spikes
/// and low step cadence hints vehicle; medium variance with periodic lateral
/// oscillation suggests bicycle; anything else is treated as on-foot.
class MotionDetectionService {
  static const _windowSize = 50; // samples per window (at ~50Hz -> ~1s)
  static const _vehicleVarThreshold = 0.6; // m/s^2 variance
  static const _vehicleSpikeThreshold = 3.0; // occasional spike allowed
  static const _bikeVarMin = 0.6;
  static const _bikeVarMax = 2.5;

  final StreamController<bool> _isInVehicleController =
      StreamController<bool>.broadcast();
  Stream<bool> get isInVehicleStream => _isInVehicleController.stream;

  final List<double> _accMagWindow = [];
  final List<double> _gyroMagWindow = [];

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _isVehicle = false;

  void start() {
    // Sensors_plus streams run on best effort; no permission required.
    _accSub = accelerometerEventStream().listen(_onAcc);
    _gyroSub = gyroscopeEventStream().listen(_onGyro);
  }

  void _onAcc(AccelerometerEvent e) {
    final mag = _magnitude(e.x, e.y, e.z) - 9.81; // remove gravity approx
    _accMagWindow.add(mag.abs());
    _trimWindows();
    _evaluate();
  }

  void _onGyro(GyroscopeEvent e) {
    final mag = _magnitude(e.x, e.y, e.z);
    _gyroMagWindow.add(mag.abs());
    _trimWindows();
    _evaluate();
  }

  void _trimWindows() {
    if (_accMagWindow.length > _windowSize) {
      _accMagWindow.removeAt(0);
    }
    if (_gyroMagWindow.length > _windowSize) {
      _gyroMagWindow.removeAt(0);
    }
  }

  void _evaluate() {
    if (_accMagWindow.length < _windowSize || _gyroMagWindow.length < 10) {
      return; // not enough data yet
    }

    final accVar = _variance(_accMagWindow);
    final maxAcc = _accMagWindow.reduce(max);
    final gyroMean = _gyroMagWindow.reduce((a, b) => a + b) /
        _gyroMagWindow.length;

    bool vehicleLike = accVar < _vehicleVarThreshold && maxAcc < _vehicleSpikeThreshold;
    bool bikeLike = accVar >= _bikeVarMin && accVar <= _bikeVarMax && gyroMean > 0.4;

    final newState = vehicleLike || bikeLike;
    if (newState != _isVehicle) {
      _isVehicle = newState;
      _isInVehicleController.add(_isVehicle);
    }
  }

  double _variance(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumSq = values.fold<double>(0, (s, v) => s + pow(v - mean, 2));
    return sumSq / values.length;
  }

  double _magnitude(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z);

  void stop() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _accSub = null;
    _gyroSub = null;
  }

  void dispose() {
    stop();
    _isInVehicleController.close();
  }
}
