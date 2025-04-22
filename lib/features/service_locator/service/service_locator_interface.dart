import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Interface for location services
abstract class ILocationService {
  /// Get the current position
  Future<Position> getCurrentPosition();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Request location permission
  Future<bool> requestLocationPermission();

  /// Calculate distance between two points in kilometers
  double calculateDistance(LatLng point1, LatLng point2);

  /// Calculate distance between two points in kilometers using coordinates
  double calculateDistanceCoordinates(
      double lat1, double lng1, double lat2, double lng2);

  /// Stream of position updates
  Stream<Position> getPositionStream();
}
