import 'dart:typed_data' show Uint8List;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final NavigationController controller = Get.find<NavigationController>();
  final Location location = Location();
  bool _initialPositionEstablished = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData locationData = await location.getLocation();
      controller.currentLocation.value = locationData;
    } catch (e) {
      print('Error getting current location: $e');
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

            return MapboxMap(
              accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN', // Replace with your Mapbox token
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude!,
                  controller.currentLocation.value!.longitude!,
                ),
                zoom: 14.0,
              ),
              onMapCreated: (MapboxMapController mapController) async{
                controller.setMapController(mapController);

                // Add custom markers
                mapController.addImage(
                  "marker-start",
                  await _createMarkerImage(Colors.green, Icons.trip_origin),
                );

                mapController.addImage(
                  "marker-end",
                  await _createMarkerImage(Colors.red, Icons.place),
                );

                // Center on user's location once map is created
                if (!_initialPositionEstablished && controller.currentLocation.value != null) {
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        controller.currentLocation.value!.latitude!,
                        controller.currentLocation.value!.longitude!,
                      ),
                      15.0,
                    ),
                  );
                  _initialPositionEstablished = true;
                }
              },
              myLocationEnabled: true,
              myLocationTrackingMode: MyLocationTrackingMode.Tracking,
              compassEnabled: true,
              onStyleLoadedCallback: () {
                DevLogs.logSuccess('Map style loaded');
              },
            );
          }),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: ()=> Get.toNamed(Routes.searchScreen),
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
                            controller.currentLocation.value!.latitude!,
                            controller.currentLocation.value!.longitude!,
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

          // Navigation button (only shown when route is available)
          Obx(() {
            if (controller.currentRoute.value != null && !controller.isNavigating.value) {
              return Positioned(
                bottom: 16,
                left: 16,
                right: 80,
                child: ElevatedButton(
                  onPressed: () {
                    controller.startNavigation();
                    Get.toNamed(Routes.navigationScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Start Navigation',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),

          // Continue navigation button (only shown when navigating)
          Obx(() {
            if (controller.isNavigating.value) {
              return Positioned(
                bottom: 16,
                left: 16,
                right: 80,
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
        ],
      ),
    );
  }

  // Create custom marker image
  Future<Uint8List> _createMarkerImage(Color color, IconData icon) async {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = color;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 40,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    canvas.drawCircle(Offset(48, 48), 24, paint);
    textPainter.paint(canvas, Offset(48 - textPainter.width / 2, 48 - textPainter.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(96, 96);
    final byteData = await img.toByteData(format: ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}

