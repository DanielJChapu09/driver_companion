import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../../../config/confidential/apikeys.dart';
import '../../../firebase_options.dart';
import '../controller/community_controller.dart';
import '../model/notifcation_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final RoadNotification notification;
  final CommunityController controller = Get.find<CommunityController>();

  NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.type.capitalize!),
        actions: [
          if (notification.userId == controller.currentLocation.value?.city)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context);
                } else if (value == 'resolve') {
                  _showResolveConfirmation(context);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'resolve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as Resolved'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map showing the notification location
            Container(
              height: 200,
              child: MapboxMap(
                accessToken: APIKeys.MAPBOXPUBLICTOKEN,
                initialCameraPosition: CameraPosition(
                  target: LatLng(notification.latitude, notification.longitude),
                  zoom: 14.0,
                ),
                onMapCreated: (MapboxMapController mapController) {
                  mapController.addSymbol(SymbolOptions(
                    geometry: LatLng(notification.latitude, notification.longitude),
                    iconImage: _getMarkerIconForType(notification.type),
                    iconSize: 1.5,
                  ));
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification header
                  Row(
                    children: [
                      _buildTypeIcon(notification.type),
                      SizedBox(width: 8),
                      Text(
                        notification.type.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _getColorForType(notification.type),
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('MMM d, h:mm a').format(notification.timestamp),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Notification message
                  Text(
                    notification.message,
                    style: TextStyle(fontSize: 18),
                  ),

                  SizedBox(height: 16),

                  // Images if available
                  if (notification.images.isNotEmpty) ...[
                    Text(
                      'Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: notification.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Show full screen image
                            Get.to(() => Scaffold(
                              appBar: AppBar(
                                backgroundColor: Colors.black,
                                iconTheme: IconThemeData(color: Colors.white),
                              ),
                              backgroundColor: Colors.black,
                              body: Center(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    notification.images[index],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              notification.images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                  ],

                  // Location info
                  Text(
                    'Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${notification.city}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // User info
                  Text(
                    'Posted by',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(notification.userName.substring(0, 1)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        notification.userName,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.thumb_up,
                        label: 'Helpful (${notification.likeCount})',
                        onTap: () {
                          controller.likeNotification(notification.id);
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          // Implement share functionality
                          Get.snackbar(
                            'Share',
                            'Sharing functionality to be implemented',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: () {
                          // Implement directions functionality
                          Get.snackbar(
                            'Directions',
                            'Navigation to be implemented',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Notification'),
          content: Text('Are you sure you want to delete this notification?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.deleteNotification(notification.id);
                Get.back();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Show resolve confirmation dialog
  void _showResolveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark as Resolved'),
          content: Text('Is this road condition no longer an issue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.markNotificationAsResolved(notification.id);
                Get.back();
              },
              child: Text('Confirm', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
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
      case 'construction':
        iconData = Icons.construction;
        break;
      default:
        iconData = Icons.info;
    }

    return Icon(
      iconData,
      color: _getColorForType(type),
      size: 28,
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
      case 'construction':
        return Colors.yellow[800]!;
      default:
        return Colors.teal;
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
      case 'construction':
        return 'construction';
      default:
        return 'marker';
    }
  }
}

