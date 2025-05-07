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
    super.key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  bool _darkMode = false;
  GoogleMapController? _mapController;
  String? _activeServiceType;
  bool _showServicesList = false;
  bool _showRouteComparison = false;

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

  void _onServiceSelected(String serviceType) async {
    setState(() {
      _activeServiceType = serviceType;
      _showServicesList = false;
    });

    // Get directions with the selected service
    await controller.getDirectionsWithService(widget.origin, widget.destination, serviceType);
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
          IconButton(
            icon: Icon(Icons.compare_arrows),
            onPressed: () {
              setState(() {
                _showRouteComparison = !_showRouteComparison;
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
                this.controller.setMapController(controller);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              trafficEnabled: controller.showTraffic.value,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              polylines: controller.polylines.value,
              markers: controller.markers.value,
            );
          }),

          // Route optimization explanation banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Showing 3 alternative routes - optimal route highlighted',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service type selection (positioned below the explanation banner)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Container(
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
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showServicesList = !_showServicesList;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        color: _darkMode ? Colors.white : Colors.black,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _activeServiceType != null
                            ? 'Service: ${_getServiceName(_activeServiceType!)}'
                            : 'Add service to route (optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        _showServicesList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: _darkMode ? Colors.white : Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Service list dropdown
          if (_showServicesList)
            Positioned(
              top: 134,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: _darkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.getServiceTypes().length,
                  itemBuilder: (context, index) {
                    final serviceType = controller.getServiceTypes()[index];
                    final isSelected = _activeServiceType == serviceType['id'];

                    return ListTile(
                      leading: Icon(
                        _getServiceIcon(serviceType['id']!),
                        color: isSelected ? Colors.blue : (_darkMode ? Colors.white70 : Colors.black54),
                      ),
                      title: Text(
                        serviceType['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : (_darkMode ? Colors.white : Colors.black),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        _onServiceSelected(serviceType['id']!);
                      },
                      tileColor: isSelected
                          ? (_darkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
                          : Colors.transparent,
                    );
                  },
                ),
              ),
            ),

          // Route comparison view (full screen overlay when active)
          if (_showRouteComparison)
            _buildRouteComparisonView(),

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
                        Spacer(),
                        TextButton.icon(
                          icon: Icon(Icons.compare_arrows, size: 16),
                          label: Text('Compare'),
                          onPressed: () {
                            setState(() {
                              _showRouteComparison = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 8),
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
                          bool isSelected = index == controller.selectedRouteIndex.value;
                          bool isOptimal = index == 0 && !route.hasServiceInfo;

                          return GestureDetector(
                            onTap: () {
                              controller.switchToRoute(index);
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
                                        isOptimal
                                            ? (isSelected ? Icons.check_circle : Icons.star)
                                            : (route.hasServiceInfo ? Icons.local_gas_station : Icons.alt_route),
                                        color: isSelected ? Colors.blue : (_darkMode ? Colors.white70 : Colors.black54),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isOptimal
                                              ? 'Optimal Route'
                                              : (route.hasServiceInfo
                                              ? 'Via Service'
                                              : 'Alternative ${index}'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.blue : (_darkMode ? Colors.white : Colors.black),
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                  if (isOptimal && index == 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Fastest Route',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (route.hasServiceInfo)
                                    Row(
                                      children: [
                                        Icon(
                                          _getServiceIcon(route.serviceInfo!['category']),
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Via ${route.serviceInfo!['name']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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

  // Build the route comparison view
  Widget _buildRouteComparisonView() {
    return Positioned.fill(
      child: Container(
        color: _darkMode ? Colors.black.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Route Comparison',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showRouteComparison = false;
                        });
                      },
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ],
                ),
              ),

              // Route comparison table
              Expanded(
                child: Obx(() {
                  List<NavigationRoute> routes = [
                    if (controller.currentRoute.value != null)
                      controller.currentRoute.value!,
                    ...controller.alternativeRoutes,
                  ];

                  if (routes.isEmpty) {
                    return Center(
                      child: Text(
                        'No routes available to compare',
                        style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route optimization explanation
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Why Route 1 is Optimal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Our algorithm analyzes multiple factors to determine the optimal route:',
                                style: TextStyle(
                                  color: _darkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildOptimizationFactor(
                                icon: Icons.timer,
                                title: 'Time Efficiency',
                                description: 'Fastest estimated travel time',
                              ),
                              _buildOptimizationFactor(
                                icon: Icons.straighten,
                                title: 'Distance',
                                description: 'Balanced with time for optimal efficiency',
                              ),
                              _buildOptimizationFactor(
                                icon: Icons.traffic,
                                title: 'Traffic Conditions',
                                description: 'Current and predicted traffic patterns',
                              ),
                              _buildOptimizationFactor(
                                icon: Icons.route,
                                title: 'Road Quality',
                                description: 'Preference for higher quality roads',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Route comparison table
                        Container(
                          decoration: BoxDecoration(
                            color: _darkMode ? Colors.grey[900] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Table header
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Route',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Time',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Services',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table rows
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: routes.length,
                                itemBuilder: (context, index) {
                                  NavigationRoute route = routes[index];
                                  bool isSelected = index == controller.selectedRouteIndex.value;
                                  bool isOptimal = index == 0 && !route.hasServiceInfo;

                                  // Calculate time difference from optimal route
                                  String timeDiff = '';
                                  if (!isOptimal && routes.isNotEmpty) {
                                    double diff = route.duration - routes[0].duration;
                                    if (diff > 0) {
                                      timeDiff = ' (+${_formatDurationDiff(diff)})';
                                    }
                                  }

                                  // Calculate distance difference from optimal route
                                  String distDiff = '';
                                  if (!isOptimal && routes.isNotEmpty) {
                                    double diff = route.distance - routes[0].distance;
                                    if (diff > 0) {
                                      distDiff = ' (+${_formatDistanceDiff(diff)})';
                                    }
                                  }

                                  return Container(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (_darkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _darkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Icon(
                                                isOptimal
                                                    ? Icons.star
                                                    : (route.hasServiceInfo ? Icons.local_gas_station : Icons.alt_route),
                                                color: isOptimal
                                                    ? Colors.amber
                                                    : (_darkMode ? Colors.white70 : Colors.black54),
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  isOptimal
                                                      ? 'Optimal Route'
                                                      : (route.hasServiceInfo
                                                      ? 'Via Service'
                                                      : 'Alternative ${index}'),
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                    color: _darkMode ? Colors.white : Colors.black,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatDuration(route.duration) + timeDiff,
                                            style: TextStyle(
                                              color: timeDiff.isNotEmpty
                                                  ? Colors.orange
                                                  : (_darkMode ? Colors.white : Colors.black),
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _formatDistance(route.distance) + distDiff,
                                            style: TextStyle(
                                              color: distDiff.isNotEmpty
                                                  ? Colors.orange
                                                  : (_darkMode ? Colors.white : Colors.black),
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: route.hasServiceInfo
                                              ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                              : Text(
                                            'None',
                                            style: TextStyle(
                                              color: _darkMode ? Colors.white70 : Colors.black54,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Route details
                        if (controller.currentRoute.value != null) ...[
                          Text(
                            'Selected Route Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _darkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _darkMode ? Colors.grey[900] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRouteDetailItem(
                                  icon: Icons.location_on,
                                  title: 'Start',
                                  value: controller.currentRoute.value!.startAddress,
                                ),
                                SizedBox(height: 12),
                                _buildRouteDetailItem(
                                  icon: Icons.flag,
                                  title: 'Destination',
                                  value: controller.currentRoute.value!.endAddress,
                                ),
                                SizedBox(height: 12),
                                _buildRouteDetailItem(
                                  icon: Icons.timer,
                                  title: 'Estimated Time',
                                  value: _formatDuration(controller.currentRoute.value!.duration),
                                ),
                                SizedBox(height: 12),
                                _buildRouteDetailItem(
                                  icon: Icons.straighten,
                                  title: 'Total Distance',
                                  value: _formatDistance(controller.currentRoute.value!.distance),
                                ),
                                if (controller.currentRoute.value!.hasServiceInfo) ...[
                                  SizedBox(height: 12),
                                  _buildRouteDetailItem(
                                    icon: _getServiceIcon(controller.currentRoute.value!.serviceInfo!['category']),
                                    title: 'Service Stop',
                                    value: controller.currentRoute.value!.serviceInfo!['name'],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a route optimization factor item
  Widget _buildOptimizationFactor({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a route detail item
  Widget _buildRouteDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDistanceDiff(double distance) {
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

  String _formatDurationDiff(double minutes) {
    if (minutes < 60) {
      return '${minutes.toInt()} min';
    } else {
      int hours = (minutes / 60).floor();
      int mins = (minutes % 60).floor();
      return '$hours h ${mins > 0 ? '$mins min' : ''}';
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'gas_station':
        return Icons.local_gas_station;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'parking':
        return Icons.local_parking;
      case 'car_wash':
        return Icons.local_car_wash;
      case 'mechanic':
        return Icons.build;
      case 'ev_charging':
        return Icons.electrical_services;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.place;
    }
  }

  String _getServiceName(String serviceType) {
    final serviceTypes = controller.getServiceTypes();
    final service = serviceTypes.firstWhere(
          (element) => element['id'] == serviceType,
      orElse: () => {'id': serviceType, 'name': 'Service'},
    );
    return service['name']!;
  }
}
