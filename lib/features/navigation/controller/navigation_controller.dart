import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/widgets/snackbar/custom_snackbar.dart';
import 'dart:async';
import '../model/place_model.dart';
import '../model/route_model.dart';
import '../model/search_result_model.dart';
import '../service/googlemaps_service.dart';
import '../service/navigation_service_interface.dart';
import '../service/navigation_service.dart';
import '../service/places_service.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

class NavigationController extends GetxController {
  final GoogleMapsService mapsService;
  final PlacesService _placesService = PlacesService();
  final INavigationService _navigationService = NavigationService();

  // Observable variables
  final Rx<Position?> currentLocation = Rx<Position?>(null);
  final RxList<SearchResult> searchResults = <SearchResult>[].obs;
  final RxList<Place> favoritePlaces = <Place>[].obs;
  final RxList<Place> recentPlaces = <Place>[].obs;
  final Rx<NavigationRoute?> currentRoute = Rx<NavigationRoute?>(null);
  final Rx<List<LatLng>> previewRoutePoints = Rx<List<LatLng>>([]);
  final RxList<NavigationRoute> alternativeRoutes = <NavigationRoute>[].obs;
  final RxBool isNavigating = false.obs;
  final RxBool isLoading = false.obs;
  final RxString currentInstruction = ''.obs;
  final RxInt currentStepIndex = 0.obs;
  final RxDouble remainingDistance = 0.0.obs;
  final RxDouble remainingDuration = 0.0.obs;
  final RxBool hasArrived = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxBool showTraffic = true.obs;
  final RxBool voiceGuidanceEnabled = true.obs;
  final RxList<String> selectedServiceTypes = <String>[].obs;
  final RxBool showAlternativeRoutes = false.obs;

  // Map controller
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);
  Rx<Set<Polyline>> polylines = Rx<Set<Polyline>>({});
  Rx<Set<Marker>> markers = Rx<Set<Marker>>({});

  NavigationController({required String googleMapsApiKey})
      : mapsService = GoogleMapsService(apiKey: googleMapsApiKey);

  @override
  void onInit() {
    super.onInit();
    initializeServices();
    loadSavedPlaces();

    // Listen to navigation service streams
    _navigationService.locationStream.listen((location) {
      currentLocation.value = location;
    });

    _navigationService.stepStream.listen((stepIndex) {
      currentStepIndex.value = stepIndex;
    });

    _navigationService.instructionStream.listen((instruction) {
      currentInstruction.value = instruction;

      // Simulate voice guidance
      if (voiceGuidanceEnabled.value) {
        // In a real app, this would use text-to-speech
        DevLogs.logInfo('Voice guidance: $instruction');
      }
    });

    _navigationService.distanceStream.listen((distance) {
      remainingDistance.value = distance;
    });

    _navigationService.durationStream.listen((duration) {
      remainingDuration.value = duration;
    });

    _navigationService.arrivalStream.listen((arrived) {
      hasArrived.value = arrived;
      if (arrived) {
        isNavigating.value = false;
        CustomSnackBar.showSuccessSnackbar(message: 'You have reached your destination');
      }
    });
  }

  @override
  void onClose() {
    _navigationService.dispose();
    super.onClose();
  }

  // Initialize services
  Future<void> initializeServices() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      bool initialized = await _navigationService.initialize();
      if (!initialized) {
        errorMessage.value = 'Failed to initialize location services';
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error initializing services: $e';
      DevLogs.logError('Error initializing services: $e');
    }
  }

  // Load saved places
  Future<void> loadSavedPlaces() async {
    try {
      List<Place> favorites = await _placesService.getFavoritePlaces();
      favoritePlaces.value = favorites;

      List<Place> recents = await _placesService.getRecentPlaces();
      recentPlaces.value = recents;
    } catch (e) {
      DevLogs.logError('Error loading saved places: $e');
    }
  }

  // Set map controller
  void setMapController(GoogleMapController controller) {
    mapController.value = controller;
  }

  // Search for places
  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    searchQuery.value = query;

    try {
      LatLng? proximity;
      if (currentLocation.value != null) {
        proximity = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude,
        );
      }

      List<SearchResult> results = await mapsService.searchPlaces(
        query,
        proximity: proximity,
      );

      searchResults.value = results;
      isSearching.value = false;
    } catch (e) {
      isSearching.value = false;
      DevLogs.logError('Error searching places: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to search places');
    }
  }

  // Get directions
  Future<void> getDirections(LatLng origin, LatLng destination) async {
    isLoading.value = true;

    try {
      // Get primary route
      NavigationRoute? route = await mapsService.getDirections(
        origin,
        destination,
      );

      if (route != null) {
        currentRoute.value = route;

        // Get alternative routes if requested
        if (showAlternativeRoutes.value) {
          NavigationRoute? alternativeRoute = await mapsService.getDirections(
            origin,
            destination,
            alternatives: true,
          );

          if (alternativeRoute != null) {
            alternativeRoutes.value = [alternativeRoute];
          } else {
            alternativeRoutes.clear();
          }
        }

        // Check if service types are selected
        if (selectedServiceTypes.isNotEmpty) {
          List<NavigationRoute> routesWithServices = await mapsService.getDirectionsWithServiceLocations(
            origin,
            destination,
            selectedServiceTypes,
          );

          // The first route is the direct route, which we already have
          if (routesWithServices.length > 1) {
            alternativeRoutes.value = routesWithServices.sublist(1);
          }
        }

        // Draw route on map
        if (mapController.value != null) {
          _drawRouteOnMap(route);
        }
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Could not find a route to the destination');
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error getting directions: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to get directions');
    }
  }

  // Get optimized route with multiple waypoints
  Future<void> getOptimizedRoute(LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    isLoading.value = true;

    try {
      NavigationRoute? route = await mapsService.getOptimizedRoute(
        origin,
        destination,
        waypoints,
      );

      if (route != null) {
        currentRoute.value = route;

        // Draw route on map
        if (mapController.value != null) {
          _drawRouteOnMap(route);
        }
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Could not find an optimized route');
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error getting optimized route: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to get optimized route');
    }
  }

  Future<void> getRoutePreview(LatLng origin, LatLng destination) async {
    isLoading.value = true;

    try {
      // Get primary route
      List<LatLng>? route = await mapsService.getPreviewRoute(
          wayPoints: [
            origin,
            destination,
          ]
      );

      if (route.isNotEmpty) {
        previewRoutePoints.value = route;
      } else {
        CustomSnackBar.showErrorSnackbar(
          message: 'Could not find a route to the destination',
        );
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error getting directions: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to get directions');
    }
  }

  // Update map camera with location
  void updateMapCameraWithLocation() {
    if (mapController.value != null && currentLocation.value != null && isNavigating.value) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            currentLocation.value!.latitude,
            currentLocation.value!.longitude,
          ),
          16.0,
        ),
      );
    }
  }

  // Start navigation
  Future<void> startNavigation() async {
    if (currentRoute.value == null) return;

    try {
      bool started = await _navigationService.startNavigation(currentRoute.value!);

      if (started) {
        isNavigating.value = true;

        // Set up periodic camera updates
        Timer.periodic(Duration(seconds: 2), (timer) {
          if (!isNavigating.value) {
            timer.cancel();
            return;
          }
          updateMapCameraWithLocation();
        });

        // Add destination to recent places
        if (currentRoute.value != null) {
          addToRecentPlaces(
            currentRoute.value!.endLatitude,
            currentRoute.value!.endLongitude,
            currentRoute.value!.endAddress,
          );
        }
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Failed to start navigation');
      }
    } catch (e) {
      DevLogs.logError('Error starting navigation: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to start navigation');
    }
  }

  // Stop navigation
  Future<void> stopNavigation() async {
    await _navigationService.stopNavigation();
    isNavigating.value = false;
    currentInstruction.value = '';
    currentStepIndex.value = 0;
    remainingDistance.value = 0.0;
    remainingDuration.value = 0.0;
    hasArrived.value = false;
  }

  // Add place to favorites
  Future<void> addToFavorites(double latitude, double longitude, String name, String address, {String? category}) async {
    try {
      Place place = Place(
        id: '',
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category,
        isFavorite: true,
      );

      bool added = await _placesService.addFavoritePlace(place);

      if (added) {
        await loadSavedPlaces();
        CustomSnackBar.showSuccessSnackbar(message: 'Place added to favorites');
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Failed to add place to favorites');
      }
    } catch (e) {
      DevLogs.logError('Error adding to favorites: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to add place to favorites');
    }
  }

  // Remove place from favorites
  Future<void> removeFromFavorites(String placeId) async {
    try {
      bool removed = await _placesService.removeFavoritePlace(placeId);

      if (removed) {
        await loadSavedPlaces();
        CustomSnackBar.showSuccessSnackbar(message: 'Place removed from favorites');
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Failed to remove place from favorites');
      }
    } catch (e) {
      DevLogs.logError('Error removing from favorites: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to remove place from favorites');
    }
  }

  // Add to recent places
  Future<void> addToRecentPlaces(double latitude, double longitude, String address) async {
    try {
      // Get place name from address
      String name = address.split(',').first;

      Place place = Place(
        id: '',
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      await _placesService.addRecentPlace(place);
      await loadSavedPlaces();
    } catch (e) {
      DevLogs.logError('Error adding to recent places: $e');
    }
  }

  // Clear recent places
  Future<void> clearRecentPlaces() async {
    try {
      bool cleared = await _placesService.clearRecentPlaces();

      if (cleared) {
        recentPlaces.clear();
        CustomSnackBar.showSuccessSnackbar(message: 'Recent places cleared');
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Failed to clear recent places');
      }
    } catch (e) {
      DevLogs.logError('Error clearing recent places: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to clear recent places');
    }
  }

  // Update place
  Future<void> updatePlace(Place place) async {
    try {
      bool updated = await _placesService.updatePlace(place);

      if (updated) {
        await loadSavedPlaces();
        CustomSnackBar.showSuccessSnackbar(message: 'Place updated');
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Failed to update place');
      }
    } catch (e) {
      DevLogs.logError('Error updating place: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to update place');
    }
  }

  // Draw route on map
  void _drawRouteOnMap(NavigationRoute route) {
    if (mapController.value == null) return;

    // Decode polyline
    List<LatLng> points = mapsService.decodePolyline(route.geometry);

    // Create a set to hold the new polylines
    Set<Polyline> newPolylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
      ),
    };

    // Add alternative routes if available
    for (int i = 0; i < alternativeRoutes.length; i++) {
      var altRoute = alternativeRoutes[i];
      List<LatLng> altPoints = mapsService.decodePolyline(altRoute.geometry);

      newPolylines.add(
        Polyline(
          polylineId: PolylineId('alt_route_$i'),
          points: altPoints,
          color: Colors.grey,
          width: 3,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      );
    }

    // Update the polylines
    polylines.value = newPolylines;

    // Create a set to hold the new markers
    Set<Marker> newMarkers = {
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(route.startLatitude, route.startLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(route.endLatitude, route.endLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Update the markers
    markers.value = newMarkers;

    // Fit bounds to show the entire route
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce(min),
        points.map((p) => p.longitude).reduce(min),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce(max),
        points.map((p) => p.longitude).reduce(max),
      ),
    );

    mapController.value!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        50.0, // padding
      ),
    );
  }

  // Decode polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Get place categories
  List<Map<String, dynamic>> getPlaceCategories() {
    return _placesService.getPlaceCategories();
  }

  // Get service types
  List<Map<String, String>> getServiceTypes() {
    return [
      {'id': 'gas_station', 'name': 'Gas Station'},
      {'id': 'restaurant', 'name': 'Restaurant'},
      {'id': 'hotel', 'name': 'Hotel'},
      {'id': 'parking', 'name': 'Parking'},
      {'id': 'car_wash', 'name': 'Car Wash'},
      {'id': 'mechanic', 'name': 'Mechanic'},
      {'id': 'ev_charging', 'name': 'EV Charging'},
      {'id': 'hospital', 'name': 'Hospital'},
      {'id': 'police', 'name': 'Police Station'},
    ];
  }

  // Toggle service type selection
  void toggleServiceType(String serviceType) {
    if (selectedServiceTypes.contains(serviceType)) {
      selectedServiceTypes.remove(serviceType);
    } else {
      selectedServiceTypes.add(serviceType);
    }
  }

  // Toggle alternative routes display
  void toggleAlternativeRoutes() {
    showAlternativeRoutes.value = !showAlternativeRoutes.value;
  }

  // Simulate navigation (for testing)
  void simulateNavigation() {
    if (currentRoute.value == null) return;

    _navigationService.simulateNavigation(currentRoute.value!);
    isNavigating.value = true;
  }

  // Toggle traffic display
  void toggleTraffic() {
    showTraffic.value = !showTraffic.value;
    if (mapController.value != null) {
      //mapController.value!.setTrafficEnabled(showTraffic.value);
    }
  }

  // Toggle voice guidance
  void toggleVoiceGuidance() {
    voiceGuidanceEnabled.value = !voiceGuidanceEnabled.value;
  }

  // Switch to alternative route
  void switchToAlternativeRoute(int index) {
    if (index < 0 || index >= alternativeRoutes.length) return;

    NavigationRoute selectedRoute = alternativeRoutes[index];
    NavigationRoute? currentMainRoute = currentRoute.value;

    if (currentMainRoute != null) {
      // Swap routes
      alternativeRoutes[index] = currentMainRoute;
      currentRoute.value = selectedRoute;

      // Redraw routes
      _drawRouteOnMap(selectedRoute);
    }
  }
}

