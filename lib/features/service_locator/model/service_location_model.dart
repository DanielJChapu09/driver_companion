import 'package:flutter/foundation.dart';

/// Model class representing a service location
class ServiceLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final bool isOpen;
  final Map<String, dynamic>? properties;
  final double? distance;
  final double? duration;
  final List<String> amenities;
  final bool isFavorite;

  ServiceLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.phoneNumber,
    this.website,
    this.rating,
    this.isOpen = true,
    this.properties,
    this.distance,
    this.duration,
    this.amenities = const [],
    this.isFavorite = false,
  });

  /// Create a copy of this ServiceLocation with the given fields replaced with the new values
  ServiceLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? phoneNumber,
    String? website,
    double? rating,
    bool? isOpen,
    Map<String, dynamic>? properties,
    double? distance,
    double? duration,
    List<String>? amenities,
    bool? isFavorite,
  }) {
    return ServiceLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      properties: properties ?? this.properties,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      amenities: amenities ?? this.amenities,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Convert ServiceLocation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'phoneNumber': phoneNumber,
      'website': website,
      'rating': rating,
      'isOpen': isOpen,
      'properties': properties,
      'distance': distance,
      'duration': duration,
      'amenities': amenities,
      'isFavorite': isFavorite,
    };
  }

  /// Create ServiceLocation from JSON
  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      category: json['category'] ?? 'other',
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      rating: json['rating']?.toDouble(),
      isOpen: json['isOpen'] ?? true,
      properties: json['properties'],
      distance: json['distance']?.toDouble(),
      duration: json['duration']?.toDouble(),
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : [],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceLocation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
