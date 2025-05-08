import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/community/controller/community_controller.dart';
import '../controller/navigation_controller.dart';
import '../model/route_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver {
  final NavigationController controller = Get.find<NavigationController>();
  final CommunityController communityController = Get.find<CommunityController>();
  late FlutterTts flutterTts;
  bool _darkMode = false;
  bool _showFullInstructions = false;
  bool _showSpeedLimit = true;
  bool _showLanes = true;
  bool _showTraffic = true;
  bool _followMode = true;
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Timer? _locationUpdateTimer;
  bool _mapInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTTS();
    _getCurrentLocation();

    // Check system brightness to set initial dark mode
    final brightness = MediaQuery.of(Get.context!).platformBrightness;
    _darkMode = brightness == Brightness.dark;

    // Listen for instruction changes to speak them
    ever(controller.currentInstruction, (instruction) {
      if (controller.voiceGuidanceEnabled.value && instruction.isNotEmpty) {
        _speakInstruction(instruction);
      }
    });

    // Listen for route changes to update polylines
    ever(controller.currentRoute, (route) {
      if (route != null && mapController != null && _mapInitialized) {
        _updatePolylines(route);
      }
    });

    // Start location updates timer
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _getCurrentLocation();
      if (controller.isNavigating.value && _followMode) {
        _updateCameraPosition();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      DevLogs.logError('Error getting current location: $e');
    }
  }

  void _updateCameraPosition() {
    if (mapController != null && currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation!,
            zoom: 17.0,
            tilt: 45.0,
            bearing: controller.currentLocation.value?.heading ?? 0,
          ),
        ),
      );
    }
  }

  Future<void> _initializeTTS() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakInstruction(String instruction) async {
    await flutterTts.speak(instruction);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    flutterTts.stop();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Update dark mode when system brightness changes
    final brightness = MediaQuery.of(Get.context!).platformBrightness;
    setState(() {
      _darkMode = brightness == Brightness.dark;
    });
    _updateMapStyle();
    super.didChangePlatformBrightness();
  }

  void _updateMapStyle() {
    if (mapController == null) return;

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

    mapController!.setMapStyle(mapStyle);
  }

  void _updatePolylines(NavigationRoute route) {
    try {
      // Decode polyline
      List<LatLng> points = controller.mapsService.decodePolyline(route.geometry);

      if (points.isEmpty) {
        DevLogs.logWarning('Empty polyline points decoded from geometry');
        return;
      }

      // Create a set to hold the new polylines
      Set<Polyline> newPolylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };

      // Add alternative routes if available
      for (int i = 0; i < controller.alternativeRoutes.length; i++) {
        var altRoute = controller.alternativeRoutes[i];
        List<LatLng> altPoints = controller.mapsService.decodePolyline(altRoute.geometry);

        if (altPoints.isNotEmpty) {
          newPolylines.add(
            Polyline(
              polylineId: PolylineId('alt_route_$i'),
              points: altPoints,
              color: Colors.grey,
              width: 3,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
          );
        }
      }

      // Update the polylines
      setState(() {
        _polylines = newPolylines;
      });

      // Create a set to hold the new markers
      Set<Marker> newMarkers = {
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(route.startLatitude, route.startLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(route.endLatitude, route.endLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };

      // Update the markers
      setState(() {
        _markers = newMarkers;
      });

      // Fit bounds to show the entire route if not in navigation mode
      if (!controller.isNavigating.value && points.length > 1) {
        _fitBoundsToRoute(points);
      }
    } catch (e) {
      DevLogs.logError('Error updating polylines: $e');
    }
  }

  void _fitBoundsToRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;

    try {
      double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50.0, // padding
        ),
      );
    } catch (e) {
      DevLogs.logError('Error fitting bounds to route: $e');
    }
  }

  void _showAlertDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Road Condition',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _darkMode ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What would you like to report?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildAlertTypeGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeGrid() {
    final List<Map<String, dynamic>> alertTypes = [
      {'type': 'traffic', 'icon': Icons.traffic, 'color': Colors.orange, 'label': 'Traffic'},
      {'type': 'accident', 'icon': Icons.car_crash, 'color': Colors.red, 'label': 'Accident'},
      {'type': 'police', 'icon': Icons.local_police, 'color': Colors.blue, 'label': 'Police'},
      {'type': 'hazard', 'icon': Icons.warning, 'color': Colors.amber, 'label': 'Hazard'},
      {'type': 'construction', 'icon': Icons.construction, 'color': Colors.yellow[800], 'label': 'Construction'},
      {'type': 'other', 'icon': Icons.info, 'color': Colors.teal, 'label': 'Other'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: alertTypes.length,
      itemBuilder: (context, index) {
        final type = alertTypes[index];
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            Get.toNamed('/create-notification', arguments: {'type': type['type']});
          },
          child: Container(
            decoration: BoxDecoration(
              color: _darkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: type['color'],
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'],
                  color: type['color'],
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  type['label'],
                  style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.currentLocation.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                zoom: 16.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                _updateMapStyle();
                _mapInitialized = true;

                // If route is already available, update polylines
                if (this.controller.currentRoute.value != null) {
                  _updatePolylines(this.controller.currentRoute.value!);
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              trafficEnabled: _showTraffic,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
              polylines: _polylines,
              markers: _markers,
            );
          }),

          // Top instruction panel
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildInstructionPanel(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          // Exit button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: _darkMode ? Colors.black.withOpacity(0.7) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  controller.stopNavigation();
                  Get.back();
                },
              ),
            ),
          ),

          // Settings button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: _darkMode ? Colors.black.withOpacity(0.7) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  _showSettingsBottomSheet();
                },
              ),
            ),
          ),

          // Center on location button
          Positioned(
            bottom: 160,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: _darkMode ? Colors.black.withOpacity(0.7) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: _followMode ? Colors.blue : (_darkMode ? Colors.white : Colors.black),
                ),
                onPressed: () {
                  setState(() {
                    _followMode = !_followMode;
                  });
                  if (_followMode) {
                    _updateCameraPosition();
                  }
                },
              ),
            ),
          ),

          // Alert button
          Positioned(
            bottom: 220,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                onPressed: _showAlertDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionPanel() {
    return Obx(() {
      if (controller.currentRoute.value == null) {
        return const SizedBox.shrink();
      }

      // Get current step
      RouteStep? currentStep;
      if (controller.currentStepIndex.value < controller.currentRoute.value!.steps.length) {
        currentStep = controller.currentRoute.value!.steps[controller.currentStepIndex.value];
      }

      if (currentStep == null) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getManeuverIcon(currentStep.maneuver),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentStep.instruction,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDistance(currentStep.distance),
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  _formatDuration(currentStep.duration),
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            if (_showFullInstructions && controller.currentStepIndex.value < controller.currentRoute.value!.steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: _darkMode ? Colors.white70 : Colors.black54,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Next: ${controller.currentRoute.value!.steps[controller.currentStepIndex.value + 1].instruction}",
                        style: TextStyle(
                          fontSize: 14,
                          color: _darkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomControls() {
    return Container(
      margin: EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ETA and distance
          Obx(() {
            if (controller.currentRoute.value == null) {
              return SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ETA',
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        _formatETA(controller.remainingDuration.value),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Text(
                        _formatDistance(controller.remainingDistance.value),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          Divider(color: _darkMode ? Colors.white24 : Colors.black12),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.volume_up,
                label: controller.voiceGuidanceEnabled.value ? 'Voice On' : 'Voice Off',
                onTap: () {
                  controller.toggleVoiceGuidance();
                },
                isActive: controller.voiceGuidanceEnabled.value,
              ),
              _buildControlButton(
                icon: Icons.dark_mode,
                label: _darkMode ? 'Dark Mode' : 'Light Mode',
                onTap: () {
                  setState(() {
                    _darkMode = !_darkMode;
                    _updateMapStyle();
                  });
                },
                isActive: _darkMode,
              ),
              _buildControlButton(
                icon: Icons.traffic,
                label: _showTraffic ? 'Traffic On' : 'Traffic Off',
                onTap: () {
                  setState(() {
                    _showTraffic = !_showTraffic;
                  });
                },
                isActive: _showTraffic,
              ),
              _buildControlButton(
                icon: Icons.list,
                label: 'Steps',
                onTap: () {
                  _showStepsBottomSheet();
                },
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? (isActive
                  ? Colors.blue
                  : (_darkMode ? Colors.white : Colors.black)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? (isActive
                    ? Colors.blue
                    : (_darkMode ? Colors.white : Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStepsBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Route Steps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: controller.currentRoute.value!.steps.length,
                itemBuilder: (context, index) {
                  RouteStep step = controller.currentRoute.value!.steps[index];
                  bool isCurrentStep = index == controller.currentStepIndex.value;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCurrentStep
                          ? (_darkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
                          : (_darkMode ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentStep
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isCurrentStep ? Colors.blue : (_darkMode ? Colors.grey[700] : Colors.grey[300]),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrentStep ? Colors.white : (_darkMode ? Colors.white : Colors.black),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.instruction,
                                style: TextStyle(
                                  color: _darkMode ? Colors.white : Colors.black,
                                  fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _formatDistance(step.distance),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _darkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _formatDuration(step.duration),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _darkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _showSettingsBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: _darkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navigation Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: _darkMode,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  _updateMapStyle();
                });
                Get.back();
              },
            ),
            SwitchListTile(
              title: Text(
                'Voice Guidance',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: controller.voiceGuidanceEnabled.value,
              activeColor: Colors.blue,
              onChanged: (value) {
                controller.toggleVoiceGuidance();
              },
            ),
            SwitchListTile(
              title: Text(
                'Show Traffic',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: _showTraffic,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _showTraffic = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(
                'Show Speed Limit',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: _showSpeedLimit,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _showSpeedLimit = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(
                'Show Lane Guidance',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: _showLanes,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _showLanes = value;
                });
              },
            ),
            SwitchListTile(
              title: Text(
                'Show Next Instruction',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              value: _showFullInstructions,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _showFullInstructions = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getManeuverIcon(String maneuver) {
    IconData iconData;

    switch (maneuver) {
      case 'turn-right':
        iconData = Icons.turn_right;
        break;
      case 'turn-left':
        iconData = Icons.turn_left;
        break;
      case 'turn-slight-right':
        iconData = Icons.turn_slight_right;
        break;
      case 'turn-slight-left':
        iconData = Icons.turn_slight_left;
        break;
      case 'turn-sharp-right':
        iconData = Icons.turn_sharp_right;
        break;
      case 'turn-sharp-left':
        iconData = Icons.turn_sharp_left;
        break;
      case 'uturn-right':
      case 'uturn-left':
        iconData = Icons.u_turn_right;
        break;
      case 'roundabout-right':
      case 'roundabout-left':
        iconData = Icons.roundabout_right;
        break;
      case 'merge':
        iconData = Icons.merge;
        break;
      case 'fork-right':
      case 'fork-left':
        iconData = Icons.fork_right;
        break;
      case 'straight':
        iconData = Icons.straight;
        break;
      case 'ramp-right':
      case 'ramp-left':
        iconData = Icons.exit_to_app;
        break;
      default:
        iconData = Icons.arrow_forward;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double seconds) {
    int minutes = (seconds / 60).floor();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = (minutes / 60).floor();
      minutes = minutes % 60;
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    }
  }

  String _formatETA(double remainingSeconds) {
    final now = DateTime.now();
    final eta = now.add(Duration(seconds: remainingSeconds.toInt()));

    final hour = eta.hour;
    final minute = eta.minute;

    final formattedHour = hour > 12 ? hour - 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';

    return '${formattedHour == 0 ? 12 : formattedHour}:${minute.toString().padLeft(2, '0')} $period';
  }
}
