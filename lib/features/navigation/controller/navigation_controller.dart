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
  final RxBool showAlternativeRoutes = true.obs; // Default to showing alternative routes
  final RxInt selectedRouteIndex = 0.obs; // Track which route is currently selected
  final RxList<Map<String, dynamic>> nearbyServices = <Map<String, dynamic>>[].obs; // Nearby services for the route

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

    // Refresh polylines when map controller is set
    if (currentRoute.value != null) {
      _drawRouteOnMap();
    }
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

  // Get directions with alternatives
  Future<void> getDirections(LatLng origin, LatLng destination) async {
    isLoading.value = true;
    alternativeRoutes.clear();
    nearbyServices.clear();
    selectedRouteIndex.value = 0;

    try {
      // Get primary route with alternatives
      List<NavigationRoute> routes = await mapsService.getDirectionsWithAlternatives(
        origin,
        destination,
      );

      if (routes.isNotEmpty) {
        // Set the first route as the current route
        currentRoute.value = routes[0];

        // Add the rest as alternative routes
        if (routes.length > 1) {
          alternativeRoutes.value = routes.sublist(1);
        }

        // Draw routes on map
        if (mapController.value != null) {
          _drawRouteOnMap();
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

  // Get directions with service waypoints
  Future<void> getDirectionsWithService(LatLng origin, LatLng destination, String serviceType) async {
    isLoading.value = true;

    try {
      // Get routes that pass by the selected service type
      List<NavigationRoute> routesWithServices = await mapsService.getDirectionsWithServiceLocations(
        origin,
        destination,
        [serviceType],
      );

      if (routesWithServices.isNotEmpty) {
        // Set the first route as the current route
        currentRoute.value = routesWithServices[0];

        // Add the rest as alternative routes
        if (routesWithServices.length > 1) {
          alternativeRoutes.value = routesWithServices.sublist(1);
        } else {
          alternativeRoutes.clear();
        }

        // Draw routes on map
        if (mapController.value != null) {
          _drawRouteOnMap();
        }
      } else {
        CustomSnackBar.showErrorSnackbar(message: 'Could not find routes with the selected service');
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error getting directions with service: $e');
      CustomSnackBar.showErrorSnackbar(message: 'Failed to get directions with service');
    }
  }

  // Find nearby services along the route
  Future<void> findNearbyServicesAlongRoute(String serviceType) async {
    if (currentRoute.value == null) return;

    isLoading.value = true;
    nearbyServices.clear();

    try {
      // Decode the route polyline to get points along the route
      List<LatLng> routePoints = mapsService.decodePolyline(currentRoute.value!.geometry);

      // Sample points along the route (every ~5km)
      List<LatLng> samplePoints = _sampleRoutePoints(routePoints, 5000);

      // For each sample point, search for the service
      for (LatLng point in samplePoints) {
        List<SearchResult> services = await mapsService.searchPlaces(
          '$serviceType near ${point.latitude},${point.longitude}',
          proximity: point,
        );

        if (services.isNotEmpty) {
          // Take the first service location found
          SearchResult service = services.first;

          nearbyServices.add({
            'id': service.id,
            'name': service.name,
            'address': service.address,
            'latitude': service.latitude,
            'longitude': service.longitude,
            'category': service.category ?? serviceType,
            'distance': _calculateDistance(
                point.latitude,
                point.longitude,
                service.latitude,
                service.longitude
            ),
          });
        }
      }

      // Sort services by distance
      nearbyServices.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error finding nearby services: $e');
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
        alternativeRoutes.clear();

        // Draw route on map
        if (mapController.value != null) {
          _drawRouteOnMap();
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

  // Get route preview
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
  Future<void> addToFavorites(double latitude, double longitude, String name, String address, {String? category, String? notes}) async {
    try {
      Place place = Place(
        id: '',
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category,
        notes: notes,
        isFavorite: true,
        lastVisited: DateTime.now(),
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
        lastVisited: DateTime.now(),
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

  // Draw routes on map
  void _drawRouteOnMap() {
    if (mapController.value == null || currentRoute.value == null) return;

    try {
      // Create a set to hold the new polylines
      Set<Polyline> newPolylines = {};
      Set<Marker> newMarkers = {};

      // Add the main route polyline
      List<LatLng> mainPoints = mapsService.decodePolyline(currentRoute.value!.geometry);
      if (mainPoints.isNotEmpty) {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId('main_route'),
            points: mainPoints,
            color: Colors.blue,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );

        // Add start and end markers
        newMarkers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: LatLng(currentRoute.value!.startLatitude, currentRoute.value!.startLongitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Start', snippet: currentRoute.value!.startAddress),
          ),
        );

        newMarkers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: LatLng(currentRoute.value!.endLatitude, currentRoute.value!.endLongitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Destination', snippet: currentRoute.value!.endAddress),
          ),
        );
      }

      // Add alternative routes
      for (int i = 0; i < alternativeRoutes.length; i++) {
        var altRoute = alternativeRoutes[i];
        List<LatLng> altPoints = mapsService.decodePolyline(altRoute.geometry);

        if (altPoints.isNotEmpty) {
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('alt_route_$i'),
              points: altPoints,
              color: Colors.grey,
              width: 4,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
          );
        }
      }

      // Add service markers if available
      for (int i = 0; i < nearbyServices.length; i++) {
        var service = nearbyServices[i];
        newMarkers.add(
          Marker(
            markerId: MarkerId('service_${service['id']}'),
            position: LatLng(service['latitude'], service['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: service['name'],
              snippet: service['address'],
            ),
          ),
        );
      }

      // Update the polylines and markers
      polylines.value = newPolylines;
      markers.value = newMarkers;

      // Fit bounds to show the entire route if not in navigation mode
      if (!isNavigating.value && mainPoints.length > 1) {
        _fitBoundsToRoute(mainPoints);
      }
    } catch (e) {
      DevLogs.logError('Error drawing routes on map: $e');
    }
  }

  // Fit map bounds to show the entire route
  void _fitBoundsToRoute(List<LatLng> points) {
    if (mapController.value == null || points.isEmpty) return;

    try {
      double minLat = points.map((p) => p.latitude).reduce(min);
      double maxLat = points.map((p) => p.latitude).reduce(max);
      double minLng = points.map((p) => p.longitude).reduce(min);
      double maxLng = points.map((p) => p.longitude).reduce(max);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      mapController.value!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50.0, // padding
        ),
      );
    } catch (e) {
      DevLogs.logError('Error fitting bounds to route: $e');
    }
  }

  // Switch to alternative route
  void switchToRoute(int index) {
    if (index == selectedRouteIndex.value) return;

    try {
      NavigationRoute selectedRoute;

      if (index == 0) {
        // User selected the main route
        if (currentRoute.value == null) return;
        selectedRoute = currentRoute.value!;
      } else {
        // User selected an alternative route
        int altIndex = index - 1;
        if (altIndex < 0 || altIndex >= alternativeRoutes.length) return;
        selectedRoute = alternativeRoutes[altIndex];
      }

      // If we're switching from the main route to an alternative
      if (selectedRouteIndex.value == 0 && index > 0) {
        // Store the current main route
        NavigationRoute mainRoute = currentRoute.value!;

        // Set the selected alternative as the main route
        currentRoute.value = selectedRoute;

        // Replace the alternative with the previous main route
        alternativeRoutes[index - 1] = mainRoute;
      }
      // If we're switching from an alternative to the main route
      else if (selectedRouteIndex.value > 0 && index == 0) {
        // Store the current alternative route
        NavigationRoute altRoute = alternativeRoutes[selectedRouteIndex.value - 1];

        // Store the current main route
        NavigationRoute mainRoute = currentRoute.value!;

        // Set the main route as the selected route
        currentRoute.value = selectedRoute;

        // Replace the main route in the alternatives
        alternativeRoutes[selectedRouteIndex.value - 1] = mainRoute;
      }
      // If we're switching between alternatives
      else if (selectedRouteIndex.value > 0 && index > 0) {
        // Store the current alternative route
        NavigationRoute currentAlt = alternativeRoutes[selectedRouteIndex.value - 1];

        // Store the selected alternative route
        NavigationRoute selectedAlt = alternativeRoutes[index - 1];

        // Swap the routes
        alternativeRoutes[selectedRouteIndex.value - 1] = selectedAlt;
        alternativeRoutes[index - 1] = currentAlt;

        // Set the selected route as the main route
        currentRoute.value = selectedAlt;
      }

      // Update the selected route index
      selectedRouteIndex.value = index;

      // Redraw the routes
      _drawRouteOnMap();
    } catch (e) {
      DevLogs.logError('Error switching routes: $e');
    }
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

  // Helper method to sample points along a route at regular intervals
  List<LatLng> _sampleRoutePoints(List<LatLng> routePoints, double intervalMeters) {
    if (routePoints.isEmpty) return [];

    List<LatLng> sampledPoints = [routePoints.first];
    double accumulatedDistance = 0;

    for (int i = 1; i < routePoints.length; i++) {
      LatLng prevPoint = routePoints[i - 1];
      LatLng currentPoint = routePoints[i];

      double segmentDistance = _calculateDistance(
          prevPoint.latitude,
          prevPoint.longitude,
          currentPoint.latitude,
          currentPoint.longitude
      );

      accumulatedDistance += segmentDistance;

      if (accumulatedDistance >= intervalMeters) {
        sampledPoints.add(currentPoint);
        accumulatedDistance = 0;
      }
    }

    // Always include the last point
    if (sampledPoints.last != routePoints.last) {
      sampledPoints.add(routePoints.last);
    }

    return sampledPoints;
  }

  // Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000; R = 6371 km
  }
}
