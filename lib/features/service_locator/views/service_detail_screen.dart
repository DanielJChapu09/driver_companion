import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../navigation/view/route_selection_screen.dart';
import '../model/service_location_model.dart';
import '../controller/service_locator_controller.dart';
import 'package:flutter/services.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceLocation service;

  const ServiceDetailsScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> with SingleTickerProviderStateMixin {
  final ServiceLocatorController controller = Get.find<ServiceLocatorController>();
  late TabController _tabController;
  bool _isMapExpanded = false;
  final GlobalKey _mapKey = GlobalKey();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Set status bar to transparent for immersive design
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    // Reset system UI when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        physics: _isMapExpanded
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        slivers: [
          // Flexible app bar with map
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: primaryColor,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Map as background
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMapExpanded = !_isMapExpanded;
                        });
                      },
                      child: Hero(
                        tag: 'map_${widget.service.id}',
                        child: GoogleMap(
                          key: _mapKey,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(widget.service.latitude, widget.service.longitude),
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(widget.service.id),
                              position: LatLng(widget.service.latitude, widget.service.longitude),
                              infoWindow: InfoWindow(title: widget.service.name),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                            ),
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Service name and rating
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(widget.service.category),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                controller.getServiceCategories()[widget.service.category] ?? widget.service.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.service.isOpen ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.service.isOpen ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Color.fromARGB(150, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.service.rating != null) ...[
                              _buildRatingStars(widget.service.rating!),
                              const SizedBox(width: 8),
                              Text(
                                widget.service.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (widget.service.distance != null)
                              Text(
                                '${widget.service.distance!.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Map controls
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        _buildMapButton(
                          icon: Icons.fullscreen,
                          onTap: () {
                            setState(() {
                              _isMapExpanded = !_isMapExpanded;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildMapButton(
                          icon: Icons.my_location,
                          onTap: () {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(widget.service.latitude, widget.service.longitude),
                                16.0,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          bool isFavorite = controller.favoriteServices.any((s) => s.id == widget.service.id);
                          return _buildMapButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            backgroundColor: isFavorite ? Colors.red : Colors.white,
                            iconColor: isFavorite ? Colors.white : Colors.red,
                            onTap: () {
                              if (isFavorite) {
                                controller.removeServiceFromFavorites(widget.service.id);
                              } else {
                                controller.addServiceToFavorites(widget.service);
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // If map is expanded, show only the map
          if (_isMapExpanded)
            SliverFillRemaining(
              child: Container(),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab bar for Info and Reviews
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primaryColor,
                      unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey[600],
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'DETAILS'),
                        Tab(text: 'AMENITIES'),
                      ],
                    ),
                  ),

                  // Tab content
                  SizedBox(
                    height: 500, // Fixed height for tab content
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Details tab
                        _buildDetailsTab(context, isDarkMode),

                        // Amenities tab
                        _buildAmenitiesTab(context, isDarkMode),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // Bottom navigation bar with action buttons
      bottomNavigationBar: _isMapExpanded
          ? null
          : Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Call button
            if (widget.service.phoneNumber != null && widget.service.phoneNumber!.isNotEmpty)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () {
                    // Launch phone call
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Spacer if both buttons are shown
            if (widget.service.phoneNumber != null && widget.service.phoneNumber!.isNotEmpty)
              const SizedBox(width: 12),

            // Navigate button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate'),
                onPressed: () {
                  // Navigate to route selection screen
                  Get.back();
                  Get.to(() => RouteSelectionScreen(
                    origin: LatLng(
                      controller.currentLocation.value!.latitude,
                      controller.currentLocation.value!.longitude,
                    ),
                    destination: LatLng(widget.service.latitude, widget.service.longitude),
                    destinationName: widget.service.name,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Details tab content
  Widget _buildDetailsTab(BuildContext context, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address card
          _buildInfoCard(
            context,
            isDarkMode,
            title: 'Address',
            icon: Icons.location_on,
            iconColor: Colors.red,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.address,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () {
                        // Copy address to clipboard
                        Clipboard.setData(ClipboardData(text: widget.service.address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address copied to clipboard')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: isDarkMode ? Colors.white30 : Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.service.distance != null && widget.service.duration != null)
                      Text(
                        '${widget.service.duration!.toStringAsFixed(0)} min drive',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contact info card
          if (widget.service.phoneNumber != null || widget.service.website != null)
            _buildInfoCard(
              context,
              isDarkMode,
              title: 'Contact Information',
              icon: Icons.contact_phone,
              iconColor: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.service.phoneNumber != null && widget.service.phoneNumber!.isNotEmpty)
                    _buildContactItem(
                      context,
                      isDarkMode,
                      icon: Icons.phone,
                      text: widget.service.phoneNumber!,
                      onTap: () {
                        // Launch phone call
                      },
                    ),
                  if (widget.service.phoneNumber != null && widget.service.phoneNumber!.isNotEmpty &&
                      widget.service.website != null && widget.service.website!.isNotEmpty)
                    const Divider(),
                  if (widget.service.website != null && widget.service.website!.isNotEmpty)
                    _buildContactItem(
                      context,
                      isDarkMode,
                      icon: Icons.language,
                      text: widget.service.website!,
                      onTap: () {
                        // Launch website
                      },
                    ),
                ],
              ),
            ),

          if (widget.service.phoneNumber != null || widget.service.website != null)
            const SizedBox(height: 16),

          // Hours card
          _buildInfoCard(
            context,
            isDarkMode,
            title: 'Hours',
            icon: Icons.access_time,
            iconColor: Colors.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.service.isOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.service.isOpen ? 'Open Now' : 'Closed',
                        style: TextStyle(
                          color: widget.service.isOpen ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sample hours - in a real app, this would come from the service data
                _buildHourRow(context, isDarkMode, day: 'Monday', hours: '9:00 AM - 6:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Tuesday', hours: '9:00 AM - 6:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Wednesday', hours: '9:00 AM - 6:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Thursday', hours: '9:00 AM - 6:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Friday', hours: '9:00 AM - 6:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Saturday', hours: '10:00 AM - 4:00 PM'),
                _buildHourRow(context, isDarkMode, day: 'Sunday', hours: 'Closed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Amenities tab content
  Widget _buildAmenitiesTab(BuildContext context, bool isDarkMode) {
    if (widget.service.amenities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No amenities information available',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.service.amenities.length,
      itemBuilder: (context, index) {
        final amenity = widget.service.amenities[index];
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAmenityColor(amenity).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAmenityIcon(amenity),
                  color: _getAmenityColor(amenity),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  amenity,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build an info card
  Widget _buildInfoCard(
      BuildContext context,
      bool isDarkMode, {
        required String title,
        required IconData icon,
        required Widget child,
        Color? iconColor,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Colors.blue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // Helper method to build a contact item
  Widget _buildContactItem(
      BuildContext context,
      bool isDarkMode, {
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build an hour row
  Widget _buildHourRow(BuildContext context, bool isDarkMode, {required String day, required String hours}) {
    final isToday = day == 'Monday'; // Just for demonstration, should be dynamic

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a map control button
  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  // Helper method to build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  // Helper method to get category color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'gas_station':
        return Colors.red;
      case 'restaurant':
        return Colors.orange;
      case 'hotel':
        return Colors.blue;
      case 'parking':
        return Colors.green;
      case 'car_wash':
        return Colors.cyan;
      case 'mechanic':
        return Colors.deepOrange;
      case 'ev_charging':
        return Colors.teal;
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.indigo;
      default:
        return Colors.purple;
    }
  }

  // Helper method to get amenity icon
  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'restroom':
      case 'restrooms':
      case 'bathroom':
        return Icons.wc;
      case 'atm':
        return Icons.atm;
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'coffee':
        return Icons.coffee;
      case 'shop':
      case 'store':
        return Icons.shopping_cart;
      case 'air':
        return Icons.air;
      case 'car wash':
        return Icons.local_car_wash;
      case 'ev charging':
        return Icons.electrical_services;
      case 'parking':
        return Icons.local_parking;
      case 'accessible':
      case 'wheelchair':
        return Icons.accessible;
      case '24 hours':
        return Icons.access_time;
      default:
        return Icons.check_circle;
    }
  }

  // Helper method to get amenity color
  Color _getAmenityColor(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Colors.blue;
      case 'restroom':
      case 'restrooms':
      case 'bathroom':
        return Colors.indigo;
      case 'atm':
        return Colors.green;
      case 'food':
      case 'restaurant':
        return Colors.orange;
      case 'coffee':
        return Colors.brown;
      case 'shop':
      case 'store':
        return Colors.purple;
      case 'air':
        return Colors.cyan;
      case 'car wash':
        return Colors.lightBlue;
      case 'ev charging':
        return Colors.teal;
      case 'parking':
        return Colors.green;
      case 'accessible':
      case 'wheelchair':
        return Colors.blue;
      case '24 hours':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}
