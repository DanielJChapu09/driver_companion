class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String maneuver;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction'],
      distance: json['distance'].toDouble(),
      duration: json['duration'].toDouble(),
      maneuver: json['maneuver'],
      startLatitude: json['startLatitude'].toDouble(),
      startLongitude: json['startLongitude'].toDouble(),
      endLatitude: json['endLatitude'].toDouble(),
      endLongitude: json['endLongitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'maneuver': maneuver,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
    };
  }
}

class NavigationRoute {
  final String id;
  final double distance;
  final double duration;
  final List<RouteStep> steps;
  final String geometry;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final String startAddress;
  final String endAddress;

  NavigationRoute({
    required this.id,
    required this.distance,
    required this.duration,
    required this.steps,
    required this.geometry,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.startAddress,
    required this.endAddress,
  });

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      id: json['id'],
      distance: json['distance'].toDouble(),
      duration: json['duration'].toDouble(),
      steps: (json['steps'] as List)
          .map((step) => RouteStep.fromJson(step))
          .toList(),
      geometry: json['geometry'],
      startLatitude: json['startLatitude'].toDouble(),
      startLongitude: json['startLongitude'].toDouble(),
      endLatitude: json['endLatitude'].toDouble(),
      endLongitude: json['endLongitude'].toDouble(),
      startAddress: json['startAddress'],
      endAddress: json['endAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distance': distance,
      'duration': duration,
      'steps': steps.map((step) => step.toJson()).toList(),
      'geometry': geometry,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'startAddress': startAddress,
      'endAddress': endAddress,
    };
  }
}

