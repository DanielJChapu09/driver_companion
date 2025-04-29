import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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


class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> with SingleTickerProviderStateMixin {
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
  MapType _currentMapType = MapType.normal;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initDriverBehavior();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    _darkMode = isDark;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.currentLocation.value == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
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
                _updateMapStyle(isDark);
              },
              myLocationEnabled: true,
              compassEnabled: true,
              markers: _markers,
              polylines: _polylines,
              onTap: (coordinates) {
                _handleMapTap(coordinates);
              },
              trafficEnabled: _showTraffic,
              mapType: _currentMapType,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
              myLocationButtonEnabled: false,
            );
          }),

          // Loading indicator for destination selection
          if (_isLoadingDestination)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Finding location...',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () => Get.toNamed(Routes.searchScreen),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Where to?',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Saved',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Map controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.layers,
                    onPressed: _showMapStyleOptions,
                    tooltip: 'Map Layers',
                    theme: theme,
                    isDark: isDark,
                  ),
                  SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: _showTraffic ? Icons.traffic : Icons.traffic_outlined,
                    onPressed: toggleTraffic,
                    tooltip: 'Traffic',
                    theme: theme,
                    isDark: isDark,
                    isActive: _showTraffic,
                  ),
                  SizedBox(height: 8),
                  _buildMapControlButton(
                    icon: Icons.my_location,
                    onPressed: _centerOnCurrentLocation,
                    tooltip: 'My Location',
                    theme: theme,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Quick action buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Driver behavior status card
                  Obx(() => AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: behaviorController.isMonitoring.value
                        ? _buildDriverStatusCard(theme, isDark)
                        : SizedBox.shrink(),
                  )),
                  SizedBox(height: 16),

                  // Quick action buttons
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickActionButton(
                                icon: Icons.search,
                                label: 'Search',
                                onTap: () => Get.toNamed(Routes.searchScreen),
                                theme: theme,
                                isDark: isDark,
                              ),
                              _buildQuickActionButton(
                                icon: Icons.star,
                                label: 'Saved',
                                onTap: () => Get.toNamed(Routes.savedPlacesScreen),
                                theme: theme,
                                isDark: isDark,
                              ),
                              _buildQuickActionButton(
                                icon: Icons.local_gas_station,
                                label: 'Services',
                                onTap: () => Get.toNamed(Routes.serviceLocatorScreen),
                                theme: theme,
                                isDark: isDark,
                              ),
                              _buildQuickActionButton(
                                icon: Icons.warning,
                                label: 'Alerts',
                                onTap: () => Get.toNamed(Routes.communityMapScreen),
                                theme: theme,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Route preview card (only shown when destination is selected)
          if (_selectedDestination != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildRoutePreviewCard(theme, isDark),
            ),

          // Continue navigation button (only shown when navigating)
          Obx(() {
            if (controller.isNavigating.value) {
              return Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  color: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () => Get.toNamed(Routes.navigationScreen),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Navigation in Progress',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to continue',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Route Preview Panel
          Obx(() {
            if (controller.currentRoute.value == null) return const SizedBox();
            return _showingRoutePreview ? _buildRoutePreviewPanel(theme, isDark) : const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeData theme,
    required bool isDark,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: isDark ? Color(0xFF2C2C2C) : Colors.white,
        elevation: 0,
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: EdgeInsets.all(12),
              child: Icon(
                icon,
                color: isActive
                    ? theme.colorScheme.primary
                    : isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverStatusCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sensors,
                color: Colors.green,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Monitoring Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tracking your driving patterns',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Get.toNamed(Routes.driverBehaviorScreen),
              child: Text('View'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
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
  Widget _buildRoutePreviewCard(ThemeData theme, bool isDark) {
    if (_selectedDestination == null || controller.currentRoute.value == null) {
      return const SizedBox.shrink();
    }

    final route = controller.currentRoute.value!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 16),

            // Route info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Distance
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Distance',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDistance(route.distance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Duration
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Duration',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDuration(route.duration),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // ETA
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ETA',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatETA(route.duration),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSavePlaceDialog(_selectedDestination!);
                    },
                    icon: Icon(Icons.star_border),
                    label: Text('Save'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.startNavigation();
                      Get.toNamed(Routes.navigationScreen);
                    },
                    icon: Icon(Icons.navigation),
                    label: Text('Start'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Close button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDestination = null;
                    _markers.clear();
                    _polylines.clear();
                  });
                  controller.currentRoute.value = null;
                },
                icon: Icon(Icons.close),
                label: Text('Close'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey[100],
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey[100],
              ),
              items: controller.getPlaceCategories().map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Row(
                    children: [
                      Icon(
                        IconData(
                          category['icon'].codePointAt(0),
                          fontFamily: 'MaterialIcons',
                        ),
                        color: theme.colorScheme.primary,
                      ),
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

              // Show success message
              Get.snackbar(
                'Place Saved',
                'Successfully added to your saved places',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                margin: EdgeInsets.all(16),
                borderRadius: 8,
                duration: Duration(seconds: 2),
              );
            },
            child: Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

    String period = arrival.hour >= 12 ? 'PM' : 'AM';
    int hour = arrival.hour > 12 ? arrival.hour - 12 : (arrival.hour == 0 ? 12 : arrival.hour);
    String minute = arrival.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }

  Widget _buildRoutePreviewPanel(ThemeData theme, bool isDark) {
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      distance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Distance',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Duration',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.flag,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatETA(route.duration),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'ETA',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
              children: [
          Expanded(
          child: OutlinedButton.icon(
          icon: Icon(Icons.star_border),
          label: Text('Save'),
          onPressed: _saveDestination,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
        icon: Icon(Icons.navigation),
        label: Text('Start'),
        onPressed: _startNavigation,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
    ],
    ),
    SizedBox(height: 8),
    Center(
    child: TextButton.icon(
    icon: Icon(Icons.close),
    label: Text('Cancel'),
    onPressed: _cancelRoutePreview,
    style: TextButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }

  void _showMapStyleOptions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Style',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.map,
                color: theme.colorScheme.primary,
              ),
              title: Text('Standard'),
              trailing: Radio<int>(
                value: 0,
                groupValue: 0,
                onChanged: (value) {
                  Get.back();
                  setState(() {
                    _currentMapType = MapType.normal;
                  });
                  _updateMapStyle(isDark);
                },
              ),
              onTap: () {
                Get.back();
                setState(() {
                  _currentMapType = MapType.normal;
                });
                _updateMapStyle(isDark);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.satellite,
                color: theme.colorScheme.primary,
              ),
              title: Text('Satellite'),
              trailing: Radio<int>(
                value: 1,
                groupValue: 0,
                onChanged: (value) {
                  Get.back();
                  setState(() {
                    _currentMapType = MapType.satellite;
                  });
                },
              ),
              onTap: () {
                Get.back();
                setState(() {
                  _currentMapType = MapType.satellite;
                });
              },
            ),
            ListTile(
              leading: Icon(
                Icons.terrain,
                color: theme.colorScheme.primary,
              ),
              title: Text('Terrain'),
              trailing: Radio<int>(
                value: 2,
                groupValue: 0,
                onChanged: (value) {
                  Get.back();
                  setState(() {
                    _currentMapType = MapType.terrain;
                  });
                },
              ),
              onTap: () {
                Get.back();
                setState(() {
                  _currentMapType = MapType.terrain;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
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
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _saveDestination() {
    if (controller.currentRoute.value == null) return;

    // Show a dialog to get the name for this place
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController();
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
                hintText: 'Home, Work, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey[100],
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Color(0xFF2C2C2C) : Colors.grey[100],
              ),
              items: controller.getPlaceCategories().map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'],
                  child: Row(
                    children: [
                      Icon(
                        IconData(
                          category['icon'].codePointAt(0),
                          fontFamily: 'MaterialIcons',
                        ),
                        color: theme.colorScheme.primary,
                      ),
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
              if (nameController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter a name for this place',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: EdgeInsets.all(16),
                  borderRadius: 8,
                );
                return;
              }

              _addToFavorites(nameController.text, selectedCategory);
              Get.back();
            },
            child: Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _addToFavorites(String name, String category) {
    if (controller.currentRoute.value == null) return;

    final route = controller.currentRoute.value!;
    controller.addToFavorites(
      route.endLatitude,
      route.endLongitude,
      name,
      route.endAddress,
      category: category,
    );

    // Show success message
    Get.snackbar(
      'Place Saved',
      'Successfully added to your saved places',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 2),
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
        color: Theme.of(context).colorScheme.primary,
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
      DevLogs.logError('Error getting directions: $e');
    }
  }

  void toggleTraffic() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
  }

  void _updateMapStyle(bool isDark) {
    if (mapController == null) return;

    if (isDark) {
      mapController!.setMapStyle('''
      [
        {
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "elementType": "labels.icon",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#212121"
            }
          ]
        },
        {
          "featureType": "administrative",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "administrative.country",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#9e9e9e"
            }
          ]
        },
        {
          "featureType": "administrative.land_parcel",
          "stylers": [
            {
              "visibility": "off"
            }
          ]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#bdbdbd"
            }
          ]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#181818"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#616161"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#1b1b1b"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry.fill",
          "stylers": [
            {
              "color": "#2c2c2c"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#8a8a8a"
            }
          ]
        },
        {
          "featureType": "road.arterial",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#373737"
            }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#3c3c3c"
            }
          ]
        },
        {
          "featureType": "road.highway.controlled_access",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#4e4e4e"
            }
          ]
        },
        {
          "featureType": "road.local",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#616161"
            }
          ]
        },
        {
          "featureType": "transit",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#757575"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#000000"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#3d3d3d"
            }
          ]
        }
      ]
      ''');
    } else {
      mapController!.setMapStyle(null); // Reset to default style
    }
  }
}
