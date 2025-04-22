import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/service_location_model.dart';

/// Interface for service repository
abstract class IServiceRepository {
  /// Search for services by category
  Future<List<ServiceLocation>> searchServicesByCategory(
      String category,
      LatLng currentLocation, {
        double radiusKm = 10.0,
      });

  /// Search for services by keyword
  Future<List<ServiceLocation>> searchServicesByKeyword(
      String keyword,
      LatLng currentLocation, {
        double radiusKm = 10.0,
      });

  /// Get details for a specific service
  Future<ServiceLocation?> getServiceDetails(
      String serviceId,
      LatLng currentLocation,
      );

  /// Add a service to favorites
  Future<bool> addServiceToFavorites(ServiceLocation service);

  /// Remove a service from favorites
  Future<bool> removeServiceFromFavorites(String serviceId);

  /// Get all favorite services
  Future<List<ServiceLocation>> getFavoriteServices(LatLng currentLocation);

  /// Add a service to recent
  Future<bool> addServiceToRecent(ServiceLocation service);

  /// Get recent services
  Future<List<ServiceLocation>> getRecentServices(LatLng currentLocation);

  /// Clear recent services
  Future<bool> clearRecentServices();

  /// Get services along a route
  Future<List<ServiceLocation>> getServicesAlongRoute(
      String category,
      List<LatLng> routePoints, {
        double bufferDistanceKm = 1.0,
      });

  /// Get available service categories
  Map<String, String> getServiceCategories();
}
