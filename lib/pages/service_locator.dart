import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Make sure this import is correct

class ServiceLocator extends StatefulWidget {
  ServiceLocator({super.key});

  @override
  _ServiceLocatorState createState() => _ServiceLocatorState();
}

class _ServiceLocatorState extends State<ServiceLocator> {
  MapboxMap? mapboxMapController;

  final Color lightPurple = Color(0xFFE6E6FA);
  final Color veryLightIndigo = Color(0xFFF0F8FF);
  final Color grey = Colors.grey;
  final Color white = Colors.white;

  final List<Map<String, dynamic>> services = [
    {'icon': Icons.local_gas_station, 'title': 'Gas'},
    {'icon': Icons.build, 'title': 'Repairs'},
    {'icon': Icons.car_repair, 'title': 'Towing'},
    {'icon': Icons.settings, 'title': 'Parts'},
    {'icon': Icons.fact_check, 'title': 'Inspection'},
    {'icon': Icons.electric_car, 'title': 'E.V Charging'},
  ];

  @override
  void initState() {
    super.initState();
    // Add any initial map settings here if necessary
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryLightIndigo,
      appBar: AppBar(
        title: Text('Service Locator', style: TextStyle(color: Colors.black)),
        backgroundColor: lightPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Map widget
                MapWidget(),
                // Search bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for Service',
                        prefixIcon: Icon(Icons.search, color: grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                // Service type buttons
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(services[index]['icon'], color: lightPurple),
                            label: Text(services[index]['title'], style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Floating Action Button (FAB)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      // Implement your logic for navigation or current location
                    },
                    backgroundColor: lightPurple,
                    child: Icon(Icons.navigation, color: white),
                  ),
                ),
              ],
            ),
          ),
          // Bottom section for Saved/Frequented buttons
          Container(
            height: 80,
            color: white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(Icons.bookmark, 'Saved'),
                _buildBottomButton(Icons.star, 'Frequented'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: lightPurple, size: 30),
          onPressed: () {},
        ),
        Text(label, style: TextStyle(color: Colors.black)),
      ],
    );
  }

  // Callback for when the map is created

}
