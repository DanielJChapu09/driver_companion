import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State <TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Trends', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.tealAccent,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel'),
            Tab(icon: Icon(Icons.traffic), text: 'Traffic'),
            Tab(icon: Icon(Icons.cloud), text: 'Weather'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FuelTab(),
          TrafficTab(),
          WeatherTab(),
        ],
      ),
    );
  }
}

class FuelTab extends StatefulWidget {
  const FuelTab({super.key});

  @override
 State<FuelTab>createState() => _FuelTabState();
}

class _FuelTabState extends State<FuelTab> {
  String _selectedFilter = 'price';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.teal),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        items: ['Past 7 days', '14 days', 'Month', '3 months', '6 months', 'Year']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (_) {},
                        hint: const Text('Select period'),
                        isExpanded: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Filter By:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadioButton('Price', 'price'),
                _buildRadioButton('Type', 'type'),
                _buildRadioButton('Rating', 'rating'),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or type',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Fuel Stations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ZUVA SERVICE STATION',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildFuelPriceRow('Blended', '\$1.47'),
                        _buildFuelPriceRow('Unblended', '\$1.58'),
                        _buildFuelPriceRow('Diesel', '\$1.39'),
                        _buildFuelPriceRow('Gas', '\$1.20'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.star, color: Colors.amber),
                                Text('4.7', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('Rate'),
                            ),
                          ],
                        ),
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

  Widget _buildRadioButton(String label, String value) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: _selectedFilter == value ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.teal),
          ),
          child: Row(
            children: [
              Icon(
                _selectedFilter == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _selectedFilter == value ? Colors.white : Colors.teal,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _selectedFilter == value ? Colors.white : Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelPriceRow(String type, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: const TextStyle(color: Colors.grey)),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class TrafficTab extends StatelessWidget {
  const TrafficTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.location_on, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Harare Institute of Technology',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(child: Text('Map here', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(height: 16),
            Text(
              'Belvedere, Harare',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peak Hours',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildPeakHourItem('0700-0830am', 'Traffic is heavy here, due to school rush and workers rush.'),
                          _buildPeakHourItem('1230-1400pm', 'Lunch hour and school rush cause heavy traffic.'),
                          _buildPeakHourItem('1700-1930pm', 'Everyone must be going home, hence traffic heavy then.'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alerts',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text('No Alerts at the moment'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Traffic Density Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text('00:00', style: TextStyle(fontSize: 10));
                            case 6:
                              return Text('06:00', style: TextStyle(fontSize: 10));
                            case 12:
                              return Text('12:00', style: TextStyle(fontSize: 10));
                            case 18:
                              return Text('18:00', style: TextStyle(fontSize: 10));
                            case 23:
                              return Text('23:00', style: TextStyle(fontSize: 10));
                            default:
                              return Text('');
                          }
                        },
                        reservedSize: 32, // Ensures enough space for labels
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 10),
                        FlSpot(6, 40),
                        FlSpot(8, 90),
                        FlSpot(12, 50),
                        FlSpot(17, 80),
                        FlSpot(19, 40),
                        FlSpot(23, 10),
                      ],
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 4,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal, // Makes the area slightly transparent
                      ),
                    ),
                  ],
                ),
              )
              ,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHourItem(String time, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.teal, size: 16),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class WeatherTab extends StatelessWidget {
  const WeatherTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Current Weather',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Belvedere, Harare',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          children: const [
                            Icon(Icons.wb_sunny, size: 64, color: Colors.orange),
                            Text('25°C', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            Text('Sunny'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWeatherDetail(Icons.opacity, 'Humidity', '60%'),
                        _buildWeatherDetail(Icons.air, 'Wind', '5 km/h'),
                        _buildWeatherDetail(Icons.compress, 'Pressure', '1015 hPa'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Extremes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExtremeButton(
                  icon: Icons.wb_sunny,
                  label: 'Hot',
                  color: Colors.orange,
                  onPressed: () => _showExtremePopup(context, 'Hot Weather Trends'),
                ),
                _buildExtremeButton(
                  icon: Icons.cloud_queue,
                  label: 'Rain',
                  color: Colors.blue,
                  onPressed: () => _showExtremePopup(context, 'Rainy Weather Trends'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Forecast',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            [Icons.wb_sunny, Icons.cloud, Icons.wb_sunny, Icons.cloud_queue, Icons.wb_sunny, Icons.thunderstorm, Icons.cloud][index],
                            color: [Colors.orange, Colors.grey, Colors.orange, Colors.lightBlue, Colors.orange, Colors.purple, Colors.grey][index],
                          ),
                          const SizedBox(height: 4),
                          Text('${20 + index}°C'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExtremeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showExtremePopup(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Here you can display trends related to extreme weather conditions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }
}

