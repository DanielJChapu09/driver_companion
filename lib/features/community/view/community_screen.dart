import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../../../firebase_options.dart';
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.updateCurrentLocation();
              controller.fetchNearbyNotifications();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${controller.errorMessage.value}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.initializeServices(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Map view showing nearby notifications
            SizedBox(
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
                      tabs: const [
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
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build the map view with notification markers
  Widget _buildMapView() {
    if (controller.currentLocation.value == null) {
      return const Center(child: Text('Location not available'));
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
          // Load map images and then add markers
          _loadMapImages(mapController).then((_) {
            // Add markers for each notification
            _addNotificationMarkers(mapController);
          }).catchError((error) {
            print('Error loading map resources: $error');
          });
        },
        onStyleLoadedCallback: () {
          // Map style loaded
          print('Map style loaded successfully');
        },
      );
    });
  }

  // Load map images before adding symbols
  Future<void> _loadMapImages(MapboxMapController controller) async {
    // Make sure to add these assets to your pubspec.yaml
    final images = {
      'car': 'assets/images/car.png',
      'accident': 'assets/images/accident.png',
      'traffic': 'assets/images/traffic.png',
      'police': 'assets/images/police.png',
      'hazard': 'assets/images/hazard.png',
      'marker': 'assets/images/marker.png',
    };

    for (final entry in images.entries) {
      try {
        final ByteData bytes = await rootBundle.load(entry.value);
        final Uint8List list = bytes.buffer.asUint8List();
        await controller.addImage(entry.key, list);
        print('Successfully loaded image: ${entry.key}');
      } catch (e) {
        print('Failed to load image asset: ${entry.value}: $e');
        // Add a fallback blank image as a placeholder
        final placeholderImage = await _createPlaceholderImage(40, 40);
        await controller.addImage(entry.key, placeholderImage);
      }
    }
  }

  // Create a placeholder image when actual assets are missing
  Future<Uint8List> _createPlaceholderImage(int width, int height) async {
    final size = width * height * 4; // RGBA
    final placeholder = Uint8List(size);

    // Fill with a simple colored square (red)
    for (var i = 0; i < size; i += 4) {
      placeholder[i] = 255; // R
      placeholder[i + 1] = 0; // G
      placeholder[i + 2] = 0; // B
      placeholder[i + 3] = 255; // A
    }

    return placeholder;
  }

  // Add markers for notifications
  void _addNotificationMarkers(MapboxMapController mapController) {
    if (this.controller.currentLocation.value == null) {
      print('Current location is null, cannot add markers');
      return;
    }

    try {
      // Add marker for current location
      mapController.addSymbol(SymbolOptions(
        geometry: LatLng(
          this.controller.currentLocation.value!.latitude,
          this.controller.currentLocation.value!.longitude,
        ),
        iconImage: 'car',
        iconSize: 1.5,
      )).then((symbol) {
        print('Added current location symbol successfully');
      }).catchError((error) {
        print('Error adding current location symbol: $error');
      });

      // Add markers for each notification
      for (var notification in this.controller.nearbyNotifications) {
        final iconImage = _getMarkerIconForType(notification.type);
        mapController.addSymbol(SymbolOptions(
          geometry: LatLng(
            notification.latitude,
            notification.longitude,
          ),
          iconImage: iconImage,
          iconSize: 1.0,
          textField: notification.type,
          textOffset: const Offset(0, 1.5),
          textColor: '#000000',
          textSize: 12.0,
        )).then((symbol) {
          print('Added notification symbol successfully');
        }).catchError((error) {
          print('Error adding notification symbol: $error');
        });
      }
    } catch (e) {
      print('Error in _addNotificationMarkers: $e');
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
          children: const [
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Get.to(() => NotificationDetailScreen(notification: notification));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(notification.type),
                  const SizedBox(width: 8),
                  Text(
                    notification.type.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForType(notification.type),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(notification.timestamp),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (notification.images.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: notification.images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            notification.images[index],
                            height: 120,
                            width: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                width: 160,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.error),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Posted by ${notification.userName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      controller.likeNotification(notification.id);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_up, size: 16),
                        const SizedBox(width: 4),
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