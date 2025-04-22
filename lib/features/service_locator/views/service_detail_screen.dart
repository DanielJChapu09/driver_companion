import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/service_location_model.dart';
import '../controller/service_locator_controller.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceLocation service;
  final ServiceLocatorController controller = Get.find<ServiceLocatorController>();

  ServiceDetailsScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.name),
        actions: [
          Obx(() {
            bool isFavorite = controller.favoriteServices.any((s) => s.id == service.id);
            return IconButton(
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
              },
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Map showing the service location
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(service.latitude, service.longitude),
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(service.id),
                  position: LatLng(service.latitude, service.longitude),
                  infoWindow: InfoWindow(title: service.name),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),

          // Service details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildInfoRow(
                    Icons.category,
                    controller.getServiceCategories()[service.category] ?? service.category,
                  ),

                  // Rating
                  if (service.rating != null)
                    _buildRatingRow(service.rating!),

                  // Open status
                  _buildInfoRow(
                    service.isOpen ? Icons.check_circle : Icons.cancel,
                    service.isOpen ? 'Open now' : 'Closed',
                    color: service.isOpen ? Colors.green : Colors.red,
                  ),

                  // Distance
                  if (service.distance != null)
                    _buildInfoRow(
                      Icons.directions_car,
                      '${service.distance!.toStringAsFixed(1)} km away',
                    ),

                  // Duration
                  if (service.duration != null)
                    _buildInfoRow(
                      Icons.access_time,
                      '${service.duration!.toStringAsFixed(0)} min drive',
                    ),

                  // Phone number
                  if (service.phoneNumber != null && service.phoneNumber!.isNotEmpty)
                    _buildInfoRow(
                      Icons.phone,
                      service.phoneNumber!,
                      isLink: true,
                      onTap: () {
                        // Launch phone call
                      },
                    ),

                  // Website
                  if (service.website != null && service.website!.isNotEmpty)
                    _buildInfoRow(
                      Icons.language,
                      service.website!,
                      isLink: true,
                      onTap: () {
                        // Launch website
                      },
                    ),

                  // Amenities
                  if (service.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to this location
              Get.back();
              _navigateToService();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            child: const Text(
              'Navigate',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color, bool isLink = false, VoidCallback? onTap}) {
    final textWidget = Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: isLink ? Colors.blue : null,
        decoration: isLink ? TextDecoration.underline : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          isLink && onTap != null
              ? GestureDetector(onTap: onTap, child: textWidget)
              : textWidget,
        ],
      ),
    );
  }

  Widget _buildRatingRow(double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          _buildRatingStars(rating),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  void _navigateToService() {
    // This would integrate with your navigation system
    // For example: Get.toNamed('/navigation', arguments: {
    //   'destination': LatLng(service.latitude, service.longitude),
    //   'destinationName': service.name,
    // });

    // For now, just center the map on the service
    controller.mapController.value?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(service.latitude, service.longitude),
        16.0,
      ),
    );
  }
}
