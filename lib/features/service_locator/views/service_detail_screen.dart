import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navigation/controller/navigation_controller.dart';
import '../controller/service_locator_controller.dart';
import '../model/service_location_model.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceLocation service;
  final ServiceLocatorController _controller = Get.find<ServiceLocatorController>();

  ServiceDetailScreen({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(service.name),
              background: _buildMapPreview(),
            ),
            actions: [
              // Favorite button
              Obx(() {
                final isFavorite = _controller.favoriteServices.any((s) => s.id == service.id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    if (isFavorite) {
                      _controller.removeServiceFromFavorites(service.id);
                    } else {
                      _controller.addServiceToFavorites(service);
                    }
                  },
                );
              }),

              // Share button
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  // Share functionality would go here
                  Get.snackbar(
                    'Share',
                    'Sharing ${service.name}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  _buildInfoRow(
                    Icons.location_on,
                    service.address,
                    onTap: () {
                      _launchMaps();
                    },
                  ),

                  SizedBox(height: 16),

                  // Distance and duration
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.directions_car,
                          'Distance',
                          '${service.distance?.toStringAsFixed(1) ?? "?"} km',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.access_time,
                          'ETA',
                          service.duration != null
                              ? '${service.duration!.toStringAsFixed(0)} min'
                              : 'Unknown',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Phone number
                  if (service.phoneNumber != null)
                    _buildInfoRow(
                      Icons.phone,
                      service.phoneNumber!,
                      onTap: () {
                        _launchPhone(service.phoneNumber!);
                      },
                    ),

                  // Website
                  if (service.website != null)
                    _buildInfoRow(
                      Icons.language,
                      service.website!,
                      onTap: () {
                        _launchUrl(service.website!);
                      },
                    ),

                  SizedBox(height: 16),

                  // Status
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: service.isOpen ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      service.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Rating
                  if (service.rating != null)
                    Row(
                      children: [
                        Text(
                          'Rating: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildRatingStars(service.rating!),
                        SizedBox(width: 8),
                        Text(
                          '(${service.reviewCount ?? 0})',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Amenities
                  if (service.amenities.isNotEmpty) ...[
                    Text(
                      'Amenities',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Payment methods
                  if (service.paymentMethods.isNotEmpty) ...[
                    Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: service.paymentMethods.map((method) {
                        return Chip(
                          label: Text(method),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.directions),
                  label: Text('Directions'),
                  onPressed: () {
                    _navigateToService();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.call),
                  label: Text('Call'),
                  onPressed: service.phoneNumber != null
                      ? () => _launchPhone(service.phoneNumber!)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build map preview
  Widget _buildMapPreview() {
    return MapboxMap(
      accessToken: APIKeys.MAPBOXPUBLICTOKEN,
      initialCameraPosition: CameraPosition(
        target: LatLng(service.latitude, service.longitude),
        zoom: 15.0,
      ),
      onMapCreated: (MapboxMapController controller) {
        controller.addSymbol(
          SymbolOptions(
            geometry: LatLng(service.latitude, service.longitude),
            iconImage: 'marker',
            iconSize: 1.0,
          ),
        );
      },
      myLocationEnabled: false,
      compassEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      tiltGesturesEnabled: false,
      doubleClickZoomEnabled: false,
    );
  }

  // Build info row
  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Get.theme.primaryColor),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: onTap != null ? Get.theme.primaryColor : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  // Build info card
  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Get.theme.primaryColor, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating.ceil() && rating.floor() != rating.ceil()) {
          return Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  // Launch maps app
  void _launchMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${service.latitude},${service.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not open maps',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Launch phone app
  void _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not make call',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Launch URL
  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar(
        'Error',
        'Could not open website',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Navigate to service
  void _navigateToService() {
    Get.back();

    // Get the navigation controller
    final navigationController = Get.find<NavigationController>();

    // Get current location
    final currentLocation = _controller.currentLocation.value;
    if (currentLocation == null) {
      Get.snackbar(
        'Error',
        'Current location not available',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Get directions
    navigationController.getDirections(
      LatLng(currentLocation.latitude, currentLocation.longitude),
      LatLng(service.latitude, service.longitude),
    );
  }
}

