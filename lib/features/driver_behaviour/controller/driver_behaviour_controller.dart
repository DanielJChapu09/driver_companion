import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:mymaptest/core/utils/logs.dart';

import '../model/driving_event_model.dart';
import '../model/driving_score_model.dart';
import '../model/trip_model.dart';
import '../service/driver_behaviour_service.dart';
import '../service/feedback_service.dart';

class DriverBehaviorController extends GetxController {
  final DriverBehaviorService _behaviorService = DriverBehaviorService();
  final FeedbackService _feedbackService = FeedbackService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  final RxBool isMonitoring = false.obs;
  final RxBool isInitialized = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;

  // Driver data
  final Rx<DriverScore?> driverScore = Rx<DriverScore?>(null);
  final RxList<DrivingTrip> recentTrips = <DrivingTrip>[].obs;
  final RxList<DrivingEvent> recentEvents = <DrivingEvent>[].obs;

  // Feedback settings
  final RxBool voiceFeedbackEnabled = true.obs;
  final RxBool hapticFeedbackEnabled = true.obs;
  final RxBool notificationFeedbackEnabled = true.obs;

  // Current user
  String? _userId;

  @override
  void onInit() {
    super.onInit();
    // Set default user ID (in a real app, this would come from authentication)
    _userId = 'default_user';
    _initializeServices();
  }

  // Initialize services
  Future<void> _initializeServices() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Initialize feedback service first
      await _feedbackService.initialize();

      // Initialize behavior service
      bool initialized = await _behaviorService.initialize(userId: _userId!);
      if (!initialized) {
        errorMessage.value = 'Failed to initialize driver behavior services';
        isInitialized.value = false;
      } else {
        isInitialized.value = true;

        // Load driver data
        await _loadDriverData();
      }
    } catch (e) {
      errorMessage.value = 'Error initializing: $e';
      DevLogs.logError('Error initializing driver behavior controller: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Start monitoring
  Future<void> startMonitoring({bool isNavigationMode = false, String? routeId}) async {
    if (!isInitialized.value) {
      errorMessage.value = 'Services not initialized';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      bool started = await _behaviorService.startMonitoring(
        isNavigationMode: isNavigationMode,
        routeId: routeId,
      );

      if (started) {
        isMonitoring.value = true;

        if (isNavigationMode) {
          _feedbackService.speakMessage('Driver behavior monitoring active during navigation');
        } else {
          _feedbackService.speakMessage('Driver behavior monitoring started');
        }
      } else {
        errorMessage.value = 'Failed to start monitoring';
      }
    } catch (e) {
      errorMessage.value = 'Error starting monitoring: $e';
      DevLogs.logError('Error starting monitoring: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    if (!isMonitoring.value) return;

    isLoading.value = true;

    try {
      await _behaviorService.stopMonitoring();
      isMonitoring.value = false;

      // Reload driver data to show latest trip
      await _loadDriverData();

      _feedbackService.speakMessage('Driver behavior monitoring stopped');
    } catch (e) {
      errorMessage.value = 'Error stopping monitoring: $e';
      DevLogs.logError('Error stopping monitoring: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load driver data (score, recent trips, events)
  Future<void> _loadDriverData() async {
    if (_userId == null) return;

    isLoading.value = true;

    try {
      // Load driver score
      DocumentSnapshot scoreDoc = await _firestore
          .collection('driverScores')
          .doc(_userId)
          .get();

      if (scoreDoc.exists && scoreDoc.data() != null) {
        driverScore.value = DriverScore.fromJson(scoreDoc.data() as Map<String, dynamic>);
      } else {
        driverScore.value = null;
      }

      // Load recent trips
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('drivingTrips')
          .where('userId', isEqualTo: _userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('endTime', descending: true)
          .limit(10)
          .get();

      List<DrivingTrip> trips = [];
      for (var doc in tripsSnapshot.docs) {
        trips.add(DrivingTrip.fromJson(doc.data() as Map<String, dynamic>));
      }
      recentTrips.value = trips;

      // Load recent events only if there are trips
      if (trips.isNotEmpty) {
        QuerySnapshot eventsSnapshot = await _firestore
            .collection('drivingEvents')
            .where('tripId', whereIn: trips.map((t) => t.id).toList())
            .where('severity', whereIn: ['high', 'critical'])
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        List<DrivingEvent> events = [];
        for (var doc in eventsSnapshot.docs) {
          events.add(DrivingEvent.fromJson(doc.data() as Map<String, dynamic>));
        }
        recentEvents.value = events;
      } else {
        recentEvents.value = [];
      }

    } catch (e) {
      DevLogs.logError('Error loading driver data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Public methods for loading data
  Future<void> loadDriverScore() async {
    await _loadDriverData();
  }

  Future<void> loadRecentTrips() async {
    if (_userId == null) return;

    isLoading.value = true;

    try {
      // Load recent trips
      QuerySnapshot tripsSnapshot = await _firestore
          .collection('drivingTrips')
          .where('userId', isEqualTo: _userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('endTime', descending: true)
          .limit(10)
          .get();

      List<DrivingTrip> trips = [];
      for (var doc in tripsSnapshot.docs) {
        trips.add(DrivingTrip.fromJson(doc.data() as Map<String, dynamic>));
      }
      recentTrips.value = trips;
    } catch (e) {
      DevLogs.logError('Error loading recent trips: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRecentEvents() async {
    if (_userId == null || recentTrips.isEmpty) return;

    isLoading.value = true;

    try {
      QuerySnapshot eventsSnapshot = await _firestore
          .collection('drivingEvents')
          .where('tripId', whereIn: recentTrips.map((t) => t.id).toList())
          .where('severity', whereIn: ['high', 'critical'])
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      List<DrivingEvent> events = [];
      for (var doc in eventsSnapshot.docs) {
        events.add(DrivingEvent.fromJson(doc.data() as Map<String, dynamic>));
      }
      recentEvents.value = events;
    } catch (e) {
      DevLogs.logError('Error loading recent events: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Update feedback settings
  void updateFeedbackSettings({
    bool? voiceFeedback,
    bool? hapticFeedback,
    bool? notificationFeedback,
  }) {
    if (voiceFeedback != null) voiceFeedbackEnabled.value = voiceFeedback;
    if (hapticFeedback != null) hapticFeedbackEnabled.value = hapticFeedback;
    if (notificationFeedback != null) notificationFeedbackEnabled.value = notificationFeedback;

    // Update service settings
    _feedbackService.setFeedbackPreferences(
      voiceFeedback: voiceFeedbackEnabled.value,
      hapticFeedback: hapticFeedbackEnabled.value,
      notificationFeedback: notificationFeedbackEnabled.value,
    );
  }

  // Get trip details by ID
  Future<DrivingTrip?> getTripDetails(String tripId) async {
    isLoading.value = true;

    try {
      DocumentSnapshot tripDoc = await _firestore
          .collection('drivingTrips')
          .doc(tripId)
          .get();

      if (tripDoc.exists && tripDoc.data() != null) {
        return DrivingTrip.fromJson(tripDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      DevLogs.logError('Error getting trip details: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get events for a specific trip
  Future<List<DrivingEvent>> getTripEvents(String tripId) async {
    isLoading.value = true;

    try {
      QuerySnapshot eventsSnapshot = await _firestore
          .collection('drivingEvents')
          .where('tripId', isEqualTo: tripId)
          .orderBy('timestamp')
          .get();

      List<DrivingEvent> events = [];
      for (var doc in eventsSnapshot.docs) {
        events.add(DrivingEvent.fromJson(doc.data() as Map<String, dynamic>));
      }
      return events;
    } catch (e) {
      DevLogs.logError('Error getting trip events: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _behaviorService.dispose();
    super.onClose();
  }
}
