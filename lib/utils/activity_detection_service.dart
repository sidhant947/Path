import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

/// Service that detect user activity (driving, walking, etc.)
/// and provides a stream of whether the user is currently in a vehicle.
class ActivityDetectionService {
  static const String _logTag = 'ActivityDetection';

  /// Stream of whether the user is currently in a vehicle (driving, passenger, etc.)
  final StreamController<bool> _isInVehicleController =
      StreamController<bool>.broadcast();

  Stream<bool> get isInVehicleStream => _isInVehicleController.stream;

  bool _isCurrentlyInVehicle = false;
  bool get isCurrentlyInVehicle => _isCurrentlyInVehicle;

  StreamSubscription<ActivityEvent>? _activitySubscription;
  final ActivityRecognition _activityRecognition = ActivityRecognition();

  /// Start listening to activity recognition events.
  /// Returns true if successfully started, false if not supported or permission denied.
  Future<bool> start() async {
    if (Platform.isLinux) {
      debugPrint('$_logTag: Activity recognition not supported on Linux');
      return false;
    }

    try {
      // Start listening to activity updates
      // Note: runForegroundService is set to false because we use flutter_background_service
      _activitySubscription = _activityRecognition
          .activityStream(runForegroundService: false)
          .listen(
            _handleActivityUpdate,
            onError: (error) {
              debugPrint('$_logTag: Error receiving activity updates: $error');
              // Don't cancel on error, just log it
            },
            cancelOnError: false,
          );

      debugPrint('$_logTag: Activity recognition started');
      return true;
    } catch (e) {
      debugPrint('$_logTag: Failed to start activity recognition: $e');
      return false;
    }
  }

  void _handleActivityUpdate(ActivityEvent activityEvent) {
    // Check if the detected activity is a vehicle-related one
    final bool wasInVehicle = _isCurrentlyInVehicle;

    // inVehicle covers driving, passenger, etc.
    // We also check onBicycle as it can generate false step counts
    _isCurrentlyInVehicle =
        activityEvent.type == ActivityType.inVehicle ||
        activityEvent.type == ActivityType.onBicycle;

    if (wasInVehicle != _isCurrentlyInVehicle) {
      debugPrint(
        '$_logTag: Activity changed to ${activityEvent.type.name} '
        '(confidence: ${activityEvent.confidence}%) - '
        'In vehicle: $_isCurrentlyInVehicle',
      );
      _isInVehicleController.add(_isCurrentlyInVehicle);
    }
  }

  /// Stop listening to activity updates.
  void stop() {
    _activitySubscription?.cancel();
    _activitySubscription = null;
    debugPrint('$_logTag: Activity recognition stopped');
  }

  void dispose() {
    stop();
    _isInVehicleController.close();
  }
}
