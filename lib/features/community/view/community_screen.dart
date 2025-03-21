import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../controller/community_controller.dart';
import '../model/notifcation_model.dart';
import 'create_notification_screen.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import 'notification_details_screen.dart';

class CommunityScreen extends StatelessWidget {

  CommunityScreen({super.key});


  final CommunityController controller = Get.find<CommunityController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentCity.value.isEmpty
            ? 'Driver Community'
            : 'Drivers in ${controller.currentCity.value}')),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              controller.updateCurrentLocation();
              controller.fetchNearbyNotifications();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${controller.errorMessage.value}',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.initializeServices(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Map view showing nearby notifications
            Container(
              height: 200,
              child: _buildMapView(),
            ),

            // Tabs for different views
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: 'City Feed'),
                        Tab(text: 'Nearby'),
                      ],
                      labelColor: Theme.of(context).primaryColor,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // City notifications tab
                          _buildNotificationsList(controller.cityNotifications),

                          // Nearby notifications tab
                          _buildNotificationsList(controller.nearbyNotifications),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CreateNotificationScreen());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Build the map view with notification markers
  Widget _buildMapView() {
    if (controller.currentLocation.value == null) {
      return Center(child: Text('Location not available'));
    }

    return Obx(() {
      return MapboxMap(
        accessToken: APIKeys.MAPBOXPUBLICTOKEN,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            controller.currentLocation.value!.latitude,
            controller.currentLocation.value!.longitude,
          ),
          zoom: 13.0,
        ),
        onMapCreated: (MapboxMapController mapController) {
          // Add markers for each notification
          _addNotificationMarkers(mapController);
        },
        onStyleLoadedCallback: () {
          // Map style loaded
        },
      );
    });
  }

  // Add markers for notifications
  void _addNotificationMarkers(MapboxMapController controller) {
    // Add marker for current location
    controller.addSymbol(SymbolOptions(
      geometry: LatLng(
        this.controller.currentLocation.value!.latitude,
        this.controller.currentLocation.value!.longitude,
      ),
      iconImage: 'car',
      iconSize: 1.5,
    ));

    // Add markers for each notification
    for (var notification in this.controller.nearbyNotifications) {
      controller.addSymbol(SymbolOptions(
        geometry: LatLng(
          notification.latitude,
          notification.longitude,
        ),
        iconImage: _getMarkerIconForType(notification.type),
        iconSize: 1.0,
        textField: notification.type,
        textOffset: Offset(0, 1.5),
      ));
    }
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
      default:
        return 'marker';
    }
  }

  // Build the notifications list
  Widget _buildNotificationsList(List<RoadNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share road information',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.updateCurrentLocation();
        await controller.fetchNearbyNotifications();
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(context, notification);
        },
      ),
    );
  }

  // Build a card for a single notification
  Widget _buildNotificationCard(BuildContext context, RoadNotification notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Get.to(() => NotificationDetailScreen(notification: notification));
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(notification.type),
                  SizedBox(width: 8),
                  Text(
                    notification.type.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForType(notification.type),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatTimeAgo(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                notification.message,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              if (notification.images.isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: notification.images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            notification.images[index],
                            height: 120,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Posted by ${notification.userName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () {
                      controller.likeNotification(notification.id);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.thumb_up, size: 16),
                        SizedBox(width: 4),
                        Text('${notification.likeCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build icon for notification type
  Widget _buildTypeIcon(String type) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'accident':
        iconData = Icons.car_crash;
        break;
      case 'traffic':
        iconData = Icons.traffic;
        break;
      case 'police':
        iconData = Icons.local_police;
        break;
      case 'hazard':
        iconData = Icons.warning;
        break;
      default:
        iconData = Icons.info;
    }

    return Icon(
      iconData,
      color: _getColorForType(type),
    );
  }

  // Get color for notification type
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Colors.red;
      case 'traffic':
        return Colors.orange;
      case 'police':
        return Colors.blue;
      case 'hazard':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }

  // Format timestamp to relative time
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

