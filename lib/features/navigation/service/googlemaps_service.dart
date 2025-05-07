import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:uuid/uuid.dart';
import '../model/search_result_model.dart';
import '../model/route_model.dart';
import 'maps_service_interface.dart';

class GoogleMapsService implements IMapsService {
  final String _apiKey;
  final Uuid _uuid = Uuid();

  GoogleMapsService({required String apiKey}) : _apiKey = apiKey;

  @override
  Future<List<SearchResult>> searchPlaces(String query,
      {LatLng? proximity}) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$query'
          '&key=$_apiKey';

      // Add location bias if proximity is provided
      if (proximity != null) {
        url += '&location=${proximity.latitude},${proximity.longitude}'
            '&radius=50000'; // 50km radius
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          DevLogs.logError('Google Places API error: ${data['status']}');
          return [];
        }

        final results = data['results'] as List;

        return results.map((place) {
          final location = place['geometry']['location'];

          return SearchResult(
            id: place['place_id'] ?? _uuid.v4(),
            name: place['name'] ?? '',
            address: place['formatted_address'] ?? '',
            latitude: location['lat'],
            longitude: location['lng'],
            category: _getCategoryFromTypes(place['types'] as List),
            properties: place as Map<String, dynamic>,
          );
        }).toList();
      } else {
        DevLogs.logError('Failed to search places: ${response.statusCode}');
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error searching places: $e');
      return [];
    }
  }

  @override
  Future<NavigationRoute?> getDirections(LatLng origin, LatLng destination,
      {String profile = 'driving',
        List<LatLng> waypoints = const [],
        bool alternatives = false,
        String language = 'en'}) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${_getGoogleMapsMode(profile)}'
          '&language=$language'
          '&key=$_apiKey';

      // Add waypoints if any
      if (waypoints.isNotEmpty) {
        String waypointsStr = waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
        url += '&waypoints=$waypointsStr';
      }

      // Add alternatives if requested
      if (alternatives) {
        url += '&alternatives=true';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          DevLogs.logError('Google Directions API error: ${data['status']}');
          return null;
        }

        final routes = data['routes'] as List;

        if (routes.isEmpty) {
          return null;
        }

        final route = routes[0];
        final legs = route['legs'] as List;

        if (legs.isEmpty) {
          return null;
        }

        // Extract steps
        List<RouteStep> steps = [];
        double totalDistance = 0;
        double totalDuration = 0;

        for (var leg in legs) {
          totalDistance += leg['distance']['value'].toDouble();
          totalDuration += leg['duration']['value'].toDouble();

          final legSteps = leg['steps'] as List;

          for (var step in legSteps) {
            final startLocation = step['start_location'];
            final endLocation = step['end_location'];

            steps.add(RouteStep(
              instruction: _stripHtmlTags(step['html_instructions']),
              distance: step['distance']['value'].toDouble(),
              duration: step['duration']['value'].toDouble(),
              maneuver: step['maneuver'] ?? '',
              startLatitude: startLocation['lat'],
              startLongitude: startLocation['lng'],
              endLatitude: endLocation['lat'],
              endLongitude: endLocation['lng'],
            ));
          }
        }

        // Get start and end addresses
        String startAddress = legs[0]['start_address'] ?? '';
        String endAddress = legs[legs.length - 1]['end_address'] ?? '';

        // Encode polyline for the route
        String encodedPolyline = route['overview_polyline']['points'];

        return NavigationRoute(
          id: _uuid.v4(),
          distance: totalDistance,
          duration: totalDuration / 60, // Convert to minutes
          steps: steps,
          geometry: encodedPolyline,
          startLatitude: origin.latitude,
          startLongitude: origin.longitude,
          endLatitude: destination.latitude,
          endLongitude: destination.longitude,
          startAddress: startAddress,
          endAddress: endAddress,
        );
      } else {
        DevLogs.logError('Failed to get directions: ${response.statusCode}');
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error getting directions: $e');
      return null;
    }
  }

  // Get directions with alternatives
  Future<List<NavigationRoute>> getDirectionsWithAlternatives(
      LatLng origin,
      LatLng destination,
      {String profile = 'driving', String language = 'en'}) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${_getGoogleMapsMode(profile)}'
          '&alternatives=true'
          '&language=$language'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          DevLogs.logError('Google Directions API error: ${data['status']}');
          return [];
        }

        final routes = data['routes'] as List;
        List<NavigationRoute> navigationRoutes = [];

        for (var route in routes) {
          final legs = route['legs'] as List;

          if (legs.isEmpty) continue;

          // Extract steps
          List<RouteStep> steps = [];
          double totalDistance = 0;
          double totalDuration = 0;

          for (var leg in legs) {
            totalDistance += leg['distance']['value'].toDouble();
            totalDuration += leg['duration']['value'].toDouble();

            final legSteps = leg['steps'] as List;

            for (var step in legSteps) {
              final startLocation = step['start_location'];
              final endLocation = step['end_location'];

              steps.add(RouteStep(
                instruction: _stripHtmlTags(step['html_instructions']),
                distance: step['distance']['value'].toDouble(),
                duration: step['duration']['value'].toDouble(),
                maneuver: step['maneuver'] ?? '',
                startLatitude: startLocation['lat'],
                startLongitude: startLocation['lng'],
                endLatitude: endLocation['lat'],
                endLongitude: endLocation['lng'],
              ));
            }
          }

          // Get start and end addresses
          String startAddress = legs[0]['start_address'] ?? '';
          String endAddress = legs[legs.length - 1]['end_address'] ?? '';

          // Encode polyline for the route
          String encodedPolyline = route['overview_polyline']['points'];

          navigationRoutes.add(NavigationRoute(
            id: _uuid.v4(),
            distance: totalDistance,
            duration: totalDuration / 60, // Convert to minutes
            steps: steps,
            geometry: encodedPolyline,
            startLatitude: origin.latitude,
            startLongitude: origin.longitude,
            endLatitude: destination.latitude,
            endLongitude: destination.longitude,
            startAddress: startAddress,
            endAddress: endAddress,
          ));
        }

        return navigationRoutes;
      } else {
        DevLogs.logError('Failed to get directions with alternatives: ${response.statusCode}');
        throw Exception('Failed to get directions with alternatives: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error getting directions with alternatives: $e');
      return [];
    }
  }

  @override
  Future<List<LatLng>> getPreviewRoute({required List<LatLng> wayPoints}) async {
    try {
      if (wayPoints.length < 2) {
        return [];
      }

      final origin = wayPoints.first;
      final destination = wayPoints.last;

      List<LatLng> intermediatePoints = [];
      if (wayPoints.length > 2) {
        intermediatePoints = wayPoints.sublist(1, wayPoints.length - 1)
            .map((wp) => LatLng(wp.latitude, wp.longitude))
            .toList();
      }

      final route = await getDirections(
        LatLng(origin.latitude, origin.longitude),
        LatLng(destination.latitude, destination.longitude),
        waypoints: intermediatePoints,
      );

      if (route == null) {
        return [];
      }

      // Decode the polyline
      return decodePolyline(route.geometry)
          .map((latLng) => LatLng(latLng.latitude, latLng.longitude))
          .toList();
    } catch (e) {
      DevLogs.logError('Error getting preview route: $e');
      return [];
    }
  }

  @override
  Future<SearchResult?> reverseGeocode(LatLng coordinates) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${coordinates.latitude},${coordinates.longitude}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          DevLogs.logError('Google Geocoding API error: ${data['status']}');
          return null;
        }

        final results = data['results'] as List;

        if (results.isEmpty) {
          return null;
        }

        final result = results[0];

        return SearchResult(
          id: result['place_id'] ?? _uuid.v4(),
          name: _extractFeatureName(result),
          address: result['formatted_address'] ?? '',
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          properties: result as Map<String, dynamic>,
        );
      } else {
        DevLogs.logError('Failed to reverse geocode: ${response.statusCode}');
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error reverse geocoding: $e');
      return null;
    }
  }

  @override
  Future<List<NavigationRoute>> getDirectionsWithServiceLocations(
      LatLng origin, LatLng destination, List<String> serviceTypes) async {
    try {
      // First get the direct route
      NavigationRoute? directRoute = await getDirections(origin, destination);

      if (directRoute == null) {
        return [];
      }

      List<NavigationRoute> routes = [directRoute];

      // For each service type, find nearby places along the route
      for (String serviceType in serviceTypes) {
        // Decode the route polyline to get points along the route
        List<LatLng> routePoints = decodePolyline(directRoute.geometry);

        // Sample points along the route (every ~5km)
        List<LatLng> samplePoints = _sampleRoutePoints(routePoints, 5000);

        // For each sample point, search for the service
        for (LatLng point in samplePoints) {
          List<SearchResult> services = await searchPlaces(
            '$serviceType near ${point.latitude},${point.longitude}',
            proximity: point,
          );

          if (services.isNotEmpty) {
            // Take the first service location found
            SearchResult service = services.first;
            LatLng serviceLocation = LatLng(service.latitude, service.longitude);

            // Get a route that passes through this service location
            NavigationRoute? routeWithService = await getDirections(
              origin,
              destination,
              waypoints: [serviceLocation],
            );

            if (routeWithService != null) {
              // Add metadata about the service to the route
              routeWithService = NavigationRoute(
                id: routeWithService.id,
                distance: routeWithService.distance,
                duration: routeWithService.duration,
                steps: routeWithService.steps,
                geometry: routeWithService.geometry,
                startLatitude: routeWithService.startLatitude,
                startLongitude: routeWithService.startLongitude,
                endLatitude: routeWithService.endLatitude,
                endLongitude: routeWithService.endLongitude,
                startAddress: routeWithService.startAddress,
                endAddress: routeWithService.endAddress,
                serviceInfo: {
                  'id': service.id,
                  'name': service.name,
                  'address': service.address,
                  'latitude': service.latitude,
                  'longitude': service.longitude,
                  'category': service.category ?? serviceType,
                },
              );

              routes.add(routeWithService);

              // Limit to one route per service type for now
              break;
            }
          }
        }
      }

      return routes;
    } catch (e) {
      DevLogs.logError('Error getting directions with service locations: $e');
      return [];
    }
  }

  @override
  Future<NavigationRoute?> getOptimizedRoute(
      LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';

      // Add waypoints with optimization
      if (waypoints.isNotEmpty) {
        String waypointsStr = waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
        url += '&waypoints=optimize:true|$waypointsStr';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          DevLogs.logError('Google Directions API error: ${data['status']}');
          return null;
        }

        final routes = data['routes'] as List;

        if (routes.isEmpty) {
          return null;
        }

        final route = routes[0];
        final legs = route['legs'] as List;

        if (legs.isEmpty) {
          return null;
        }

        // Extract steps
        List<RouteStep> steps = [];
        double totalDistance = 0;
        double totalDuration = 0;

        for (var leg in legs) {
          totalDistance += leg['distance']['value'].toDouble();
          totalDuration += leg['duration']['value'].toDouble();

          final legSteps = leg['steps'] as List;

          for (var step in legSteps) {
            final startLocation = step['start_location'];
            final endLocation = step['end_location'];

            steps.add(RouteStep(
              instruction: _stripHtmlTags(step['html_instructions']),
              distance: step['distance']['value'].toDouble(),
              duration: step['duration']['value'].toDouble(),
              maneuver: step['maneuver'] ?? '',
              startLatitude: startLocation['lat'],
              startLongitude: startLocation['lng'],
              endLatitude: endLocation['lat'],
              endLongitude: endLocation['lng'],
            ));
          }
        }

        // Get start and end addresses
        String startAddress = legs[0]['start_address'] ?? '';
        String endAddress = legs[legs.length - 1]['end_address'] ?? '';

        // Encode polyline for the route
        String encodedPolyline = route['overview_polyline']['points'];

        return NavigationRoute(
          id: _uuid.v4(),
          distance: totalDistance,
          duration: totalDuration / 60, // Convert to minutes
          steps: steps,
          geometry: encodedPolyline,
          startLatitude: origin.latitude,
          startLongitude: origin.longitude,
          endLatitude: destination.latitude,
          endLongitude: destination.longitude,
          startAddress: startAddress,
          endAddress: endAddress,
        );
      } else {
        DevLogs.logError('Failed to get optimized route: ${response.statusCode}');
        throw Exception('Failed to get optimized route: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error getting optimized route: $e');
      return null;
    }
  }

  // Helper method to get Google Maps travel mode
  String _getGoogleMapsMode(String profile) {
    switch (profile) {
      case 'driving':
        return 'driving';
      case 'walking':
        return 'walking';
      case 'cycling':
        return 'bicycling';
      case 'transit':
        return 'transit';
      default:
        return 'driving';
    }
  }

  // Helper method to extract a category from place types
  String _getCategoryFromTypes(List types) {
    if (types.contains('gas_station')) return 'gas_station';
    if (types.contains('car_repair') || types.contains('car_dealer'))
      return 'mechanic';
    if (types.contains('car_wash')) return 'car_wash';
    if (types.contains('parking')) return 'parking';
    if (types.contains('restaurant') || types.contains('food'))
      return 'restaurant';
    if (types.contains('lodging') || types.contains('hotel')) return 'hotel';
    if (types.contains('hospital') || types.contains('health'))
      return 'hospital';
    if (types.contains('police')) return 'police';
    if (types.contains('charging_station')) return 'ev_charging';
    return 'other';
  }

  // Helper method to extract a feature name from geocoding result
  String _extractFeatureName(Map<String, dynamic> result) {
    final components = result['address_components'] as List;

    // Try to find a meaningful name component
    for (var component in components) {
      final types = component['types'] as List;
      if (types.contains('point_of_interest') ||
          types.contains('establishment') ||
          types.contains('premise')) {
        return component['long_name'];
      }
    }

    // Fallback to the first component or the formatted address
    if (components.isNotEmpty) {
      return components[0]['long_name'];
    }

    return result['formatted_address']?.split(',')[0] ?? 'Unknown Location';
  }

  // Helper method to strip HTML tags from instructions
  String _stripHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  // Helper method to decode Google polyline
  List<LatLng> decodePolyline(String encoded) {
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