import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'features/main/pages/mainscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set your Mapbox Access Token
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}