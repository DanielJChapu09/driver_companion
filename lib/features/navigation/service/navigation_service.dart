import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import '../model/route_model.dart';

class NavigationService {
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final StreamController<LocationData> _locationController = StreamController<LocationData>.broadcast();
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
  Stream<LocationData> get locationStream => _locationController.stream;
  Stream<int> get stepStream => _stepController.stream;
  Stream<String> get instructionStream => _instructionController.stream;
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<double> get durationStream => _durationController.stream;
  Stream<bool> get arrivalStream => _arrivalController.stream;

  // Getters
  NavigationRoute? get currentRoute => _currentRoute;
  int get currentStepIndex => _currentStepIndex;
  bool get isNavigating => _isNavigating;

  // Initialize location service
  Future<bool> initialize() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        permissionStatus = await _location.requestPermission();
        if (permissionStatus != PermissionStatus.granted) {
          return false;
        }
      }

      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000, // 1 second
        distanceFilter: 5, // 5 meters
      );

      return true;
    } catch (e) {
      print('Error initializing navigation service: $e');
      return false;
    }
  }

  // Start navigation
  Future<bool> startNavigation(NavigationRoute route) async {
    try {
      if (_isNavigating) {
        await stopNavigation();
      }

      _currentRoute = route;
      _currentStepIndex = 0;
      _isNavigating = true;

      // Start location updates
      _locationSubscription = _location.onLocationChanged.listen(_onLocationUpdate);

      // Initial instruction
      if (route.steps.isNotEmpty) {
        _instructionController.add(route.steps[0].instruction);
      }

      return true;
    } catch (e) {
      print('Error starting navigation: $e');
      return false;
    }
  }

  // Stop navigation
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
  void _onLocationUpdate(LocationData locationData) {
    if (!_isNavigating || _currentRoute == null) return;

    _locationController.add(locationData);

    // Calculate distance to current step end
    if (_currentRoute!.steps.isNotEmpty && _currentStepIndex < _currentRoute!.steps.length) {
      RouteStep currentStep = _currentRoute!.steps[_currentStepIndex];

      // Calculate distance to end of current step
      double distanceToStepEnd = _calculateDistance(
        locationData.latitude!,
        locationData.longitude!,
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

      // Create simulated location data
      LocationData locationData = LocationData.fromMap({
        'latitude': lat,
        'longitude': lng,
        'accuracy': 10.0,
        'altitude': 0.0,
        'speed': 15.0,
        'heading': 0.0,
        'time': DateTime.now().millisecondsSinceEpoch,
      });

      // Emit location update
      _locationController.add(locationData);

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

