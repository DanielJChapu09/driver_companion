import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/navigation_controller.dart';
import '../model/place_model.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  _SavedPlacesScreenState createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String selectedCategory = 'other';

  @override
  void initState() {
    super.initState();
    controller.loadSavedPlaces();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Places'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddPlaceDialog();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.favoritePlaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No saved places',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your favorite places for quick access',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddPlaceDialog();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Place'),
                ),
              ],
            ),
          );
        }

        // Group places by category
        Map<String?, List<Place>> categorizedPlaces = {};

        for (var place in controller.favoritePlaces) {
          if (!categorizedPlaces.containsKey(place.category)) {
            categorizedPlaces[place.category] = [];
          }
          categorizedPlaces[place.category]!.add(place);
        }

        // Sort categories with 'home' and 'work' first
        List<String?> sortedCategories = categorizedPlaces.keys.toList();
        sortedCategories.sort((a, b) {
          if (a == 'home') return -1;
          if (b == 'home') return 1;
          if (a == 'work') return -1;
          if (b == 'work') return 1;
          return (a ?? '').compareTo(b ?? '');
        });

        return ListView.builder(
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            String? category = sortedCategories[index];
            List<Place> places = categorizedPlaces[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _getCategoryIcon(category),
                      SizedBox(width: 8),
                      Text(
                        _getCategoryName(category),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ...places.map((place) => _buildPlaceItem(place)).toList(),
                Divider(),
              ],
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlaceDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaceItem(Place place) {
    return Dismissible(
      key: Key(place.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        controller.removeFromFavorites(place.id);
      },
      child: ListTile(
        leading: _getCategoryIcon(place.category),
        title: Text(place.name),
        subtitle: Text(
          place.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditPlaceDialog(place);
              },
            ),
            IconButton(
              icon: Icon(Icons.directions),
              onPressed: () {
                // Get directions to this place
                if (controller.currentLocation.value != null) {
                  controller.getDirections(
                    LatLng(
                      controller.currentLocation.value!.latitude!,
                      controller.currentLocation.value!.longitude!,
                    ),
                    LatLng(place.latitude, place.longitude),
                  );
                  Get.back();
                }
              },
            ),
          ],
        ),
        onTap: () {
          // Get directions to this place
          if (controller.currentLocation.value != null) {
            controller.getDirections(
              LatLng(
                controller.currentLocation.value!.latitude!,
                controller.currentLocation.value!.longitude!,
              ),
              LatLng(place.latitude, place.longitude),
            );
            Get.back();
          }
        },
      ),
    );
  }

  void _showAddPlaceDialog() {
    nameController.clear();
    addressController.clear();
    selectedCategory = 'other';

    Get.dialog(
      AlertDialog(
        title: Text('Add New Place'),
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
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                hintText: 'Or tap on map to select location',
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
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please fill in all fields',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              // For simplicity, we'll use geocoding to get coordinates from address
              // In a real app, you'd want to use a map picker or more robust geocoding
              controller.searchPlaces(addressController.text).then((_) {
                if (controller.searchResults.isNotEmpty) {
                  final result = controller.searchResults.first;

                  controller.addToFavorites(
                    result.latitude,
                    result.longitude,
                    nameController.text,
                    result.address,
                    category: selectedCategory,
                  );

                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'Could not find location. Try a different address.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              });
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPlaceDialog(Place place) {
    nameController.text = place.name;
    addressController.text = place.address;
    selectedCategory = place.category ?? 'other';

    Get.dialog(
      AlertDialog(
        title: Text('Edit Place'),
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
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                enabled: false, // Don't allow address editing to maintain coordinates
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
              if (nameController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Name cannot be empty',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              controller.updatePlace(place.copyWith(
                name: nameController.text,
                category: selectedCategory,
              ));

              Get.back();
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String? category) {
    IconData iconData;

    switch (category) {
      case 'home':
        iconData = Icons.home;
        break;
      case 'work':
        iconData = Icons.work;
        break;
      case 'school':
        iconData = Icons.school;
        break;
      case 'restaurant':
        iconData = Icons.restaurant;
        break;
      case 'shopping':
        iconData = Icons.shopping_cart;
        break;
      case 'gas':
        iconData = Icons.local_gas_station;
        break;
      case 'parking':
        iconData = Icons.local_parking;
        break;
      default:
        iconData = Icons.place;
    }

    return Icon(iconData);
  }

  String _getCategoryName(String? category) {
    switch (category) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      case 'school':
        return 'School';
      case 'restaurant':
        return 'Restaurants';
      case 'shopping':
        return 'Shopping';
      case 'gas':
        return 'Gas Stations';
      case 'parking':
        return 'Parking';
      default:
        return 'Other Places';
    }
  }
}
