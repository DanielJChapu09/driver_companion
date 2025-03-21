class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? category; // home, work, favorite, etc.
  final String? notes;
  final DateTime? lastVisited;
  final int visitCount;
  final bool isFavorite;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
    this.notes,
    this.lastVisited,
    this.visitCount = 0,
    this.isFavorite = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      category: json['category'],
      notes: json['notes'],
      lastVisited: json['lastVisited'] != null
          ? DateTime.parse(json['lastVisited'])
          : null,
      visitCount: json['visitCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
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
      'notes': notes,
      'lastVisited': lastVisited?.toIso8601String(),
      'visitCount': visitCount,
      'isFavorite': isFavorite,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? notes,
    DateTime? lastVisited,
    int? visitCount,
    bool? isFavorite,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      lastVisited: lastVisited ?? this.lastVisited,
      visitCount: visitCount ?? this.visitCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

