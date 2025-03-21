// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mymaptest/config/confidential/apikeys.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
// import 'package:geolocator/geolocator.dart' as gl;
// import 'package:dio/dio.dart';
//
// import '../../maps/controller/campus_map_controller.dart';
//
// class Location {
//   final double lat;
//   final double long;
//
//   Location({required this.lat, required this.long});
// }
//
// class MapBoxPlace {
//   final String? text;
//   final String? placeName;
//   final Location center;
//
//   MapBoxPlace({this.text, this.placeName, required this.center});
// }
//
// class MapTab extends StatefulWidget {
//   const MapTab({super.key});
//
//   @override
//   State<MapTab> createState() => _MapTabState();
// }
//
// class _MapTabState extends State<MapTab> {
//   mp.MapboxMap? mapboxMapController;
//   StreamSubscription? userPositionStream;
//   String currentAddress = "Fetching location...";
//   bool _isExpanded = false;
//   List<MapBoxPlace> searchResults = [];
//   final TextEditingController searchController = TextEditingController();
//   final controller = Get.find<MapController>();
//
//
//   @override
//   void initState() {
//     super.initState();
//     _setupPositionTracking();
//   }
//
//   @override
//   void dispose() {
//     userPositionStream?.cancel();
//     searchController.dispose();
//     super.dispose();
//   }
//
//   Future<bool> requestLocationPermission() async {
//     var status = await Permission.locationWhenInUse.request();
//     return status.isGranted;
//   }
//
//   Future<void> _onMapCreated(mp.MapboxMap controller) async {
//     setState(() {
//       mapboxMapController = controller;
//     });
//
//     if (await requestLocationPermission()) {
//       mapboxMapController?.location.updateSettings(mp.LocationComponentSettings(
//         enabled: true,
//       ));
//     }
//   }
//
//   Future<void> _setupPositionTracking() async {
//     bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled!');
//     }
//
//     gl.LocationPermission permission = await gl.Geolocator.checkPermission();
//     if (permission == gl.LocationPermission.denied) {
//       permission = await gl.Geolocator.requestPermission();
//       if (permission == gl.LocationPermission.denied) {
//         return Future.error('Location permissions denied');
//       }
//     }
//
//     if (permission == gl.LocationPermission.deniedForever) {
//       return Future.error('Location permissions are denied forever');
//     }
//
//     gl.LocationSettings locationSettings = gl.LocationSettings(
//       accuracy: gl.LocationAccuracy.high,
//       distanceFilter: 50,
//     );
//
//     userPositionStream?.cancel();
//     userPositionStream = gl.Geolocator.getPositionStream(locationSettings: locationSettings).listen(
//           (gl.Position? position) {
//         if (position != null && mapboxMapController != null) {
//           mapboxMapController?.setCamera(mp.CameraOptions(
//             zoom: 15,
//             center: mp.Point(coordinates: mp.Position(position.longitude, position.latitude)),
//           ));
//
//           setState(() {
//             currentAddress = "Lat: ${position.latitude}, Lng: ${position.longitude}";
//           });
//         }
//       },
//     );
//   }
//
//   void _expandContainer() {
//     setState(() {
//       _isExpanded = true;
//     });
//   }
//
//   Future<void> _onSearchChanged(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//       });
//       return;
//     }
//
//     try {
//       String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?country=zw&limit=5&types=place,address,poi&access_token=${APIKeys.MAPBOXPUBLICTOKEN}';
//
//       final response = await Dio().get(url);
//       final data = response.data;
//
//       List features = data['features'];
//
//       if (features.isNotEmpty) {
//         setState(() {
//           searchResults = features.map((place) => MapBoxPlace(
//             text: place['text'],
//             placeName: place['place_name'],
//             center: Location(
//               lat: place['center'][1],
//               long: place['center'][0],
//             ),
//           )).toList();
//         });
//       } else {
//         setState(() {
//           searchResults = [];
//         });
//       }
//     } catch (e) {
//       print("Error fetching search results: $e");
//       setState(() {
//         searchResults = [];
//       });
//     }
//   }
//
//   void _addMarker(double lat, double lng) async {
//     if (mapboxMapController == null) return;
//
//     var pointAnnotationManager =
//     await mapboxMapController!.annotations.createPointAnnotationManager();
//
//     await pointAnnotationManager.create(
//       mp.PointAnnotationOptions(
//         geometry: mp.Point(coordinates: mp.Position(lng, lat)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenHeight = MediaQuery.of(context).size.height;
//
//     double firstContainerHeight = _isExpanded ? screenHeight * 0.2 : screenHeight * 0.8;
//     double secondContainerHeight = _isExpanded ? screenHeight * 0.8 : screenHeight * 0.2;
//
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       resizeToAvoidBottomInset: true,
//       body: SafeArea(
//         child: Column(
//           children: [
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               height: firstContainerHeight,
//               child: mp.MapWidget(
//                 cameraOptions: mp.CameraOptions(
//                   center: mp.Point(
//                     coordinates: mp.Position(
//                       18.3333,
//                       -30.0333,
//                     ),
//                   ),
//                   zoom: 14.0,
//                 ),
//                 onMapCreated: controller.initializeMap,
//                 styleUri: mp.MapboxStyles.MAPBOX_STREETS,
//               ),
//             ),
//             Expanded(
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//                 height: secondContainerHeight,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//                     border: Border.all(color: Colors.black, width: 2),
//                   ),
//                   child: Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                         child: TextField(
//                           controller: searchController,
//                           textInputAction: TextInputAction.done,
//                           keyboardType: TextInputType.text,
//                           onChanged: (value) {
//                             _expandContainer();
//                             _onSearchChanged(value);
//                           },
//                           decoration: InputDecoration(
//                             hintText: 'Where to?',
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: searchResults.length,
//                           itemBuilder: (context, index) {
//                             final place = searchResults[index];
//                             return ListTile(
//                               title: Text(place.text ?? "Unknown Place"),
//                               subtitle: Text(place.placeName ?? ""),
//                               onTap: () {
//                                 _addMarker(place.center.lat, place.center.long);
//                                 setState(() {
//                                   _isExpanded = false;
//                                 });
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Tab'),
      ),
      body: const Center(
        child: Text('This is the Maps tab content.'),
      )
    );
  }
}
