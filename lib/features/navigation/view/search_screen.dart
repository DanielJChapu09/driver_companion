import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controller/navigation_controller.dart';
import '../model/search_result_model.dart';
import '../model/place_model.dart';
import 'route_selection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final NavigationController controller = Get.find<NavigationController>();
  final TextEditingController searchController = TextEditingController();
  late TabController _tabController;
  bool _darkMode = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.loadSavedPlaces();
    // Remove MediaQuery access from here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check system brightness here instead
    final brightness = MediaQuery.of(context).platformBrightness;
    setState(() {
      _darkMode = brightness == Brightness.dark;
    });
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
        backgroundColor: _darkMode ? Colors.black : Colors.white,
        foregroundColor: _darkMode ? Colors.white : Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Search'),
            Tab(text: 'Saved Places'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: _darkMode ? Colors.white70 : Colors.black54,
          indicatorColor: Colors.blue,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode),
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
              });
            },
          ),
        ],
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
    return Container(
      color: _darkMode ? Colors.black : Colors.white,
      child: Column(
        children: [
          // Search input
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place',
                hintStyle: TextStyle(
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    searchController.clear();
                    controller.searchResults.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _darkMode ? Colors.white24 : Colors.black12,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _darkMode ? Colors.white24 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue,
                  ),
                ),
                filled: true,
                fillColor: _darkMode ? Colors.grey[900] : Colors.grey[100],
              ),
              style: TextStyle(
                color: _darkMode ? Colors.white : Colors.black,
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
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                );
              }

              if (controller.searchResults.isEmpty) {
                if (controller.searchQuery.value.length > 2) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: _darkMode ? Colors.white70 : Colors.black54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: _darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _darkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _darkMode ? Colors.grey[800] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.place,
            color: Colors.blue,
          ),
        ),
        title: Text(
          result.name,
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          result.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _darkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.star_border,
            color: _darkMode ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {
            controller.addToFavorites(
              result.latitude,
              result.longitude,
              result.name,
              result.address,
              category: result.category,
            );
          },
        ),
        onTap: () {
          // Get directions to this place
          if (controller.currentLocation.value != null) {
            // Add to recent places
            controller.addToRecentPlaces(
              result.latitude,
              result.longitude,
              result.address,
            );

            // Navigate to route selection screen
            Get.to(() => RouteSelectionScreen(
              origin: LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude,
              ),
              destination: LatLng(result.latitude, result.longitude),
              destinationName: result.name,
            ));
          }
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Obx(() {
      if (controller.recentPlaces.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: _darkMode ? Colors.white70 : Colors.black54,
              ),
              SizedBox(height: 16),
              Text(
                'No recent searches',
                style: TextStyle(
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
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
                    color: _darkMode ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    controller.clearRecentPlaces();
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentPlaces.length,
              itemBuilder: (context, index) {
                Place place = controller.recentPlaces[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: _darkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _darkMode ? Colors.grey[800] : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      place.name,
                      style: TextStyle(
                        color: _darkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      place.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _darkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    trailing: Text(
                      _formatTimeAgo(place.lastVisited!),
                      style: TextStyle(
                        color: _darkMode ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      // Get directions to this place
                      if (controller.currentLocation.value != null) {
                        // Navigate to route selection screen
                        Get.to(() => RouteSelectionScreen(
                          origin: LatLng(
                            controller.currentLocation.value!.latitude,
                            controller.currentLocation.value!.longitude,
                          ),
                          destination: LatLng(place.latitude, place.longitude),
                          destinationName: place.name,
                        ));
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSavedPlacesTab() {
    return Container(
      color: _darkMode ? Colors.black : Colors.white,
      child: Obx(() {
        if (controller.favoritePlaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 48,
                  color: _darkMode ? Colors.white70 : Colors.black54,
                ),
                SizedBox(height: 16),
                Text(
                  'No saved places',
                  style: TextStyle(
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add places to your favorites for quick access',
                  style: TextStyle(
                    color: _darkMode ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
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
                    _formatCategory(category),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                ...places.map((place) => _buildSavedPlaceItem(place)).toList(),
                Divider(
                  color: _darkMode ? Colors.white24 : Colors.black12,
                  height: 32,
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildSavedPlaceItem(Place place) {
    IconData iconData = _getCategoryIcon(place.category);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _darkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _darkMode ? Colors.grey[800] : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: Colors.blue,
          ),
        ),
        title: Text(
          place.name,
          style: TextStyle(
            color: _darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          place.address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _darkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: _darkMode ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {
            controller.removeFromFavorites(place.id);
          },
        ),
        onTap: () {
          // Get directions to this place
          if (controller.currentLocation.value != null) {
            // Navigate to route selection screen
            Get.to(() => RouteSelectionScreen(
              origin: LatLng(
                controller.currentLocation.value!.latitude,
                controller.currentLocation.value!.longitude,
              ),
              destination: LatLng(place.latitude, place.longitude),
              destinationName: place.name,
            ));
          }
        },
        onLongPress: () {
          _showEditPlaceDialog(place);
        },
      ),
    );
  }

  void _showEditPlaceDialog(Place place) {
    TextEditingController nameController = TextEditingController(text: place.name);
    String selectedCategory = place.category ?? 'other';

    Get.dialog(
      Dialog(
        backgroundColor: _darkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Place',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _darkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(
                    color: _darkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _darkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
                dropdownColor: _darkMode ? Colors.grey[800] : Colors.white,
                items: controller.getPlaceCategories().map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'],
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category['id']),
                          color: _darkMode ? Colors.white : Colors.black,
                        ),
                        SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      controller.updatePlace(place.copyWith(
                        name: nameController.text,
                        category: selectedCategory,
                      ));
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_cart;
      case 'gas':
        return Icons.local_gas_station;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.place;
    }
  }

  String _formatCategory(String? category) {
    if (category == null) return 'Other';

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
        return category.capitalize ?? 'Other';
    }
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
