import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';
import 'package:mymaptest/widgets/snackbar/custom_snackbar.dart';
import '../../../firebase_options.dart';
import '../../driver_behaviour/controller/driver_behaviour_controller.dart';
import '../../navigation/model/search_result_model.dart';
import '../../navigation/view/navigation_screen.dart';
import '../../navigation/view/saved_places_screen.dart';
import '../../navigation/view/search_screen.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final NavigationController controller = Get.find<NavigationController>();
  final DriverBehaviorController behaviorController = Get.find<DriverBehaviorController>();
  final MapController _mapController = MapController();
  late MapboxMapController _mapboxMapController;
  bool _isLoadingDestination = false;
  SearchResult? _selectedDestination;
  bool _isInitialized = false;
  Symbol? _destinationMarker;
  Line? _routeLine;
  bool _showingRoutePreview = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initDriverBehavior();
  }

  Future<void> _initDriverBehavior() async {
    // Initialize driver behavior monitoring
    if (!behaviorController.isInitialized.value) {
      await Future.delayed(Duration(seconds: 1)); // Allow UI to render first
      behaviorController.startMonitoring();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation
        ),
      );
      controller.currentLocation.value = position;
    } catch (e) {
      DevLogs.logError('Error getting current location: $e');
    }
  }

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

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: latlong2.LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                initialZoom: 16,
                maxZoom: 40,
                minZoom: 0,

                onTap: (tapPosition, point) {
                  _handleMapTap(coordinates: LatLng(point.latitude, point.longitude));
                },

              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${APIKeys.MAPBOXPUBLICTOKEN}',
                  additionalOptions: {
                    'accessToken': APIKeys.MAPBOXPUBLICTOKEN
                  },
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      width: 20,
                      height: 20,
                      point: latlong2.LatLng(controller.currentLocation.value!.latitude, controller.currentLocation.value!.longitude),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                          Colors.green.withOpacity(0.5),
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 12,
                                height:12,
                                decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue
                                            .withValues(alpha: 0.5),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset:
                                        const Offset(
                                            0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if(_selectedDestination != null) Marker(
                      width: 20,
                      height: 20,
                      point: latlong2.LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.orange,
                        size: 50,
                      ),
                    ),
                  ],
                ),


                if (controller.previewRoutePoints.value.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: controller.previewRoutePoints.value,
                        // points: controller.currentRoute.value!.steps.map((step) => latlong2.LatLng(step.startLatitude, step.startLongitude)).toList(),
                        strokeWidth: 4.0,
                        color: AppColors.blue,
                      ),
                    ],
                  ),
              ],

            );
          }),

          // Loading indicator for destination selection
          if (_isLoadingDestination)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Get.toNamed(Routes.searchScreen),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text(
                      'Search for a destination',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My location button
                FloatingActionButton(
                  heroTag: 'locationButton',
                  mini: true,
                  onPressed: () {
                    if (controller.mapController.value != null && controller.currentLocation.value != null) {
                      controller.mapController.value!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(
                            controller.currentLocation.value!.latitude,
                            controller.currentLocation.value!.longitude,
                          ),
                          16.0,
                        ),
                      );
                    }
                  },
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 8),
                // Saved places button
                FloatingActionButton(
                  heroTag: 'placesButton',
                  mini: true,
                  onPressed: () => Get.toNamed(Routes.savedPlacesScreen),
                  child: Icon(Icons.star),
                ),
              ],
            ),
          ),

          // Route preview card (only shown when destination is selected)
          if (_selectedDestination != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 70,
              child: _buildRoutePreviewCard(),
            ),


          // Continue navigation button (only shown when navigating)
          Obx(() {
            if (controller.isNavigating.value) {
              return Positioned(
                bottom: 16,
                left: 16,
                right: 70,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(Routes.navigationScreen),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Continue Navigation',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),

          // Route Preview Panel
          Obx(() {
            if (controller.currentRoute.value == null) return SizedBox();
            return _showingRoutePreview ? _buildRoutePreviewPanel() : SizedBox();
          }),

          // Driver Behavior Status
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: Obx(() => _buildDriverBehaviorStatus()),
          ),
        ],
      ),
    );
  }

  // Handle map tap to select destination
  void _handleMapTap({required LatLng coordinates}) async {
    // Don't process taps if already loading or navigating
    if (_isLoadingDestination || controller.isNavigating.value) return;

    setState(() {
      _isLoadingDestination = true;
      _selectedDestination = null;
    });

    try {
      // Clear previous routes and markers
      if (controller.mapController.value != null) {
        controller.mapController.value!.clearSymbols();
        controller.mapController.value!.clearLines();
      }

      // Add destination marker
      if (controller.mapController.value != null) {
        controller.mapController.value!.addSymbol(
          SymbolOptions(
            geometry: coordinates,
            iconImage: "marker-end",
            iconSize: 1.5,
          ),
        );
      }

      // Reverse geocode to get address
      SearchResult? result = await controller.mapboxService.reverseGeocode(coordinates);

      if (result != null) {
        setState(() {
          _selectedDestination = result;
        });

        // Get directions to this location
        if (controller.currentLocation.value != null) {

          await controller.getRoutePreview(
              latlong2.LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude,
              ),
              latlong2.LatLng(
                coordinates.latitude,
                coordinates.longitude,
              )
          ).then((value) async{
            await controller.getDirections(
              LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude,
              ),
              LatLng(coordinates.latitude, coordinates.longitude),
            );
          });
        }
      } else {
        CustomSnackBar.showErrorSnackbar(
          message: 'Could not find address for this location',
        );
      }
    } catch (e) {
      DevLogs.logError('Error handling map tap: $e');
      CustomSnackBar.showErrorSnackbar(
        message:'Failed to process location',
      );
    } finally {
      setState(() {
        _isLoadingDestination = false;
      });
    }
  }

  // Build route preview card
  Widget _buildRoutePreviewCard() {
    if (_selectedDestination == null || controller.currentRoute.value == null) {
      return SizedBox.shrink();
    }

    final route = controller.currentRoute.value!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Destination name
            Text(
              _selectedDestination!.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Address
            Text(
              _selectedDestination!.address,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12),

            // Route info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: AppColors.blue),
                    SizedBox(width: 4),
                    Text(
                      _formatDistance(route.distance),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Duration
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.blue),
                    SizedBox(width: 4),
                    Text(
                      _formatDuration(route.duration),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // ETA
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      _formatETA(route.duration),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Save button
                OutlinedButton.icon(
                  onPressed: () {
                    _showSavePlaceDialog(_selectedDestination!);
                  },
                  icon: Icon(Icons.star_border),
                  label: Text('Save'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),


                SizedBox(width: 8),

                // Close button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDestination = null;
                    });
                    controller.currentRoute.value = null;

                    // Clear map
                    if (controller.mapController.value != null) {
                      controller.mapController.value!.clearSymbols();
                      controller.mapController.value!.clearLines();
                    }
                  },
                  icon: Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),

            ElevatedButton.icon(
              onPressed: () {
                controller.startNavigation();
                Get.toNamed(Routes.navigationScreen);
              },
              icon: Icon(Icons.navigation),
              label: Text('Start'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog to save place
  void _showSavePlaceDialog(SearchResult destination) {
    final TextEditingController nameController = TextEditingController(text: destination.name);
    String selectedCategory = 'other';

    Get.dialog(
      AlertDialog(
        title: Text('Save Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: controller.getPlaceCategories().map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Row(
                    children: [
                      Icon(IconData(
                        category['icon'].codePointAt(0),
                        fontFamily: 'MaterialIcons',
                      )),
                      SizedBox(width: 8),
                      Text(category['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.addToFavorites(
                destination.latitude,
                destination.longitude,
                nameController.text,
                destination.address,
                category: selectedCategory,
              );
              Get.back();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Format distance
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Format duration
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

  // Format ETA
  String _formatETA(double seconds) {
    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: seconds.toInt()));

    return '${arrival.hour}:${arrival.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRoutePreviewPanel() {
    final route = controller.currentRoute.value!;

    // Format distance and duration
    String distance = '';
    if (route.distance < 1000) {
      distance = '${route.distance.toInt()} m';
    } else {
      distance = '${(route.distance / 1000).toStringAsFixed(1)} km';
    }

    String duration = '';
    if (route.duration < 60) {
      duration = '${route.duration.toInt()} sec';
    } else if (route.duration < 3600) {
      duration = '${(route.duration / 60).toStringAsFixed(0)} min';
    } else {
      int hours = (route.duration / 3600).floor();
      int minutes = ((route.duration % 3600) / 60).floor();
      duration = '$hours h $minutes min';
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.endAddress.isEmpty ? 'Destination' : route.endAddress,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.directions_car, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.favorite_border),
                    label: Text('Save'),
                    onPressed: () {
                      _saveDestination();
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.navigation),
                    label: Text('Start Navigation'),
                    onPressed: () {
                      _startNavigation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.close),
                    label: Text('Cancel'),
                    onPressed: () {
                      _cancelRoutePreview();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverBehaviorStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              behaviorController.isMonitoring.value
                  ? Icons.sensors
                  : Icons.sensors_off,
              color: behaviorController.isMonitoring.value
                  ? Colors.green
                  : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              behaviorController.isMonitoring.value
                  ? 'Monitoring Active'
                  : 'Monitoring Off',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: behaviorController.isMonitoring.value
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapboxMapController = controller;
    this.controller.setMapController(controller);
    setState(() {
      _isInitialized = true;
    });
  }

  void _onMapLongClick(Point<double> point, LatLng coordinates) async {
    // Clear any existing markers and lines
    if (_destinationMarker != null) {
      _mapboxMapController.removeSymbol(_destinationMarker!);
      _destinationMarker = null;
    }

    if (_routeLine != null) {
      _mapboxMapController.removeLine(_routeLine!);
      _routeLine = null;
    }

    // Add a new destination marker
    _destinationMarker = await _mapboxMapController.addSymbol(
      SymbolOptions(
        geometry: coordinates,
        iconImage: 'marker-15', // Use a default Mapbox icon
        iconSize: 2.0,
      ),
    );

    // Get the address for this location
    SearchResult? location = await controller.mapboxService.reverseGeocode(coordinates);

    if (location != null) {
      // Get directions from current location to this point
      await _getDirectionsToPoint(coordinates, location);
    }
  }

  Future<void> _getDirectionsToPoint(LatLng destination, SearchResult location) async {
    if (controller.currentLocation.value == null) return;

    // Show loading indicator
    Get.dialog(
      Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding route...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Get current location
      LatLng origin = LatLng(
        controller.currentLocation.value!.latitude,
        controller.currentLocation.value!.longitude,
      );

      // Get directions
      await controller.getDirections(origin, destination);

      // Show route preview
      setState(() {
        _showingRoutePreview = true;
      });
    } catch (e) {
      print('Error getting directions: $e');
    } finally {
      // Close loading dialog
      Get.back();
    }
  }

  void _goToSearchScreen() async {
    // Navigate to search screen
    final result = await Get.to(() => SearchScreen());

    // If a place was selected, get directions to it
    if (result != null && result is SearchResult) {
      LatLng destination = LatLng(result.latitude, result.longitude);

      // Add a marker at the destination
      if (_destinationMarker != null) {
        _mapboxMapController.removeSymbol(_destinationMarker!);
      }

      _destinationMarker = await _mapboxMapController.addSymbol(
        SymbolOptions(
          geometry: destination,
          iconImage: 'marker-15',
          iconSize: 2.0,
        ),
      );

      // Get directions
      await _getDirectionsToPoint(destination, result);
    }
  }

  void _goToSavedPlacesScreen() async {
    // Navigate to saved places screen
    final result = await Get.to(() => SavedPlacesScreen());

    // If a place was selected, get directions to it
    if (result != null && result is SearchResult) {
      LatLng destination = LatLng(result.latitude, result.longitude);

      // Add a marker at the destination
      if (_destinationMarker != null) {
        _mapboxMapController.removeSymbol(_destinationMarker!);
      }

      _destinationMarker = await _mapboxMapController.addSymbol(
        SymbolOptions(
          geometry: destination,
          iconImage: 'marker-15',
          iconSize: 2.0,
        ),
      );

      // Get directions
      await _getDirectionsToPoint(destination, result);
    }
  }

  void _centerOnCurrentLocation() {
    if (controller.currentLocation.value != null) {
      _mapboxMapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude,
          ),
          15.0,
        ),
      );
    }
  }

  void _saveDestination() {
    if (controller.currentRoute.value == null) return;

    // Show a dialog to get the name for this place
    Get.dialog(
      AlertDialog(
        title: Text('Save Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Home, Work, etc.',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addToFavorites(value);
                  Get.back();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              // Get the text from the field and save
              final TextEditingController controller = TextEditingController();
              if (controller.text.isNotEmpty) {
                _addToFavorites(controller.text);
              }
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  void _addToFavorites(String name) {
    if (controller.currentRoute.value == null) return;

    final route = controller.currentRoute.value!;
    controller.addToFavorites(
      route.endLatitude,
      route.endLongitude,
      name,
      route.endAddress,
    );
  }

  void _startNavigation() {
    if (controller.currentRoute.value == null) return;

    // Make sure driver behavior monitoring is active
    if (!behaviorController.isMonitoring.value) {
      behaviorController.startMonitoring(
        isNavigationMode: true,
        routeId: controller.currentRoute.value!.id,
      );
    }

    // Start navigation
    controller.startNavigation();

    // Navigate to navigation screen
    Get.to(() => NavigationScreen());
  }

  void _cancelRoutePreview() {
    setState(() {
      _showingRoutePreview = false;
    });

    // Clear markers and route
    if (_destinationMarker != null) {
      _mapboxMapController.removeSymbol(_destinationMarker!);
      _destinationMarker = null;
    }

    if (_routeLine != null) {
      _mapboxMapController.removeLine(_routeLine!);
      _routeLine = null;
    }

    // Clear route in controller
    controller.currentRoute.value = null;
  }
}

