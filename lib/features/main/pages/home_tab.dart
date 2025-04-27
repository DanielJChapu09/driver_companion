import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import 'package:mymaptest/core/routes/app_pages.dart';
import 'package:mymaptest/features/driver_behaviour/controller/driver_behaviour_controller.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';
import 'package:mymaptest/features/community/controller/community_controller.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  final NavigationController navigationController = Get.find<NavigationController>();
  final DriverBehaviorController driverController = Get.find<DriverBehaviorController>();
  final CommunityController communityController = Get.find<CommunityController>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.forward();

    // Fetch data
    _loadData();
  }

  Future<void> _loadData() async {
    await driverController.loadDriverScore();
    await navigationController.loadSavedPlaces();
    await communityController.fetchNearbyNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color(0xFF2C2C2C), Color(0xFF1E1E1E)]
                          : [Colors.white, Colors.grey[50]!],
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getGreeting(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: 4),
                          Obx(() => Text(
                            driverController.driverScore.value?.userId.split('_').last.capitalize ?? 'Driver',
                            style: theme.textTheme.headlineSmall,
                          )),
                        ],
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.profileScreen),
                        child: Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: EdgeInsets.only(left: 0, bottom: 16),
                expandedTitleScale: 1.0,
              ),
            ),

            // Content
            SliverFadeTransition(
              opacity: _fadeAnimation,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Score Card
                      _buildDriverScoreCard(theme, isDark),
                      SizedBox(height: 24),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 12),
                      _buildQuickActions(theme, isDark),
                      SizedBox(height: 24),

                      // Services
                      Text(
                        'Services',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 12),
                      _buildServicesGrid(theme, isDark),
                      SizedBox(height: 24),

                      // Recent Activity
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 12),
                      _buildRecentActivity(theme, isDark),
                      SizedBox(height: 24),

                      // Community Updates
                      Text(
                        'Community Updates',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 12),
                      _buildCommunityUpdates(theme, isDark),
                      SizedBox(height: 80), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(Routes.navigationScreen),
        icon: Icon(Icons.navigation),
        label: Text('Navigate'),
        elevation: 4,
      ),
    );
  }

  Widget _buildDriverScoreCard(ThemeData theme, bool isDark) {
    return Obx(() {
      final score = driverController.driverScore.value;
      if (score == null) {
        return _buildScoreCardSkeleton(theme, isDark);
      }

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
        child: InkWell(
          onTap: () => Get.toNamed(Routes.driverBehaviorScreen),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Driver Score',
                      style: theme.textTheme.titleLarge,
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: scoreColor,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            score.overallScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
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
                    _buildScoreStat('Trips', '${score.tripsCount}', Icons.route),
                    _buildScoreStat('Distance', '${score.totalDistance.toStringAsFixed(1)} km', Icons.straighten),
                    _buildScoreStat('Time', '${score.totalDuration.toStringAsFixed(1)} h', Icons.access_time),
                  ],
                ),
                SizedBox(height: 16),
                if (score.improvementSuggestions != null && score.improvementSuggestions!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            score.improvementSuggestions!.entries.first.value,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildScoreCardSkeleton(ThemeData theme, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Driver Score',
                  style: theme.textTheme.titleLarge,
                ),
                Spacer(),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStatSkeleton(theme),
                _buildScoreStatSkeleton(theme),
                _buildScoreStatSkeleton(theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStatSkeleton(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(height: 4),
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
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        children: [
          _buildQuickActionCard(
            theme,
            isDark,
            'Find Route',
            Icons.directions,
            AppColors.primary,
                () => Get.toNamed(Routes.searchScreen),
          ),
          _buildQuickActionCard(
            theme,
            isDark,
            'Saved Places',
            Icons.star,
            AppColors.accent,
                () => Get.toNamed(Routes.savedPlacesScreen),
          ),
          _buildQuickActionCard(
            theme,
            isDark,
            'Find Services',
            Icons.local_gas_station,
            AppColors.secondary,
                () => Get.toNamed(Routes.serviceLocatorScreen),
          ),
          _buildQuickActionCard(
            theme,
            isDark,
            'Road Alerts',
            Icons.warning,
            Colors.amber,
                () => Get.toNamed(Routes.communityMapScreen),
          ),
          _buildQuickActionCard(
            theme,
            isDark,
            'Trip History',
            Icons.history,
            Colors.purple,
                () => Get.toNamed(Routes.driverBehaviorScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      ThemeData theme,
      bool isDark,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
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
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(ThemeData theme, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildServiceCard(
          theme,
          isDark,
          'Navigation',
          'Real-time directions',
          Icons.navigation,
          AppColors.primary,
              () => Get.toNamed(Routes.navigationScreen),
        ),
        _buildServiceCard(
          theme,
          isDark,
          'Driver Behavior',
          'Monitor your driving',
          Icons.analytics,
          AppColors.secondary,
              () => Get.toNamed(Routes.driverBehaviorScreen),
        ),
        _buildServiceCard(
          theme,
          isDark,
          'Community',
          'Connect with drivers',
          Icons.people,
          AppColors.accent,
              () => Get.toNamed(Routes.communityScreen),
        ),
        _buildServiceCard(
          theme,
          isDark,
          'Service Locator',
          'Find nearby services',
          Icons.location_on,
          Colors.purple,
              () => Get.toNamed(Routes.serviceLocatorScreen),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      ThemeData theme,
      bool isDark,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ],
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme, bool isDark) {
    return Obx(() {
      if (driverController.recentTrips.isEmpty) {
        return _buildEmptyState(
          theme,
          'No recent trips',
          'Your recent driving activity will appear here',
          Icons.route,
        );
      }

      return Column(
        children: driverController.recentTrips.take(3).map((trip) {
          String dateText = DateFormat('MMM d, h:mm a').format(trip.startTime);

          return Card(
            elevation: 1,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => Get.toNamed(
                Routes.tripDetailsScreen,
                arguments: {'tripId': trip.id},
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_car,
                          color: AppColors.primary,
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
                            '${trip.startAddress} to ${trip.endAddress ?? 'Unknown'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            dateText,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${trip.distanceTraveled.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${trip.duration.toInt()} min',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCommunityUpdates(ThemeData theme, bool isDark) {
    return Obx(() {
      if (communityController.nearbyNotifications.isEmpty) {
        return _buildEmptyState(
          theme,
          'No community updates',
          'Updates from nearby drivers will appear here',
          Icons.people,
        );
      }

      return Column(
        children: communityController.nearbyNotifications.take(3).map((notification) {
          String timeAgo = _getTimeAgo(notification.timestamp);

          return Card(
            elevation: 1,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => Get.toNamed(
                Routes.notificationDetailsScreen,
                arguments: {'notification': notification},
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorForType(notification.type).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getIconForType(notification.type),
                          color: _getColorForType(notification.type),
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
                            notification.type.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _getColorForType(notification.type),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              size: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${notification.likeCount}',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildEmptyState(
      ThemeData theme,
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Icons.car_crash;
      case 'traffic':
        return Icons.traffic;
      case 'police':
        return Icons.local_police;
      case 'hazard':
        return Icons.warning;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Colors.red;
      case 'traffic':
        return Colors.orange;
      case 'police':
        return Colors.blue;
      case 'hazard':
        return Colors.amber;
      case 'construction':
        return Colors.yellow[800]!;
      default:
        return Colors.teal;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class SliverFadeTransition extends SingleChildRenderObjectWidget {
  final Animation<double> opacity;

  const SliverFadeTransition({
    super.key,
    required this.opacity,
    required Widget sliver,
  }) : super(child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSliverFadeTransition(opacity);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSliverFadeTransition renderObject) {
    renderObject.opacity = opacity;
  }
}

class _RenderSliverFadeTransition extends RenderProxySliver {
  _RenderSliverFadeTransition(Animation<double> opacity) : _opacity = opacity {
    _opacity.addListener(markNeedsPaint);
  }

  Animation<double> _opacity;
  Animation<double> get opacity => _opacity;
  set opacity(Animation<double> value) {
    if (_opacity == value) return;
    if (attached) _opacity.removeListener(markNeedsPaint);
    _opacity = value;
    _opacity.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _opacity.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _opacity.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Apply opacity value to the layer
    if (_opacity.value > 0.0) {
      final layer = context.pushOpacity(
          offset, (_opacity.value * 255).round(), super.paint);
    }
  }
}
