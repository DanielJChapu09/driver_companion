import 'package:uuid/uuid.dart';

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
  final int? reviewCount;
  final bool isOpen;
  final Map<String, dynamic> properties;
  final double? distance; // Distance from current location in km
  final double? duration; // Estimated time to reach in minutes
  final List<String> amenities;
  final List<String> paymentMethods;
  final String? priceLevel;
  final Map<String, dynamic>? hours;

  ServiceLocation({
    String? id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.phoneNumber,
    this.website,
    this.rating,
    this.reviewCount,
    this.isOpen = true,
    this.properties = const {},
    this.distance,
    this.duration,
    this.amenities = const [],
    this.paymentMethods = const [],
    this.priceLevel,
    this.hours,
  }) : id = id ?? const Uuid().v4();

  factory ServiceLocation.fromJson(Map<String, dynamic> json) {
    return ServiceLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      category: json['category'],
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      rating: json['rating'],
      reviewCount: json['reviewCount'],
      isOpen: json['isOpen'] ?? true,
      properties: json['properties'] ?? {},
      distance: json['distance'],
      duration: json['duration'],
      amenities: List<String>.from(json['amenities'] ?? []),
      paymentMethods: List<String>.from(json['paymentMethods'] ?? []),
      priceLevel: json['priceLevel'],
      hours: json['hours'],
    );
  }

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
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'properties': properties,
      'distance': distance,
      'duration': duration,
      'amenities': amenities,
      'paymentMethods': paymentMethods,
      'priceLevel': priceLevel,
      'hours': hours,
    };
  }

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
    int? reviewCount,
    bool? isOpen,
    Map<String, dynamic>? properties,
    double? distance,
    double? duration,
    List<String>? amenities,
    List<String>? paymentMethods,
    String? priceLevel,
    Map<String, dynamic>? hours,
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
      reviewCount: reviewCount ?? this.reviewCount,
      isOpen: isOpen ?? this.isOpen,
      properties: properties ?? this.properties,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      amenities: amenities ?? this.amenities,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      priceLevel: priceLevel ?? this.priceLevel,
      hours: hours ?? this.hours,
    );
  }
}

