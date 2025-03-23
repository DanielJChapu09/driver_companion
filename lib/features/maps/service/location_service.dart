// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
//
// class LocationService extends GetxService {
//   final RxBool _isTracking = false.obs;
//   final Rx<Position?> _currentPosition = Rx<Position?>(null);
//
//   bool get isTracking => _isTracking.value;
//   Position? get currentPosition => _currentPosition.value;
//
//   Future<LocationService> init() async {
//     await _checkPermission();
//     return this;
//   }
//
//   Future<void> _checkPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//     }
//   }
//
//   Future<void> startTracking() async {
//     _isTracking.value = true;
//     Geolocator.getPositionStream(
//       locationSettings: LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10,
//       ),
//     ).listen((Position position) {
//       _currentPosition.value = position;
//     });
//   }
//
//   void stopTracking() {
//     _isTracking.value = false;
//   }
//
//   Future<Position> getCurrentLocation() async {
//     return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//   }
//
//   double getDistanceTo(Position location) {
//     if (_currentPosition.value == null) return double.infinity;
//
//     return Geolocator.distanceBetween(
//       _currentPosition.value!.latitude,
//       _currentPosition.value!.longitude,
//       location.latitude,
//       location.longitude,
//     );
//   }
//
//   mb.Point getCurrentPoint() {
//     if (_currentPosition.value == null) {
//       throw Exception('Current position is not available');
//     }
//     return mb.Point(
//       coordinates: mb.Position(
//         _currentPosition.value!.longitude,
//         _currentPosition.value!.latitude,
//       ),
//     );
//   }
// }
//
