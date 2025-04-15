import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../controller/navigation_controller.dart';
import '../model/search_result_model.dart';
import '../model/place_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final NavigationController controller = Get.find<NavigationController>();
  final TextEditingController searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.loadSavedPlaces();
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Destinations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Search'),
            Tab(text: 'Saved Places'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildSavedPlacesTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Search input
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search for a place',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  controller.searchResults.clear();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              if (value.length > 2) {
                controller.searchPlaces(value);
              } else if (value.isEmpty) {
                controller.searchResults.clear();
              }
            },
          ),
        ),

        // Search results
        Expanded(
          child: Obx(() {
            if (controller.isSearching.value) {
              return Center(child: CircularProgressIndicator());
            }

            if (controller.searchResults.isEmpty) {
              if (controller.searchQuery.value.length > 2) {
                return Center(
                  child: Text('No results found'),
                );
              } else {
                return _buildRecentSearches();
              }
            }

            return ListView.builder(
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                SearchResult result = controller.searchResults[index];
                return _buildSearchResultItem(result);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return ListTile(
      leading: Icon(Icons.place),
      title: Text(result.name),
      subtitle: Text(
        result.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(Icons.star_border),
        onPressed: () {
          controller.addToFavorites(
            result.latitude,
            result.longitude,
            result.name,
            result.address,
          );
        },
      ),
      onTap: () {
        // Get directions to this place
        if (controller.currentLocation.value != null) {
          controller.getDirections(
            LatLng(
              controller.currentLocation.value!.latitude!,
              controller.currentLocation.value!.longitude!,
            ),
            LatLng(result.latitude, result.longitude),
          );

          // Add to recent places
          controller.addToRecentPlaces(
            result.latitude,
            result.longitude,
            result.address,
          );

          Get.back();
        }
      },
    );
  }

  Widget _buildRecentSearches() {
    return Obx(() {
      if (controller.recentPlaces.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No recent searches',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.clearRecentPlaces();
                  },
                  child: Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentPlaces.length,
              itemBuilder: (context, index) {
                Place place = controller.recentPlaces[index];
                return ListTile(
                  leading: Icon(Icons.history),
                  title: Text(place.name),
                  subtitle: Text(
                    place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTimeAgo(place.lastVisited!),
                    style: TextStyle(color: Colors.grey),
                  ),
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
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSavedPlacesTab() {
    return Obx(() {
      if (controller.favoritePlaces.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No saved places',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Add places to your favorites for quick access',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
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
                child: Text(
                  category?.capitalize ?? 'Other',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...places.map((place) => _buildSavedPlaceItem(place)).toList(),
              Divider(),
            ],
          );
        },
      );
    });
  }

  Widget _buildSavedPlaceItem(Place place) {
    IconData iconData;

    switch (place.category) {
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

    return ListTile(
      leading: Icon(iconData),
      title: Text(place.name),
      subtitle: Text(
        place.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () {
          controller.removeFromFavorites(place.id);
        },
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
      onLongPress: () {
        _showEditPlaceDialog(place);
      },
    );
  }

  void _showEditPlaceDialog(Place place) {
    TextEditingController nameController = TextEditingController(text: place.name);
    String selectedCategory = place.category ?? 'other';

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

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

