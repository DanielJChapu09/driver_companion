import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymaptest/core/constants/image_asset_constants.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/widgets/cards/service_card.dart';
import '../../../config/theme/app_colors.dart';
import '../../../widgets/cards/utility_card.dart';
import '../../authentication/controller/auth_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {

  final authController = Get.find<AuthController>();

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
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    ServiceCard(
                      icon: ImageAssetPath.location,
                      title: 'Service Locator',
                      onPressed: ()=> Get.toNamed(Routes.serviceLocator)
                    ),
                    ServiceCard(
                      icon: ImageAssetPath.car,
                      title: 'Vehicle Details',
                      onPressed: ()=> Get.toNamed(Routes.vehicleDetails)
                    ),
                    ServiceCard(
                      icon: ImageAssetPath.route,
                      title: 'Plan A Drive',
                      onPressed: ()=> Get.toNamed(Routes.driverAIScreen)
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),


            Expanded(
              child: GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.3,
                children: [

                  SmartDeviceCard(
                    onTap: ()=>Get.toNamed(Routes.driverAIScreen),
                    color: Colors.purple,
                    utilityName: "AI Car Assistant",
                    utilityIcon: ImageAssetPath.ai,
                  ),


                  SmartDeviceCard(
                    onTap: ()=>Get.toNamed(Routes.driverBehavior),
                    color: AppColors.primaryRed,
                    utilityName: "Driver Behaviour",
                    utilityIcon: ImageAssetPath.driver,
                  ),



                  SmartDeviceCard(
                    onTap: ()=>Get.toNamed(Routes.community),
                    color: AppColors.blue,
                    utilityName: "Community",
                    utilityIcon: ImageAssetPath.community,
                  ),


                  SmartDeviceCard(
                    onTap: ()=>Get.toNamed(Routes.trends),
                    color: Colors.green,
                    utilityName: "Trends",
                    utilityIcon: ImageAssetPath.trending
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

