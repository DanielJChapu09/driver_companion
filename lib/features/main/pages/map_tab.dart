import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';
import 'package:mymaptest/firebase_options.dart';
import 'package:mymaptest/widgets/snackbar/custom_snackbar.dart';
import '../../driver_behaviour/controller/driver_behaviour_controller.dart';
import '../../navigation/model/route_model.dart';
import '../../navigation/model/search_result_model.dart';
import '../../navigation/service/googlemaps_service.dart';
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
  GoogleMapController? mapController;
  final LatLng _initialCameraPosition = const LatLng(37.77483, -122.41942); // San Francisco
  bool _isLoadingDestination = false;
  SearchResult? _selectedDestination;
  bool _isInitialized = false;
  Marker? _destinationMarker;
  Polyline? _routeLine;
  bool _showingRoutePreview = false;
  final GoogleMapsService _googleMapsService = GoogleMapsService(apiKey: APIKeys.GGOOGLEMAPSAPIKEY);
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _showTraffic = false;
  bool _darkMode = false;

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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
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
              },
              myLocationEnabled: true,
              compassEnabled: true,
              markers: _markers,
              polylines: _polylines,
              onTap: (coordinates) {
                _handleMapTap(coordinates);
              },
              trafficEnabled: _showTraffic,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
            );
          }),

          // Loading indicator for destination selection
          if (_isLoadingDestination)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
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
                    if (mapController != null && controller.currentLocation.value != null) {
                      mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              controller.currentLocation.value!.latitude,
                              controller.currentLocation.value!.longitude,
                            ),
                            zoom: 16.0,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                // Saved places button
                FloatingActionButton(
                  heroTag: 'placesButton',
                  mini: true,
                  onPressed: () => Get.toNamed(Routes.savedPlacesScreen),
                  child: const Icon(Icons.star),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Continue Navigation',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Route Preview Panel
          Obx(() {
            if (controller.currentRoute.value == null) return const SizedBox();
            return _showingRoutePreview ? _buildRoutePreviewPanel() : const SizedBox();
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
  void _handleMapTap(LatLng coordinates) async {
    // Don't process taps if already loading or navigating
    if (_isLoadingDestination || controller.isNavigating.value) return;

    setState(() {
      _isLoadingDestination = true;
      _selectedDestination = null;
    });

    try {
      // Clear previous routes and markers
      setState(() {
        _markers.clear();
        _polylines.clear();
      });

      // Add destination marker
      _destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: coordinates,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );

      // Update markers
      setState(() {
        _markers.add(_destinationMarker!);
      });

      // Reverse geocode to get address
      SearchResult? result = await _googleMapsService.reverseGeocode(coordinates);

      if (result != null) {
        setState(() {
          _selectedDestination = result;
        });

        // Get directions to this location
        if (controller.currentLocation.value != null) {
          await getDirections(
            LatLng(
              controller.currentLocation.value!.latitude,
              controller.currentLocation.value!.longitude,
            ),
            LatLng(coordinates.latitude, coordinates.longitude),
          );
        }
      } else {
        CustomSnackBar.showErrorSnackbar(
          message: 'Could not find address for this location',
        );
      }
    } catch (e) {
      DevLogs.logError('Error handling map tap: $e');
      CustomSnackBar.showErrorSnackbar(
        message: 'Failed to process location',
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
      return const SizedBox.shrink();
    }

    final route = controller.currentRoute.value!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Destination name
            Text(
              _selectedDestination!.name,
              style: const TextStyle(
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

            const SizedBox(height: 12),

            // Route info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: AppColors.blue),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(route.distance),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Duration
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.blue),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(route.duration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // ETA
                Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      _formatETA(route.duration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Save button
                OutlinedButton.icon(
                  onPressed: () {
                    _showSavePlaceDialog(_selectedDestination!);
                  },
                  icon: const Icon(Icons.star_border),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Close button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDestination = null;
                      _markers.clear();
                      _polylines.clear();
                    });
                    controller.currentRoute.value = null;
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),

            ElevatedButton.icon(
              onPressed: () {
                controller.startNavigation();
                Get.toNamed(Routes.navigationScreen);
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Start'),
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
        title: const Text('Save Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
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
                      const SizedBox(width: 8),
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
            child: const Text('Cancel'),
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
            child: const Text('Save'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.endAddress.isEmpty ? 'Destination' : route.endAddress,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    distance,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Save'),
                    onPressed: () {
                      _saveDestination();
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start Navigation'),
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
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(width: 8),
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _getDirectionsToPoint(LatLng destination, SearchResult location) async {
    if (controller.currentLocation.value == null) return;

    // Show loading indicator
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Finding route...'),
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
      NavigationRoute? route = await _googleMapsService.getDirections(origin, destination);

      if (route != null) {
        controller.currentRoute.value = route;

        // Draw route on map
        if (mapController != null) {
          _drawRouteOnMap(route);
        }

        // Show route preview
        setState(() {
          _showingRoutePreview = true;
        });
      } else {
        CustomSnackBar.showErrorSnackbar(
          message: 'Could not find a route to the destination',
        );
      }
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
        mapController!.dispose();
      }

      _destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
        mapController!.dispose();
      }

      _destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );

      // Get directions
      await _getDirectionsToPoint(destination, result);
    }
  }

  void _centerOnCurrentLocation() {
    if (controller.currentLocation.value != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              controller.currentLocation.value!.latitude,
              controller.currentLocation.value!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _saveDestination() {
    if (controller.currentRoute.value == null) return;

    // Show a dialog to get the name for this place
    Get.dialog(
      AlertDialog(
        title: const Text('Save Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
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
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            child: const Text('Save'),
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
      _markers.clear();
      _polylines.clear();
    });

    // Clear route in controller
    controller.currentRoute.value = null;
  }

  void _drawRouteOnMap(NavigationRoute route) {
    if (mapController == null) return;

    // Decode polyline
    List<LatLng> points = _googleMapsService.decodePolyline(route.geometry);

    // Update polylines
    Set<Polyline> newPolylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
      ),
    };
    setState(() {
      _polylines = newPolylines;
    });

    // Update markers
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
    setState(() {
      _markers = newMarkers;
    });

    // Fit bounds to show the entire route
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        points.map((p) => p.latitude).reduce(min),
        points.map((p) => p.longitude).reduce(min),
      ),
      northeast: LatLng(
        points.map((p) => p.latitude).reduce(max),
        points.map((p) => p.longitude).reduce(max),
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        50.0, // padding
      ),
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? sLat, sLng, nLat, nLng;
    for (LatLng latLng in list) {
      sLat = sLat == null || latLng.latitude < sLat ? latLng.latitude : sLat;
      sLng = sLng == null || latLng.longitude < sLng ? latLng.longitude : sLng;
      nLat = nLat == null || latLng.latitude > nLat ? latLng.latitude : nLat;
      nLng = nLng == null || latLng.longitude > nLng ? latLng.longitude : nLng;
    }
    return LatLngBounds(southwest: LatLng(sLat!, sLng!), northeast: LatLng(nLat!, nLng!));
  }

  Future<void> getDirections(LatLng origin, LatLng destination) async {
    try {
      // Get directions
      NavigationRoute? route = await _googleMapsService.getDirections(origin, destination);

      if (route != null) {
        controller.currentRoute.value = route;

        // Draw route on map
        if (mapController != null) {
          _drawRouteOnMap(route);
        }

        // Show route preview
        setState(() {
          _showingRoutePreview = true;
        });
      } else {
        CustomSnackBar.showErrorSnackbar(
          message: 'Could not find a route to the destination',
        );
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
  }

  void toggleTraffic() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
    mapController?.setMapStyle(null);
  }
}
