import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../controller/navigation_controller.dart';
import '../model/route_model.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  bool _darkMode = true;
  bool _showFullInstructions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.currentLocation.value == null) {
              return Center(child: CircularProgressIndicator());
            }

            return MapboxMap(
              accessToken: APIKeys.MAPBOXPUBLICTOKEN,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude!,
                  controller.currentLocation.value!.longitude!,
                ),
                zoom: 16.0,
                tilt: 45.0,
                bearing: controller.currentLocation.value!.heading?.toDouble() ?? 0.0,
              ),
              onMapCreated: (MapboxMapController mapController) {
                controller.setMapController(mapController);

                // Set dark mode if enabled
                if (_darkMode) {
                  // mapController.setStyleString('mapbox://styles/mapbox/navigation-night-v1');
                } else {
                  // mapController.setStyleString('mapbox://styles/mapbox/navigation-day-v1');
                }

                // Draw route
                if (controller.currentRoute.value != null) {
                  _drawRouteOnMap(mapController, controller.currentRoute.value!);
                }
              },
              myLocationEnabled: true,
              myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
              compassEnabled: true,
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
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.close),
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
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  _showSettingsBottomSheet();
                },
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
        return SizedBox.shrink();
      }

      // Get current step
      RouteStep? currentStep;
      if (controller.currentStepIndex.value < controller.currentRoute.value!.steps.length) {
        currentStep = controller.currentRoute.value!.steps[controller.currentStepIndex.value];
      }

      if (currentStep == null) {
        return SizedBox.shrink();
      }

      // Get next step if available
      RouteStep? nextStep;
      if (controller.currentStepIndex.value + 1 < controller.currentRoute.value!.steps.length) {
        nextStep = controller.currentRoute.value!.steps[controller.currentStepIndex.value + 1];
      }

      return GestureDetector(
        onTap: () {
          setState(() {
            _showFullInstructions = !_showFullInstructions;
          });
        },
        child: Container(
          color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current instruction
              Row(
                children: [
                  _buildManeuverIcon(currentStep.maneuver),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep.instruction,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDistance(currentStep.distance),
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Next instruction (if available and expanded view)
              if (_showFullInstructions && nextStep != null) ...[
                Divider(color: _darkMode ? Colors.white24 : Colors.black12),
                Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      _buildManeuverIcon(nextStep.maneuver, size: 24),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Then ${nextStep.instruction}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _darkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatDistance(nextStep.distance),
                              style: TextStyle(
                                fontSize: 12,
                                color: _darkMode ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Show full route summary if expanded
              if (_showFullInstructions) ...[
                Divider(color: _darkMode ? Colors.white24 : Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Arrival: ${_formatTime(DateTime.now().add(Duration(seconds: controller.remainingDuration.value.toInt())))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _darkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      'Remaining: ${_formatDuration(controller.remainingDuration.value)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _darkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomControls() {
    return Container(
      color: _darkMode ? Colors.black.withOpacity(0.8) : Colors.white,
      padding: EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.volume_up,
            label: 'Sound',
            onTap: () {
              // Toggle sound
              Get.snackbar(
                'Sound',
                'Sound settings toggled',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          _buildControlButton(
            icon: Icons.dark_mode,
            label: 'Dark Mode',
            onTap: () {
              setState(() {
                _darkMode = !_darkMode;
              });

              // Update map style
              if (controller.mapController.value != null) {
                if (_darkMode) {
                  // controller.mapController.value!.setStyleString('mapbox://styles/mapbox/navigation-night-v1');
                } else {
                  // controller.mapController.value!.setStyleString('mapbox://styles/mapbox/navigation-day-v1');
                }
              }
            },
          ),
          _buildControlButton(
            icon: Icons.list,
            label: 'Steps',
            onTap: () {
              _showStepsBottomSheet();
            },
          ),
          _buildControlButton(
            icon: Icons.stop,
            label: 'End',
            onTap: () {
              controller.stopNavigation();
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _darkMode ? Colors.white : Colors.black,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _darkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManeuverIcon(String maneuver, {double size = 36}) {
    IconData iconData;

    switch (maneuver) {
      case 'turn':
        iconData = Icons.turn_right;
        break;
      case 'straight':
        iconData = Icons.straight;
        break;
      case 'merge':
        iconData = Icons.merge_type;
        break;
      case 'ramp':
        iconData = Icons.exit_to_app;
        break;
      case 'fork':
        iconData = Icons.call_split;
        break;
      case 'roundabout':
        iconData = Icons.roundabout_left;
        break;
      case 'arrive':
        iconData = Icons.place;
        break;
      default:
        iconData = Icons.arrow_forward;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  void _showStepsBottomSheet() {
    if (controller.currentRoute.value == null) return;

    Get.bottomSheet(
      Container(
        color: _darkMode ? Colors.black : Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: controller.currentRoute.value!.steps.length,
                itemBuilder: (context, index) {
                  RouteStep step = controller.currentRoute.value!.steps[index];
                  bool isCurrentStep = index == controller.currentStepIndex.value;

                  return ListTile(
                    leading: _buildManeuverIcon(
                      step.maneuver,
                      size: 24,
                    ),
                    title: Text(
                      step.instruction,
                      style: TextStyle(
                        color: _darkMode ? Colors.white : Colors.black,
                        fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _formatDistance(step.distance),
                      style: TextStyle(
                        color: _darkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    tileColor: isCurrentStep
                        ? (_darkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    Get.bottomSheet(
      Container(
        color: _darkMode ? Colors.black : Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navigation Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: _darkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });

                  // Update map style
                  if (controller.mapController.value != null) {
                    if (_darkMode) {
                      // controller.mapController.value!.setStyleString('mapbox://styles/mapbox/navigation-night-v1');
                    } else {
                      // controller.mapController.value!.setStyleString('mapbox://styles/mapbox/navigation-day-v1');
                    }
                  }

                  Get.back();
                },
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.volume_up,
                color: _darkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Voice Guidance',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Toggle voice guidance
                  Get.back();
                },
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.speed,
                color: _darkMode ? Colors.white : Colors.black,
              ),
              title: Text(
                'Speed Limit Alerts',
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Toggle speed limit alerts
                  Get.back();
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  controller.simulateNavigation();
                  Get.back();
                },
                child: Text('Simulate Navigation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _drawRouteOnMap(MapboxMapController mapController, NavigationRoute route) {
    // Clear previous routes
    mapController.clearLines();

    // Decode polyline
    List<LatLng> points = _decodePolyline(route.geometry);

    // Add line
    mapController.addLine(
      LineOptions(
        geometry: points,
        lineColor: "#3887be",
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );

    // Add destination marker
    mapController.addSymbol(
      SymbolOptions(
        geometry: LatLng(route.endLatitude, route.endLongitude),
        iconImage: "marker-end",
        iconSize: 1.5,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E6, lng / 1E6));
    }

    return points;
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
    int hours = (minutes / 60).floor();
    minutes = minutes % 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

