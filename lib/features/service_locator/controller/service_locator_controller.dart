import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../model/service_location_model.dart';
import '../service/service_locator_interface.dart';
import '../service/service_repository_interface.dart';
import '../service/service_repository.dart';
import '../service/location_service.dart';


class ServiceLocatorController extends GetxController {
  final IServiceRepository _serviceRepository;
  final ILocationService _locationService;

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
  Rx<GoogleMapController?> mapController = Rx<GoogleMapController?>(null);

  // Map markers
  final RxSet<Marker> markers = <Marker>{}.obs;

  // Location stream subscription
  StreamSubscription<Position>? _positionStreamSubscription;

  ServiceLocatorController({
    required String apiKey,
    IServiceRepository? serviceRepository,
    ILocationService? locationService,
  }) : _serviceRepository = serviceRepository ?? ServiceRepository(apiKey: apiKey),
        _locationService = locationService ?? LocationService();

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
    loadFavoriteServices();
    loadRecentServices();
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    mapController.value?.dispose();
    super.onClose();
  }

  // Initialize location services
  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = 'Location services are disabled.';
        return;
      }

      bool permissionGranted = await _locationService.requestLocationPermission();
      if (!permissionGranted) {
        errorMessage.value = 'Location permissions are denied.';
        return;
      }

      // Get initial position
      Position position = await _locationService.getCurrentPosition();
      currentLocation.value = position;

      // Start listening to position updates
      _positionStreamSubscription = _locationService.getPositionStream().listen(
              (Position position) {
            currentLocation.value = position;
            _updateServicesDistances();

            // Update user location marker if map is initialized
            if (mapController.value != null) {
              _updateUserLocationMarker();
            }
          },
          onError: (error) {
            DevLogs.logError('Error from position stream: $error');
          }
      );
    } catch (e) {
      errorMessage.value = 'Failed to initialize location: $e';
      DevLogs.logError('Error initializing location: $e');
    }
  }

  // Set map controller
  void setMapController(GoogleMapController controller) {
    mapController.value = controller;

    // Update markers if we have services
    if (nearbyServices.isNotEmpty) {
      _addServiceMarkersToMap(nearbyServices);
    }

    // Add user location marker
    _updateUserLocationMarker();
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

      List<ServiceLocation> services = await _serviceRepository.searchServicesByCategory(
          category,
          location
      );

      nearbyServices.value = services;
      isLoading.value = false;

      // Add markers to map
      _addServiceMarkersToMap(services);
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

      List<ServiceLocation> services = await _serviceRepository.searchServicesByKeyword(
          keyword,
          location
      );

      searchResults.value = services;
      isSearching.value = false;

      // Add markers to map if in search mode
      if (services.isNotEmpty) {
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

      return await _serviceRepository.getServiceDetails(serviceId, location);
    } catch (e) {
      errorMessage.value = 'Failed to get service details: $e';
      DevLogs.logError('Error getting service details: $e');
      return null;
    }
  }

  // Add service to favorites
  Future<void> addServiceToFavorites(ServiceLocation service) async {
    try {
      bool success = await _serviceRepository.addServiceToFavorites(service);

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
      bool success = await _serviceRepository.removeServiceFromFavorites(serviceId);

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

      List<ServiceLocation> services = await _serviceRepository.getFavoriteServices(location);
      favoriteServices.value = services;
    } catch (e) {
      DevLogs.logError('Error loading favorite services: $e');
    }
  }

  // Add service to recent
  Future<void> addServiceToRecent(ServiceLocation service) async {
    try {
      await _serviceRepository.addServiceToRecent(service);
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

      List<ServiceLocation> services = await _serviceRepository.getRecentServices(location);
      recentServices.value = services;
    } catch (e) {
      DevLogs.logError('Error loading recent services: $e');
    }
  }

  // Clear recent services
  Future<void> clearRecentServices() async {
    try {
      bool success = await _serviceRepository.clearRecentServices();

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
      List<ServiceLocation> services = await _serviceRepository.getServicesAlongRoute(
          category,
          routePoints
      );

      routeServices.value = services;
      isLoading.value = false;

      // Add markers to map
      _addServiceMarkersToMap(services);
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to get services along route: $e';
      DevLogs.logError('Error getting services along route: $e');
    }
  }

  // Get available service categories
  Map<String, String> getServiceCategories() {
    return _serviceRepository.getServiceCategories();
  }

  // Helper method to add service markers to map
  void _addServiceMarkersToMap(List<ServiceLocation> services) {
    if (mapController.value == null) return;

    // Clear existing markers except user location
    Set<Marker> updatedMarkers = {};

    // Keep user location marker if it exists
    for (var marker in markers) {
      if (marker.markerId.value == 'user_location') {
        updatedMarkers.add(marker);
        break;
      }
    }

    // Add markers for each service
    for (var service in services) {
      final markerId = MarkerId(service.id);

      updatedMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(service.latitude, service.longitude),
          infoWindow: InfoWindow(
            title: service.name,
            snippet: service.address,
            onTap: () {
              // Navigate to service details
              _onMarkerTapped(service);
            },
          ),
          icon: _getMarkerIconForCategory(service.category),
        ),
      );
    }

    markers.value = updatedMarkers;
  }

  // Update user location marker
  void _updateUserLocationMarker() {
    if (mapController.value == null || currentLocation.value == null) return;

    // Create a set with existing markers but remove user location marker if it exists
    Set<Marker> updatedMarkers = markers.where((m) => m.markerId.value != 'user_location').toSet();

    // Add updated user location marker
    updatedMarkers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
            currentLocation.value!.latitude,
            currentLocation.value!.longitude
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 2, // Ensure user marker is on top
        flat: true,
        rotation: currentLocation.value!.heading.toDouble(),
      ),
    );

    markers.value = updatedMarkers;
  }

  // Helper method to get marker icon for category
  BitmapDescriptor _getMarkerIconForCategory(String category) {
    // In a real app, you would use custom icons for each category
    // For now, we'll use different hues of the default marker
    switch (category) {
      case 'gas_station':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'mechanic':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'car_wash':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'parking':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'restaurant':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'hotel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'police':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'ev_charging':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  // Helper method to handle marker tap
  void _onMarkerTapped(ServiceLocation service) {
    // Add to recent services
    addServiceToRecent(service);

    // Navigate to service details screen
    // This would be implemented in your navigation system
    // For example: Get.toNamed('/service-details', arguments: service);
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
      double distance = _locationService.calculateDistanceCoordinates(
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
      double distance = _locationService.calculateDistanceCoordinates(
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
}
