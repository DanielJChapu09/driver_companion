class UserLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String address;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.address,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      city: json['city'],
      country: json['country'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'address': address,
    };
  }
}

