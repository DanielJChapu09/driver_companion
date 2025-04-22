import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mymaptest/config/confidential/apikeys.dart';
import '../controller/navigation_controller.dart';
import '../model/search_result_model.dart';

class AddPlaceMapScreen extends StatefulWidget {
  final Function(double latitude, double longitude, String address) onPlaceSelected;

  const AddPlaceMapScreen({super.key, required this.onPlaceSelected});

  @override
  State<AddPlaceMapScreen> createState() => _AddPlaceMapScreenState();
}

class _AddPlaceMapScreenState extends State<AddPlaceMapScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  LatLng? selectedLocation;
  String? selectedAddress;
  bool isLoading = false;
  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.currentLocation.value == null) {
              return Center(child: CircularProgressIndicator());
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  controller.currentLocation.value!.latitude!,
                  controller.currentLocation.value!.longitude!,
                ),
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              onTap: (coordinates) {
                _handleMapClick(coordinates);
              },
              myLocationEnabled: true,
              compassEnabled: true,
            );
          }),

          // Center marker
          Center(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 36,
            ),
          ),

          // Selected location info
          if (selectedLocation != null && selectedAddress != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(selectedAddress!),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onPlaceSelected(
                                selectedLocation!.latitude,
                                selectedLocation!.longitude,
                                selectedAddress!,
                              );
                              Get.back();
                            },
                            child: Text('Use This Location'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMapClick(LatLng coordinates) async {
    setState(() {
      isLoading = true;
      selectedLocation = coordinates;
      selectedAddress = null;
    });

    try {
      // Reverse geocode to get address
      // SearchResult? result = await controller.mapboxService.reverseGeocode(coordinates);
      //TODO: Implement reverse geocoding with Google Maps API

      setState(() {
        isLoading = false;
        selectedAddress = 'Unknown location';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        selectedAddress = 'Error getting address';
      });

      print('Error reverse geocoding: $e');
    }
  }
}
