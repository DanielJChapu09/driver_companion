import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class DriverBehavior extends StatelessWidget {
  DriverBehavior({super.key});

  final Color teal = Colors.lightBlueAccent;
  final Color lightIndigo = Color(0xFF89D8F3);
  final Color lightPurple = Color(0xFF8FE6D8);
  final Color darkColor = Color(0xFF303F9F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightIndigo,
      appBar: AppBar(
        title: Text('Driver Behavior', style: TextStyle(color: darkColor)),
        backgroundColor: lightPurple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDriverScoreCard(context),
              SizedBox(height: 20),
              _buildSafetyScoreGauge(context),
              SizedBox(height: 20),
              _buildBehaviorBreakdown(context),
              SizedBox(height: 20),
              _buildTipsAndAlerts(),
              SizedBox(height: 20),
              _buildDailyDrivingTrend(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverScoreCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('106 pts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkColor)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('Top 20%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Text('this week', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                _showInfoDialog(context, 'Driver Score', 'The Driver Score is a measure of your overall driving performance. It takes into account various factors such as safety, efficiency, and consistency.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: teal),
              child: Text('Driver Score'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyScoreGauge(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: 0.82,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('82%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkColor)),
                        Text('SAFE', style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Safety Score Gauge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('*25', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: teal),
                        onPressed: () {
                          _showInfoDialog(context, 'Safety Levels', '🟢 80-100 (Safe)\n🟡 50-79 (Moderate Risk)\n🔴 0-49 (Unsafe)');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorBreakdown(BuildContext context) {
    final behaviors = [
      {'icon': Icons.emergency, 'title': 'Harsh Braking', 'incidents': '3 incidents today'},
      {'icon': Icons.speed, 'title': 'Rapid Acceleration', 'incidents': '2 times'},
      {'icon': Icons.turn_sharp_right, 'title': 'Sharp Turns', 'incidents': '4 times'},
      {'icon': Icons.directions_car, 'title': 'Speeding', 'incidents': '5 incidents'},
      {'icon': Icons.phone_android, 'title': 'Phone Usage', 'incidents': '1 detected instance'},
      {'icon': Icons.hourglass_empty, 'title': 'Idle Time', 'incidents': '2 minutes today'},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Behavior Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
                IconButton(
                  icon: Icon(Icons.info_outline, color: teal),
                  onPressed: () {
                    _showInfoDialog(context, 'Behavior Breakdown', 'This section shows various driving behaviors and their frequency.');
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: behaviors.length,
              itemBuilder: (context, index) {
                return Card(
                  color: lightPurple,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(behaviors[index]['icon'] as IconData, color: teal),
                        SizedBox(height: 4),
                        Text(behaviors[index]['title'] as String, style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(behaviors[index]['incidents'] as String, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsAndAlerts() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tips & Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
            SizedBox(height: 8),
            Text('• Avoid harsh braking for a smoother ride.'),
            Text('• Your speeding incidents increased this week. Try to maintain speed limits.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyDrivingTrend(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              title: Text('Daily Driving Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor)),
              children: [
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 50),
                            FlSpot(1, 70),
                            FlSpot(2, 60),
                            FlSpot(3, 80),
                            FlSpot(4, 75),
                            FlSpot(5, 85),
                            FlSpot(6, 82),
                          ],
                          isCurved: true,
                          color: teal,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

