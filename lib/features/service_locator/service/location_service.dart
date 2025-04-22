import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/service_locator/service/service_locator_interface.dart';

/// Implementation of the location service interface
class LocationService implements ILocationService {
  /// Singleton instance
  static final LocationService _instance = LocationService._internal();

  /// Factory constructor
  factory LocationService() => _instance;

  /// Private constructor
  LocationService._internal();

  @override
  Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      bool permissionGranted = await requestLocationPermission();
      if (!permissionGranted) {
        throw Exception('Location permissions are denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      DevLogs.logError('Error getting current position: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  double calculateDistance(LatLng point1, LatLng point2) {
    return calculateDistanceCoordinates(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude
    );
  }

  @override
  double calculateDistanceCoordinates(
      double lat1, double lng1, double lat2, double lng2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
