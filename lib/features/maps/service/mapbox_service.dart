// import 'package:dio/dio.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart' as gl;
// import 'package:flutter/material.dart';
// import 'package:mymaptest/config/confidential/apikeys.dart';
// import 'package:mymaptest/core/utils/logs.dart';
// import 'dart:typed_data';
// import '../../../core/constants/image_asset_constants.dart';
//
// class MapboxService {
//
//   final Dio _dio;
//
//   MapboxService({Dio? dio}) : _dio = dio ?? Dio();
//
//
//   late MapboxMap mapboxMap;
//   final String mapboxDirectionsUrl = 'https://api.mapbox.com/directions/v5/mapbox/walking';
//
//   Future<void> initializeMap(MapboxMap map) async {
//     mapboxMap = map;
//     await mapboxMap.loadStyleURI(MapboxStyles.MAPBOX_STREETS);
//
//     await mapboxMap.location.updateSettings(
//         LocationComponentSettings(
//           enabled: true,
//           showAccuracyRing: true,
//           pulsingEnabled: true,
//         )
//     );
//   }
//
//   Future<void> addLocationMarker(gl.Position location, VoidCallback onTap) async {
//     final point = Point(coordinates: Position(location.longitude, location.latitude));
//     final annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
//
//     final Uint8List imageData = await loadMarkerImage();
//
//     final pointAnnotation = PointAnnotationOptions(
//       geometry: point,
//       image: imageData,
//       iconSize: 0.3,
//       textField: location.speed.toString(),
//       textOffset: [0, 0.8],
//       textColor: Colors.black.value,
//       textHaloColor: Colors.white.value,
//       textHaloWidth: 1.0,
//     );
//
//     final annotation = await annotationManager.create(pointAnnotation);
//   }
//
//   Future<Uint8List> loadMarkerImage() async {
//     final ByteData bytes = await rootBundle.load(ImageAssetPath.logo);
//     return bytes.buffer.asUint8List();
//   }
//
//   Future<void> fitBounds(List<gl.Position> locations) async {
//     if (locations.isEmpty) return;
//
//     final coordinates = locations.map((loc) =>
//         Point(coordinates: Position(loc.longitude, loc.latitude))).toList();
//
//     final bounds = CoordinateBounds(
//       southwest: coordinates.reduce((value, element) => Point(coordinates: Position(
//         value.coordinates.lng < element.coordinates.lng ? value.coordinates.lng : element.coordinates.lng,
//         value.coordinates.lat < element.coordinates.lat ? value.coordinates.lat : element.coordinates.lat,
//       ))),
//       northeast: coordinates.reduce((value, element) => Point(coordinates: Position(
//         value.coordinates.lng > element.coordinates.lng ? value.coordinates.lng : element.coordinates.lng,
//         value.coordinates.lat > element.coordinates.lat ? value.coordinates.lat : element.coordinates.lat,
//       ))),
//       infiniteBounds: false,
//     );
//
//     await mapboxMap.cameraForCoordinateBounds(
//         bounds,
//         MbxEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
//         null, null, null, null
//     );
//   }
//
//
//   Future<List<Point>> getRoute(gl.Position start, gl.Position end) async {
//     try {
//       final response = await _dio.get(
//           '$mapboxDirectionsUrl/${start.longitude},${start.latitude};'
//               '${end.longitude},${end.latitude}?'
//               'access_token=${APIKeys.MAPBOXPUBLICTOKEN}&'
//               'geometries=geojson'
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.data);
//         if (data['routes']?.isEmpty ?? true) {
//           throw Exception('No route found');
//         }
//
//         final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
//         return coordinates.map((coord) =>
//             Point(coordinates: Position(coord[0], coord[1]))
//         ).toList();
//       } else {
//         throw Exception('Failed to get route: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to get route: $e');
//     }
//   }
//
//   Future<void> addRoute(List<Point> routeCoordinates) async {
//     // Convert points to GeoJSON LineString
//     final Map<String, dynamic> lineStringGeoJson = {
//       "type": "Feature",
//       "properties": {},
//       "geometry": {
//         "type": "LineString",
//         "coordinates": routeCoordinates.map((point) =>
//         [point.coordinates.lng, point.coordinates.lat]
//         ).toList()
//       }
//     };
//
//     // Remove existing route if it exists
//     await removeRoute();
//
//     // Add source and layer
//     await mapboxMap.style.addLayer(LineLayer(
//       id: "routeline-active",
//       sourceId: "route",
//       lineColor: Colors.blue.value,
//       lineWidth: 3,
//     ));
//   }
//
//   // Future<List<Point>> getRoute(CampusLocation start, CampusLocation end) async {
//   //   try {
//   //     final response = await http.get(Uri.parse(
//   //         '$mapboxDirectionsUrl/${start.longitude},${start.latitude};'
//   //             '${end.longitude},${end.latitude}?'
//   //             'access_token=$mapboxAccessToken&'
//   //             'geometries=geojson'
//   //     ));
//   //
//   //     if (response.statusCode == 200) {
//   //       final data = json.decode(response.body);
//   //       if (data['routes']?.isEmpty ?? true) {
//   //         throw Exception('No route found');
//   //       }
//   //
//   //       final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
//   //       return coordinates.map((coord) =>
//   //           Point(coordinates: Position(coord[0], coord[1]))
//   //       ).toList();
//   //     } else {
//   //       throw Exception('Failed to get route: ${response.statusCode}');
//   //     }
//   //   } catch (e) {
//   //     throw Exception('Failed to get route: $e');
//   //   }
//   // }
//
//
//
//   Future<void> removeRoute() async {
//     try {
//       if (await mapboxMap.style.styleLayerExists("routeline-active")) {
//         await mapboxMap.style.removeStyleLayer("routeline-active");
//       }
//       if (await mapboxMap.style.styleSourceExists("route")) {
//         await mapboxMap.style.removeStyleSource("route");
//       }
//     } catch (e) {
//       DevLogs.logError("Error removing route: $e");
//     }
//   }
// }