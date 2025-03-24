import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/service_location_model.dart';

class ServiceLocatorService {
  final String _accessToken;
  final Uuid _uuid = Uuid();

  // Cache keys
  static const String _recentServicesKey = 'recent_services';
  static const String _favoriteServicesKey = 'favorite_services';
  static const int _cacheDurationHours = 24; // Cache duration in hours

  // Service categories
  static const Map<String, String> serviceCategories = {
    'gas_station': 'Gas Station',
    'mechanic': 'Mechanic',
    'car_wash': 'Car Wash',
    'parking': 'Parking',
    'restaurant': 'Restaurant',
    'hotel': 'Hotel',
    'hospital': 'Hospital',
    'police': 'Police Station',
    'ev_charging': 'EV Charging',
    'rest_area': 'Rest Area',
    'atm': 'ATM',
    'convenience_store': 'Convenience Store',
  };

  // Mapbox POI types mapping to our categories
  final Map<String, List<String>> _poiTypeMapping = {
    'gas_station': ['fuel', 'gas_station', 'gas', 'petrol_station'],
    'mechanic': ['car_repair', 'mechanic', 'automotive', 'car_service'],
    'car_wash': ['car_wash'],
    'parking': ['parking', 'parking_lot', 'parking_garage'],
    'restaurant': ['restaurant', 'food', 'cafe', 'fast_food'],
    'hotel': ['hotel', 'lodging', 'motel'],
    'hospital': ['hospital', 'clinic', 'emergency_room', 'medical_center'],
    'police': ['police', 'police_station'],
    'ev_charging': ['charging_station', 'ev_charging'],
    'rest_area': ['rest_area', 'rest_stop'],
    'atm': ['atm', 'bank'],
    'convenience_store': ['convenience', 'convenience_store', 'shop'],
  };

  ServiceLocatorService({required String accessToken}) : _accessToken = accessToken;

  // Search for services by category
  Future<List<ServiceLocation>> searchServicesByCategory(
      String category,
      LatLng currentLocation,
      {double radiusKm = 10.0}
      ) async {
    try {
      // Check cache first
      final cachedServices = await _getCachedServicesByCategory(category, currentLocation, radiusKm);
      if (cachedServices.isNotEmpty) {
        return cachedServices;
      }

      // Convert our category to Mapbox POI types
      final poiTypes = _poiTypeMapping[category] ?? [category];
      final poiTypesString = poiTypes.join(',');

      // Build the URL for Mapbox POI search
      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$poiTypesString.json'
          '?access_token=$_accessToken'
          '&limit=15'
          '&types=poi'
          '&proximity=${currentLocation.longitude},${currentLocation.latitude}'
          '&radius=${radiusKm * 1000}'; // Convert km to meters

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        List<ServiceLocation> services = [];

        for (var feature in features) {
          final coordinates = feature['geometry']['coordinates'] as List;
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};
          final context = feature['context'] as List? ?? [];

          // Extract place details
          String name = feature['text'] ?? '';
          String address = feature['place_name'] ?? '';

          // Extract additional details from properties and context
          String? phoneNumber;
          String? website;
          double? rating;
          bool isOpen = true; // Default to true since Mapbox doesn't always provide this
          List<String> amenities = [];

          // Try to extract more details from properties
          if (properties.containsKey('phone')) {
            phoneNumber = properties['phone'];
          }

          if (properties.containsKey('website')) {
            website = properties['website'];
          }

          if (properties.containsKey('rating')) {
            rating = properties['rating']?.toDouble();
          }

          if (properties.containsKey('open')) {
            isOpen = properties['open'] == true;
          }

          // Calculate distance (straight line)
          double distance = _calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              coordinates[1],
              coordinates[0]
          );

          // Estimate duration (assuming average speed of 50 km/h)
          double duration = (distance / 50) * 60; // Convert to minutes

          services.add(ServiceLocation(
            id: feature['id'] ?? _uuid.v4(),
            name: name,
            address: address,
            latitude: coordinates[1],
            longitude: coordinates[0],
            category: category,
            phoneNumber: phoneNumber,
            website: website,
            rating: rating,
            isOpen: isOpen,
            properties: properties,
            distance: distance,
            duration: duration,
            amenities: amenities,
          ));
        }

        // Cache the results
        await _cacheServicesByCategory(category, services);

        return services;
      } else {
        DevLogs.logError('Failed to search services: ${response.statusCode}');
        throw Exception('Failed to search services: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error searching services: $e');
      return [];
    }
  }

  // Search for services by name or keyword
  Future<List<ServiceLocation>> searchServicesByKeyword(
      String keyword,
      LatLng currentLocation,
      {double radiusKm = 10.0}
      ) async {
    try {
      // Build the URL for Mapbox POI search
      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$keyword.json'
          '?access_token=$_accessToken'
          '&limit=15'
          '&types=poi'
          '&proximity=${currentLocation.longitude},${currentLocation.latitude}'
          '&radius=${radiusKm * 1000}'; // Convert km to meters

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        List<ServiceLocation> services = [];

        for (var feature in features) {
          final coordinates = feature['geometry']['coordinates'] as List;
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};

          // Extract place details
          String name = feature['text'] ?? '';
          String address = feature['place_name'] ?? '';

          // Determine category based on properties or name
          String category = _determineCategoryFromFeature(feature);

          // Calculate distance (straight line)
          double distance = _calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              coordinates[1],
              coordinates[0]
          );

          // Estimate duration (assuming average speed of 50 km/h)
          double duration = (distance / 50) * 60; // Convert to minutes

          services.add(ServiceLocation(
            id: feature['id'] ?? _uuid.v4(),
            name: name,
            address: address,
            latitude: coordinates[1],
            longitude: coordinates[0],
            category: category,
            properties: properties,
            distance: distance,
            duration: duration,
          ));
        }

        return services;
      } else {
        DevLogs.logError('Failed to search services by keyword: ${response.statusCode}');
        throw Exception('Failed to search services by keyword: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error searching services by keyword: $e');
      return [];
    }
  }

  // Get details for a specific service
  Future<ServiceLocation?> getServiceDetails(String serviceId, LatLng currentLocation) async {
    try {
      // Check if we have it in cache
      final prefs = await SharedPreferences.getInstance();
      final String? recentServicesJson = prefs.getString(_recentServicesKey);
      final String? favoriteServicesJson = prefs.getString(_favoriteServicesKey);

      if (recentServicesJson != null) {
        List<dynamic> recentServices = jsonDecode(recentServicesJson);
        final serviceIndex = recentServices.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          ServiceLocation service = ServiceLocation.fromJson(recentServices[serviceIndex]);

          // Update distance and duration
          double distance = _calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              service.latitude,
              service.longitude
          );
          double duration = (distance / 50) * 60; // Convert to minutes

          return service.copyWith(distance: distance, duration: duration);
        }
      }

      if (favoriteServicesJson != null) {
        List<dynamic> favoriteServices = jsonDecode(favoriteServicesJson);
        final serviceIndex = favoriteServices.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          ServiceLocation service = ServiceLocation.fromJson(favoriteServices[serviceIndex]);

          // Update distance and duration
          double distance = _calculateDistance(
              currentLocation.latitude,
              currentLocation.longitude,
              service.latitude,
              service.longitude
          );
          double duration = (distance / 50) * 60; // Convert to minutes

          return service.copyWith(distance: distance, duration: duration);
        }
      }

      // If not in cache, try to fetch from Mapbox
      // Note: Mapbox doesn't have a direct "get details by ID" API, so this is a workaround
      // In a real app, you might want to use Google Places API or similar for this

      // For now, return null if not found in cache
      return null;
    } catch (e) {
      DevLogs.logError('Error getting service details: $e');
      return null;
    }
  }

  // Add a service to favorites
  Future<bool> addServiceToFavorites(ServiceLocation service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoriteServicesKey);

      List<Map<String, dynamic>> favorites = [];
      if (favoritesJson != null) {
        favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      }

      // Check if already exists
      int existingIndex = favorites.indexWhere((s) => s['id'] == service.id);
      if (existingIndex != -1) {
        // Update existing
        favorites[existingIndex] = service.toJson();
      } else {
        // Add new
        favorites.add(service.toJson());
      }

      await prefs.setString(_favoriteServicesKey, jsonEncode(favorites));
      return true;
    } catch (e) {
      DevLogs.logError('Error adding service to favorites: $e');
      return false;
    }
  }

  // Remove a service from favorites
  Future<bool> removeServiceFromFavorites(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoriteServicesKey);

      if (favoritesJson == null) {
        return true; // Nothing to remove
      }

      List<Map<String, dynamic>> favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      favorites.removeWhere((s) => s['id'] == serviceId);

      await prefs.setString(_favoriteServicesKey, jsonEncode(favorites));
      return true;
    } catch (e) {
      DevLogs.logError('Error removing service from favorites: $e');
      return false;
    }
  }

  // Get all favorite services
  Future<List<ServiceLocation>> getFavoriteServices(LatLng currentLocation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoriteServicesKey);

      if (favoritesJson == null) {
        return [];
      }

      List<dynamic> favorites = jsonDecode(favoritesJson);
      List<ServiceLocation> services = [];

      for (var service in favorites) {
        ServiceLocation serviceLocation = ServiceLocation.fromJson(service);

        // Update distance and duration
        double distance = _calculateDistance(
            currentLocation.latitude,
            currentLocation.longitude,
            serviceLocation.latitude,
            serviceLocation.longitude
        );
        double duration = (distance / 50) * 60; // Convert to minutes

        services.add(serviceLocation.copyWith(distance: distance, duration: duration));
      }

      // Sort by distance
      services.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

      return services;
    } catch (e) {
      DevLogs.logError('Error getting favorite services: $e');
      return [];
    }
  }

  // Add a service to recent
  Future<bool> addServiceToRecent(ServiceLocation service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recentsJson = prefs.getString(_recentServicesKey);

      List<Map<String, dynamic>> recents = [];
      if (recentsJson != null) {
        recents = List<Map<String, dynamic>>.from(jsonDecode(recentsJson));
      }

      // Remove if already exists
      recents.removeWhere((s) => s['id'] == service.id);

      // Add to beginning
      recents.insert(0, service.toJson());

      // Limit to 20 recent services
      if (recents.length > 20) {
        recents = recents.sublist(0, 20);
      }

      await prefs.setString(_recentServicesKey, jsonEncode(recents));
      return true;
    } catch (e) {
      DevLogs.logError('Error adding service to recent: $e');
      return false;
    }
  }

  // Get recent services
  Future<List<ServiceLocation>> getRecentServices(LatLng currentLocation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recentsJson = prefs.getString(_recentServicesKey);

      if (recentsJson == null) {
        return [];
      }

      List<dynamic> recents = jsonDecode(recentsJson);
      List<ServiceLocation> services = [];

      for (var service in recents) {
        ServiceLocation serviceLocation = ServiceLocation.fromJson(service);

        // Update distance and duration
        double distance = _calculateDistance(
            currentLocation.latitude,
            currentLocation.longitude,
            serviceLocation.latitude,
            serviceLocation.longitude
        );
        double duration = (distance / 50) * 60; // Convert to minutes

        services.add(serviceLocation.copyWith(distance: distance, duration: duration));
      }

      return services;
    } catch (e) {
      DevLogs.logError('Error getting recent services: $e');
      return [];
    }
  }

  // Clear recent services
  Future<bool> clearRecentServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentServicesKey);
      return true;
    } catch (e) {
      DevLogs.logError('Error clearing recent services: $e');
      return false;
    }
  }

  // Get services along a route
  Future<List<ServiceLocation>> getServicesAlongRoute(
      String category,
      List<LatLng> routePoints,
      {double bufferDistanceKm = 1.0}
      ) async {
    try {
      // This is a simplified implementation
      // In a real app, you would use a more sophisticated algorithm to find services along a route

      // For now, we'll just check services near each point in the route
      Set<String> seenServiceIds = {};
      List<ServiceLocation> services = [];

      // Sample points along the route (not every point to avoid too many API calls)
      List<LatLng> sampledPoints = _sampleRoutePoints(routePoints, 5); // Sample every 5 km

      for (var point in sampledPoints) {
        List<ServiceLocation> nearbyServices = await searchServicesByCategory(
            category,
            point,
            radiusKm: bufferDistanceKm
        );

        // Add only services we haven't seen yet
        for (var service in nearbyServices) {
          if (!seenServiceIds.contains(service.id)) {
            seenServiceIds.add(service.id);
            services.add(service);
          }
        }
      }

      // Sort by distance from the first point (origin)
      if (routePoints.isNotEmpty) {
        services.sort((a, b) {
          double distanceA = _calculateDistance(
              routePoints.first.latitude,
              routePoints.first.longitude,
              a.latitude,
              a.longitude
          );
          double distanceB = _calculateDistance(
              routePoints.first.latitude,
              routePoints.first.longitude,
              b.latitude,
              b.longitude
          );
          return distanceA.compareTo(distanceB);
        });
      }

      return services;
    } catch (e) {
      DevLogs.logError('Error getting services along route: $e');
      return [];
    }
  }

  // Helper method to sample points along a route
  List<LatLng> _sampleRoutePoints(List<LatLng> routePoints, double intervalKm) {
    if (routePoints.isEmpty) return [];
    if (routePoints.length == 1) return routePoints;

    List<LatLng> sampledPoints = [routePoints.first];
    double distanceSoFar = 0.0;

    for (int i = 1; i < routePoints.length; i++) {
      LatLng prevPoint = routePoints[i - 1];
      LatLng currentPoint = routePoints[i];

      double segmentDistance = _calculateDistance(
          prevPoint.latitude,
          prevPoint.longitude,
          currentPoint.latitude,
          currentPoint.longitude
      );

      distanceSoFar += segmentDistance;

      if (distanceSoFar >= intervalKm) {
        sampledPoints.add(currentPoint);
        distanceSoFar = 0.0;
      }
    }

    // Always include the last point
    if (sampledPoints.last != routePoints.last) {
      sampledPoints.add(routePoints.last);
    }

    return sampledPoints;
  }

  // Helper method to calculate distance between two points in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Helper method to determine category from Mapbox feature
  String _determineCategoryFromFeature(dynamic feature) {
    // Try to extract category from properties
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    if (properties.containsKey('category')) {
      String propCategory = properties['category'];

      // Map to our categories
      for (var entry in _poiTypeMapping.entries) {
        if (entry.value.contains(propCategory.toLowerCase())) {
          return entry.key;
        }
      }
    }

    // Try to determine from the place name
    String name = feature['text'] ?? '';
    String placeName = feature['place_name'] ?? '';
    String combinedText = '$name $placeName'.toLowerCase();

    // Check for keywords in the name
    if (combinedText.contains('gas') || combinedText.contains('fuel') || combinedText.contains('petrol')) {
      return 'gas_station';
    } else if (combinedText.contains('mechanic') || combinedText.contains('repair') || combinedText.contains('service')) {
      return 'mechanic';
    } else if (combinedText.contains('car wash')) {
      return 'car_wash';
    } else if (combinedText.contains('parking')) {
      return 'parking';
    } else if (combinedText.contains('restaurant') || combinedText.contains('food') || combinedText.contains('cafe')) {
      return 'restaurant';
    } else if (combinedText.contains('hotel') || combinedText.contains('motel') || combinedText.contains('lodge')) {
      return 'hotel';
    } else if (combinedText.contains('hospital') || combinedText.contains('clinic') || combinedText.contains('medical')) {
      return 'hospital';
    } else if (combinedText.contains('police')) {
      return 'police';
    } else if (combinedText.contains('charging') || combinedText.contains('ev')) {
      return 'ev_charging';
    } else if (combinedText.contains('rest') && (combinedText.contains('area') || combinedText.contains('stop'))) {
      return 'rest_area';
    } else if (combinedText.contains('atm') || combinedText.contains('bank')) {
      return 'atm';
    } else if (combinedText.contains('store') || combinedText.contains('shop') || combinedText.contains('mart')) {
      return 'convenience_store';
    }

    // Default to 'other' if we can't determine
    return 'other';
  }

  // Helper method to get cached services by category
  Future<List<ServiceLocation>> _getCachedServicesByCategory(
      String category,
      LatLng currentLocation,
      double radiusKm
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'services_${category}_${currentLocation.latitude.toStringAsFixed(2)}_${currentLocation.longitude.toStringAsFixed(2)}_$radiusKm';
      final String? cachedDataJson = prefs.getString(cacheKey);
      final String? cacheTimeString = prefs.getString('${cacheKey}_time');

      if (cachedDataJson != null && cacheTimeString != null) {
        // Check if cache is still valid
        final cacheTime = DateTime.parse(cacheTimeString);
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference.inHours < _cacheDurationHours) {
          // Cache is still valid
          List<dynamic> cachedData = jsonDecode(cachedDataJson);
          List<ServiceLocation> services = cachedData.map((data) => ServiceLocation.fromJson(data)).toList();

          // Update distances and durations
          services = services.map((service) {
            double distance = _calculateDistance(
                currentLocation.latitude,
                currentLocation.longitude,
                service.latitude,
                service.longitude
            );
            double duration = (distance / 50) * 60; // Convert to minutes

            return service.copyWith(distance: distance, duration: duration);
          }).toList();

          // Sort by distance
          services.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

          return services;
        }
      }

      return []; // No valid cache
    } catch (e) {
      DevLogs.logError('Error getting cached services: $e');
      return [];
    }
  }

  // Helper method to cache services by category
  Future<void> _cacheServicesByCategory(String category, List<ServiceLocation> services) async {
    try {
      if (services.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      // Use the first service's location as reference point
      final referenceService = services.first;
      final cacheKey = 'services_${category}_${referenceService.latitude.toStringAsFixed(2)}_${referenceService.longitude.toStringAsFixed(2)}_10.0';

      await prefs.setString(cacheKey, jsonEncode(services.map((s) => s.toJson()).toList()));
      await prefs.setString('${cacheKey}_time', DateTime.now().toIso8601String());
    } catch (e) {
      DevLogs.logError('Error caching services: $e');
    }
  }
}

