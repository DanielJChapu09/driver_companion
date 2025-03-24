import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import '../controller/driver_behaviour_controller.dart';
import '../model/driving_event_model.dart';
import '../model/trip_model.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  final String? highlightedEventId;

  const TripDetailsScreen({super.key,
    required this.tripId,
    this.highlightedEventId,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final DriverBehaviorController controller = Get.find<DriverBehaviorController>();

  DrivingTrip? trip;
  List<DrivingEvent> events = [];
  bool isLoading = true;
  MapboxMapController? mapController;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load trip details
      trip = await controller.getTripDetails(widget.tripId);

      // Load trip events
      events = await controller.getTripEvents(widget.tripId);

    } catch (e) {
      print('Error loading trip data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : trip == null
          ? Center(child: Text('Trip not found'))
          : _buildTripDetails(),
    );
  }

  Widget _buildTripDetails() {
    return Column(
      children: [
        // Map showing the trip route
        Expanded(
          flex: 2,
          child: _buildMap(),
        ),

        // Trip details
        Expanded(
          flex: 3,
          child: _buildTripInfo(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        MapboxMap(
          accessToken: 'YOUR_MAPBOX_ACCESS_TOKEN', // Replace with your token
          initialCameraPosition: CameraPosition(
            target: LatLng(
              trip!.startLatitude,
              trip!.startLongitude,
            ),
            zoom: 14.0,
          ),
          onMapCreated: (MapboxMapController controller) {
            mapController = controller;

            // Draw trip route and markers
            _drawTripOnMap();
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            child: Icon(Icons.layers),
            onPressed: () {
              _showMapStyleDialog();
            },
          ),
        ),
      ],
    );
  }

  void _drawTripOnMap() {
    if (mapController == null || events.isEmpty) return;

    // Add start and end markers
    mapController!.addSymbol(
      SymbolOptions(
        geometry: LatLng(trip!.startLatitude, trip!.startLongitude),
        iconImage: 'marker-start',
        iconSize: 1.5,
      ),
    );

    if (trip!.endLatitude != null && trip!.endLongitude != null) {
      mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(trip!.endLatitude!, trip!.endLongitude!),
          iconImage: 'marker-end',
          iconSize: 1.5,
        ),
      );
    }

    // Add event markers
    for (var event in events) {
      Color markerColor;

      switch (event.severity) {
        case EventSeverity.critical:
          markerColor = Colors.red;
          break;
        case EventSeverity.high:
          markerColor = Colors.deepOrange;
          break;
        case EventSeverity.medium:
          markerColor = Colors.orange;
          break;
        case EventSeverity.low:
          markerColor = Colors.blue;
          break;
        default:
          markerColor = Colors.grey;
      }

      mapController!.addCircle(
        CircleOptions(
          geometry: LatLng(event.latitude, event.longitude),
          circleRadius: 8,
          circleColor: '#${markerColor.value.toRadixString(16).substring(2)}',
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // If this is the highlighted event, center the map on it
      if (widget.highlightedEventId != null && event.id == widget.highlightedEventId) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(event.latitude, event.longitude),
            15.0,
          ),
        );
      }
    }

    // Fit bounds to show all points (if no highlighted event)
    if (widget.highlightedEventId == null) {
      List<LatLng> points = events.map((e) => LatLng(e.latitude, e.longitude)).toList();
      if (points.length > 1) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBoundsForPoints(points),
            left: 50,
            top: 100,
            right: 50,
            bottom: 50,
          ),
        );
      }
    }
  }

  LatLngBounds _getBoundsForPoints(List<LatLng> points) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showMapStyleDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Map Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Streets'),
              onTap: () {
                //mapController?.setStyleString('mapbox://styles/mapbox/streets-v11');
                Get.back();
              },
            ),
            ListTile(
              title: Text('Satellite'),
              onTap: () {
                //mapController?.setStyleString('mapbox://styles/mapbox/satellite-v9');
                Get.back();
              },
            ),
            ListTile(
              title: Text('Dark'),
              onTap: () {
                //mapController?.setStyleString('mapbox://styles/mapbox/dark-v10');
                Get.back();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo() {
    String startDate = DateFormat('MMM d, yyyy - h:mm a').format(trip!.startTime);
    String endDate = trip!.endTime != null
        ? DateFormat('h:mm a').format(trip!.endTime!)
        : 'N/A';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Trip summary
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trip!.startAddress} → ${trip!.endAddress ?? 'Unknown'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$startDate to $endDate',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trip!.overallScore != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getScoreColor(trip!.overallScore!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Score: ${trip!.overallScore!.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTripStat('Distance', '${trip!.distanceTraveled.toStringAsFixed(1)} km', Icons.straighten),
                    _buildTripStat('Duration', '${trip!.duration.toInt()} min', Icons.timer),
                    _buildTripStat('Events', '${events.length}', Icons.event_note),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Analytics'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildEventsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    if (events.isEmpty) {
      return Center(
        child: Text('No events recorded during this trip'),
      );
    }

    // Group events by type
    Map<EventType, List<DrivingEvent>> eventsByType = {};

    for (var event in events) {
      if (!eventsByType.containsKey(event.type)) {
        eventsByType[event.type] = [];
      }
      eventsByType[event.type]!.add(event);
    }

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        for (var entry in eventsByType.entries)
          _buildEventTypeSection(entry.key, entry.value),
      ],
    );
  }

  Widget _buildEventTypeSection(EventType type, List<DrivingEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Row(
            children: [
              Icon(
                DrivingEvent(
                  type: type,
                  severity: EventSeverity.medium,
                  latitude: 0,
                  longitude: 0,
                  value: 0,
                  threshold: 0,
                ).getEventIcon(),
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                '${events.first.getEventTypeDisplay()} (${events.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...events.map((event) => _buildEventItem(event)).toList(),
        Divider(),
      ],
    );
  }

  Widget _buildEventItem(DrivingEvent event) {
    String timeText = DateFormat('h:mm:ss a').format(event.timestamp);

    String valueLabel = '';
    String valueText = '';

    switch (event.type) {
      case EventType.harshAcceleration:
        valueLabel = 'Acceleration';
        valueText = '${event.value.toStringAsFixed(1)} m/s²';
        break;
      case EventType.hardBraking:
        valueLabel = 'Deceleration';
        valueText = '${event.value.abs().toStringAsFixed(1)} m/s²';
        break;
      case EventType.sharpTurn:
        valueLabel = 'Turn Rate';
        valueText = '${event.value.toStringAsFixed(1)} rad/s';
        break;
      case EventType.speeding:
        valueLabel = 'Speed';
        valueText = '${event.value.toStringAsFixed(1)} km/h';
        break;
      default:
        valueLabel = 'Value';
        valueText = event.value.toStringAsFixed(1);
    }

    bool isHighlighted = widget.highlightedEventId != null &&
        event.id == widget.highlightedEventId;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isHighlighted ? Colors.amber.withOpacity(0.2) : null,
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: event.getSeverityColor(),
          child: Text(
            event.severity.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(timeText),
        subtitle: Row(
          children: [
            Text('$valueLabel: '),
            Text(
              valueText,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.location_on),
          onPressed: () {
            if (mapController != null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(event.latitude, event.longitude),
                  16.0,
                ),
              );
            }
          },
          tooltip: 'Show on map',
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (trip!.scoreBreakdown == null || events.isEmpty) {
      return Center(
        child: Text('No analytics available for this trip'),
      );
    }

    // Event counts by severity
    int criticalEvents = events.where((e) => e.severity == EventSeverity.critical).length;
    int highEvents = events.where((e) => e.severity == EventSeverity.high).length;
    int mediumEvents = events.where((e) => e.severity == EventSeverity.medium).length;
    int lowEvents = events.where((e) => e.severity == EventSeverity.low).length;

    // Event counts by type
    Map<EventType, int> eventsByType = {};
    for (var event in events) {
      eventsByType[event.type] = (eventsByType[event.type] ?? 0) + 1;
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Events by severity
        Text(
          'Events by Severity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSeverityCounter('Critical', criticalEvents, Colors.red),
            _buildSeverityCounter('High', highEvents, Colors.deepOrange),
            _buildSeverityCounter('Medium', mediumEvents, Colors.orange),
            _buildSeverityCounter('Low', lowEvents, Colors.blue),
          ],
        ),

        SizedBox(height: 24),

        // Events distribution by type
        Text(
          'Events by Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 200,
          child: _buildEventTypeChart(eventsByType),
        ),

        SizedBox(height: 24),

        // Trip scores
        if (trip!.scoreBreakdown!.containsKey('accelerationScore') ||
            trip!.scoreBreakdown!.containsKey('brakingScore') ||
            trip!.scoreBreakdown!.containsKey('turningScore') ||
            trip!.scoreBreakdown!.containsKey('speedingScore')) ...[
          Text(
            'Driving Scores',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            child: _buildScoresChart(trip!.scoreBreakdown!),
          ),
        ],

        SizedBox(height: 24),

        // Event rate metrics
        Text(
          'Event Metrics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMetricRow(
                  'Events per hour',
                  (events.length / (trip!.duration / 60)).toStringAsFixed(2),
                ),
                SizedBox(height: 8),
                _buildMetricRow(
                  'Events per kilometer',
                  (events.length / trip!.distanceTraveled).toStringAsFixed(2),
                ),
                SizedBox(height: 8),
                _buildMetricRow(
                  'Average event severity',
                  _calculateAverageEventSeverity().toStringAsFixed(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityCounter(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeChart(Map<EventType, int> eventsByType) {
    // Implement a bar chart here
    return Center(
      child: Text('Event Type Distribution Chart'),
    );
  }

  Widget _buildScoresChart(Map<String, dynamic> scoreBreakdown) {
    // Implement a radar chart here
    return Center(
      child: Text('Driving Scores Chart'),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  double _calculateAverageEventSeverity() {
    if (events.isEmpty) return 0;

    double totalSeverity = 0;
    for (var event in events) {
      switch (event.severity) {
        case EventSeverity.critical:
          totalSeverity += 4;
          break;
        case EventSeverity.high:
          totalSeverity += 3;
          break;
        case EventSeverity.medium:
          totalSeverity += 2;
          break;
        case EventSeverity.low:
          totalSeverity += 1;
          break;
      }
    }

    return totalSeverity / events.length;
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.amber;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

