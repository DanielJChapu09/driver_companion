import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mymaptest/features/driver_behaviour/view/trip_detail_screen.dart';
import '../controller/driver_behaviour_controller.dart';
import '../model/driving_event_model.dart';
import '../model/driving_score_model.dart';
import '../model/trip_model.dart';

class DriverBehaviorScreen extends StatefulWidget {
  const DriverBehaviorScreen({super.key});

  @override
  State<DriverBehaviorScreen> createState() => _DriverBehaviorScreenState();
}

class _DriverBehaviorScreenState extends State<DriverBehaviorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DriverBehaviorController controller = Get.find<DriverBehaviorController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Behavior'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trips', icon: Icon(Icons.route)),
            Tab(text: 'Events', icon: Icon(Icons.event_note)),
          ],
        ),
        actions: [
          Obx(() => IconButton(
            icon: Icon(controller.isMonitoring.value ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              if (controller.isMonitoring.value) {
                controller.stopMonitoring();
              } else {
                controller.startMonitoring();
              }
            },
            tooltip: controller.isMonitoring.value ? 'Stop Monitoring' : 'Start Monitoring',
          )),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
            tooltip: 'Behavior Settings',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTripsTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.driverScore.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No driving data available yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text('Start Monitoring'),
                onPressed: () => controller.startMonitoring(),
              ),
            ],
          ),
        );
      }

      DriverScore score = controller.driverScore.value!;

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall score card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Driver Score',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    _buildScoreIndicator(score.overallScore),
                    SizedBox(height: 8),
                    Text(
                      score.getScoreDescription(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: score.getScoreColor(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Trips', score.tripsCount.toString(), Icons.route),
                        _buildStatItem('Distance', '${score.totalDistance.toStringAsFixed(1)} km', Icons.straighten),
                        _buildStatItem('Time', '${score.totalDuration.toStringAsFixed(1)} h', Icons.access_time),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Category scores
            if (score.categoryScores.isNotEmpty) ...[
              Text(
                'Driving Behaviors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 220,
                child: _buildCategoryScoresChart(score.categoryScores),
              ),
            ],

            SizedBox(height: 16),

            // Improvement suggestions
            if (score.improvementSuggestions != null && score.improvementSuggestions!.isNotEmpty) ...[
              Text(
                'Improvement Suggestions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...score.improvementSuggestions!.entries.map((entry) =>
                  _buildSuggestionItem(entry.key, entry.value),
              ),
            ],

            SizedBox(height: 16),

            // Recent significant events
            if (score.recentEvents.isNotEmpty) ...[
              Text(
                'Recent Significant Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...score.recentEvents.take(3).map((event) =>
                  _buildEventItem(event),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTripsTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.recentTrips.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No trips recorded yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: controller.recentTrips.length,
        itemBuilder: (context, index) {
          final trip = controller.recentTrips[index];
          return _buildTripItem(trip);
        },
      );
    });
  }

  Widget _buildEventsTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.recentEvents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No driving events recorded yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: controller.recentEvents.length,
        itemBuilder: (context, index) {
          final event = controller.recentEvents[index];
          return _buildEventItem(event);
        },
      );
    });
  }

  Widget _buildScoreIndicator(double score) {
    Color scoreColor;
    if (score >= 90) {
      scoreColor = Colors.green;
    } else if (score >= 80) {
      scoreColor = Colors.lightGreen;
    } else if (score >= 70) {
      scoreColor = Colors.amber;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scoreColor.withOpacity(0.2),
            border: Border.all(
              color: scoreColor,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
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

  Widget _buildCategoryScoresChart(Map<String, double> categoryScores) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    categoryScores.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _getScoreColor(value),
              width: 18,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: 100,
        minY: 0,
        groupsSpace: 12,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              },
              interval: 20,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                String title = '';

                if (idx < categoryScores.keys.length) {
                  String key = categoryScores.keys.elementAt(idx);

                  if (key.contains('Score')) {
                    title = key.replaceAll('Score', '');
                  } else {
                    title = key;
                  }

                  // Capitalize and truncate
                  if (title.isNotEmpty) {
                    title = title[0].toUpperCase() + title.substring(1);
                    if (title.length > 8) {
                      title = title.substring(0, 8) + '...';
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 20,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.amber;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSuggestionItem(String category, String suggestion) {
    IconData icon;
    switch (category) {
      case 'acceleration':
        icon = Icons.speed;
        break;
      case 'braking':
        icon = Icons.stop_circle;
        break;
      case 'turning':
        icon = Icons.turn_right;
        break;
      case 'speeding':
        icon = Icons.speed_outlined;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          category[0].toUpperCase() + category.substring(1),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(suggestion),
      ),
    );
  }

  Widget _buildTripItem(DrivingTrip trip) {
    String dateText = DateFormat('MMM d, yyyy - h:mm a').format(trip.startTime);
    String durationText = '${trip.duration.toInt()} min';
    String distanceText = '${trip.distanceTraveled.toStringAsFixed(1)} km';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: trip.overallScore != null
              ? _getScoreColor(trip.overallScore!)
              : Colors.grey,
          child: trip.overallScore != null
              ? Text(
            trip.overallScore!.toInt().toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
              : Icon(Icons.question_mark, color: Colors.white),
        ),
        title: Text(
          '${trip.startAddress} to ${trip.endAddress ?? 'Unknown'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.straighten, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(distanceText),
                SizedBox(width: 12),
                Icon(Icons.timer, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(durationText),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to trip details
          Get.to(() => TripDetailsScreen(tripId: trip.id));
        },
      ),
    );
  }

  Widget _buildEventItem(DrivingEvent event) {
    String dateText = DateFormat('MMM d, h:mm a').format(event.timestamp);
    String valueText = '';

    switch (event.type) {
      case EventType.harshAcceleration:
        valueText = '${event.value.toStringAsFixed(1)} m/s²';
        break;
      case EventType.hardBraking:
        valueText = '${event.value.toStringAsFixed(1)} m/s²';
        break;
      case EventType.sharpTurn:
        valueText = '${event.value.toStringAsFixed(1)} rad/s';
        break;
      case EventType.speeding:
        valueText = '${event.value.toStringAsFixed(1)} km/h';
        break;
      default:
        valueText = event.value.toStringAsFixed(1);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: event.getSeverityColor(),
          child: Icon(
            event.getEventIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(event.getEventTypeDisplay()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText),
            SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.getSeverityColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.getSeverityDisplay(),
                    style: TextStyle(
                      fontSize: 12,
                      color: event.getSeverityColor(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(valueText),
              ],
            ),
          ],
        ),
        trailing: event.tripId != null
            ? IconButton(
          icon: Icon(Icons.map),
          onPressed: () {
            if (event.tripId != null) {
              Get.to(() => TripDetailsScreen(
                tripId: event.tripId!,
                highlightedEventId: event.id,
              ));
            }
          },
        )
            : null,
      ),
    );
  }

  void _showSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Driver Behavior Settings'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Voice Alerts'),
              subtitle: Text('Speak alerts while driving'),
              value: controller.voiceFeedbackEnabled.value,
              onChanged: (value) {
                controller.updateFeedbackSettings(voiceFeedback: value);
              },
            ),
            SwitchListTile(
              title: Text('Vibration Feedback'),
              subtitle: Text('Vibrate on critical events'),
              value: controller.hapticFeedbackEnabled.value,
              onChanged: (value) {
                controller.updateFeedbackSettings(hapticFeedback: value);
              },
            ),
            SwitchListTile(
              title: Text('Notification Alerts'),
              subtitle: Text('Show notifications for events'),
              value: controller.notificationFeedbackEnabled.value,
              onChanged: (value) {
                controller.updateFeedbackSettings(notificationFeedback: value);
              },
            ),
          ],
        )),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

