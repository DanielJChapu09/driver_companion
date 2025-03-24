import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
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
  MapboxMapController? mapController;
  bool showAllTypes = true;
  Set<String> selectedTypes = {'accident', 'traffic', 'police', 'hazard', 'construction', 'other'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Road Alerts Map'),
        actions: [
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
            MapboxMap(
              accessToken: APIKeys.MAPBOXPUBLICTOKEN,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                zoom: 13.0,
              ),
              onMapCreated: (MapboxMapController controller) {
                mapController = controller;
                _updateMapMarkers();
              },
              onStyleLoadedCallback: () {
                // Map style loaded
              },
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
          Get.toNamed('/create-notification');
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
    mapController!.clearSymbols();

    // Add marker for current location
    if (controller.currentLocation.value != null) {
      mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(
          controller.currentLocation.value!.latitude,
          controller.currentLocation.value!.longitude,
        ),
        iconImage: 'car',
        iconSize: 1.5,
      ));
    }

    // Add markers for filtered notifications
    List<RoadNotification> filteredNotifications = controller.nearbyNotifications
        .where((notification) => selectedTypes.contains(notification.type.toLowerCase()))
        .toList();

    for (var notification in filteredNotifications) {
      mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            notification.latitude,
            notification.longitude,
          ),
          iconImage: _getMarkerIconForType(notification.type),
          iconSize: 1.0,
          textField: notification.type,
          textOffset: Offset(0, 1.5),
        ),
        {
          'id': notification.id,
          'type': notification.type,
        },
      ).then((symbol) {
        // Add tap handler for the symbol
        mapController!.onSymbolTapped.add((Symbol symbol) {
          if (symbol.data != null && symbol.data!.containsKey('id')) {
            String id = symbol.data!['id'];
            RoadNotification? tappedNotification = controller.nearbyNotifications
                .firstWhereOrNull((n) => n.id == id);

            if (tappedNotification != null) {
              Get.to(() => NotificationDetailScreen(notification: tappedNotification));
            }
          }
        });
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
  String _getMarkerIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return 'accident';
      case 'traffic':
        return 'traffic';
      case 'police':
        return 'police';
      case 'hazard':
        return 'hazard';
      case 'construction':
        return 'construction';
      default:
        return 'marker';
    }
  }
}

