import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/search_result_model.dart';
import '../model/route_model.dart';

abstract class IMapsService {
  // Search for places
  Future<List<SearchResult>> searchPlaces(String query, {LatLng? proximity});

  // Get directions between two points
  Future<NavigationRoute?> getDirections(
      LatLng origin,
      LatLng destination, {
        String profile,
        List<LatLng> waypoints,
        bool alternatives,
        String language,
      });

  // Get preview route
  Future<List<LatLng>> getPreviewRoute({required List<LatLng> wayPoints});

  // Reverse geocode (get address from coordinates)
  Future<SearchResult?> reverseGeocode(LatLng coordinates);

  // Get directions with service locations along route
  Future<List<NavigationRoute>> getDirectionsWithServiceLocations(
      LatLng origin,
      LatLng destination,
      List<String> serviceTypes,
      );

  // Get optimized route with multiple waypoints
  Future<NavigationRoute?> getOptimizedRoute(
      LatLng origin,
      LatLng destination,
      List<LatLng> waypoints,
      );
}
