import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import './driving_event_model.dart';

class DrivingTrip {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startLatitude;
  final double startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String startAddress;
  final String? endAddress;
  final double distanceTraveled; // in kilometers
  final double duration; // in minutes
  final List<DrivingEvent> events;
  final double? overallScore; // 0-100 score
  final Map<String, dynamic>? scoreBreakdown;
  final String? userId;
  final String? vehicleId;
  final bool isNavigationTrip; // Whether the trip used navigation
  final String? routeId; // If navigation was used, reference to the route
  final bool isCompleted;

  DrivingTrip({
    String? id,
    required this.startTime,
    this.endTime,
    required this.startLatitude,
    required this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    required this.startAddress,
    this.endAddress,
    required this.distanceTraveled,
    required this.duration,
    required this.events,
    this.overallScore,
    this.scoreBreakdown,
    this.userId,
    this.vehicleId,
    required this.isNavigationTrip,
    this.routeId,
    required this.isCompleted,
  }) : this.id = id ?? Uuid().v4();

  // Total number of events by severity
  int countEventsBySeverity(EventSeverity severity) {
    return events.where((event) => event.severity == severity).length;
  }

  // Total number of events by type
  int countEventsByType(EventType type) {
    return events.where((event) => event.type == type).length;
  }

  // Calculate number of events per hour
  double get eventsPerHour {
    if (duration <= 0) return 0;
    return (events.length / (duration / 60)).toDouble();
  }

  // Calculate number of events per kilometer
  double get eventsPerKilometer {
    if (distanceTraveled <= 0) return 0;
    return (events.length / distanceTraveled).toDouble();
  }

  // Get total number of events
  int get eventsCount {
    return events.length;
  }

  factory DrivingTrip.fromJson(Map<String, dynamic> json) {
    List<DrivingEvent> eventsList = [];
    if (json['events'] != null) {
      (json['events'] as List).forEach((eventJson) {
        eventsList.add(DrivingEvent.fromJson(eventJson));
      });
    }

    return DrivingTrip(
      id: json['id'],
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null ? (json['endTime'] as Timestamp).toDate() : null,
      startLatitude: json['startLatitude'],
      startLongitude: json['startLongitude'],
      endLatitude: json['endLatitude'],
      endLongitude: json['endLongitude'],
      startAddress: json['startAddress'],
      endAddress: json['endAddress'],
      distanceTraveled: json['distanceTraveled'],
      duration: json['duration'],
      events: eventsList,
      overallScore: json['overallScore'],
      scoreBreakdown: json['scoreBreakdown'],
      userId: json['userId'],
      vehicleId: json['vehicleId'],
      isNavigationTrip: json['isNavigationTrip'],
      routeId: json['routeId'],
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'startAddress': startAddress,
      'endAddress': endAddress,
      'distanceTraveled': distanceTraveled,
      'duration': duration,
      'events': events.map((event) => event.toJson()).toList(),
      'overallScore': overallScore,
      'scoreBreakdown': scoreBreakdown,
      'userId': userId,
      'vehicleId': vehicleId,
      'isNavigationTrip': isNavigationTrip,
      'routeId': routeId,
      'isCompleted': isCompleted,
    };
  }
}
