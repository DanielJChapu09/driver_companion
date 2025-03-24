import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../controller/service_locator_controller.dart';
import '../model/service_location_model.dart';
import '../service/service_locator_service.dart';
import 'service_detail_screen.dart';

class ServiceLocatorScreen extends StatefulWidget {
  const ServiceLocatorScreen({super.key});

  @override
  State<ServiceLocatorScreen> createState() => _ServiceLocatorScreenState();
}

class _ServiceLocatorScreenState extends State<ServiceLocatorScreen> {
  final ServiceLocatorController _controller = Get.find<ServiceLocatorController>();
  MapboxMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high
          ),
      );

      _controller.updateCurrentLocation(position);

      // Move map to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                14.0
            )
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Locator'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              _showFavoritesBottomSheet();
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              _showRecentBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _controller.searchResults.clear();
                  },
                ),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _controller.searchServicesByKeyword(value);
                } else if (value.isEmpty) {
                  _controller.searchResults.clear();
                }
              },
            ),
          ),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ServiceLocatorService.serviceCategories.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Obx(() => FilterChip(
                    label: Text(entry.value),
                    selected: _controller.selectedCategory.value == entry.key,
                    onSelected: (selected) {
                      if (selected) {
                        _controller.searchServicesByCategory(entry.key);
                      } else {
                        _controller.selectedCategory.value = '';
                        _controller.nearbyServices.clear();
                      }
                    },
                  )),
                );
              }).toList(),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                // Map view
                Obx(() {
                  final currentLocation = _controller.currentLocation.value;

                  if (currentLocation == null) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return MapboxMap(
                    accessToken: APIKeys.MAPBOXPUBLICTOKEN,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation.latitude, currentLocation.longitude),
                      zoom: 14.0,
                    ),
                    onMapCreated: (MapboxMapController controller) {
                      _mapController = controller;
                      _controller.setMapController(controller);
                    },
                    onStyleLoadedCallback: () {
                      // Add custom markers for different service types
                      _addCustomMarkerImages();
                    },
                    myLocationEnabled: true,
                    myLocationTrackingMode: MyLocationTrackingMode.Tracking,
                    onMapClick: (point, coordinates) {
                      // Hide any open bottom sheets when map is clicked
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  );
                }),

                // Loading indicator
                Obx(() {
                  if (_controller.isLoading.value) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),

                // Search results
                Obx(() {
                  if (_controller.searchResults.isNotEmpty) {
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: _controller.searchResults.length,
                          itemBuilder: (context, index) {
                            final service = _controller.searchResults[index];
                            return ListTile(
                              title: Text(service.name),
                              subtitle: Text(service.address),
                              trailing: Text(
                                '${service.distance?.toStringAsFixed(1) ?? "?"} km',
                              ),
                              onTap: () {
                                _showServiceDetails(service);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),

                // Nearby services indicator
                Obx(() {
                  if (_controller.nearbyServices.isNotEmpty) {
                    return Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_controller.nearbyServices.length} ${ServiceLocatorService.serviceCategories[_controller.selectedCategory.value] ?? ""} nearby',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _showNearbyServicesBottomSheet();
                              },
                              child: Text('View List'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }

  // Add custom marker images for different service types
  void _addCustomMarkerImages() async{
    if (_mapController == null) return;

    // Add marker images for different service types
    // In a real app, you would use actual image assets
    _mapController!.addImage(
      'gas-station',
      await _createMarkerImage(Colors.red, Icons.local_gas_station),
    );

    _mapController!.addImage(
      'car-repair',
      await _createMarkerImage(Colors.blue, Icons.build),
    );

    _mapController!.addImage(
      'car-wash',
      await _createMarkerImage(Colors.cyan, Icons.local_car_wash),
    );

    _mapController!.addImage(
      'parking',
      await _createMarkerImage(Colors.indigo, Icons.local_parking),
    );

    _mapController!.addImage(
      'restaurant',
      await _createMarkerImage(Colors.orange, Icons.restaurant),
    );

    _mapController!.addImage(
      'lodging',
      await _createMarkerImage(Colors.purple, Icons.hotel),
    );

    _mapController!.addImage(
      'hospital',
      await _createMarkerImage(Colors.green, Icons.local_hospital),
    );

    _mapController!.addImage(
      'police',
      await _createMarkerImage(Colors.blue, Icons.local_police),
    );

    _mapController!.addImage(
      'charging',
      await _createMarkerImage(Colors.teal, Icons.electrical_services),
    );

    _mapController!.addImage(
      'rest-area',
      await _createMarkerImage(Colors.brown, Icons.airline_seat_recline_normal),
    );

    _mapController!.addImage(
      'atm',
      await _createMarkerImage(Colors.green, Icons.atm),
    );

    _mapController!.addImage(
      'shop',
      await _createMarkerImage(Colors.amber, Icons.shopping_cart),
    );

    _mapController!.addImage(
      'marker',
      await _createMarkerImage(Colors.red, Icons.place),
    );
  }

  // Create a marker image with an icon
  Future<Uint8List> _createMarkerImage(Color color, IconData icon) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(48, 48);
    final paint = Paint()..color = color;

    // Draw marker background
    canvas.drawCircle(Offset(24, 24), 16, paint);

    // Draw icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 24,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        24 - textPainter.width / 2,
        24 - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await img.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  // Show service details
  void _showServiceDetails(ServiceLocation service) {
    // Add to recent services
    _controller.addServiceToRecent(service);

    // Navigate to details screen
    Get.to(() => ServiceDetailScreen(service: service));

    // Move map to service location
    if (_mapController != null) {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
              LatLng(service.latitude, service.longitude),
              16.0
          )
      );
    }
  }

  // Show nearby services bottom sheet
  void _showNearbyServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final services = _controller.nearbyServices;
              final categoryName = ServiceLocatorService.serviceCategories[_controller.selectedCategory.value] ?? "";

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Nearby $categoryName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.address),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${service.distance?.toStringAsFixed(1) ?? "?"} km'),
                              if (service.duration != null)
                                Text('${service.duration!.toStringAsFixed(0)} min'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showServiceDetails(service);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  // Show favorites bottom sheet
  void _showFavoritesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final services = _controller.favoriteServices;

              if (services.isEmpty) {
                return Center(
                  child: Text('No favorite services yet'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Favorite Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.address),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${service.distance?.toStringAsFixed(1) ?? "?"} km'),
                              if (service.duration != null)
                                Text('${service.duration!.toStringAsFixed(0)} min'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showServiceDetails(service);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  // Show recent services bottom sheet
  void _showRecentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final services = _controller.recentServices;

              if (services.isEmpty) {
                return Center(
                  child: Text('No recent services'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.address),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${service.distance?.toStringAsFixed(1) ?? "?"} km'),
                              if (service.duration != null)
                                Text('${service.duration!.toStringAsFixed(0)} min'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showServiceDetails(service);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _controller.clearRecentServices();
                        Navigator.pop(context);
                      },
                      child: Text('Clear Recent Services'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }
}

