import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymaptest/util/smart_device_box.dart';
import 'package:mymaptest/util/my_button.dart';
import 'package:mymaptest/pages/service_locator.dart';
import 'package:mymaptest/pages/vehicle_details.dart';
import 'package:mymaptest/pages/driver_ai.dart';
import 'package:mymaptest/pages/community.dart';
import 'package:mymaptest/pages/trends.dart';
import 'package:mymaptest/pages/driver_behavior.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // padding constants
  final double horizontalPadding = 40;
  final double verticalPadding = 25;

  // list of smart devices
  List mySmartDevices = [
    // [ smartDeviceName, iconPath , powerStatus, pageRoute ]
    ["AI Car Assistant", "lib/icons/a_i.png", true, DriverAIScreen()],
    ["Driver Behavior", "lib/icons/driver.png", false, DriverBehavior()],
    ["Driver Community", "lib/icons/community.png", false, CommunityPage()],
    ["Trends", "lib/icons/trending.png", true, TrendsPage()],
  ];

  // power button switched
  void powerSwitchChanged(bool value, int index) {
    setState(() {
      mySmartDevices[index][2] = value;
    });
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Color scheme
  final Color lightIndigo = Color(0xFFE8EAF6);
  final Color lightPurple = Color(0xFFE1BEE7);
  final Color grey = Colors.grey;
  final Color darkGrey = Colors.grey[800]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightIndigo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // app bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // menu icon
                  Image.asset(
                    'lib/icons/menu.png',
                    height: 45,
                    color: Colors.black,
                  ),

                  // account icon
                  Icon(
                    Icons.person,
                    size: 45,
                    color: darkGrey,
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            // welcome home
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SMART DRIVER COMPANION",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyButton(
                        iconImagePath: "lib/icons/location.png",
                        buttonText: 'Service Locator',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ServiceLocator()),
                          );
                        },
                      ),
                      MyButton(
                        iconImagePath: "lib/icons/car.png",
                        buttonText: 'Vehicle Details',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VehicleDetails()),
                          );
                        },
                      ),
                      MyButton(
                        iconImagePath: "lib/icons/route.png",
                        buttonText: 'Plan A Drive',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DriverAIScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Divider(
                thickness: 1,
                color: Color.fromARGB(255, 204, 204, 204),
              ),
            ),

            const SizedBox(height: 25),

            // smart devices grid
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                "SERVICES",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // grid
            Expanded(
              child: GridView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 25),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1 / 1.3,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => mySmartDevices[index][3]),
                      );
                    },
                    child: SmartDeviceBox(
                      smartDeviceName: mySmartDevices[index][0],
                      iconPath: mySmartDevices[index][1],
                      powerOn: mySmartDevices[index][2],
                      onChanged: (value) => powerSwitchChanged(value, index),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

