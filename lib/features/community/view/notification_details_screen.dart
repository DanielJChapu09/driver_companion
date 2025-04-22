import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/community_controller.dart';
import '../model/notifcation_model.dart';

class NotificationDetailScreen extends StatefulWidget {
  final RoadNotification notification;

  NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final CommunityController controller = Get.find<CommunityController>();
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notification.type.capitalize!),
        actions: [
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
              });
            },
          ),
          if (widget.notification.userId == controller.currentLocation.value?.city)
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
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.notification.latitude, widget.notification.longitude),
                  zoom: 14.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  setState(() {
                    _markers.add(
                      Marker(
                        markerId: MarkerId('notification'),
                        position: LatLng(
                          widget.notification.latitude,
                          widget.notification.longitude,
                        ),
                        icon: _getMarkerIconForType(widget.notification.type),
                        infoWindow: InfoWindow(title: widget.notification.type),
                      ),
                    );
                  });
                },
                markers: _markers,
                myLocationEnabled: true,
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
                      _buildTypeIcon(widget.notification.type),
                      SizedBox(width: 8),
                      Text(
                        widget.notification.type.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _getColorForType(widget.notification.type),
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('MMM d, h:mm a').format(widget.notification.timestamp),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Notification message
                  Text(
                    widget.notification.message,
                    style: TextStyle(fontSize: 18),
                  ),

                  SizedBox(height: 16),

                  // Images if available
                  if (widget.notification.images.isNotEmpty) ...[
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
                      itemCount: widget.notification.images.length,
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
                                    widget.notification.images[index],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.notification.images[index],
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
                          '${widget.notification.city}',
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
                        child: Text(widget.notification.userName.substring(0, 1)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        widget.notification.userName,
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
                        label: 'Helpful (${widget.notification.likeCount})',
                        onTap: () {
                          controller.likeNotification(widget.notification.id);
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
                controller.deleteNotification(widget.notification.id);
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
                controller.markNotificationAsResolved(widget.notification.id);
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
