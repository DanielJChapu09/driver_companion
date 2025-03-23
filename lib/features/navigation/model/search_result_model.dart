class SearchResult {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? category;
  final double? distance;
  final Map<String, dynamic>? properties;

  SearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
    this.distance,
    this.properties,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      category: json['category'],
      distance: json['distance']?.toDouble(),
      properties: json['properties'],
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
      'distance': distance,
      'properties': properties,
    };
  }
}

