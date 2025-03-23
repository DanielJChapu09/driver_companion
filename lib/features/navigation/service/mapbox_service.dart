import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/core/utils/logs.dart';
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
      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
          '?access_token=$_accessToken'
          '&limit=10'
          '&types=address,poi,place'
          '&country=zw'  // Restrict to Zimbabwe
          '&autocomplete=true'  // Improve search results
          '&bbox=25.237, -22.417, 33.048, -15.609'; // Zimbabwe's bounding box (approx)

      // Add proximity if available
      if (proximity != null) {
        url += '&proximity=${proximity.longitude},${proximity.latitude}';
      }

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
        DevLogs.logError('Failed to search places: ${response.statusCode}');
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error searching places: $e');
      return [];
    }
  }

  // Get directions between two points with optional waypoints and alternatives
  Future<NavigationRoute?> getDirections(LatLng origin, LatLng destination, {String profile = 'driving', List<LatLng> waypoints = const [], bool alternatives = false,  String language = 'en',}) async {
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
      url += '&voice_instructions=true';
      url += '&banner_instructions=true';

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
              // Check if destination_location exists
              if (leg.containsKey('destination_location') && leg['destination_location'] != null) {
                endCoords = leg['destination_location'] as List;
              } else {
                // Fallback to destination coordinates
                endCoords = [destination.longitude, destination.latitude];
              }
            } else {
              final nextStep = legSteps[legSteps.indexOf(step) + 1];
              if (nextStep.containsKey('maneuver') &&
                  nextStep['maneuver'] != null &&
                  nextStep['maneuver'].containsKey('location') &&
                  nextStep['maneuver']['location'] != null) {
                endCoords = nextStep['maneuver']['location'] as List;
              } else {
                // Fallback in case the next step doesn't have location
                endCoords = [destination.longitude, destination.latitude];
              }
            }

            steps.add(RouteStep(
              instruction: step['maneuver']['instruction'] ?? '',
              distance: step['distance']?.toDouble() ?? 0.0,
              duration: step['duration']?.toDouble() ?? 0.0,
              maneuver: step['maneuver']['type'] ?? '',
              startLatitude: startCoords[1],
              startLongitude: startCoords[0],
              endLatitude: endCoords[1],
              endLongitude: endCoords[0],
            ));
          }
        }

        // Get start and end addresses
        String startAddress = '';
        String endAddress = '';

        if (data.containsKey('waypoints') && data['waypoints'] != null && data['waypoints'] is List && data['waypoints'].isNotEmpty) {
          startAddress = data['waypoints'][0]['name'] ?? '';
          if (data['waypoints'].length > 1) {
            endAddress = data['waypoints'][data['waypoints'].length - 1]['name'] ?? '';
          }
        }

        return NavigationRoute(
          id: _uuid.v4(),
          distance: route['distance']?.toDouble() ?? 0.0,
          duration: route['duration']?.toDouble() ?? 0.0,
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
        DevLogs.logError('Failed to get directions: ${response.statusCode}');
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      DevLogs.logError('Error getting directions: $e');
      return null;
    }
  }

  // Reverse geocode (get address from coordinates)
  Future<SearchResult?> reverseGeocode(LatLng coordinates) async {
    try {


      String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/${coordinates.longitude},${coordinates.latitude}.json';
      url += '?access_token=$_accessToken';
      //url += '&types=address,poi,place';
      // url += '&limit=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;

        DevLogs.logWarning('Tapped POINT: Latitude ${coordinates.latitude} Longitude ${coordinates.longitude}');

        DevLogs.logInfo('Reverse geocode response: $data');

        if (features.isEmpty) {
          return null;
        }

        final feature = features[0];
        final featureCoordinates = data['query'] as List;
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
          latitude: featureCoordinates[1],
          longitude: featureCoordinates[0],
          category: properties['category'],
          properties: properties,
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

  Future<List<latlong2.LatLng>> getPreviewRoute({required List<latlong2.LatLng> wayPoints}) async {
    try{
      final coordinates = wayPoints.map((waypoint) => "${waypoint.longitude},${waypoint.latitude}").join(';');

      final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/$coordinates?geometries=geojson&access_token=$_accessToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];
        final geometry = route['geometry'];
        final coordinates = geometry['coordinates'] as List;

        List<latlong2.LatLng> routePoints = coordinates.map((coord) => latlong2.LatLng(coord[1], coord[0])).toList();

        return routePoints;
      } else {
        DevLogs.logError('Failed to get preview route: ${response.statusCode}');
        return [];
      }
    }

    catch (e){
      DevLogs.logError('Error getting preview route: $e');
      return [];
    }
  }
}