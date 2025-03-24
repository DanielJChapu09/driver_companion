import 'dart:math';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../model/service_location_model.dart';
import '../service/service_locator_service.dart';

class ServiceLocatorController extends GetxController {
  final ServiceLocatorService _serviceLocatorService;

  // Observable variables
  final Rx<Position?> currentLocation = Rx<Position?>(null);
  final RxList<ServiceLocation> nearbyServices = <ServiceLocation>[].obs;
  final RxList<ServiceLocation> favoriteServices = <ServiceLocation>[].obs;
  final RxList<ServiceLocation> recentServices = <ServiceLocation>[].obs;
  final RxString selectedCategory = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxList<ServiceLocation> searchResults = <ServiceLocation>[].obs;
  final RxList<ServiceLocation> routeServices = <ServiceLocation>[].obs;

  // Map controller
  Rx<MapboxMapController?> mapController = Rx<MapboxMapController?>(null);

  ServiceLocatorController({required String mapboxAccessToken})
      : _serviceLocatorService = ServiceLocatorService(accessToken: mapboxAccessToken);

  @override
  void onInit() {
    super.onInit();
    loadFavoriteServices();
    loadRecentServices();
  }

  // Set map controller
  void setMapController(MapboxMapController controller) {
    mapController.value = controller;
  }

  // Update current location
  void updateCurrentLocation(Position position) {
    currentLocation.value = position;

    // Refresh services if we have a selected category
    if (selectedCategory.value.isNotEmpty) {
      searchServicesByCategory(selectedCategory.value);
    }

    // Update distances for favorites and recents
    _updateServicesDistances();
  }

  // Search for services by category
  Future<void> searchServicesByCategory(String category) async {
    if (currentLocation.value == null) {
      errorMessage.value = 'Location not available';
      return;
    }

    isLoading.value = true;
    selectedCategory.value = category;
    errorMessage.value = '';

    try {
      LatLng location = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude
      );

      List<ServiceLocation> services = await _serviceLocatorService.searchServicesByCategory(
          category,
          location
      );

      nearbyServices.value = services;
      isLoading.value = false;

      // Add markers to map
      if (mapController.value != null) {
        _addServiceMarkersToMap(services);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to search services: $e';
      DevLogs.logError('Error searching services: $e');
    }
  }

  // Search for services by keyword
  Future<void> searchServicesByKeyword(String keyword) async {
    if (currentLocation.value == null) {
      errorMessage.value = 'Location not available';
      return;
    }

    if (keyword.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    searchQuery.value = keyword;
    errorMessage.value = '';

    try {
      LatLng location = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude
      );

      List<ServiceLocation> services = await _serviceLocatorService.searchServicesByKeyword(
          keyword,
          location
      );

      searchResults.value = services;
      isSearching.value = false;

      // Add markers to map if in search mode
      if (mapController.value != null && services.isNotEmpty) {
        _addServiceMarkersToMap(services);
      }
    } catch (e) {
      isSearching.value = false;
      errorMessage.value = 'Failed to search services: $e';
      DevLogs.logError('Error searching services by keyword: $e');
    }
  }

  // Get service details
  Future<ServiceLocation?> getServiceDetails(String serviceId) async {
    if (currentLocation.value == null) {
      errorMessage.value = 'Location not available';
      return null;
    }

    try {
      LatLng location = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude
      );

      return await _serviceLocatorService.getServiceDetails(serviceId, location);
    } catch (e) {
      errorMessage.value = 'Failed to get service details: $e';
      DevLogs.logError('Error getting service details: $e');
      return null;
    }
  }

  // Add service to favorites
  Future<void> addServiceToFavorites(ServiceLocation service) async {
    try {
      bool success = await _serviceLocatorService.addServiceToFavorites(service);

      if (success) {
        await loadFavoriteServices();
        Get.snackbar(
          'Success',
          '${service.name} added to favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add to favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error adding service to favorites: $e');
      Get.snackbar(
        'Error',
        'Failed to add to favorites',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Remove service from favorites
  Future<void> removeServiceFromFavorites(String serviceId) async {
    try {
      bool success = await _serviceLocatorService.removeServiceFromFavorites(serviceId);

      if (success) {
        await loadFavoriteServices();
        Get.snackbar(
          'Success',
          'Removed from favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove from favorites',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error removing service from favorites: $e');
      Get.snackbar(
        'Error',
        'Failed to remove from favorites',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Load favorite services
  Future<void> loadFavoriteServices() async {
    if (currentLocation.value == null) return;

    try {
      LatLng location = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude
      );

      List<ServiceLocation> services = await _serviceLocatorService.getFavoriteServices(location);
      favoriteServices.value = services;
    } catch (e) {
      DevLogs.logError('Error loading favorite services: $e');
    }
  }

  // Add service to recent
  Future<void> addServiceToRecent(ServiceLocation service) async {
    try {
      await _serviceLocatorService.addServiceToRecent(service);
      await loadRecentServices();
    } catch (e) {
      DevLogs.logError('Error adding service to recent: $e');
    }
  }

  // Load recent services
  Future<void> loadRecentServices() async {
    if (currentLocation.value == null) return;

    try {
      LatLng location = LatLng(
          currentLocation.value!.latitude,
          currentLocation.value!.longitude
      );

      List<ServiceLocation> services = await _serviceLocatorService.getRecentServices(location);
      recentServices.value = services;
    } catch (e) {
      DevLogs.logError('Error loading recent services: $e');
    }
  }

  // Clear recent services
  Future<void> clearRecentServices() async {
    try {
      bool success = await _serviceLocatorService.clearRecentServices();

      if (success) {
        recentServices.clear();
        Get.snackbar(
          'Success',
          'Recent services cleared',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to clear recent services',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DevLogs.logError('Error clearing recent services: $e');
      Get.snackbar(
        'Error',
        'Failed to clear recent services',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Get services along a route
  Future<void> getServicesAlongRoute(String category, List<LatLng> routePoints) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      List<ServiceLocation> services = await _serviceLocatorService.getServicesAlongRoute(
          category,
          routePoints
      );

      routeServices.value = services;
      isLoading.value = false;

      // Add markers to map
      if (mapController.value != null) {
        _addServiceMarkersToMap(services);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to get services along route: $e';
      DevLogs.logError('Error getting services along route: $e');
    }
  }

  // Helper method to add service markers to map
  void _addServiceMarkersToMap(List<ServiceLocation> services) {
    if (mapController.value == null) return;

    // Clear existing markers
    mapController.value!.clearSymbols();

    // Add markers for each service
    for (var service in services) {
      mapController.value!.addSymbol(
        SymbolOptions(
          geometry: LatLng(service.latitude, service.longitude),
          iconImage: _getMarkerIconForCategory(service.category),
          iconSize: 1.0,
          textField: service.name,
          textOffset: const Offset(0, 1.5),
          textSize: 12.0,
        ),
      );
    }
  }

  // Helper method to get marker icon for category
  String _getMarkerIconForCategory(String category) {
    switch (category) {
      case 'gas_station':
        return 'gas-station';
      case 'mechanic':
        return 'car-repair';
      case 'car_wash':
        return 'car-wash';
      case 'parking':
        return 'parking';
      case 'restaurant':
        return 'restaurant';
      case 'hotel':
        return 'lodging';
      case 'hospital':
        return 'hospital';
      case 'police':
        return 'police';
      case 'ev_charging':
        return 'charging';
      case 'rest_area':
        return 'rest-area';
      case 'atm':
        return 'atm';
      case 'convenience_store':
        return 'shop';
      default:
        return 'marker';
    }
  }

  // Helper method to update distances for favorites and recents
  void _updateServicesDistances() {
    if (currentLocation.value == null) return;

    LatLng location = LatLng(
        currentLocation.value!.latitude,
        currentLocation.value!.longitude
    );

    // Update favorites
    List<ServiceLocation> updatedFavorites = favoriteServices.map((service) {
      double distance = _calculateDistance(
          location.latitude,
          location.longitude,
          service.latitude,
          service.longitude
      );
      double duration = (distance / 50) * 60; // Convert to minutes

      return service.copyWith(distance: distance, duration: duration);
    }).toList();

    // Sort by distance
    updatedFavorites.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    favoriteServices.value = updatedFavorites;

    // Update recents
    List<ServiceLocation> updatedRecents = recentServices.map((service) {
      double distance = _calculateDistance(
          location.latitude,
          location.longitude,
          service.latitude,
          service.longitude
      );
      double duration = (distance / 50) * 60; // Convert to minutes

      return service.copyWith(distance: distance, duration: duration);
    }).toList();

    recentServices.value = updatedRecents;
  }

  // Helper method to calculate distance between two points in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}

