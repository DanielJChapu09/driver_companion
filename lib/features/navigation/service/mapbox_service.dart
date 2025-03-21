import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:uuid/uuid.dart';
import '../model/search_result_model.dart';
import '../model/route_model.dart';

class MapboxService {
  final String _accessToken;
  final Uuid _uuid = Uuid();

  MapboxService({required String accessToken}) : _accessToken = accessToken;

  // Search for places
  Future<List<SearchResult>> searchPlaces(String query, {LatLng? proximity}) async {
    try {
      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$_accessToken';

      // Add proximity if available
      if (proximity != null) {
        url += '&proximity=${proximity.longitude},${proximity.latitude}';
      }

      // Add additional parameters
      url += '&limit=10&types=address,poi,place';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        return features.map((feature) {
          final coordinates = feature['geometry']['coordinates'] as List;
          final properties = feature['properties'] as Map<String, dynamic>? ?? {};

          // Extract place details
          String name = feature['text'] ?? '';
          String address = feature['place_name'] ?? '';

          // If name is empty, use the first part of the address
          if (name.isEmpty && address.isNotEmpty) {
            name = address.split(',').first;
          }

          return SearchResult(
            id: feature['id'] ?? _uuid.v4(),
            name: name,
            address: address,
            latitude: coordinates[1],
            longitude: coordinates[0],
            category: properties['category'],
            properties: properties,
          );
        }).toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Get directions between two points
  Future<NavigationRoute?> getDirections(
      LatLng origin, LatLng destination, {
        String profile = 'driving',
        List<LatLng> waypoints = const [],
        bool alternatives = false,
        String language = 'en',
      }) async {
    try {
      // Build coordinates string
      String coordinates = '${origin.longitude},${origin.latitude};';

      // Add waypoints if any
      for (var waypoint in waypoints) {
        coordinates += '${waypoint.longitude},${waypoint.latitude};';
      }

      coordinates += '${destination.longitude},${destination.latitude}';

      // Build URL
      String url = 'https://api.mapbox.com/directions/v5/mapbox/$profile/$coordinates';
      url += '?access_token=$_accessToken';
      url += '&geometries=polyline6';
      url += '&overview=full';
      url += '&steps=true';
      url += '&language=$language';

      if (alternatives) {
        url += '&alternatives=true';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return null;
        }

        final route = data['routes'][0];
        final legs = route['legs'] as List;

        if (legs.isEmpty) {
          return null;
        }

        // Extract steps
        List<RouteStep> steps = [];
        for (var leg in legs) {
          final legSteps = leg['steps'] as List;

          for (var step in legSteps) {
            final maneuver = step['maneuver'];
            final startCoords = maneuver['location'] as List;

            // Get end coordinates from the next step or the leg end
            List endCoords;
            if (step == legSteps.last) {
              endCoords = leg['destination_location'] as List;
            } else {
              endCoords = legSteps[legSteps.indexOf(step) + 1]['maneuver']['location'] as List;
            }

            steps.add(RouteStep(
              instruction: step['maneuver']['instruction'] ?? '',
              distance: step['distance'].toDouble(),
              duration: step['duration'].toDouble(),
              maneuver: step['maneuver']['type'] ?? '',
              startLatitude: startCoords[1],
              startLongitude: startCoords[0],
              endLatitude: endCoords[1],
              endLongitude: endCoords[0],
            ));
          }
        }

        // Get start and end addresses
        String startAddress = data['waypoints'][0]['name'] ?? '';
        String endAddress = data['waypoints'][data['waypoints'].length - 1]['name'] ?? '';

        return NavigationRoute(
          id: _uuid.v4(),
          distance: route['distance'].toDouble(),
          duration: route['duration'].toDouble(),
          steps: steps,
          geometry: route['geometry'],
          startLatitude: origin.latitude,
          startLongitude: origin.longitude,
          endLatitude: destination.latitude,
          endLongitude: destination.longitude,
          startAddress: startAddress,
          endAddress: endAddress,
        );
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  // Reverse geocode (get address from coordinates)
  Future<SearchResult?> reverseGeocode(LatLng coordinates) async {
    try {
      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/${coordinates.longitude},${coordinates.latitude}.json';
      url += '?access_token=$_accessToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        if (features.isEmpty) {
          return null;
        }

        final feature = features[0];
        final featureCoordinates = feature['geometry']['coordinates'] as List;

        return SearchResult(
          id: feature['id'] ?? _uuid.v4(),
          name: feature['text'] ?? '',
          address: feature['place_name'] ?? '',
          latitude: featureCoordinates[1],
          longitude: featureCoordinates[0],
        );
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }
}

