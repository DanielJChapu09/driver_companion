// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:geolocator/geolocator.dart' as gl;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
// import '../../../core/utils/logs.dart';
// import '../service/mapbox_service.dart';
//
// class MapController extends GetxController {
//   final MapboxService _mapboxService = MapboxService();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   RxList<gl.Position> locations = <gl.Position>[].obs;
//   Rx<gl.Position?> routeStart = Rx<gl.Position?>(null);
//   Rx<gl.Position?> routeEnd = Rx<gl.Position?>(null);
//   RxList<String> activeFilters = <String>[].obs;
//
//   mp.MapboxMap? mapboxMapController;
//   StreamSubscription<gl.Position>? userPositionStream;
//   final Rx<gl.Position?> selectedLocation = Rx<gl.Position?>(null);
//   final RxBool isLoading = false.obs;
//   final RxBool isRoutingMode = false.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//
//   }
//
//   Future<void> setupPositionTracking() async {
//     bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       throw 'Location services are disabled.';
//     }
//
//     gl.LocationPermission permission = await gl.Geolocator.checkPermission();
//     if (permission == gl.LocationPermission.denied) {
//       permission = await gl.Geolocator.requestPermission();
//       if (permission == gl.LocationPermission.denied) {
//         throw 'Location permissions are denied.';
//       }
//     }
//
//     if (permission == gl.LocationPermission.deniedForever) {
//       throw 'Location permissions are permanently denied.';
//     }
//
//     gl.LocationSettings locationSettings = gl.LocationSettings(
//       accuracy: gl.LocationAccuracy.bestForNavigation,
//       distanceFilter: 10, // Update location every 10 meters
//     );
//
//     userPositionStream?.cancel();
//     userPositionStream = gl.Geolocator.getPositionStream(locationSettings: locationSettings).listen((position) {
//       if (position != null) {
//         updateMapCamera(position);
//       }
//     });
//   }
//
//   void updateMapCamera(gl.Position position) {
//     mapboxMapController?.setCamera(
//       mp.CameraOptions(
//         center: mp.Point(
//           coordinates: mp.Position(
//             position.longitude,
//             position.latitude,
//           ),
//         ),
//         zoom: 14.0,
//       ),
//     );
//   }
//
//
//   void initializeMap(mp.MapboxMap mapboxMap) {
//     mapboxMapController = mapboxMap;
//     _mapboxService.initializeMap(mapboxMap); // Initialize the map in the service
//     mapboxMapController?.location.updateSettings(
//       mp.LocationComponentSettings(
//         enabled: true,
//         showAccuracyRing: true,
//         pulsingEnabled: true,
//       ),
//     );
//   }
//
//
//   Future<void> _fitMapToCampus() async {
//     if (locations.isNotEmpty) {
//       await _mapboxService.fitBounds(locations);
//     }
//   }
//
//   Future<void> selectLocation(gl.Position location) async {
//     if (isRoutingMode.value) {
//       if (routeStart.value == null) {
//         routeStart.value = location;
//         Get.snackbar('Starting Point', 'Selected ${location.speed} as the starting point');
//       } else {
//         routeEnd.value = location;
//         Get.snackbar('Destination', 'Selected ${location.speed} as the destination');
//         await _showRoute();
//       }
//     } else {
//       selectedLocation.value = location;
//       await _mapboxService.mapboxMap.setCamera(
//         mp.CameraOptions(
//           center: mp.Point(coordinates: mp.Position(location.longitude, location.latitude)),
//           zoom: 16.0,
//         ),
//       );
//     }
//   }
//
//   Future<void> getCurrentLocation() async {
//     try {
//       bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         Get.snackbar('Error', 'Location services are disabled.');
//         return;
//       }
//
//       gl.LocationPermission permission = await gl.Geolocator.checkPermission();
//       if (permission == gl.LocationPermission.denied) {
//         permission = await gl.Geolocator.requestPermission();
//         if (permission == gl.LocationPermission.denied) {
//           Get.snackbar('Error', 'Location permissions are denied');
//           return;
//         }
//       }
//
//       if (permission == gl.LocationPermission.deniedForever) {
//         Get.snackbar('Error', 'Location permissions are permanently denied');
//         return;
//       }
//
//       gl.Position position = await gl.Geolocator.getCurrentPosition();
//       await _mapboxService.mapboxMap.setCamera(
//         mp.CameraOptions(
//           center: mp.Point(coordinates: mp.Position(position.longitude, position.latitude)),
//           zoom: 16.0,
//         ),
//       );
//     } catch (e) {
//       DevLogs.logError('Error getting current location: $e');
//       Get.snackbar('Error', 'Failed to get current location');
//     }
//   }
//
//   Future<void> _showRoute() async {
//     if (routeStart.value != null && routeEnd.value != null) {
//       try {
//         List<mp.Point> routeCoordinates = await _mapboxService.getRoute(
//             routeStart.value!,
//             routeEnd.value!
//         );
//         await _mapboxService.addRoute(routeCoordinates);
//         await _mapboxService.fitBounds([routeStart.value!, routeEnd.value!]);
//       } catch (e) {
//         DevLogs.logError('Error showing route: $e');
//         Get.snackbar('Error', 'Unable to find a route between the selected locations.');
//       }
//     }
//   }
//
//   void toggleRoutingMode() {
//     isRoutingMode.value = !isRoutingMode.value;
//     if (!isRoutingMode.value) {
//       _clearRoute();
//       Get.snackbar('Navigation Off', 'Routing mode disabled');
//     } else {
//       Get.snackbar('Navigation On', 'Select a starting point and a destination');
//     }
//   }
//
//   void _clearRoute() {
//     routeStart.value = null;
//     routeEnd.value = null;
//     _mapboxService.removeRoute();
//   }
//
//
//   void toggleFilter(String filter) {
//     if (activeFilters.contains(filter)) {
//       activeFilters.remove(filter);
//     } else {
//       activeFilters.add(filter);
//     }
//     _applyFilters();
//   }
//
//   void _applyFilters() {
//     // This is a placeholder - you'll need to implement the actual filtering
//     // based on your annotation manager implementation
//     DevLogs.logInfo('Applying filters: ${activeFilters.join(", ")}');
//   }
//
//   Future<void> startNavigation(gl.Position destination) async {
//     isRoutingMode.value = true;
//
//     try {
//       gl.Position position = await gl.Geolocator.getCurrentPosition();
//
//       // Create a temporary "current location" campus location
//       gl.Position currentLocation = position;
//
//       routeStart.value = currentLocation;
//       routeEnd.value = destination;
//
//       await _showRoute();
//       Get.snackbar('Navigation Started', 'Navigating to ${destination.speed}');
//     } catch (e) {
//       DevLogs.logError('Error starting navigation: $e');
//       Get.snackbar('Error', 'Failed to start navigation');
//     }
//   }
//
//
// }