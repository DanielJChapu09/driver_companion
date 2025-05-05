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
  final TextEditingController searchController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String selectedCategory = 'other';
  RxString searchQuery = ''.obs;
  RxBool isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    controller.loadSavedPlaces();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    searchController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => isSearching.value
            ? TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search places...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                searchQuery.value = '';
                isSearching.value = false;
              },
            ),
          ),
          autofocus: true,
          onChanged: (value) {
            searchQuery.value = value;
          },
        )
            : Text('Saved Places')
        ),
        actions: [
          Obx(() => isSearching.value
              ? Container()
              : IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              isSearching.value = true;
            },
          )
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddPlaceDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('All'),
                    selected: selectedCategory == 'all',
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = 'all';
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  ...controller.getPlaceCategories().map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: Icon(category['icon']),  // Just use the IconData directly
                        label: Text(category['name']),
                        selected: selectedCategory == category['id'],
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = selected ? category['id'] : 'all';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Places list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.favoritePlaces.isEmpty) {
                return _buildEmptyState();
              }

              // Filter places based on search query and selected category
              List<Place> filteredPlaces = controller.favoritePlaces.where((place) {
                bool matchesSearch = searchQuery.value.isEmpty ||
                    place.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                    place.address.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                    (place.notes?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false);

                bool matchesCategory = selectedCategory == 'all' || place.category == selectedCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredPlaces.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No places found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group places by category
              Map<String?, List<Place>> categorizedPlaces = {};

              for (var place in filteredPlaces) {
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlaceDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm"),
              content: Text("Are you sure you want to delete this place?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Delete"),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        controller.removeFromFavorites(place.id);
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () {
            // Get directions to this place
            if (controller.currentLocation.value != null) {
              controller.getDirections(
                LatLng(
                  controller.currentLocation.value!.latitude,
                  controller.currentLocation.value!.longitude,
                ),
                LatLng(place.latitude, place.longitude),
              );
              Get.back();
            }
          },
          child: ExpansionTile(
            leading: _getCategoryIcon(place.category),
            title: Text(
              place.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.lastVisited != null)
                  Text(
                    'Last visited: ${_formatDate(place.lastVisited!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (place.notes != null && place.notes!.isNotEmpty) ...[
                      Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(place.notes!),
                      SizedBox(height: 8),
                    ],
                    if (place.visitCount > 0)
                      Text('Visited ${place.visitCount} times'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.edit),
                          label: Text('Edit'),
                          onPressed: () {
                            _showEditPlaceDialog(place);
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.directions),
                          label: Text('Navigate'),
                          onPressed: () {
                            // Get directions to this place
                            if (controller.currentLocation.value != null) {
                              controller.getDirections(
                                LatLng(
                                  controller.currentLocation.value!.latitude,
                                  controller.currentLocation.value!.longitude,
                                ),
                                LatLng(place.latitude, place.longitude),
                              );
                              Get.back();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            place.isFavorite ? Icons.star : Icons.star_border,
                            color: place.isFavorite ? Colors.amber : null,
                          ),
                          onPressed: () {
                            controller.updatePlace(place.copyWith(
                              isFavorite: !place.isFavorite,
                            ));
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddPlaceDialog() {
    nameController.clear();
    addressController.clear();
    notesController.clear();
    selectedCategory = 'other';

    Get.dialog(
      AlertDialog(
        title: Text('Add New Place'),
        content: SingleChildScrollView(
          child: Column(
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
                  suffixIcon: IconButton(
                    icon: Icon(Icons.map),
                    onPressed: () {
                      // TODO: Implement map picker
                      Get.back();
                      Get.toNamed('/add-place-map')?.then((value) {
                        if (value != null && value is Map<String, dynamic>) {
                          addressController.text = value['address'];
                          // Show dialog again with the selected address
                          _showAddPlaceDialog();
                        }
                      });
                    },
                  ),
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
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
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
                  'Please fill in all required fields',
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
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );

                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'Could not find location. Try a different address or use the map picker.',
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
    notesController.text = place.notes ?? '';
    selectedCategory = place.category ?? 'other';

    Get.dialog(
      AlertDialog(
        title: Text('Edit Place'),
        content: SingleChildScrollView(
          child: Column(
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
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
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
                notes: notesController.text.isNotEmpty ? notesController.text : null,
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
      case 'hospital':
        iconData = Icons.local_hospital;
        break;
      case 'gym':
        iconData = Icons.fitness_center;
        break;
      case 'entertainment':
        iconData = Icons.movie;
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
      case 'hospital':
        return 'Hospitals';
      case 'gym':
        return 'Gyms';
      case 'entertainment':
        return 'Entertainment';
      default:
        return 'Other Places';
    }
  }
}
