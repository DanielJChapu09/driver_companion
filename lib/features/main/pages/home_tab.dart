import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymaptest/core/constants/image_asset_constants.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/core/utils/dimensions.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import '../../authentication/controller/auth_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final authController = Get.find<AuthController>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.textDark;
    final cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDarkMode ? Colors.black54 : Colors.black12;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.width20,
                  vertical: Dimensions.height10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                          authController.currentUser.value?.displayName ?? 'Driver',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        )),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Obx(() => CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                        backgroundImage: authController.currentUser.value?.photoURL != null
                            ? NetworkImage(authController.currentUser.value!.photoURL!)
                            : null,
                        child: authController.currentUser.value?.photoURL == null
                            ? Icon(Icons.person, color: AppColors.primaryRed)
                            : null,
                      )),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.width20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "QUICK ACTIONS",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: Dimensions.height15),
                    Container(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: BouncingScrollPhysics(),
                        children: [
                          _buildQuickActionCard(
                            context: context,
                            icon: ImageAssetPath.location,
                            title: 'Service Locator',
                            color: AppColors.blue,
                            onTap: () => Get.toNamed(Routes.serviceLocator),
                            cardColor: cardColor,
                            shadowColor: shadowColor,
                          ),
                          SizedBox(width: Dimensions.width15),
                          _buildQuickActionCard(
                            context: context,
                            icon: ImageAssetPath.car,
                            title: 'Vehicle Details',
                            color: AppColors.primaryRed,
                            onTap: () => Get.toNamed(Routes.vehicleDetails),
                            cardColor: cardColor,
                            shadowColor: shadowColor,
                          ),
                          SizedBox(width: Dimensions.width15),
                          _buildQuickActionCard(
                            context: context,
                            icon: ImageAssetPath.route,
                            title: 'Plan A Drive',
                            color: Colors.green,
                            onTap: () => Get.toNamed(Routes.driverAIScreen),
                            cardColor: cardColor,
                            shadowColor: shadowColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Services Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SERVICES",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: Dimensions.height15),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.width20),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimensions.width15,
                  mainAxisSpacing: Dimensions.height15,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _buildServiceCard(
                    context: context,
                    title: "AI Car Assistant",
                    icon: ImageAssetPath.ai,
                    color: Colors.purple,
                    onTap: () => Get.toNamed(Routes.driverAIScreen),
                    cardColor: cardColor,
                    shadowColor: shadowColor,
                  ),
                  _buildServiceCard(
                    context: context,
                    title: "Driver Behaviour",
                    icon: ImageAssetPath.driver,
                    color: AppColors.primaryRed,
                    onTap: () => Get.toNamed(Routes.driverBehavior),
                    cardColor: cardColor,
                    shadowColor: shadowColor,
                  ),
                  _buildServiceCard(
                    context: context,
                    title: "Community",
                    icon: ImageAssetPath.community,
                    color: AppColors.blue,
                    onTap: () => Get.toNamed(Routes.community),
                    cardColor: cardColor,
                    shadowColor: shadowColor,
                  ),
                  _buildServiceCard(
                    context: context,
                    title: "Trends",
                    icon: ImageAssetPath.trending,
                    color: Colors.green,
                    onTap: () => Get.toNamed(Routes.trends),
                    cardColor: cardColor,
                    shadowColor: shadowColor,
                  ),
                ]),
              ),
            ),

            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.width20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECENT ACTIVITY",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: Dimensions.height15),
                    _buildRecentActivityCard(
                      context: context,
                      title: "Last Trip",
                      subtitle: "15 miles • 25 minutes",
                      icon: Icons.route,
                      color: AppColors.blue,
                      onTap: () {},
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                    SizedBox(height: Dimensions.height10),
                    _buildRecentActivityCard(
                      context: context,
                      title: "Driving Score",
                      subtitle: "92/100 • Great driving!",
                      icon: Icons.speed,
                      color: Colors.green,
                      onTap: () => Get.toNamed(Routes.driverBehavior),
                      cardColor: cardColor,
                      shadowColor: shadowColor,
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.only(bottom: Dimensions.height30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String icon,
    required String title,
    required Color color,
    required Function() onTap,
    required Color cardColor,
    required Color shadowColor,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  icon,
                  width: 28,
                  height: 28,
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String icon,
    required Color color,
    required Function() onTap,
    required Color cardColor,
    required Color shadowColor,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  icon,
                  width: 32,
                  height: 32,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Function() onTap,
    required Color cardColor,
    required Color shadowColor,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }
}
