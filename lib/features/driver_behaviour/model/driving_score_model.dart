import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'driving_event_model.dart';

class DriverScore {
  final String id;
  final String userId;
  final double overallScore; // 0-100
  final Map<String, double> categoryScores; // Individual scores by category
  final int tripsCount;
  final int totalEvents;
  final double totalDistance; // in kilometers
  final double totalDuration; // in hours
  final DateTime lastUpdated;
  final List<DrivingEvent> recentEvents; // Recent significant events
  final Map<String, dynamic>? improvementSuggestions;

  DriverScore({
    required this.id,
    required this.userId,
    required this.overallScore,
    required this.categoryScores,
    required this.tripsCount,
    required this.totalEvents,
    required this.totalDistance,
    required this.totalDuration,
    required this.lastUpdated,
    required this.recentEvents,
    this.improvementSuggestions,
  });

  // Get score for specific category
  double getCategoryScore(String category) {
    return categoryScores[category] ?? 0.0;
  }

  // Get description of overall score
  String getScoreDescription() {
    if (overallScore >= 90) {
      return 'Excellent Driver';
    } else if (overallScore >= 80) {
      return 'Good Driver';
    } else if (overallScore >= 70) {
      return 'Average Driver';
    } else if (overallScore >= 60) {
      return 'Below Average Driver';
    } else {
      return 'Needs Improvement';
    }
  }

  // Get color representing the score
  Color getScoreColor() {
    if (overallScore >= 90) {
      return Colors.green;
    } else if (overallScore >= 80) {
      return Colors.lightGreen;
    } else if (overallScore >= 70) {
      return Colors.amber;
    } else if (overallScore >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  factory DriverScore.fromJson(Map<String, dynamic> json) {
    List<DrivingEvent> eventsList = [];
    if (json['recentEvents'] != null) {
      (json['recentEvents'] as List).forEach((eventJson) {
        eventsList.add(DrivingEvent.fromJson(eventJson));
      });
    }

    Map<String, double> categoryScoresMap = {};
    if (json['categoryScores'] != null) {
      (json['categoryScores'] as Map<String, dynamic>).forEach((key, value) {
        categoryScoresMap[key] = value.toDouble();
      });
    }

    return DriverScore(
      id: json['id'],
      userId: json['userId'],
      overallScore: json['overallScore'],
      categoryScores: categoryScoresMap,
      tripsCount: json['tripsCount'],
      totalEvents: json['totalEvents'],
      totalDistance: json['totalDistance'],
      totalDuration: json['totalDuration'],
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      recentEvents: eventsList,
      improvementSuggestions: json['improvementSuggestions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'overallScore': overallScore,
      'categoryScores': categoryScores,
      'tripsCount': tripsCount,
      'totalEvents': totalEvents,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'lastUpdated': lastUpdated,
      'recentEvents': recentEvents.map((event) => event.toJson()).toList(),
      'improvementSuggestions': improvementSuggestions,
    };
  }
}

