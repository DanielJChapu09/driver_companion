import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mymaptest/features/main/pages/home_tab.dart';
import 'package:mymaptest/features/main/pages/map_tab.dart';
import 'package:mymaptest/features/main/pages/settings_tab.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_theme.dart';
import '../controller/botton_nav_controller.dart';
import '../controller/theme_controller.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // List of pages
  final List<Widget> _screens = [
    HomeTab(),
    MapTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final BottomNavController navigationController = Get.find();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 10,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Obx(() => _screens[navigationController.currentIndex.value]),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: navigationController.currentIndex.value,
          onTap: (index) => navigationController.navigateTo(index),
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: themeController.isDarkMode.value ? AppTheme.darkBackground : AppTheme.lightBackground,
          elevation: 2,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                FontAwesomeIcons.house,
                color: navigationController.currentIndex.value == 0 ? AppColors.primaryRed : const Color(0xFF596375)
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                  FontAwesomeIcons.map,
                  color: navigationController.currentIndex.value == 0 ? AppColors.primaryRed : const Color(0xFF596375)
              ),
              label: "Map",
            ),

            BottomNavigationBarItem(
              icon: Icon(
                  FontAwesomeIcons.gears,
                  color: navigationController.currentIndex.value == 0 ? AppColors.primaryRed : const Color(0xFF596375)
              ),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}