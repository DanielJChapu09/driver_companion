import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../model/user_location_model.dart';

class LocationService {
  // Get current position with permission handling
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }

  // Get address details from coordinates
  Future<UserLocation> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return UserLocation(
          latitude: latitude,
          longitude: longitude,
          city: place.locality ?? 'Unknown',
          country: place.country ?? 'Unknown',
          address: '${place.street}, ${place.locality}, ${place.country}',
        );
      } else {
        return UserLocation(
          latitude: latitude,
          longitude: longitude,
          city: 'Unknown',
          country: 'Unknown',
          address: 'Unknown location',
        );
      }
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  // Get current location with address details
  Future<UserLocation> getCurrentLocation() async {
    try {
      Position position = await getCurrentPosition();
      return await getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Calculate distance between two coordinates in kilometers
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude
    ) / 1000; // Convert meters to kilometers
  }
}

