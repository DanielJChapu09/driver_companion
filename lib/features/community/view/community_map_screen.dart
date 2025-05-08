import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/community_controller.dart';
import '../model/notifcation_model.dart';
import 'create_notification_screen.dart';
import 'notification_details_screen.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  final CommunityController controller = Get.find<CommunityController>();
  GoogleMapController? mapController;
  bool showAllTypes = true;
  Set<String> selectedTypes = {'accident', 'traffic', 'police', 'hazard', 'construction', 'other'};
  bool _darkMode = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMapMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Road Alerts Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
                if (mapController != null) {
                  mapController!.setMapStyle(_darkMode ?
                  '[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]' :
                  null);
                }
              });
            },
            tooltip: 'Toggle dark mode',
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
            onPressed: _showFilterDialog,
            tooltip: 'Filter alerts',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
            onPressed: () {
              controller.updateCurrentLocation();
              controller.fetchNearbyNotifications();
              _updateMapMarkers();

              // Show feedback to user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing alerts...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            tooltip: 'Refresh alerts',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading alerts...',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.currentLocation.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Location not available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please enable location services',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  onPressed: () => controller.updateCurrentLocation(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                zoom: 13.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                if (_darkMode) {
                  mapController!.setMapStyle('[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]');
                }
                _updateMapMarkers();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
            ),

            // Legend for map markers
            Positioned(
              bottom: 90,
              right: 16,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(height: 1, thickness: 1),
                      SizedBox(height: 8),
                      _buildLegendItem('Accident', Colors.red, Icons.car_crash),
                      _buildLegendItem('Traffic', Colors.orange, Icons.traffic),
                      _buildLegendItem('Police', Colors.blue, Icons.local_police),
                      _buildLegendItem('Hazard', Colors.amber, Icons.warning),
                      _buildLegendItem('Construction', Colors.yellow[800]!, Icons.construction),
                      _buildLegendItem('Other', Colors.teal, Icons.info),
                    ],
                  ),
                ),
              ),
            ),

            // Current location button
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'locationButton',
                    onPressed: _centerOnCurrentLocation,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.my_location, color: Colors.white),
                    mini: true,
                    tooltip: 'My location',
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoomInButton',
                    onPressed: () {
                      if (mapController != null) {
                        mapController!.animateCamera(CameraUpdate.zoomIn());
                      }
                    },
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.add),
                    mini: true,
                    tooltip: 'Zoom in',
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoomOutButton',
                    onPressed: () {
                      if (mapController != null) {
                        mapController!.animateCamera(CameraUpdate.zoomOut());
                      }
                    },
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.remove),
                    mini: true,
                    tooltip: 'Zoom out',
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(
            () => CreateNotificationScreen(),
            transition: Transition.rightToLeft,
            duration: Duration(milliseconds: 300),
          );
        },
        icon: Icon(Icons.add_alert),
        label: Text('Report'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

// Build legend item
  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// Show filter dialog
  void _showFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text('Filter Alerts'),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Show All Types',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: showAllTypes,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          showAllTypes = value;
                          if (showAllTypes) {
                            selectedTypes = {'accident', 'traffic', 'police', 'hazard', 'construction', 'other'};
                          }
                        });
                      },
                    ),
                    Divider(),
                    if (!showAllTypes) ...[
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildFilterCheckbox(setState, 'Accident', 'accident', Colors.red, Icons.car_crash),
                              _buildFilterCheckbox(setState, 'Traffic', 'traffic', Colors.orange, Icons.traffic),
                              _buildFilterCheckbox(setState, 'Police', 'police', Colors.blue, Icons.local_police),
                              _buildFilterCheckbox(setState, 'Hazard', 'hazard', Colors.amber, Icons.warning),
                              _buildFilterCheckbox(setState, 'Construction', 'construction', Colors.yellow[800]!, Icons.construction),
                              _buildFilterCheckbox(setState, 'Other', 'other', Colors.teal, Icons.info),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateMapMarkers();

                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Filters applied'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Text('Apply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Build filter checkbox
  Widget _buildFilterCheckbox(StateSetter setState, String label, String type, Color color, IconData icon) {
    return CheckboxListTile(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      value: selectedTypes.contains(type),
      activeColor: Theme.of(context).primaryColor,
      onChanged: (value) {
        setState(() {
          if (value!) {
            selectedTypes.add(type);
          } else {
            selectedTypes.remove(type);
          }
        });
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 8),
      controlAffinity: ListTileControlAffinity.trailing,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

// Update map markers based on notifications
  void _updateMapMarkers() {
    if (mapController == null) return;

    // Clear existing markers
    setState(() {
      _markers.clear();
    });

    // Add marker for current location
    if (controller.currentLocation.value != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('currentLocation'),
            position: LatLng(
              controller.currentLocation.value!.latitude,
              controller.currentLocation.value!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );
      });
    }

    // Add markers for filtered notifications
    List<RoadNotification> filteredNotifications = controller.nearbyNotifications
        .where((notification) => selectedTypes.contains(notification.type.toLowerCase()))
        .toList();

    for (var notification in filteredNotifications) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(notification.id),
            position: LatLng(
              notification.latitude,
              notification.longitude,
            ),
            icon: _getMarkerIconForType(notification.type),
            infoWindow: InfoWindow(
              title: notification.type,
              snippet: notification.message.length > 30
                  ? '${notification.message.substring(0, 30)}...'
                  : notification.message,
              onTap: () {
                Get.to(() => NotificationDetailScreen(notification: notification));
              },
            ),
            onTap: () {
              // Show a brief animation to highlight the selected marker
              mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(notification.latitude, notification.longitude),
                  15.0,
                ),
              );
            },
          ),
        );
      });
    }
  }

// Add the missing _centerOnCurrentLocation method
  void _centerOnCurrentLocation() {
    if (mapController != null && controller.currentLocation.value != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude,
          ),
          14.0,
        ),
      );

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Centered on your location'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

// Get appropriate marker icon based on notification type
  BitmapDescriptor _getMarkerIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'traffic':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'police':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'hazard':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'construction':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
}
