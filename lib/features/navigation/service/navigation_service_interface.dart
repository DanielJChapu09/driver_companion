import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../model/route_model.dart';

abstract class INavigationService {
  // Streams
  Stream<Position> get locationStream;
  Stream<int> get stepStream;
  Stream<String> get instructionStream;
  Stream<double> get distanceStream;
  Stream<double> get durationStream;
  Stream<bool> get arrivalStream;

  // Getters
  NavigationRoute? get currentRoute;
  int get currentStepIndex;
  bool get isNavigating;

  // Methods
  Future<bool> initialize();
  Future<bool> startNavigation(NavigationRoute route);
  Future<void> stopNavigation();
  void simulateNavigation(NavigationRoute route, {double speedFactor});
  void dispose();
}
