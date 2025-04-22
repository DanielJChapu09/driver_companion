import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../model/route_model.dart';
import 'navigation_service_interface.dart';

class NavigationService implements INavigationService {
  StreamSubscription<Position>? _locationSubscription;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  final StreamController<int> _stepController = StreamController<int>.broadcast();
  final StreamController<String> _instructionController = StreamController<String>.broadcast();
  final StreamController<double> _distanceController = StreamController<double>.broadcast();
  final StreamController<double> _durationController = StreamController<double>.broadcast();
  final StreamController<bool> _arrivalController = StreamController<bool>.broadcast();

  NavigationRoute? _currentRoute;
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  Timer? _simulationTimer;

  // Streams
  @override
  Stream<Position> get locationStream => _locationController.stream;

  @override
  Stream<int> get stepStream => _stepController.stream;

  @override
  Stream<String> get instructionStream => _instructionController.stream;

  @override
  Stream<double> get distanceStream => _distanceController.stream;

  @override
  Stream<double> get durationStream => _durationController.stream;

  @override
  Stream<bool> get arrivalStream => _arrivalController.stream;

  // Getters
  @override
  NavigationRoute? get currentRoute => _currentRoute;

  @override
  int get currentStepIndex => _currentStepIndex;

  @override
  bool get isNavigating => _isNavigating;

  // Initialize location service
  @override
  Future<bool> initialize() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return false;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return false;
        }
      }
      return true;
    } catch (e) {
      DevLogs.logError('Error initializing navigation service: $e');
      return false;
    }
  }

  // Start navigation
  @override
  Future<bool> startNavigation(NavigationRoute route) async {
    try {
      if (_isNavigating) {
        await stopNavigation();
      }

      _currentRoute = route;
      _currentStepIndex = 0;
      _isNavigating = true;

      // Start location updates
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      _locationSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(_onLocationUpdate);

      // Initial instruction
      if (route.steps.isNotEmpty) {
        _instructionController.add(route.steps[0].instruction);
      }

      return true;
    } catch (e) {
      DevLogs.logError('Error starting navigation: $e');
      return false;
    }
  }

  // Stop navigation
  @override
  Future<void> stopNavigation() async {
    _isNavigating = false;
    _currentRoute = null;
    _currentStepIndex = 0;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  // Handle location updates
  void _onLocationUpdate(Position position) {
    if (!_isNavigating || _currentRoute == null) return;

    _locationController.add(position);

    // Calculate distance to current step end
    if (_currentRoute!.steps.isNotEmpty && _currentStepIndex < _currentRoute!.steps.length) {
      RouteStep currentStep = _currentRoute!.steps[_currentStepIndex];

      // Calculate distance to end of current step
      double distanceToStepEnd = _calculateDistance(
        position.latitude,
        position.longitude,
        currentStep.endLatitude,
        currentStep.endLongitude,
      );

      // Update distance
      _distanceController.add(distanceToStepEnd);

      // Check if we've reached the end of the step
      if (distanceToStepEnd < 20) { // Within 20 meters
        _moveToNextStep();
      }

      // Check if we've reached the destination
      if (_currentStepIndex >= _currentRoute!.steps.length - 1 && distanceToStepEnd < 50) {
        _arrivalController.add(true);
        stopNavigation();
      }
    }
  }

  // Move to next navigation step
  void _moveToNextStep() {
    if (_currentRoute == null || _currentStepIndex >= _currentRoute!.steps.length - 1) return;

    _currentStepIndex++;
    _stepController.add(_currentStepIndex);

    // Update instruction
    RouteStep nextStep = _currentRoute!.steps[_currentStepIndex];
    _instructionController.add(nextStep.instruction);

    // Update estimated duration
    double remainingDuration = 0;
    for (int i = _currentStepIndex; i < _currentRoute!.steps.length; i++) {
      remainingDuration += _currentRoute!.steps[i].duration;
    }
    _durationController.add(remainingDuration);
  }

  // Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000; R = 6371 km
  }

  // Simulate navigation (for testing)
  @override
  void simulateNavigation(NavigationRoute route, {double speedFactor = 10.0}) {
    if (_isNavigating) {
      stopNavigation();
    }

    _currentRoute = route;
    _currentStepIndex = 0;
    _isNavigating = true;

    // Initial instruction
    if (route.steps.isNotEmpty) {
      _instructionController.add(route.steps[0].instruction);
    }

    // Simulate location updates along the route
    int stepIndex = 0;
    double progress = 0.0;

    _simulationTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!_isNavigating || stepIndex >= route.steps.length) {
        timer.cancel();
        _arrivalController.add(true);
        stopNavigation();
        return;
      }

      RouteStep step = route.steps[stepIndex];

      // Interpolate position along the step
      double lat = step.startLatitude + (step.endLatitude - step.startLatitude) * progress;
      double lng = step.startLongitude + (step.endLongitude - step.startLongitude) * progress;

      // Create simulated position
      Position position = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 15.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      );

      // Emit location update
      _locationController.add(position);

      // Update progress
      progress += 0.05 * speedFactor;

      // Move to next step if completed current one
      if (progress >= 1.0) {
        progress = 0.0;
        stepIndex++;

        if (stepIndex < route.steps.length) {
          _currentStepIndex = stepIndex;
          _stepController.add(stepIndex);
          _instructionController.add(route.steps[stepIndex].instruction);

          // Update remaining duration
          double remainingDuration = 0;
          for (int i = stepIndex; i < route.steps.length; i++) {
            remainingDuration += route.steps[i].duration;
          }
          _durationController.add(remainingDuration);
        }
      }
    });
  }

  // Dispose resources
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationController.close();
    _stepController.close();
    _instructionController.close();
    _distanceController.close();
    _durationController.close();
    _arrivalController.close();
    _simulationTimer?.cancel();
  }
}
