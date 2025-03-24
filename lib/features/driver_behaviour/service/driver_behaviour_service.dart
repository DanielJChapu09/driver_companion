import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:uuid/uuid.dart';
import '../model/driving_event_model.dart';
import '../model/driving_score_model.dart';
import '../model/trip_model.dart';
import './sensor_service.dart';
import './feedback_service.dart';

class DriverBehaviorService {
  final SensorService _sensorService = SensorService();
  final FeedbackService _feedbackService = FeedbackService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current trip data
  DrivingTrip? _currentTrip;
  final List<DrivingEvent> _currentTripEvents = [];
  final List<Position> _tripPositions = [];
  DateTime? _tripStartTime;
  Position? _lastKnownPosition;
  String? _userId;

  // Subscriptions
  StreamSubscription<DrivingEvent>? _eventSubscription;
  StreamSubscription<Position>? _positionSubscription;

  // Status
  bool _isMonitoring = false;
  bool _isNavigationMode = false;
  String? _currentRouteId;

  // Initialize the service
  Future<bool> initialize({required String userId}) async {
    try {
      _userId = userId;

      // Initialize sensor service
      bool sensorInitialized = await _sensorService.initialize();
      if (!sensorInitialized) {
        DevLogs.logError('Driver behavior service: Failed to initialize sensor service');
        return false;
      }

      // Initialize feedback service
      await _feedbackService.initialize();

      return true;
    } catch (e) {
      DevLogs.logError('Error initializing driver behavior service: $e');
      return false;
    }
  }

  // Start monitoring driver behavior
  Future<bool> startMonitoring({bool isNavigationMode = false, String? routeId}) async {
    if (_isMonitoring) return true;

    try {
      // Start the sensor service
      bool started = await _sensorService.startMonitoring();
      if (!started) {
        DevLogs.logError('Driver behavior service: Failed to start sensor service');
        return false;
      }

      _isNavigationMode = isNavigationMode;
      _currentRouteId = routeId;

      // Subscribe to driving events
      _eventSubscription = _sensorService.drivingEventStream.listen(_handleDrivingEvent);

      // Subscribe to position updates
      _positionSubscription = _sensorService.locationStream.listen(_updatePosition);

      // Start a new trip
      _startNewTrip();

      _isMonitoring = true;
      return true;
    } catch (e) {
      DevLogs.logError('Error starting driver behavior monitoring: $e');
      return false;
    }
  }

  // Stop monitoring and save trip data
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      // Stop the sensor service
      _sensorService.stopMonitoring();

      // Cancel subscriptions
      _eventSubscription?.cancel();
      _positionSubscription?.cancel();

      // End the current trip
      await _endCurrentTrip();

      _isMonitoring = false;
      _isNavigationMode = false;
      _currentRouteId = null;
    } catch (e) {
      DevLogs.logError('Error stopping driver behavior monitoring: $e');
    }
  }

  // Handle a driving event
  void _handleDrivingEvent(DrivingEvent event) {
    // Add trip ID to the event
    final tripEvent = DrivingEvent(
      type: event.type,
      severity: event.severity,
      latitude: event.latitude,
      longitude: event.longitude,
      value: event.value,
      threshold: event.threshold,
      additionalData: event.additionalData,
      tripId: _currentTrip?.id,
    );

    // Add to current trip events
    _currentTripEvents.add(tripEvent);

    // Provide feedback based on the event
    _provideFeedback(tripEvent);

    // Save event to Firestore
    _saveEventToFirestore(tripEvent);
  }

  // Update current position
  void _updatePosition(Position position) {
    _lastKnownPosition = position;
    _tripPositions.add(position);
  }

  // Start a new trip
  void _startNewTrip() async {
    if (_lastKnownPosition == null) {
      // Wait for first position
      await _getInitialPosition();
    }

    if (_lastKnownPosition == null) {
      DevLogs.logError('Driver behavior service: Could not get initial position');
      return;
    }

    _tripStartTime = DateTime.now();

    // Create a new trip
    _currentTrip = DrivingTrip(
      id: Uuid().v4(),
      startTime: _tripStartTime!,
      startLatitude: _lastKnownPosition!.latitude,
      startLongitude: _lastKnownPosition!.longitude,
      startAddress: 'Starting point', // Ideally get this from geocoding
      distanceTraveled: 0,
      duration: 0,
      events: [],
      isNavigationTrip: _isNavigationMode,
      routeId: _currentRouteId,
      isCompleted: false,
      userId: _userId,
    );

    // Save initial trip to Firestore
    _saveTripToFirestore(_currentTrip!);
  }

  // Get initial position
  Future<void> _getInitialPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _lastKnownPosition = position;
    } catch (e) {
      DevLogs.logError('Error getting initial position: $e');
    }
  }

  // End the current trip and save data
  Future<void> _endCurrentTrip() async {
    if (_currentTrip == null || _lastKnownPosition == null) return;

    try {
      // Calculate trip statistics
      double totalDistance = _calculateTripDistance();
      double tripDuration = DateTime.now().difference(_tripStartTime!).inMinutes.toDouble();

      // Calculate trip score
      Map<String, dynamic> scoreBreakdown = _calculateTripScore();
      double overallScore = scoreBreakdown['overallScore'];

      // Update the trip
      _currentTrip = DrivingTrip(
        id: _currentTrip!.id,
        startTime: _currentTrip!.startTime,
        endTime: DateTime.now(),
        startLatitude: _currentTrip!.startLatitude,
        startLongitude: _currentTrip!.startLongitude,
        endLatitude: _lastKnownPosition!.latitude,
        endLongitude: _lastKnownPosition!.longitude,
        startAddress: _currentTrip!.startAddress,
        endAddress: 'Destination', // Ideally get this from geocoding
        distanceTraveled: totalDistance,
        duration: tripDuration,
        events: _currentTripEvents,
        overallScore: overallScore,
        scoreBreakdown: scoreBreakdown,
        userId: _userId,
        vehicleId: _currentTrip!.vehicleId,
        isNavigationTrip: _currentTrip!.isNavigationTrip,
        routeId: _currentTrip!.routeId,
        isCompleted: true,
      );

      // Save final trip to Firestore
      await _saveTripToFirestore(_currentTrip!);

      // Update driver score
      await _updateDriverScore();

      // Provide trip summary feedback
      _provideTripSummaryFeedback(_currentTrip!);

      // Reset trip data
      _currentTripEvents.clear();
      _tripPositions.clear();
      _tripStartTime = null;
      _currentTrip = null;
    } catch (e) {
      DevLogs.logError('Error ending trip: $e');
    }
  }

  // Calculate total distance traveled in kilometers
  double _calculateTripDistance() {
    if (_tripPositions.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < _tripPositions.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _tripPositions[i].latitude,
        _tripPositions[i].longitude,
        _tripPositions[i + 1].latitude,
        _tripPositions[i + 1].longitude,
      );
    }

    // Convert meters to kilometers
    return totalDistance / 1000;
  }

  // Calculate trip score based on events
  Map<String, dynamic> _calculateTripScore() {
    // Count events by type and severity
    int totalEvents = _currentTripEvents.length;
    int criticalEvents = _currentTripEvents.where((e) => e.severity == EventSeverity.critical).length;
    int highEvents = _currentTripEvents.where((e) => e.severity == EventSeverity.high).length;
    int mediumEvents = _currentTripEvents.where((e) => e.severity == EventSeverity.medium).length;
    int lowEvents = _currentTripEvents.where((e) => e.severity == EventSeverity.low).length;

    // Count specific event types
    int accelerationEvents = _currentTripEvents.where((e) => e.type == EventType.harshAcceleration).length;
    int brakingEvents = _currentTripEvents.where((e) => e.type == EventType.hardBraking).length;
    int turnEvents = _currentTripEvents.where((e) => e.type == EventType.sharpTurn).length;
    int speedingEvents = _currentTripEvents.where((e) => e.type == EventType.speeding).length;

    // Calculate category scores (0-100, higher is better)
    double accelerationScore = _calculateCategoryScore(accelerationEvents, totalEvents);
    double brakingScore = _calculateCategoryScore(brakingEvents, totalEvents);
    double turningScore = _calculateCategoryScore(turnEvents, totalEvents);
    double speedingScore = _calculateCategoryScore(speedingEvents, totalEvents);

    // Calculate overall score with weighted categories
    double overallScore = 100;
    if (totalEvents > 0) {
      overallScore -= (criticalEvents * 10); // -10 points per critical event
      overallScore -= (highEvents * 5); // -5 points per high severity event
      overallScore -= (mediumEvents * 2); // -2 points per medium severity event
      overallScore -= (lowEvents * 0.5); // -0.5 points per low severity event
    }

    // Ensure score is within 0-100 range
    overallScore = overallScore.clamp(0, 100);

    return {
      'overallScore': overallScore,
      'accelerationScore': accelerationScore,
      'brakingScore': brakingScore,
      'turningScore': turningScore,
      'speedingScore': speedingScore,
      'eventCounts': {
        'total': totalEvents,
        'critical': criticalEvents,
        'high': highEvents,
        'medium': mediumEvents,
        'low': lowEvents,
        'acceleration': accelerationEvents,
        'braking': brakingEvents,
        'turning': turnEvents,
        'speeding': speedingEvents,
      }
    };
  }

  // Calculate category score
  double _calculateCategoryScore(int eventCount, int totalEvents) {
    if (totalEvents == 0) return 100;
    double ratio = eventCount / totalEvents;
    return 100 - (ratio * 100).clamp(0, 100);
  }

  // Save event to Firestore
  Future<void> _saveEventToFirestore(DrivingEvent event) async {
    try {
      await _firestore.collection('drivingEvents').add(event.toJson());
    } catch (e) {
      DevLogs.logError('Error saving event to Firestore: $e');
    }
  }

  // Save trip to Firestore
  Future<void> _saveTripToFirestore(DrivingTrip trip) async {
    try {
      await _firestore.collection('drivingTrips')
          .doc(trip.id)
          .set(trip.toJson());
    } catch (e) {
      DevLogs.logError('Error saving trip to Firestore: $e');
    }
  }

  // Update driver score
  Future<void> _updateDriverScore() async {
    if (_userId == null || _currentTrip == null) return;

    try {
      // Get current driver score
      DocumentSnapshot scoreDoc = await _firestore
          .collection('driverScores')
          .doc(_userId)
          .get();

      DriverScore driverScore;

      if (scoreDoc.exists && scoreDoc.data() != null) {
        // Update existing score
        driverScore = DriverScore.fromJson(scoreDoc.data() as Map<String, dynamic>);

        // Calculate new score (weighted average of existing and current trip)
        double existingWeight = driverScore.tripsCount / (driverScore.tripsCount + 1);
        double newTripWeight = 1 / (driverScore.tripsCount + 1);

        double newOverallScore = (driverScore.overallScore * existingWeight) +
            (_currentTrip!.overallScore! * newTripWeight);

        // Update category scores
        Map<String, double> newCategoryScores = Map.from(driverScore.categoryScores);
        (_currentTrip!.scoreBreakdown as Map<String, dynamic>).forEach((key, value) {
          if (key != 'overallScore' && key != 'eventCounts' && value is double) {
            if (newCategoryScores.containsKey(key)) {
              newCategoryScores[key] = (newCategoryScores[key]! * existingWeight) +
                  (value * newTripWeight);
            } else {
              newCategoryScores[key] = value;
            }
          }
        });

        // Create updated driver score
        driverScore = DriverScore(
          id: driverScore.id,
          userId: _userId!,
          overallScore: newOverallScore,
          categoryScores: newCategoryScores,
          tripsCount: driverScore.tripsCount + 1,
          totalEvents: driverScore.totalEvents + _currentTripEvents.length,
          totalDistance: driverScore.totalDistance + _currentTrip!.distanceTraveled,
          totalDuration: driverScore.totalDuration + (_currentTrip!.duration / 60), // convert minutes to hours
          lastUpdated: DateTime.now(),
          recentEvents: _getCurrentSignificantEvents() + driverScore.recentEvents,
          improvementSuggestions: _generateImprovementSuggestions(),
        );
      } else {
        // Create new driver score
        driverScore = DriverScore(
          id: _userId!,
          userId: _userId!,
          overallScore: _currentTrip!.overallScore!,
          categoryScores: _extractCategoryScores(),
          tripsCount: 1,
          totalEvents: _currentTripEvents.length,
          totalDistance: _currentTrip!.distanceTraveled,
          totalDuration: _currentTrip!.duration / 60, // convert minutes to hours
          lastUpdated: DateTime.now(),
          recentEvents: _getCurrentSignificantEvents(),
          improvementSuggestions: _generateImprovementSuggestions(),
        );
      }

      // Save updated score
      await _firestore.collection('driverScores')
          .doc(_userId)
          .set(driverScore.toJson());
    } catch (e) {
      DevLogs.logError('Error updating driver score: $e');
    }
  }

  // Extract category scores from current trip
  Map<String, double> _extractCategoryScores() {
    Map<String, double> scores = {};
    if (_currentTrip?.scoreBreakdown != null) {
      (_currentTrip!.scoreBreakdown as Map<String, dynamic>).forEach((key, value) {
        if (key != 'overallScore' && key != 'eventCounts' && value is double) {
          scores[key] = value;
        }
      });
    }
    return scores;
  }

  // Get significant events from current trip
  List<DrivingEvent> _getCurrentSignificantEvents() {
    // Get critical and high severity events, max 5
    return _currentTripEvents
        .where((e) => e.severity == EventSeverity.critical || e.severity == EventSeverity.high)
        .take(5)
        .toList();
  }

  // Generate improvement suggestions based on trip data
  Map<String, dynamic> _generateImprovementSuggestions() {
    if (_currentTrip?.scoreBreakdown == null) return {};

    Map<String, dynamic> suggestions = {};
    Map<String, dynamic> scoreBreakdown = _currentTrip!.scoreBreakdown as Map<String, dynamic>;
    Map<String, dynamic> eventCounts = scoreBreakdown['eventCounts'] as Map<String, dynamic>;

    // Check for areas that need improvement
    if (eventCounts['acceleration'] > 0) {
      suggestions['acceleration'] = 'Try to accelerate more smoothly to improve fuel efficiency and reduce wear on your vehicle.';
    }

    if (eventCounts['braking'] > 0) {
      suggestions['braking'] = 'Anticipate stops earlier and brake gradually to improve safety and comfort.';
    }

    if (eventCounts['turning'] > 0) {
      suggestions['turning'] = 'Take corners at a slower speed to improve stability and passenger comfort.';
    }

    if (eventCounts['speeding'] > 0) {
      suggestions['speeding'] = 'Adhering to speed limits improves safety and can save fuel.';
    }

    return suggestions;
  }

  // Provide real-time feedback for events
  void _provideFeedback(DrivingEvent event) {
    String message = '';
    bool useHaptic = false;
    bool useVoice = false;

    switch (event.type) {
      case EventType.harshAcceleration:
        message = 'Harsh acceleration detected';
        useHaptic = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        useVoice = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        break;
      case EventType.hardBraking:
        message = 'Hard braking detected';
        useHaptic = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        useVoice = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        break;
      case EventType.sharpTurn:
        message = 'Sharp turn detected';
        useHaptic = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        useVoice = event.severity == EventSeverity.high || event.severity == EventSeverity.critical;
        break;
      case EventType.speeding:
        message = 'Speeding detected';
        useHaptic = true;
        useVoice = true;
        break;
      default:
        return;
    }

    // Provide feedback
    if (useHaptic) {
      _feedbackService.provideHapticFeedback(
          intensity: event.severity == EventSeverity.critical
              ? HapticIntensity.heavy
              : HapticIntensity.medium
      );
    }

    if (useVoice) {
      _feedbackService.speakMessage(message);
    }

    // Show notification for all events
    _feedbackService.showNotification(
      title: event.getEventTypeDisplay(),
      message: message,
      severity: event.severity,
    );
  }

  // Provide trip summary feedback
  void _provideTripSummaryFeedback(DrivingTrip trip) {
    if (trip.overallScore == null) return;

    String message = 'Trip completed. ';

    if (trip.overallScore! >= 90) {
      message += 'Excellent driving! Your score: ${trip.overallScore!.toStringAsFixed(1)}';
    } else if (trip.overallScore! >= 80) {
      message += 'Good driving. Your score: ${trip.overallScore!.toStringAsFixed(1)}';
    } else if (trip.overallScore! >= 70) {
      message += 'Average driving. Your score: ${trip.overallScore!.toStringAsFixed(1)}';
    } else {
      message += 'Your driving needs improvement. Score: ${trip.overallScore!.toStringAsFixed(1)}';
    }

    // Speak summary
    _feedbackService.speakMessage(message);

    // Show notification
    _feedbackService.showNotification(
      title: 'Trip Summary',
      message: message,
      severity: _getTripSeverity(trip.overallScore!),
    );
  }

  // Get severity level based on trip score
  EventSeverity _getTripSeverity(double score) {
    if (score >= 90) return EventSeverity.low;
    if (score >= 80) return EventSeverity.low;
    if (score >= 70) return EventSeverity.medium;
    if (score >= 60) return EventSeverity.high;
    return EventSeverity.critical;
  }

  // Dispose resources
  void dispose() {
    stopMonitoring();
    _sensorService.dispose();
    _feedbackService.dispose();
  }
}

