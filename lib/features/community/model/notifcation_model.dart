class RoadNotification {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final String city;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String type; // traffic, accident, police, hazard, etc.
  final int likeCount;
  final bool isActive;
  final List<String> images; // Optional images of the road condition

  RoadNotification({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.type,
    this.likeCount = 0,
    this.isActive = true,
    this.images = const [],
  });

  factory RoadNotification.fromJson(Map<String, dynamic> json) {
    return RoadNotification(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      message: json['message'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      likeCount: json['likeCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'likeCount': likeCount,
      'isActive': isActive,
      'images': images,
    };
  }

  RoadNotification copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    String? city,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? type,
    int? likeCount,
    bool? isActive,
    List<String>? images,
  }) {
    return RoadNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      likeCount: likeCount ?? this.likeCount,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
    );
  }
}

