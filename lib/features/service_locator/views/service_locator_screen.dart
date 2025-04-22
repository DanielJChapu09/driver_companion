import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../../../firebase_options.dart';
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
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Uint8List> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkerImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high
        ),
      );

      _controller.updateCurrentLocation(position);

      // Move map to current location
      if (_mapController != null) {
        _mapController.move(
            latlong2.LatLng(position.latitude, position.longitude),
            14.0
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Create marker images for different service types
  Future<void> _createMarkerImages() async {
    final serviceTypes = {
      'gas-station': Colors.red,
      'car-repair': Colors.blue,
      'car-wash': Colors.cyan,
      'parking': Colors.indigo,
      'restaurant': Colors.orange,
      'lodging': Colors.purple,
      'hospital': Colors.green,
      'police': Colors.blue,
      'charging': Colors.teal,
      'rest-area': Colors.brown,
      'atm': Colors.green,
      'shop': Colors.amber,
      'marker': Colors.red,
    };

    final iconMap = {
      'gas-station': Icons.local_gas_station,
      'car-repair': Icons.build,
      'car-wash': Icons.local_car_wash,
      'parking': Icons.local_parking,
      'restaurant': Icons.restaurant,
      'lodging': Icons.hotel,
      'hospital': Icons.local_hospital,
      'police': Icons.local_police,
      'charging': Icons.electrical_services,
      'rest-area': Icons.airline_seat_recline_normal,
      'atm': Icons.atm,
      'shop': Icons.shopping_cart,
      'marker': Icons.place,
    };

    for (var entry in serviceTypes.entries) {
      _markerIcons[entry.key] = await _createMarkerImage(
          entry.value,
          iconMap[entry.key] ?? Icons.place
      );
    }
  }

  // Create a marker image with an icon
  Future<Uint8List> _createMarkerImage(Color color, IconData icon) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(48, 48);
    final paint = Paint()..color = color;

    // Draw marker background
    canvas.drawCircle(const Offset(24, 24), 16, paint);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Locator'),
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
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: latlong2.LatLng(currentLocation.latitude, currentLocation.longitude),
                      initialZoom: 14.0,
                      onTap: (tapPosition, point) {
                        // Hide any open bottom sheets when map is clicked
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${APIKeys.MAPBOXPUBLICTOKEN}',
                        additionalOptions: {
                          'accessToken': APIKeys.MAPBOXPUBLICTOKEN
                        },
                      ),

                      // Current location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 20,
                            height: 20,
                            point: latlong2.LatLng(currentLocation.latitude, currentLocation.longitude),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 4,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Service location markers
                      MarkerLayer(
                        markers: _buildServiceMarkers(),
                      ),
                    ],
                  );
                }),

                // Loading indicator
                Obx(() {
                  if (_controller.isLoading.value) {
                    return Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
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
                    return const SizedBox.shrink();
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_controller.nearbyServices.length} ${ServiceLocatorService.serviceCategories[_controller.selectedCategory.value] ?? ""} nearby',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _showNearbyServicesBottomSheet();
                              },
                              child: const Text('View List'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // Build service markers for the map
  List<Marker> _buildServiceMarkers() {
    List<Marker> markers = [];

    // Add markers for nearby services
    for (var service in _controller.nearbyServices) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: latlong2.LatLng(service.latitude, service.longitude),
          child: GestureDetector(
            onTap: () => _showServiceDetails(service),
            child: _getMarkerWidget(service.category),
          ),
        ),
      );
    }

    return markers;
  }

  // Get marker widget based on service category
  Widget _getMarkerWidget(String category) {
    IconData iconData;
    Color color;

    switch (category) {
      case 'gas-station':
        iconData = Icons.local_gas_station;
        color = Colors.red;
        break;
      case 'car-repair':
        iconData = Icons.build;
        color = Colors.blue;
        break;
      case 'car-wash':
        iconData = Icons.local_car_wash;
        color = Colors.cyan;
        break;
      case 'parking':
        iconData = Icons.local_parking;
        color = Colors.indigo;
        break;
      case 'restaurant':
        iconData = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'lodging':
        iconData = Icons.hotel;
        color = Colors.purple;
        break;
      case 'hospital':
        iconData = Icons.local_hospital;
        color = Colors.green;
        break;
      case 'police':
        iconData = Icons.local_police;
        color = Colors.blue;
        break;
      case 'charging':
        iconData = Icons.electrical_services;
        color = Colors.teal;
        break;
      case 'rest-area':
        iconData = Icons.airline_seat_recline_normal;
        color = Colors.brown;
        break;
      case 'atm':
        iconData = Icons.atm;
        color = Colors.green;
        break;
      case 'shop':
        iconData = Icons.shopping_cart;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.place;
        color = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  // Show service details
  void _showServiceDetails(ServiceLocation service) {
    // Add to recent services
    _controller.addServiceToRecent(service);

    // Navigate to details screen
    Get.to(() => ServiceDetailScreen(service: service));

    // Move map to service location
    _mapController.move(
        latlong2.LatLng(service.latitude, service.longitude),
        16.0
    );
  }

  // Show nearby services bottom sheet
  void _showNearbyServicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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
                      style: const TextStyle(
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
                          leading: _getMarkerWidget(service.category),
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
      shape: const RoundedRectangleBorder(
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
                return const Center(
                  child: Text('No favorite services yet'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Favorite Services',
                      style: const TextStyle(
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
                          leading: _getMarkerWidget(service.category),
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
      shape: const RoundedRectangleBorder(
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
                return const Center(
                  child: Text('No recent services'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Services',
                      style: const TextStyle(
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
                          leading: _getMarkerWidget(service.category),
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
                      child: const Text('Clear Recent Services'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
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