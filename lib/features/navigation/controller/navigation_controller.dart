import 'dart:math';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/core/utils/logs.dart';

import '../model/place_model.dart';
import '../model/route_model.dart';
import '../model/search_result_model.dart';
import '../service/mapbox_service.dart';
import '../service/navigation_service.dart';
import '../service/places_service.dart';

class NavigationController extends GetxController {
  final MapboxService mapboxService;
  final PlacesService _placesService = PlacesService();
  final NavigationService _navigationService = NavigationService();

  // Observable variables
  final Rx<Position?> currentLocation = Rx<Position?>(null);
  final RxList<SearchResult> searchResults = <SearchResult>[].obs;
  final RxList<Place> favoritePlaces = <Place>[].obs;
  final RxList<Place> recentPlaces = <Place>[].obs;
  final Rx<NavigationRoute?> currentRoute = Rx<NavigationRoute?>(null);
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

  // Map controller
  Rx<MapboxMapController?> mapController = Rx<MapboxMapController?>(null);

  NavigationController({required String mapboxAccessToken})
      : mapboxService = MapboxService(accessToken: mapboxAccessToken);

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
        Get.snackbar(
          'Arrived',
          'You have reached your destination',
          snackPosition: SnackPosition.BOTTOM,
        );
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
  void setMapController(MapboxMapController controller) {
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

      List<SearchResult> results = await mapboxService.searchPlaces(
        query,
        proximity: proximity,
      );

      searchResults.value = results;
      isSearching.value = false;
    } catch (e) {
      isSearching.value = false;
      DevLogs.logError('Error searching places: $e');
      Get.snackbar(
        'Error',
        'Failed to search places',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Get directions
  Future<void> getDirections(LatLng origin, LatLng destination) async {
    isLoading.value = true;

    try {
      // Get primary route
      NavigationRoute? route = await mapboxService.getDirections(
        origin,
        destination,
      );

      if (route != null) {
        currentRoute.value = route;

        // Get alternative routes
        NavigationRoute? alternativeRoute = await mapboxService.getDirections(
          origin,
          destination,
          alternatives: true,
        );

        if (alternativeRoute != null) {
          alternativeRoutes.value = [alternativeRoute];
        } else {
          alternativeRoutes.clear();
        }

        // Draw route on map
        if (mapController.value != null) {
          _drawRouteOnMap(route);
        }
      } else {
        Get.snackbar(
          'No Route Found',
          'Could not find a route to the destination',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      DevLogs.logError('Error getting directions: $e');
      Get.snackbar(
        'Error',
        'Failed to get directions',
        snackPosition: SnackPosition.BOTTOM,
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

        // Add destination to recent places
        if (currentRoute.value != null) {
          addToRecentPlaces(
            currentRoute.value!.endLatitude,
            currentRoute.value!.endLongitude,
            currentRoute.value!.endAddress,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to start navigation',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error starting navigation: $e');
      Get.snackbar(
        'Error',
        'Failed to start navigation',
        snackPosition: SnackPosition.BOTTOM,
      );
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
        Get.snackbar(
          'Success',
          'Place added to favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add place to favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error adding to favorites: $e');
      Get.snackbar(
        'Error',
        'Failed to add place to favorites',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Remove place from favorites
  Future<void> removeFromFavorites(String placeId) async {
    try {
      bool removed = await _placesService.removeFavoritePlace(placeId);

      if (removed) {
        await loadSavedPlaces();
        Get.snackbar(
          'Success',
          'Place removed from favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove place from favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error removing from favorites: $e');
      Get.snackbar(
        'Error',
        'Failed to remove place from favorites',
        snackPosition: SnackPosition.BOTTOM,
      );
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
        Get.snackbar(
          'Success',
          'Recent places cleared',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to clear recent places',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error clearing recent places: $e');
      Get.snackbar(
        'Error',
        'Failed to clear recent places',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Update place
  Future<void> updatePlace(Place place) async {
    try {
      bool updated = await _placesService.updatePlace(place);

      if (updated) {
        await loadSavedPlaces();
        Get.snackbar(
          'Success',
          'Place updated',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update place',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error updating place: $e');
      Get.snackbar(
        'Error',
        'Failed to update place',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Draw route on map
  void _drawRouteOnMap(NavigationRoute route) {
    if (mapController.value == null) return;

    // Clear previous routes
    mapController.value!.clearLines();

    // Decode polyline
    List<LatLng> points = _decodePolyline(route.geometry);

    // Add main route line
    mapController.value!.addLine(
      LineOptions(
        geometry: points,
        lineColor: "#3887be",
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );

    // Add alternative routes if available
    for (var altRoute in alternativeRoutes) {
      List<LatLng> altPoints = _decodePolyline(altRoute.geometry);
      mapController.value!.addLine(
        LineOptions(
          geometry: altPoints,
          lineColor: "#888888",
          lineWidth: 3.0,
          lineOpacity: 0.6,
          linePattern: "dash",
        ),
      );
    }

    // Add start and end markers
    mapController.value!.addSymbol(
      SymbolOptions(
        geometry: LatLng(route.startLatitude, route.startLongitude),
        iconImage: "marker-start",
        iconSize: 1.5,
      ),
    );

    mapController.value!.addSymbol(
      SymbolOptions(
        geometry: LatLng(route.endLatitude, route.endLongitude),
        iconImage: "marker-end",
        iconSize: 1.5,
      ),
    );

    // Fit bounds to show the entire route
    mapController.value!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            points.map((p) => p.latitude).reduce(min),
            points.map((p) => p.longitude).reduce(min),
          ),
          northeast: LatLng(
            points.map((p) => p.latitude).reduce(max),
            points.map((p) => p.longitude).reduce(max),
          ),
        ),
        left: 50,
        top: 50,
        right: 50,
        bottom: 50,
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

      points.add(LatLng(lat / 1E6, lng / 1E6));
    }

    return points;
  }

  // Get place categories
  List<Map<String, dynamic>> getPlaceCategories() {
    return _placesService.getPlaceCategories();
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
      //mapController.value!.setLayerVisibility("traffic", showTraffic.value);
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
