import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/features/community/view/community_screen.dart';
import '../controller/community_controller.dart';
import '../model/notifcation_model.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Road Alerts Map'),
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              controller.updateCurrentLocation();
              controller.fetchNearbyNotifications();
              _updateMapMarkers();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.currentLocation.value == null) {
          return Center(child: Text('Location not available'));
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
                _updateMapMarkers();
              },
              myLocationEnabled: true,
              markers: _markers,
            ),

            // Legend for map markers
            Positioned(
              bottom: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Legend',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
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
              left: 16,
              child: FloatingActionButton(
                heroTag: 'locationButton',
                mini: true,
                onPressed: _centerOnCurrentLocation,
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
              () => CommunityScreen()
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

// Build legend item
  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
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
            infoWindow: InfoWindow(title: notification.type),
          ),
        );
      });
    }
  }

// Center map on current location
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
    }
  }

// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter Alerts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text('Show All Types'),
                    value: showAllTypes,
                    onChanged: (value) {
                      setState(() {
                        showAllTypes = value!;
                        if (showAllTypes) {
                          selectedTypes = {'accident', 'traffic', 'police', 'hazard', 'construction', 'other'};
                        }
                      });
                    },
                  ),
                  Divider(),
                  if (!showAllTypes) ...[
                    _buildFilterCheckbox(setState, 'Accident', 'accident', Colors.red, Icons.car_crash),
                    _buildFilterCheckbox(setState, 'Traffic', 'traffic', Colors.orange, Icons.traffic),
                    _buildFilterCheckbox(setState, 'Police', 'police', Colors.blue, Icons.local_police),
                    _buildFilterCheckbox(setState, 'Hazard', 'hazard', Colors.amber, Icons.warning),
                    _buildFilterCheckbox(setState, 'Construction', 'construction', Colors.yellow[800]!, Icons.construction),
                    _buildFilterCheckbox(setState, 'Other', 'other', Colors.teal, Icons.info),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateMapMarkers();
                  },
                  child: Text('Apply'),
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
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: selectedTypes.contains(type),
      onChanged: (value) {
        setState(() {
          if (value!) {
            selectedTypes.add(type);
          } else {
            selectedTypes.remove(type);
          }
        });
      },
    );
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
