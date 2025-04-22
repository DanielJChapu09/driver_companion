import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/navigation_controller.dart';
import '../model/route_model.dart';

class RouteSelectionScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationName;

  const RouteSelectionScreen({
    Key? key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  bool _darkMode = false;
  GoogleMapController? _mapController;
  int _selectedRouteIndex = 0;
  List<String> _selectedServiceTypes = [];

  @override
  void initState() {
    super.initState();

    // Check system brightness to set initial dark mode
    final brightness = MediaQuery.of(Get.context!).platformBrightness;
    _darkMode = brightness == Brightness.dark;

    // Enable alternative routes
    controller.showAlternativeRoutes.value = true;

    // Get directions
    _getDirections();
  }

  Future<void> _getDirections() async {
    await controller.getDirections(widget.origin, widget.destination);
  }

  void _updateMapStyle() {
    if (_mapController == null) return;

    String mapStyle = _darkMode
        ? '''
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
          }
        ]
        '''
        : '[]'; // Default style

    _mapController!.setMapStyle(mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${widget.destinationName}'),
        backgroundColor: _darkMode ? Colors.black : Colors.white,
        foregroundColor: _darkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
                _updateMapStyle();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (widget.origin.latitude + widget.destination.latitude) / 2,
                  (widget.origin.longitude + widget.destination.longitude) / 2,
                ),
                zoom: 12.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMapStyle();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              trafficEnabled: controller.showTraffic.value,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
            );
          }),

          // Service type selection
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                children: controller.getServiceTypes().map((serviceType) {
                  final isSelected = _selectedServiceTypes.contains(serviceType['id']);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        serviceType['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (_darkMode ? Colors.white : Colors.black),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      backgroundColor: _darkMode ? Colors.grey[800] : Colors.grey[200],
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServiceTypes.add(serviceType['id']!);
                          } else {
                            _selectedServiceTypes.remove(serviceType['id']!);
                          }
                        });

                        // Update controller
                        controller.selectedServiceTypes.value = _selectedServiceTypes;

                        // Refresh routes
                        _getDirections();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Routes list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Available Routes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    List<NavigationRoute> routes = [
                      if (controller.currentRoute.value != null)
                        controller.currentRoute.value!,
                      ...controller.alternativeRoutes,
                    ];

                    if (routes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No routes available',
                          style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }

                    return Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          NavigationRoute route = routes[index];
                          bool isSelected = index == _selectedRouteIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRouteIndex = index;
                              });

                              if (index > 0) {
                                controller.switchToAlternativeRoute(index - 1);
                              }
                            },
                            child: Container(
                              width: 200,
                              margin: EdgeInsets.only(right: 16, bottom: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (_darkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
                                    : (_darkMode ? Colors.grey[800] : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        index == 0 ? Icons.star : Icons.alt_route,
                                        color: isSelected ? Colors.blue : (_darkMode ? Colors.white70 : Colors.black54),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        index == 0 ? 'Fastest Route' : 'Alternative ${index}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.blue : (_darkMode ? Colors.white : Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    _formatDuration(route.duration),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _darkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatDistance(route.distance),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _darkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  Spacer(),
                                  if (_hasServiceLocation(route))
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_gas_station,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Passes by services',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: EdgeInsets.all(16).copyWith(top: 0),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.toNamed('/navigation');
                        controller.startNavigation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start Navigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasServiceLocation(NavigationRoute route) {
    // In a real app, you would check if this route passes by any service locations
    // For now, we'll just return true for alternative routes
    return route != controller.currentRoute.value;
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.toInt()} min';
    } else {
      int hours = (minutes / 60).floor();
      int mins = (minutes % 60).floor();
      return '$hours h ${mins > 0 ? '$mins min' : ''}';
    }
  }
}
