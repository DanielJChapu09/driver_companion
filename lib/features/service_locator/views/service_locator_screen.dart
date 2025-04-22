import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import '../controller/service_locator_controller.dart';
import '../model/service_location_model.dart';

class ServiceLocatorScreen extends StatefulWidget {
  final String apiKey;

  const ServiceLocatorScreen({
    super.key,
    required this.apiKey,
  });

  @override
  State<ServiceLocatorScreen> createState() => _ServiceLocatorScreenState();
}

class _ServiceLocatorScreenState extends State<ServiceLocatorScreen> {
  late ServiceLocatorController controller;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ServiceLocatorController(apiKey: widget.apiKey));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              _showFavoritesBottomSheet();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showRecentServicesBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.searchResults.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  controller.searchServicesByKeyword(value);
                }
              },
            ),
          ),

          // Category chips
          _buildCategoryChips(),

          // Map and results
          Expanded(
            child: Stack(
              children: [
                // Google Map
                Obx(() => GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.currentLocation.value != null
                        ? LatLng(
                      controller.currentLocation.value!.latitude,
                      controller.currentLocation.value!.longitude,
                    )
                        : const LatLng(0, 0), // Default position
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled: true,
                  markers: controller.markers,
                  onMapCreated: (GoogleMapController mapController) {
                    controller.setMapController(mapController);
                  },
                )),

                // Loading indicator
                Obx(() => controller.isLoading.value
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : const SizedBox.shrink()),

                // Search results
                Obx(() => controller.searchResults.isNotEmpty
                    ? _buildSearchResultsList()
                    : const SizedBox.shrink()),

                // Error message
                Obx(() => controller.errorMessage.value.isNotEmpty
                    ? Container(
                  color: Colors.red.withOpacity(0.8),
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.all(8.0),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
                    : const SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = controller.getServiceCategories();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() => FilterChip(
              label: Text(entry.value),
              selected: controller.selectedCategory.value == entry.key,
              onSelected: (selected) {
                if (selected) {
                  controller.searchServicesByCategory(entry.key);
                } else {
                  controller.selectedCategory.value = '';
                  controller.nearbyServices.clear();
                }
              },
            )),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        color: Colors.white,
        child: ListView.builder(
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final service = controller.searchResults[index];
            return ListTile(
              title: Text(service.name),
              subtitle: Text(service.address),
              trailing: Text(
                service.distance != null
                    ? '${service.distance!.toStringAsFixed(1)} km'
                    : '',
              ),
              onTap: () {
                _showServiceDetails(service);
              },
            );
          },
        ),
      ),
    );
  }

  void _showServiceDetails(ServiceLocation service) async {
    // Add to recent services
    controller.addServiceToRecent(service);

    // Check if service is in favorites
    bool isFavorite = controller.favoriteServices.any((s) => s.id == service.id);

    // Show bottom sheet with service details
    await Get.bottomSheet(
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    if (isFavorite) {
                      controller.removeServiceFromFavorites(service.id);
                    } else {
                      controller.addServiceToFavorites(service);
                    }
                    Get.back();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(service.address),
            if (service.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${service.rating!.toStringAsFixed(1)}'),
                ],
              ),
            ],
            if (service.isOpen) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Open now'),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text('Closed'),
                ],
              ),
            ],
            if (service.distance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 16),
                  const SizedBox(width: 4),
                  Text('${service.distance!.toStringAsFixed(1)} km away'),
                ],
              ),
            ],
            if (service.duration != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text('${service.duration!.toStringAsFixed(0)} min drive'),
                ],
              ),
            ],
            if (service.phoneNumber != null && service.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Text(service.phoneNumber!),
                ],
              ),
            ],
            if (service.website != null && service.website!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 4),
                  Text(service.website!, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to this location
                  Get.back();
                  _navigateToService(service);
                },
                child: const Text('Navigate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToService(ServiceLocation service) {
    // This would integrate with your navigation system
    // For example: Get.toNamed('/navigation', arguments: {
    //   'destination': LatLng(service.latitude, service.longitude),
    //   'destinationName': service.name,
    // });

    DevLogs.logInfo('Navigating to ${service.name}');

    // For now, just center the map on the service
    controller.mapController.value?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(service.latitude, service.longitude),
        16.0,
      ),
    );
  }

  void _showFavoritesBottomSheet() {
    Get.bottomSheet(
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Favorite Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.favoriteServices.isEmpty) {
                  return const Center(
                    child: Text('No favorite services yet'),
                  );
                }

                return ListView.builder(
                  itemCount: controller.favoriteServices.length,
                  itemBuilder: (context, index) {
                    final service = controller.favoriteServices[index];
                    return ListTile(
                      title: Text(service.name),
                      subtitle: Text(service.address),
                      trailing: Text(
                        service.distance != null
                            ? '${service.distance!.toStringAsFixed(1)} km'
                            : '',
                      ),
                      onTap: () {
                        Get.back();
                        _showServiceDetails(service);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showRecentServicesBottomSheet() {
    Get.bottomSheet(
      Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.clearRecentServices();
                    Get.back();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.recentServices.isEmpty) {
                  return const Center(
                    child: Text('No recent services'),
                  );
                }

                return ListView.builder(
                  itemCount: controller.recentServices.length,
                  itemBuilder: (context, index) {
                    final service = controller.recentServices[index];
                    return ListTile(
                      title: Text(service.name),
                      subtitle: Text(service.address),
                      trailing: Text(
                        service.distance != null
                            ? '${service.distance!.toStringAsFixed(1)} km'
                            : '',
                      ),
                      onTap: () {
                        Get.back();
                        _showServiceDetails(service);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}
