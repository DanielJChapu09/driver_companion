import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymaptest/util/smart_device_box.dart';
import 'package:mymaptest/util/my_button.dart';
import 'package:mymaptest/pages/service_locator.dart';
import 'package:mymaptest/pages/vehicle_details.dart';
import 'package:mymaptest/pages/driver_ai.dart';
import 'package:mymaptest/pages/community.dart';
import 'package:mymaptest/pages/trends.dart';
import 'package:mymaptest/pages/driver_behavior.dart';

import '../../authentication/controller/auth_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  final authController = Get.find<AuthController>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Afternoon',
              style: TextStyle(
                fontSize: 12
              ),
            ),
            Text(
              authController.currentUser.value!.displayName!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // welcome home
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SMART DRIVER COMPANION",
                  style: TextStyle(
                      fontSize: 20,
                  ),
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
            Text(
              "SERVICES",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
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

