import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../model/driving_event_model.dart';

class SensorService {
  // Stream controllers for different sensor data
  final StreamController<AccelerometerEvent> _accelerometerStreamController = StreamController<AccelerometerEvent>.broadcast();
  final StreamController<GyroscopeEvent> _gyroscopeStreamController = StreamController<GyroscopeEvent>.broadcast();
  final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();
  final StreamController<DrivingEvent> _drivingEventStreamController = StreamController<DrivingEvent>.broadcast();

  // Subscriptions to sensor streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _locationSubscription;

  // Configuration thresholds
  double _accelerationThreshold = 2.0; // m/s²
  double _brakingThreshold = -2.0; // m/s²
  double _turnThreshold = 1.5; // rad/s

  // Current status
  bool _isMonitoring = false;
  Position? _lastKnownPosition;

  // Current speed for speeding detection
  double _currentSpeed = 0;
  double _speedLimitMargin = 5.0; // km/h above limit to trigger warning

  // Detection debounce timestamps
  DateTime? _lastAccelerationEventTime;
  DateTime? _lastBrakingEventTime;
  DateTime? _lastTurnEventTime;
  DateTime? _lastSpeedingEventTime;

  // Buffers for smoothing sensor readings
  final List<AccelerometerEvent> _accelerometerBuffer = [];
  final List<GyroscopeEvent> _gyroscopeBuffer = [];
  final int _bufferSize = 5;

  // Getter for the monitoring status
  bool get isMonitoring => _isMonitoring;

  // Expose streams
  Stream<AccelerometerEvent> get accelerometerStream => _accelerometerStreamController.stream;
  Stream<GyroscopeEvent> get gyroscopeStream => _gyroscopeStreamController.stream;
  Stream<Position> get locationStream => _locationStreamController.stream;
  Stream<DrivingEvent> get drivingEventStream => _drivingEventStreamController.stream;

  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Request sensor and activity recognition permissions
      PermissionStatus sensorPermission = await Permission.sensors.request();
      PermissionStatus activityPermission = await Permission.activityRecognition.request();

      // Request location permission
      LocationPermission locationPermission = await Geolocator.requestPermission();

      // Check if any permission is denied
      bool isSensorDenied = sensorPermission.isDenied || sensorPermission.isPermanentlyDenied;
      bool isActivityDenied = activityPermission.isDenied || activityPermission.isPermanentlyDenied;
      bool isLocationDenied = locationPermission == LocationPermission.denied || locationPermission == LocationPermission.deniedForever;

      if (isSensorDenied || isActivityDenied || isLocationDenied) {
        DevLogs.logError('SensorService: Required permissions not granted, now requesting');

        // Request only the missing permissions again
        Map<Permission, PermissionStatus> permissions = await [
          if (isSensorDenied) Permission.sensors,
          if (isActivityDenied) Permission.activityRecognition,
          if (isLocationDenied) Permission.location,
        ].request();

        // Final check after requesting again
        if (permissions.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
          DevLogs.logError('SensorService: Permissions still denied after re-requesting.');
          return false;
        }
      }

      return true;
    } catch (e) {
      DevLogs.logError('Error initializing SensorService: $e');
      return false;
    }
  }

  // Start monitoring driver behavior
  Future<bool> startMonitoring() async {
    if (_isMonitoring) return true;

    try {
      // Initialize if not already done
      if (!await initialize()) {
        return false;
      }

      // Subscribe to accelerometer
      _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        _processAccelerometerData(event);
        _accelerometerStreamController.add(event);
      });

      // Subscribe to gyroscope
      _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
        _processGyroscopeData(event);
        _gyroscopeStreamController.add(event);
      });

      // Subscribe to location
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        _processLocationData(position);
        _locationStreamController.add(position);
      });

      _isMonitoring = true;
      DevLogs.logInfo('SensorService: Monitoring started');
      return true;
    } catch (e) {
      DevLogs.logError('Error starting monitoring: $e');
      return false;
    }
  }

  // Stop monitoring driver behavior
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();

    _isMonitoring = false;
    DevLogs.logInfo('SensorService: Monitoring stopped');
  }

  // Update the configuration thresholds
  void updateThresholds({
    double? accelerationThreshold,
    double? brakingThreshold,
    double? turnThreshold,
    double? speedLimitMargin,
  }) {
    if (accelerationThreshold != null) _accelerationThreshold = accelerationThreshold;
    if (brakingThreshold != null) _brakingThreshold = brakingThreshold;
    if (turnThreshold != null) _turnThreshold = turnThreshold;
    if (speedLimitMargin != null) _speedLimitMargin = speedLimitMargin;
  }

  // Process accelerometer data to detect harsh acceleration and braking
  void _processAccelerometerData(AccelerometerEvent event) {
    // Add to buffer and maintain buffer size
    _accelerometerBuffer.add(event);
    if (_accelerometerBuffer.length > _bufferSize) {
      _accelerometerBuffer.removeAt(0);
    }

    // Only process when we have enough data
    if (_accelerometerBuffer.length < _bufferSize) return;

    // Calculate smoothed acceleration values
    double avgX = _accelerometerBuffer.map((e) => e.x).reduce((a, b) => a + b) / _bufferSize;
    double avgY = _accelerometerBuffer.map((e) => e.y).reduce((a, b) => a + b) / _bufferSize;
    double avgZ = _accelerometerBuffer.map((e) => e.z).reduce((a, b) => a + b) / _bufferSize;

    // Y-axis typically represents forward/backward acceleration in portrait orientation
    // Positive Y = acceleration, Negative Y = braking

    // Check for harsh acceleration
    if (avgY > _accelerationThreshold) {
      // Debounce: only trigger if it's been at least 3 seconds since last event
      if (_lastAccelerationEventTime == null ||
          DateTime.now().difference(_lastAccelerationEventTime!).inSeconds >= 3) {
        _lastAccelerationEventTime = DateTime.now();

        // Create and emit event (if we have location data)
        if (_lastKnownPosition != null) {
          final EventSeverity severity = _calculateSeverity(avgY, _accelerationThreshold);
          final event = DrivingEvent(
            type: EventType.harshAcceleration,
            severity: severity,
            latitude: _lastKnownPosition!.latitude,
            longitude: _lastKnownPosition!.longitude,
            value: avgY,
            threshold: _accelerationThreshold,
            additionalData: {
              'x': avgX,
              'y': avgY,
              'z': avgZ,
              'speed': _currentSpeed
            },
          );

          _drivingEventStreamController.add(event);
        }
      }
    }

    // Check for hard braking
    if (avgY < _brakingThreshold) {
      // Debounce: only trigger if it's been at least 3 seconds since last event
      if (_lastBrakingEventTime == null ||
          DateTime.now().difference(_lastBrakingEventTime!).inSeconds >= 3) {
        _lastBrakingEventTime = DateTime.now();

        // Create and emit event (if we have location data)
        if (_lastKnownPosition != null) {
          final EventSeverity severity = _calculateSeverity(avgY.abs(), _brakingThreshold.abs());
          final event = DrivingEvent(
            type: EventType.hardBraking,
            severity: severity,
            latitude: _lastKnownPosition!.latitude,
            longitude: _lastKnownPosition!.longitude,
            value: avgY,
            threshold: _brakingThreshold,
            additionalData: {
              'x': avgX,
              'y': avgY,
              'z': avgZ,
              'speed': _currentSpeed
            },
          );

          _drivingEventStreamController.add(event);
        }
      }
    }
  }

  // Process gyroscope data to detect sharp turns
  void _processGyroscopeData(GyroscopeEvent event) {
    // Add to buffer and maintain buffer size
    _gyroscopeBuffer.add(event);
    if (_gyroscopeBuffer.length > _bufferSize) {
      _gyroscopeBuffer.removeAt(0);
    }

    // Only process when we have enough data
    if (_gyroscopeBuffer.length < _bufferSize) return;

    // Calculate smoothed gyroscope values
    double avgX = _gyroscopeBuffer.map((e) => e.x).reduce((a, b) => a + b) / _bufferSize;
    double avgY = _gyroscopeBuffer.map((e) => e.y).reduce((a, b) => a + b) / _bufferSize;
    double avgZ = _gyroscopeBuffer.map((e) => e.z).reduce((a, b) => a + b) / _bufferSize;

    // Z-axis typically represents rotation around vertical axis (turning)
    // Magnitude of Z indicates sharpness of turn
    double turnRate = avgZ.abs();

    if (turnRate > _turnThreshold) {
      // Debounce: only trigger if it's been at least 3 seconds since last event
      if (_lastTurnEventTime == null ||
          DateTime.now().difference(_lastTurnEventTime!).inSeconds >= 3) {
        _lastTurnEventTime = DateTime.now();

        // Create and emit event (if we have location data)
        if (_lastKnownPosition != null) {
          final EventSeverity severity = _calculateSeverity(turnRate, _turnThreshold);
          final event = DrivingEvent(
            type: EventType.sharpTurn,
            severity: severity,
            latitude: _lastKnownPosition!.latitude,
            longitude: _lastKnownPosition!.longitude,
            value: turnRate,
            threshold: _turnThreshold,
            additionalData: {
              'x': avgX,
              'y': avgY,
              'z': avgZ,
              'direction': avgZ > 0 ? 'right' : 'left',
              'speed': _currentSpeed
            },
          );

          _drivingEventStreamController.add(event);
        }
      }
    }
  }

  // Process location data to detect speeding and update position
  void _processLocationData(Position position) {
    _currentSpeed = position.speed * 3.6; // Convert m/s to km/h

    // TODO: Get actual speed limit from map data
    // For now, using a dummy speed limit for testing
    double speedLimit = 50.0; // km/h

    // Check for speeding
    if (_currentSpeed > speedLimit + _speedLimitMargin) {
      // Debounce: only trigger if it's been at least 10 seconds since last event
      if (_lastSpeedingEventTime == null ||
          DateTime.now().difference(_lastSpeedingEventTime!).inSeconds >= 10) {
        _lastSpeedingEventTime = DateTime.now();

        final EventSeverity severity = _calculateSpeedingSeverity(_currentSpeed, speedLimit);
        final event = DrivingEvent(
          type: EventType.speeding,
          severity: severity,
          latitude: position.latitude,
          longitude: position.longitude,
          value: _currentSpeed,
          threshold: speedLimit,
          additionalData: {
            'speedLimit': speedLimit,
            'excessSpeed': _currentSpeed - speedLimit,
          },
        );

        _drivingEventStreamController.add(event);
      }
    }
  }

  // Calculate event severity based on how much the threshold was exceeded
  EventSeverity _calculateSeverity(double value, double threshold) {
    double ratio = value / threshold;

    if (ratio < 1.2) {
      return EventSeverity.low;
    } else if (ratio < 1.5) {
      return EventSeverity.medium;
    } else if (ratio < 2.0) {
      return EventSeverity.high;
    } else {
      return EventSeverity.critical;
    }
  }

  // Calculate speeding severity
  EventSeverity _calculateSpeedingSeverity(double speed, double limit) {
    double excessSpeed = speed - limit;

    if (excessSpeed <= 10) {
      return EventSeverity.low;
    } else if (excessSpeed <= 20) {
      return EventSeverity.medium;
    } else if (excessSpeed <= 30) {
      return EventSeverity.high;
    } else {
      return EventSeverity.critical;
    }
  }

  // Dispose resources
  void dispose() {
    stopMonitoring();
    _accelerometerStreamController.close();
    _gyroscopeStreamController.close();
    _locationStreamController.close();
    _drivingEventStreamController.close();
  }
}

