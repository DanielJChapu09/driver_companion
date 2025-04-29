import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import '../../../core/routes/app_pages.dart';
import '../controller/driver_behaviour_controller.dart';
import '../model/driving_event_model.dart';
import '../model/driving_score_model.dart';
import '../model/trip_model.dart';

class DriverBehaviorScreen extends StatefulWidget {
  const DriverBehaviorScreen({super.key});

  @override
  State<DriverBehaviorScreen> createState() => _DriverBehaviorScreenState();
}

// Changed from SingleTickerProviderStateMixin to TickerProviderStateMixin
class _DriverBehaviorScreenState extends State<DriverBehaviorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DriverBehaviorController controller = Get.find<DriverBehaviorController>();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Load data
    controller.loadDriverScore();
    controller.loadRecentTrips();
    controller.loadRecentEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Behavior'),
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              controller.isMonitoring.value ? Icons.stop : Icons.play_arrow,
              color: controller.isMonitoring.value ? Colors.red : Colors.green,
            ),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trips', icon: Icon(Icons.route)),
            Tab(text: 'Events', icon: Icon(Icons.event_note)),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(theme, isDark),
              _buildTripsTab(theme, isDark),
              _buildEventsTab(theme, isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to detailed analytics or insights
          Get.toNamed(Routes.driverInsightsScreen);
        },
        icon: Icon(Icons.insights),
        label: Text('Insights'),
        elevation: 4,
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.driverScore.value == null) {
        return _buildEmptyState(
          theme,
          'No driving data available yet',
          'Start monitoring to track your driving behavior',
          Icons.directions_car,
          controller.startMonitoring,
          'Start Monitoring',
        );
      }

      DriverScore score = controller.driverScore.value!;

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadDriverScore();
          await controller.loadRecentTrips();
          await controller.loadRecentEvents();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall score card
              _buildScoreCard(theme, isDark, score),
              SizedBox(height: 24),

              // Category scores
              if (score.categoryScores.isNotEmpty) ...[
                Text(
                  'Driving Behaviors',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                _buildCategoryScoresCard(theme, isDark, score.categoryScores),
                SizedBox(height: 24),
              ],

              // Improvement suggestions
              if (score.improvementSuggestions != null && score.improvementSuggestions!.isNotEmpty) ...[
                Text(
                  'Improvement Suggestions',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                _buildSuggestionsCard(theme, isDark, score!.improvementSuggestions),
                SizedBox(height: 24),
              ],

              // Recent significant events
              if (score.recentEvents.isNotEmpty) ...[
                Text(
                  'Recent Significant Events',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 12),
                ...score.recentEvents.take(3).map((event) =>
                    _buildEventCard(theme, isDark, event),
                ),
                SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _tabController.animateTo(2); // Switch to Events tab
                    },
                    icon: Icon(Icons.arrow_forward),
                    label: Text('View All Events'),
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Weekly summary
              Text(
                'Weekly Summary',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 12),
              _buildWeeklySummaryCard(theme, isDark),
              SizedBox(height: 80), // Bottom padding for FAB
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTripsTab(ThemeData theme, bool isDark) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.recentTrips.isEmpty) {
        return _buildEmptyState(
          theme,
          'No trips recorded yet',
          'Your driving trips will appear here once you start monitoring',
          Icons.route,
          controller.startMonitoring,
          'Start Monitoring',
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadRecentTrips();
        },
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.recentTrips.length,
          itemBuilder: (context, index) {
            final trip = controller.recentTrips[index];
            return _buildTripCard(theme, isDark, trip);
          },
        ),
      );
    });
  }

  Widget _buildEventsTab(ThemeData theme, bool isDark) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.recentEvents.isEmpty) {
        return _buildEmptyState(
          theme,
          'No driving events recorded yet',
          'Events will appear here as they occur during your trips',
          Icons.event_note,
          controller.startMonitoring,
          'Start Monitoring',
        );
      }

      // Group events by type
      Map<EventType, List<DrivingEvent>> eventsByType = {};

      for (var event in controller.recentEvents) {
        if (!eventsByType.containsKey(event.type)) {
          eventsByType[event.type] = [];
        }
        eventsByType[event.type]!.add(event);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadRecentEvents();
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            for (var entry in eventsByType.entries)
              _buildEventTypeSection(theme, isDark, entry.key, entry.value),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(
      ThemeData theme,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onAction,
      String actionLabel,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.play_arrow),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme, bool isDark, DriverScore score) {
    Color scoreColor;
    if (score.overallScore >= 90) {
      scoreColor = Colors.green;
    } else if (score.overallScore >= 80) {
      scoreColor = Colors.lightGreen;
    } else if (score.overallScore >= 70) {
      scoreColor = Colors.amber;
    } else if (score.overallScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Driver Score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    score.getScoreDescription(),
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildScoreIndicator(score.overallScore, scoreColor),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trips', score.tripsCount.toString(), Icons.route, theme),
                _buildStatItem('Distance', '${score.totalDistance.toStringAsFixed(1)} km', Icons.straighten, theme),
                _buildStatItem('Time', '${score.totalDuration.toStringAsFixed(1)} h', Icons.access_time, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(double score, Color scoreColor) {
    return Container(
      width: 150,
      height: 150,
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
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scoreColor.withOpacity(0.7),
                scoreColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
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
            color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryScoresCard(ThemeData theme, bool isDark, Map<String, double> categoryScores) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 220,
              child: _buildCategoryScoresChart(categoryScores, theme),
            ),
            Divider(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: categoryScores.entries.map((entry) {
                String key = entry.key;
                double value = entry.value;

                if (key.contains('Score')) {
                  key = key.replaceAll('Score', '');
                }

                // Capitalize and format
                if (key.isNotEmpty) {
                  key = key[0].toUpperCase() + key.substring(1);
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getScoreColor(value).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(value),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScoresChart(Map<String, double> categoryScores, ThemeData theme) {
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
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
                      color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
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
                      color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
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
              color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(ThemeData theme, bool isDark, dynamic suggestions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: suggestions.entries.map((entry) {
            return _buildSuggestionItem(entry.key, entry.value, theme);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String category, String suggestion, ThemeData theme) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category[0].toUpperCase() + category.substring(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  suggestion,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ThemeData theme, bool isDark, DrivingTrip trip) {
    String dateText = DateFormat('MMM d, yyyy - h:mm a').format(trip.startTime);
    String durationText = '${trip.duration.toInt()} min';
    String distanceText = '${trip.distanceTraveled.toStringAsFixed(1)} km';

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to trip details
          Get.toNamed(
            Routes.tripDetailsScreen,
            arguments: {'tripId': trip.id},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: trip.overallScore != null
                        ? _getScoreColor(trip.overallScore!).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    child: trip.overallScore != null
                        ? Text(
                      trip.overallScore!.toInt().toString(),
                      style: TextStyle(
                        color: _getScoreColor(trip.overallScore!),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : Icon(Icons.question_mark, color: Colors.grey),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.startAddress} to ${trip.endAddress ?? 'Unknown'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateText,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTripStat(Icons.straighten, distanceText, 'Distance', theme),
                    _buildTripStat(Icons.timer, durationText, 'Duration', theme),
                    _buildTripStat(
                        Icons.event_note,
                        trip.eventsCount.toString(),
                        'Events',
                        theme
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to trip details
                      Get.toNamed(
                        Routes.tripDetailsScreen,
                        arguments: {'tripId': trip.id},
                      );
                    },
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('View Details'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripStat(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeSection(ThemeData theme, bool isDark, EventType type, List<DrivingEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEventTypeIcon(type),
                  color: _getEventTypeColor(type),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${_getEventTypeDisplay(type)} (${events.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...events.map((event) => _buildEventCard(theme, isDark, event)).toList(),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEventCard(ThemeData theme, bool isDark, DrivingEvent event) {
    String timeText = DateFormat('MMM d, h:mm a').format(event.timestamp);
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

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (event.tripId != null) {
            Get.toNamed(
              Routes.tripDetailsScreen,
              arguments: {
                'tripId': event.tripId!,
                'highlightedEventId': event.id,
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: event.getSeverityColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    event.getEventIcon(),
                    color: event.getSeverityColor(),
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.getEventTypeDisplay(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.getSeverityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.getSeverityDisplay(),
                            style: TextStyle(
                              fontSize: 12,
                              color: event.getSeverityColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$valueLabel: $valueText',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  if (event.tripId != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(ThemeData theme, bool isDark) {
    // This would normally be populated with real data
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: Colors.green,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '+5.2%',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeeklyStat('Trips', '12', Icons.route, theme),
                _buildWeeklyStat('Distance', '152.3 km', Icons.straighten, theme),
                _buildWeeklyStat('Avg. Score', '87.5', Icons.star, theme),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 120,
              child: _buildWeeklyChart(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStat(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 16,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, bool isDark) {
    // Sample data for the weekly chart
    final List<FlSpot> spots = [
      FlSpot(0, 82),
      FlSpot(1, 85),
      FlSpot(2, 83),
      FlSpot(3, 86),
      FlSpot(4, 84),
      FlSpot(5, 87),
      FlSpot(6, 89),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(''),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 60,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            Divider(),
            ListTile(
              title: Text('Sensitivity Settings'),
              subtitle: Text('Adjust event detection thresholds'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                _showSensitivitySettingsDialog();
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showSensitivitySettingsDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // These would normally be loaded from the controller
    double accelerationThreshold = 3.0;
    double brakingThreshold = 3.0;
    double turningThreshold = 0.3;
    double speedingThreshold = 10.0;

    Get.dialog(
      AlertDialog(
        title: Text('Sensitivity Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adjust the sensitivity thresholds for event detection',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            _buildSensitivitySlider(
              'Acceleration',
              'Harsh acceleration threshold (m/s²)',
              accelerationThreshold,
              1.0,
              5.0,
                  (value) {
                accelerationThreshold = value;
                // Update in controller
              },
              theme,
            ),
            _buildSensitivitySlider(
              'Braking',
              'Hard braking threshold (m/s²)',
              brakingThreshold,
              1.0,
              5.0,
                  (value) {
                brakingThreshold = value;
                // Update in controller
              },
              theme,
            ),
            _buildSensitivitySlider(
              'Turning',
              'Sharp turning threshold (rad/s)',
              turningThreshold,
              0.1,
              0.5,
                  (value) {
                turningThreshold = value;
                // Update in controller
              },
              theme,
            ),
            _buildSensitivitySlider(
              'Speeding',
              'Speed limit excess (km/h)',
              speedingThreshold,
              5.0,
              20.0,
                  (value) {
                speedingThreshold = value;
                // Update in controller
              },
              theme,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Get.back(),
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              // Save settings to controller
              Get.back();

              // Show confirmation
              Get.snackbar(
                'Settings Saved',
                'Your sensitivity settings have been updated',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                margin: EdgeInsets.all(16),
                borderRadius: 8,
                duration: Duration(seconds: 2),
              );
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSensitivitySlider(
      String title,
      String subtitle,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ThemeData theme,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) * 10).toInt(),
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
            Container(
              width: 50,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.amber;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.harshAcceleration:
        return Icons.speed;
      case EventType.hardBraking:
        return Icons.stop_circle;
      case EventType.sharpTurn:
        return Icons.turn_right;
      case EventType.speeding:
        return Icons.speed_outlined;
      default:
        return Icons.warning;
    }
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.harshAcceleration:
        return Colors.orange;
      case EventType.hardBraking:
        return Colors.red;
      case EventType.sharpTurn:
        return Colors.purple;
      case EventType.speeding:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  String _getEventTypeDisplay(EventType type) {
    switch (type) {
      case EventType.harshAcceleration:
        return 'Harsh Acceleration';
      case EventType.hardBraking:
        return 'Hard Braking';
      case EventType.sharpTurn:
        return 'Sharp Turn';
      case EventType.speeding:
        return 'Speeding';
      default:
        return 'Unknown Event';
    }
  }
}
