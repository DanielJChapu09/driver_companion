import 'dart:typed_data' show Uint8List;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:mymaptest/config/confidential/apikeys.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/core/utils/logs.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';

import '../../../core/constants/map_styles.dart';
import '../../../widgets/snackbar/custom_snackbar.dart';
import '../../navigation/model/search_result_model.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final NavigationController controller = Get.find<NavigationController>();
  final MapController _mapController = MapController();
  bool _initialPositionEstablished = false;
  bool _isLoadingDestination = false;
  SearchResult? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
              return Center(child: CircularProgressIndicator());
            }

            // return MapboxMap(
            //   accessToken: APIKeys.MAPBOXPUBLICTOKEN,
            //   initialCameraPosition: CameraPosition(
            //     target: LatLng(
            //       controller.currentLocation.value!.latitude,
            //       controller.currentLocation.value!.longitude,
            //     ),
            //     zoom: 14.0,
            //   ),
            //   onMapCreated: (MapboxMapController mapController) async {
            //     controller.setMapController(mapController);
            //
            //     // Add custom markers
            //     mapController.addImage(
            //       "marker-start",
            //       await _createMarkerImage(Colors.green, Icons.trip_origin),
            //     );
            //
            //     mapController.addImage(
            //       "marker-end",
            //       await _createMarkerImage(Colors.red, Icons.place),
            //     );
            //
            //     // Center on user's location once map is created
            //     if (!_initialPositionEstablished && controller.currentLocation.value != null) {
            //       mapController.animateCamera(
            //         CameraUpdate.newLatLngZoom(
            //           LatLng(
            //             controller.currentLocation.value!.latitude,
            //             controller.currentLocation.value!.longitude,
            //           ),
            //           15.0,
            //         ),
            //       );
            //       _initialPositionEstablished = true;
            //     }
            //   },
            //   onMapClick: _handleMapTap,
            //   myLocationEnabled: true,
            //   myLocationTrackingMode: MyLocationTrackingMode.Tracking,
            //   compassEnabled: true,
            //   onStyleLoadedCallback: () {
            //     DevLogs.logSuccess('Map style loaded');
            //   },
            // );

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: latlong2.LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                initialZoom: 16,
                maxZoom: 40,
                minZoom: 0,

                onTap: (tapPosition, point) {
                  _handleMapTap(coordinates: LatLng(point.latitude, point.longitude));
                },

              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${APIKeys.MAPBOXPUBLICTOKEN}',
                  additionalOptions: {
                    'accessToken': APIKeys.MAPBOXPUBLICTOKEN
                  },
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      width: 20,
                      height: 20,
                      point: latlong2.LatLng(controller.currentLocation.value!.latitude, controller.currentLocation.value!.longitude),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                          Colors.green.withOpacity(0.5),
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 12,
                                height:12,
                                decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue
                                            .withValues(alpha: 0.5),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset:
                                        const Offset(
                                            0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if(_selectedDestination != null) Marker(
                      width: 20,
                      height: 20,
                      point: latlong2.LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.orange,
                        size: 50,
                      ),
                    ),
                  ],
                ),


                if (controller.currentRoute.value != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: controller.currentRoute.value!.steps.map((step) => latlong2.LatLng(step.startLatitude, step.startLongitude)).toList(),
                        strokeWidth: 4.0,
                        color: AppColors.blue,
                      ),
                    ],
                  ),
              ],

            );
          }),

          // Loading indicator for destination selection
          if (_isLoadingDestination)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
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
                            controller.currentLocation.value!.latitude,
                            controller.currentLocation.value!.longitude,
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

          // Route preview card (only shown when destination is selected)
          if (_selectedDestination != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: _buildRoutePreviewCard(),
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

  // Handle map tap to select destination
  void _handleMapTap({required LatLng coordinates}) async {
    // Don't process taps if already loading or navigating
    if (_isLoadingDestination || controller.isNavigating.value) return;

    setState(() {
      _isLoadingDestination = true;
      _selectedDestination = null;
    });

    try {
      // Clear previous routes and markers
      if (controller.mapController.value != null) {
        controller.mapController.value!.clearSymbols();
        controller.mapController.value!.clearLines();
      }

      // Add destination marker
      if (controller.mapController.value != null) {
        controller.mapController.value!.addSymbol(
          SymbolOptions(
            geometry: coordinates,
            iconImage: "marker-end",
            iconSize: 1.5,
          ),
        );
      }

      setState(() {
        _selectedDestination = SearchResult(
          address: '',
          id: '',
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          name: '',
        );
      });

      // Add route preview
        // Get directions to this location
        if (controller.currentLocation.value != null) {
          await controller.getDirections(
            LatLng(
              controller.currentLocation.value!.latitude,
              controller.currentLocation.value!.longitude,
            ),
            LatLng(coordinates.latitude, coordinates.longitude),
          );
        }


      // Reverse geocode to get address
      // SearchResult? result = await controller.mapboxService.reverseGeocode(coordinates);
      //
      // if (result != null) {
      //   setState(() {
      //     _selectedDestination = result;
      //   });
      //
      //   // Get directions to this location
      //   if (controller.currentLocation.value != null) {
      //     // await controller.getDirections(
      //     //   LatLng(
      //     //     controller.currentLocation.value!.latitude,
      //     //     controller.currentLocation.value!.longitude,
      //     //   ),
      //     //   LatLng(coordinates.latitude, coordinates.longitude),
      //     // );
      //
      //     await controller.getRoutePreview(
      //         latlong2.LatLng(
      //           controller.currentLocation.value!.latitude,
      //           controller.currentLocation.value!.longitude,
      //         ),
      //         latlong2.LatLng(coordinates.latitude, coordinates.longitude),
      //     );
      //   }
      // } else {
      //   CustomSnackBar.showErrorSnackbar(
      //     message: 'Could not find address for this location',
      //   );
      // }
    } catch (e) {
      DevLogs.logError('Error handling map tap: $e');
      CustomSnackBar.showErrorSnackbar(
        message:'Failed to process location',
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
      return SizedBox.shrink();
    }

    final route = controller.currentRoute.value!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12),

            // Route info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      _formatDistance(route.distance),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Duration
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      _formatDuration(route.duration),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // ETA
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      _formatETA(route.duration),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Save button
                OutlinedButton.icon(
                  onPressed: () {
                    _showSavePlaceDialog(_selectedDestination!);
                  },
                  icon: Icon(Icons.star_border),
                  label: Text('Save'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Start navigation button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.startNavigation();
                      Get.toNamed(Routes.navigationScreen);
                    },
                    icon: Icon(Icons.navigation),
                    label: Text('Start'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Close button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDestination = null;
                    });
                    controller.currentRoute.value = null;

                    // Clear map
                    if (controller.mapController.value != null) {
                      controller.mapController.value!.clearSymbols();
                      controller.mapController.value!.clearLines();
                    }
                  },
                  icon: Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: CircleBorder(),
                  ),
                ),
              ],
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
        title: Text('Save Place'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
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
            },
            child: Text('Save'),
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

