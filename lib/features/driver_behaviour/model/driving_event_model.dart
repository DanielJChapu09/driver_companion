import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum EventSeverity {
  low,
  medium,
  high,
  critical
}

enum EventType {
  harshAcceleration,
  hardBraking,
  sharpTurn,
  speeding,
  phoneUsage,
  drowsiness,
  inconsistentLanePosition,
  smoothDriving, // Positive event
  ecoFriendlyDriving, // Positive event
}

class DrivingEvent {
  final String id;
  final EventType type;
  final EventSeverity severity;
  final double latitude;
  final double longitude;
  final double value; // Measured value (e.g., acceleration in m/s², speed in km/h)
  final double threshold; // Threshold that was exceeded
  final DateTime timestamp;
  final String? tripId;
  final Map<String, dynamic>? additionalData;

  DrivingEvent({
    String? id,
    required this.type,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.value,
    required this.threshold,
    DateTime? timestamp,
    this.tripId,
    this.additionalData,
  }) :
        this.id = id ?? Uuid().v4(),
        this.timestamp = timestamp ?? DateTime.now();

  bool get isPositive =>
      type == EventType.smoothDriving ||
          type == EventType.ecoFriendlyDriving;

  factory DrivingEvent.fromJson(Map<String, dynamic> json) {
    return DrivingEvent(
      id: json['id'],
      type: EventType.values.byName(json['type']),
      severity: EventSeverity.values.byName(json['severity']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      value: json['value'],
      threshold: json['threshold'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      tripId: json['tripId'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'latitude': latitude,
      'longitude': longitude,
      'value': value,
      'threshold': threshold,
      'timestamp': timestamp,
      'tripId': tripId,
      'additionalData': additionalData,
    };
  }

  String getEventTypeDisplay() {
    switch (type) {
      case EventType.harshAcceleration:
        return 'Harsh Acceleration';
      case EventType.hardBraking:
        return 'Hard Braking';
      case EventType.sharpTurn:
        return 'Sharp Turn';
      case EventType.speeding:
        return 'Speeding';
      case EventType.phoneUsage:
        return 'Phone Usage';
      case EventType.drowsiness:
        return 'Drowsiness Detected';
      case EventType.inconsistentLanePosition:
        return 'Inconsistent Lane Position';
      case EventType.smoothDriving:
        return 'Smooth Driving';
      case EventType.ecoFriendlyDriving:
        return 'Eco-Friendly Driving';
      default:
        return 'Unknown Event';
    }
  }

  String getSeverityDisplay() {
    switch (severity) {
      case EventSeverity.low:
        return 'Low';
      case EventSeverity.medium:
        return 'Medium';
      case EventSeverity.high:
        return 'High';
      case EventSeverity.critical:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  Color getSeverityColor() {
    switch (severity) {
      case EventSeverity.low:
        return Colors.blue;
      case EventSeverity.medium:
        return Colors.orange;
      case EventSeverity.high:
        return Colors.deepOrange;
      case EventSeverity.critical:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getEventIcon() {
    switch (type) {
      case EventType.harshAcceleration:
        return Icons.speed;
      case EventType.hardBraking:
        return Icons.stop_circle;
      case EventType.sharpTurn:
        return Icons.turn_right;
      case EventType.speeding:
        return Icons.speed_outlined;
      case EventType.phoneUsage:
        return Icons.phone_android;
      case EventType.drowsiness:
        return Icons.bedtime;
      case EventType.inconsistentLanePosition:
        return Icons.agriculture;
      case EventType.smoothDriving:
        return Icons.thumb_up;
      case EventType.ecoFriendlyDriving:
        return Icons.eco;
      default:
        return Icons.error;
    }
  }
}

