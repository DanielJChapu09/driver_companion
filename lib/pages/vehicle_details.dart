import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriverAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VehicleDetails(),
    );
  }
}




class VehicleDetails extends StatefulWidget {
  const VehicleDetails({super.key});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text('Vehicle Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              onPageChanged: (index) {
                setState(() {
                  _currentCardIndex = index;
                });
              },
              children: [
                VehicleCard(
                  make: 'Toyota Aqua',
                  licensePlate: 'ABC 1234',
                  registrationDate: '09/28',
                ),
                VehicleCard(
                  make: 'Honda Civic',
                  licensePlate: 'XYZ 5678',
                  registrationDate: '10/15',
                ),
                VehicleCard(
                  make: 'Nissan Leaf',
                  licensePlate: 'DEF 9012',
                  registrationDate: '11/03',
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
                  (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentCardIndex == index ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement schedule functionality
                },
                icon: Icon(Icons.add),
                label: Text('Schedule'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement notes functionality
                },
                icon: Icon(Icons.add),
                label: Text('Notes'),
              ),
            ],
          ),
          SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CalendarView(),
                HistoryView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleCard extends StatefulWidget {
  final String make;
  final String licensePlate;
  final String registrationDate;

  const VehicleCard({
    super.key,
    required this.make,
    required this.licensePlate,
    required this.registrationDate,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  bool _isFlipped = false;

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Card(
        margin: EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 600),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: child,
            );
          },
          child: _isFlipped ? _buildBackSide() : _buildFrontSide(),
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      key: ValueKey<bool>(false),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.make,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.compare_arrows),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              widget.licensePlate,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  // TODO: Implement info popup
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'reg.',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    widget.registrationDate,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      key: ValueKey<bool>(true),
      padding: EdgeInsets.all(16),
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 100,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildEventTile('14 Oct', 'Maintenance', '14:00', 'Mbare'),
        _buildEventTile('19 Oct', 'Oil Change', '13:00', 'CBD'),
        _buildEventTile('25 Oct', 'Tire Rotation', '10:00', 'Highfield'),
        _buildEventTile('02 Nov', 'Car Wash', '15:30', 'Avondale'),
      ],
    );
  }

  Widget _buildEventTile(String date, String event, String time, String venue) {
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      title: Text(event),
      subtitle: Text('$time - $venue'),
    );
  }
}

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildHistoryTile('05 Oct', 'Oil Change', 'Completed'),
        _buildHistoryTile('28 Sep', 'Tire Rotation', 'Completed'),
        _buildHistoryTile('15 Sep', 'Car Wash', 'Completed'),
        _buildHistoryTile('02 Sep', 'Maintenance', 'Completed'),
      ],
    );
  }

  Widget _buildHistoryTile(String date, String task, String status) {
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      title: Text(task),
      trailing: Text(
        status,
        style: TextStyle(color: Colors.green),
      ),
    );
  }
}