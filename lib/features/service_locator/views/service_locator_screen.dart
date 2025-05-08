import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/service_locator/views/service_detail_screen.dart';
import '../controller/service_locator_controller.dart';
import '../model/service_location_model.dart';
import '../../../widgets/circular_loader/circular_loader.dart';

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

    // Add a small delay to ensure the map is properly initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (controller.nearbyServices.isNotEmpty) {
        controller.searchServicesByCategory(controller.selectedCategory.value);
      }
    });
  }

  // Add a method to refresh markers when returning to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when returning to the screen
    if (controller.mapController.value != null) {
      if (controller.nearbyServices.isNotEmpty) {
        controller.addServiceMarkersToMap(controller.nearbyServices);
      } else if (controller.searchResults.isNotEmpty) {
        controller.addServiceMarkersToMap(controller.searchResults);
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Replace the entire build method with this enhanced version
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Services'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            tooltip: 'Favorites',
            onPressed: () {
              _showFavoritesBottomSheet();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Recent',
            onPressed: () {
              _showRecentServicesBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with enhanced styling
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for services...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    controller.searchResults.clear();
                  },
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const CustomLoader(message: "Searching services");
                    },
                  );

                  controller.searchServicesByKeyword(value).then((_) {
                    // Close loading dialog
                    Navigator.pop(context);

                    // Show results bottom sheet
                    if (controller.searchResults.isNotEmpty) {
                      _showServicesBottomSheet(controller.searchResults);
                    } else {
                      // Show no results found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No services found for "$value"'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.redAccent,
                          action: SnackBarAction(
                            label: 'OK',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  });
                }
              },
            ),
          ),

          // Category chips with enhanced styling
          Container(
            color: primaryColor,
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryChips(),
          ),

          // Map and results with enhanced styling
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
                  myLocationButtonEnabled: false, // We'll add our own button
                  mapToolbarEnabled: true,
                  markers: controller.markers,
                  onMapCreated: (GoogleMapController mapController) {
                    controller.setMapController(mapController);

                    // Set map style based on theme
                    if (isDarkMode) {
                      mapController.setMapStyle('''
                        [
                          {
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#242f3e"
                              }
                            ]
                          },
                          {
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#746855"
                              }
                            ]
                          },
                          {
                            "elementType": "labels.text.stroke",
                            "stylers": [
                              {
                                "color": "#242f3e"
                              }
                            ]
                          },
                          {
                            "featureType": "administrative.locality",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#d59563"
                              }
                            ]
                          },
                          {
                            "featureType": "poi",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#d59563"
                              }
                            ]
                          },
                          {
                            "featureType": "poi.park",
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#263c3f"
                              }
                            ]
                          },
                          {
                            "featureType": "poi.park",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#6b9a76"
                              }
                            ]
                          },
                          {
                            "featureType": "road",
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#38414e"
                              }
                            ]
                          },
                          {
                            "featureType": "road",
                            "elementType": "geometry.stroke",
                            "stylers": [
                              {
                                "color": "#212a37"
                              }
                            ]
                          },
                          {
                            "featureType": "road",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#9ca5b3"
                              }
                            ]
                          },
                          {
                            "featureType": "road.highway",
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#746855"
                              }
                            ]
                          },
                          {
                            "featureType": "road.highway",
                            "elementType": "geometry.stroke",
                            "stylers": [
                              {
                                "color": "#1f2835"
                              }
                            ]
                          },
                          {
                            "featureType": "road.highway",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#f3d19c"
                              }
                            ]
                          },
                          {
                            "featureType": "transit",
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#2f3948"
                              }
                            ]
                          },
                          {
                            "featureType": "transit.station",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#d59563"
                              }
                            ]
                          },
                          {
                            "featureType": "water",
                            "elementType": "geometry",
                            "stylers": [
                              {
                                "color": "#17263c"
                              }
                            ]
                          },
                          {
                            "featureType": "water",
                            "elementType": "labels.text.fill",
                            "stylers": [
                              {
                                "color": "#515c6d"
                              }
                            ]
                          },
                          {
                            "featureType": "water",
                            "elementType": "labels.text.stroke",
                            "stylers": [
                              {
                                "color": "#17263c"
                              }
                            ]
                          }
                        ]
                      ''');
                    }
                  },
                )),

                // Map controls
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      // My location button
                      _buildMapButton(
                        icon: Icons.my_location,
                        tooltip: 'My Location',
                        onPressed: () {
                          if (controller.currentLocation.value != null && controller.mapController.value != null) {
                            controller.mapController.value!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  controller.currentLocation.value!.latitude,
                                  controller.currentLocation.value!.longitude,
                                ),
                                16.0,
                              ),
                            );

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Centered on your location'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: primaryColor,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Zoom in button
                      _buildMapButton(
                        icon: Icons.add,
                        tooltip: 'Zoom In',
                        onPressed: () {
                          if (controller.mapController.value != null) {
                            controller.mapController.value!.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Zoom out button
                      _buildMapButton(
                        icon: Icons.remove,
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          if (controller.mapController.value != null) {
                            controller.mapController.value!.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Refresh button
                      _buildMapButton(
                        icon: Icons.refresh,
                        tooltip: 'Refresh',
                        onPressed: () {
                          if (controller.selectedCategory.value.isNotEmpty) {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const CustomLoader(message: "Refreshing services");
                              },
                            );

                            controller.searchServicesByCategory(controller.selectedCategory.value).then((_) {
                              // Close loading dialog
                              Navigator.of(context, rootNavigator: true).pop();

                              // Show feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Services refreshed'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: primaryColor,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Loading indicator
                Obx(() => controller.isLoading.value
                    ? Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
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
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          controller.errorMessage.value = '';
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('DISMISS'),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink()),

                // Legend
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800]!.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Your Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        if (controller.selectedCategory.value.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(controller.selectedCategory.value),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                controller.getServiceCategories()[controller.selectedCategory.value] ?? 'Service',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (controller.nearbyServices.isNotEmpty) {
            _showServicesBottomSheet(controller.nearbyServices);
          } else if (controller.selectedCategory.value.isEmpty) {
            // Show category selection hint
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Select a category to find services'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: primaryColor,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          } else {
            // Show no services found
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No ${controller.getServiceCategories()[controller.selectedCategory.value]} found nearby'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.redAccent,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        label: const Text('Show List'),
        icon: const Icon(Icons.list),
        backgroundColor: primaryColor,
      ),
    );
  }

  // Helper method to build a map button
  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: onPressed,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // Helper method to get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'gas_station':
        return Colors.red;
      case 'mechanic':
        return Colors.orange;
      case 'car_wash':
        return Colors.blue;
      case 'parking':
        return Colors.green;
      case 'restaurant':
        return Colors.amber;
      case 'hotel':
        return Colors.purple;
      case 'hospital':
        return Colors.redAccent;
      case 'police':
        return Colors.indigo;
      case 'ev_charging':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Enhanced category chips
  Widget _buildCategoryChips() {
    final categories = controller.getServiceCategories();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Obx(() {
              final isSelected = controller.selectedCategory.value == entry.key;
              return FilterChip(
                label: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(entry.value),
                  ],
                ),
                selected: isSelected,
                checkmarkColor: Colors.white,
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: isSelected ? 4 : 0,
                pressElevation: 4,
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const CustomLoader(message: "Finding services");
                      },
                    );

                    controller.searchServicesByCategory(entry.key).then((_) {
                      // Close loading dialog
                      Navigator.of(context, rootNavigator: true).pop();

                      // Force refresh markers
                      if (controller.mapController.value != null && controller.nearbyServices.isNotEmpty) {
                        controller.addServiceMarkersToMap(controller.nearbyServices);
                      }

                      // Show results bottom sheet
                      if (controller.nearbyServices.isNotEmpty) {
                        _showServicesBottomSheet(controller.nearbyServices);
                      } else {
                        // Show no results found
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No ${entry.value} found nearby'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.redAccent,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    });
                  } else {
                    controller.selectedCategory.value = '';
                    controller.nearbyServices.clear();

                    // Clear markers except user location
                    if (controller.mapController.value != null) {
                      Set<Marker> userMarker = controller.markers
                          .where((m) => m.markerId.value == 'user_location')
                          .toSet();
                      controller.markers.value = userMarker;
                    }
                  }
                },
              );
            }),
          );
        }).toList(),
      ),
    );
  }

  // Enhanced search results list
  Widget _buildSearchResultsList() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.searchResults.length} Results',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.searchResults.clear();
                      searchController.clear();
                    },
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: ListView.builder(
                itemCount: controller.searchResults.length,
                itemBuilder: (context, index) {
                  final service = controller.searchResults[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(service.category).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getServiceIcon(service.category),
                        color: _getCategoryColor(service.category),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      service.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      service.address,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: service.distance != null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${service.distance!.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (service.duration != null)
                          Text(
                            '${service.duration!.toStringAsFixed(0)} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                      ],
                    )
                        : null,
                    onTap: () {
                      Get.to(

                          ()=> ServiceDetailsScreen(service: service),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get service icon
  IconData _getServiceIcon(String category) {
    switch (category) {
      case 'gas_station':
        return Icons.local_gas_station;
      case 'mechanic':
        return Icons.build;
      case 'car_wash':
        return Icons.local_car_wash;
      case 'parking':
        return Icons.local_parking;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'ev_charging':
        return Icons.electrical_services;
      default:
        return Icons.place;
    }
  }

  // Enhanced services bottom sheet
  void _showServicesBottomSheet(List<ServiceLocation> services) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getServiceIcon(controller.selectedCategory.value),
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${services.length} Services Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              height: 1,
            ),

            // Services list
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(service.category).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getServiceIcon(service.category),
                        color: _getCategoryColor(service.category),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      service.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.address,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (service.rating != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    service.rating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: service.isOpen
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                service.isOpen ? 'Open' : 'Closed',
                                style: TextStyle(
                                  color: service.isOpen ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: service.distance != null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${service.distance!.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (service.duration != null)
                          Text(
                            '${service.duration!.toStringAsFixed(0)} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                      ],
                    )
                        : null,
                    onTap: () {
                      Get.back();
                      // Navigate to service details screen
                      Get.to(() => ServiceDetailsScreen(service: service));

                      // Center map on the selected service
                      controller.mapController.value?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(service.latitude, service.longitude),
                          16.0,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Enhanced favorites bottom sheet
  void _showFavoritesBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Favorite Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Favorites list
            Expanded(
              child: Obx(() {
                if (controller.favoriteServices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: isDarkMode ? Colors.white30 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite services yet',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on a service to add it to favorites',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.favoriteServices.length,
                  itemBuilder: (context, index) {
                    final service = controller.favoriteServices[index];
                    return Dismissible(
                      key: Key(service.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        controller.removeServiceFromFavorites(service.id);
                      },
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(service.category).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getServiceIcon(service.category),
                            color: _getCategoryColor(service.category),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          service.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          service.address,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: service.distance != null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${service.distance!.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (service.duration != null)
                              Text(
                                '${service.duration!.toStringAsFixed(0)} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                          ],
                        )
                            : null,
                        onTap: () {
                          Get.back();

                          Get.to(() => ServiceDetailsScreen(service: service));
                        },
                      ),
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

  // Enhanced recent services bottom sheet
  void _showRecentServicesBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Get.back();
                    // Show confirmation dialog
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text('Are you sure you want to clear all recent services?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              controller.clearRecentServices();
                            },
                            child: const Text('CLEAR'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recent services list
            Expanded(
              child: Obx(() {
                if (controller.recentServices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: isDarkMode ? Colors.white30 : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recent services',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Services you view will appear here',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.recentServices.length,
                  itemBuilder: (context, index) {
                    final service = controller.recentServices[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(service.category).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getServiceIcon(service.category),
                          color: _getCategoryColor(service.category),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        service.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        service.address,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: service.distance != null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${service.distance!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          if (service.duration != null)
                            Text(
                              '${service.duration!.toStringAsFixed(0)} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                        ],
                      )
                          : null,
                      onTap: () {
                        Get.back();
                        Get.to(() => ServiceDetailsScreen(service: service));
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
