import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/navigation_controller.dart';

class AddPlaceMapScreen extends StatefulWidget {
  const AddPlaceMapScreen({Key? key}) : super(key: key);

  @override
  _AddPlaceMapScreenState createState() => _AddPlaceMapScreenState();
}

class _AddPlaceMapScreenState extends State<AddPlaceMapScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  String? selectedAddress;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          if (selectedLocation != null)
            TextButton(
              onPressed: () {
                Get.back(result: {
                  'latitude': selectedLocation!.latitude,
                  'longitude': selectedLocation!.longitude,
                  'address': selectedAddress ?? 'Selected location',
                });
              },
              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: controller.currentLocation.value != null
                  ? LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude,
              )
                  : LatLng(37.7749, -122.4194), // Default to San Francisco
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: selectedLocation != null
                ? {
              Marker(
                markerId: MarkerId('selected_location'),
                position: selectedLocation!,
                infoWindow: InfoWindow(
                  title: 'Selected Location',
                  snippet: selectedAddress,
                ),
              ),
            }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (LatLng location) {
              _selectLocation(location);
            },
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap on the map to select a location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (selectedAddress != null) ...[
                      Text(
                        'Selected Address:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(selectedAddress!),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.my_location),
                          label: Text('Use My Location'),
                          onPressed: () {
                            if (controller.currentLocation.value != null) {
                              _selectLocation(LatLng(
                                controller.currentLocation.value!.latitude,
                                controller.currentLocation.value!.longitude,
                              ));
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.search),
                          label: Text('Search'),
                          onPressed: () {
                            _showSearchDialog();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(LatLng location) async {
    setState(() {
      selectedLocation = location;
      isLoading = true;
    });

    try {
      // Reverse geocode to get address
      final address = await controller.mapsService.reverseGeocode(
        LatLng(
          location.latitude,
          location.longitude,
        )
      );

      setState(() {
        selectedAddress = address?.address;
        isLoading = false;
      });

      // Add marker
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16),
        );
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Unknown location';
        isLoading = false;
      });
    }
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Search Location'),
        content: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Enter address or place name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _searchPlace(value);
              Get.back();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                _searchPlace(searchController.text);
                Get.back();
              }
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _searchPlace(String query) async {
    setState(() {
      isLoading = true;
    });

    try {
      await controller.searchPlaces(query);

      if (controller.searchResults.isNotEmpty) {
        final result = controller.searchResults.first;
        _selectLocation(LatLng(result.latitude, result.longitude));
      } else {
        Get.snackbar(
          'Error',
          'No results found for "$query"',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to search for location',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        isLoading = false;
      });
    }
  }
}
