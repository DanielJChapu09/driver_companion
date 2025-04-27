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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  // List of pages
  final List<Widget> _screens = [
    HomeTab(),
    MapsTab(),
    SettingsTab(),
  ];

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final BottomNavController navigationController = Get.find();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Obx(() => AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _screens[navigationController.currentIndex.value],
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      )),
      bottomNavigationBar: Obx(
            () => Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: navigationController.currentIndex.value,
              onTap: (index) => navigationController.navigateTo(index),
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
              backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_rounded,
                    size: 24,
                  ),
                  activeIcon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.map_rounded,
                    size: 24,
                  ),
                  activeIcon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  label: "Map",
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.settings_rounded,
                    size: 24,
                  ),
                  activeIcon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  label: "Settings",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
