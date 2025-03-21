// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
// import '../controller/campus_map_controller.dart';
//
// class MapView extends StatefulWidget {
//   const MapView({super.key});
//
//   @override
//   State<MapView> createState() => _MapViewState();
// }
//
// class _MapViewState extends State<MapView> {
//   final MapController controller = Get.find<MapController>();
//
//   @override
//   void initState() {
//     super.initState();
//     controller.setupPositionTracking();
//   }
//
//   @override
//   void dispose() {
//     controller.userPositionStream?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             icon: Icon(Icons.my_location),
//             onPressed: controller.getCurrentLocation,
//           ),
//           IconButton(
//             icon: Icon(Icons.filter_list),
//             onPressed: _showFilterDialog,
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           mp.MapWidget(
//             cameraOptions: mp.CameraOptions(
//               center: mp.Point(
//                 coordinates: mp.Position(
//                   18.3333,
//                   -30.0333,
//                 ),
//               ),
//               zoom: 14.0,
//             ),
//             onMapCreated: controller.initializeMap,
//             styleUri: mp.MapboxStyles.MAPBOX_STREETS,
//           ),
//
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: _buildRoutingButton(),
//           ),
//           Obx(() => controller.isLoading.value
//               ? Center(child: CircularProgressIndicator())
//               : SizedBox.shrink()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRoutingButton() {
//     return Obx(() => FloatingActionButton(
//       child: Icon(controller.isRoutingMode.value ? Icons.close : Icons.directions),
//       onPressed: controller.toggleRoutingMode,
//     ));
//   }
//
//   void _showFilterDialog() {
//     final List<String> filterTypes = ['building', 'facility', 'poi', 'accessible', 'wifi'];
//     final List<String> filterLabels = ['Building', 'Facility', 'Point of Interest', 'Accessible', 'WiFi Available'];
//
//     Get.dialog(
//       AlertDialog(
//         title: Text('Filter Locations'),
//         content: Obx(() => Wrap(
//           spacing: 8,
//           children: List.generate(filterTypes.length, (index) {
//             return FilterChip(
//               label: Text(filterLabels[index]),
//               selected: controller.activeFilters.contains(filterTypes[index]),
//               onSelected: (selected) {
//                 controller.toggleFilter(filterTypes[index]);
//               },
//             );
//           }),
//         )),
//         actions: [
//           TextButton(
//             child: Text('Close'),
//             onPressed: () => Get.back(),
//           ),
//         ],
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
            'Map View'
        ),
      ),
    );
  }
}
