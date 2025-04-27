import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymaptest/config/theme/app_colors.dart';
import 'package:mymaptest/features/main/controller/theme_controller.dart';
import 'package:mymaptest/features/driver_behaviour/controller/driver_behaviour_controller.dart';
import 'package:mymaptest/features/navigation/controller/navigation_controller.dart';
import 'package:mymaptest/core/routes/app_pages.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with SingleTickerProviderStateMixin {
  final ThemeController themeController = Get.find<ThemeController>();
  final DriverBehaviorController driverController = Get.find<DriverBehaviorController>();
  final NavigationController navigationController = Get.find<NavigationController>();

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Profile Section
            _buildSectionHeader(theme, 'Account'),
            _buildProfileCard(theme, isDark),
            SizedBox(height: 24),

            // Appearance Section
            _buildSectionHeader(theme, 'Appearance'),
            _buildAppearanceSettings(theme, isDark),
            SizedBox(height: 24),

            // Navigation Section
            _buildSectionHeader(theme, 'Navigation'),
            _buildNavigationSettings(theme, isDark),
            SizedBox(height: 24),

            // Driver Behavior Section
            _buildSectionHeader(theme, 'Driver Behavior'),
            _buildDriverBehaviorSettings(theme, isDark),
            SizedBox(height: 24),

            // Privacy & Security Section
            _buildSectionHeader(theme, 'Privacy & Security'),
            _buildPrivacySettings(theme, isDark),
            SizedBox(height: 24),

            // About & Support Section
            _buildSectionHeader(theme, 'About & Support'),
            _buildAboutSettings(theme, isDark),
            SizedBox(height: 24),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(200, 50),
                ),
              ),
            ),
            SizedBox(height: 40),

            // App Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Get.toNamed(Routes.profileScreen),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'john.doe@example.com',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Obx(() => SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Use dark theme throughout the app'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                themeController.isDarkMode.value
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
            ),
            value: themeController.isDarkMode.value,
            onChanged: (value) {
              themeController.toggleTheme();
            },
          )),
          Divider(height: 1),
          ListTile(
            title: Text('Map Style'),
            subtitle: Text('Customize map appearance'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.map,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Navigate to map style settings
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Language'),
            subtitle: Text('English (US)'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.language,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Navigate to language settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSettings(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Obx(() => SwitchListTile(
            title: Text('Voice Guidance'),
            subtitle: Text('Spoken directions while navigating'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_up,
                color: theme.colorScheme.primary,
              ),
            ),
            value: navigationController.voiceGuidanceEnabled.value,
            onChanged: (value) {
              navigationController.toggleVoiceGuidance();
            },
          )),
          Divider(height: 1),
          ListTile(
            title: Text('Distance Unit'),
            subtitle: Text('Kilometers'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.straighten,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Show distance unit options
            },
          ),
          Divider(height: 1),
          SwitchListTile(
            title: Text('Traffic Display'),
            subtitle: Text('Show traffic conditions on map'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.traffic,
                color: theme.colorScheme.primary,
              ),
            ),
            value: true,
            onChanged: (value) {
              // Toggle traffic display
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Manage Saved Places'),
            subtitle: Text('Edit your favorite locations'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () => Get.toNamed(Routes.savedPlacesScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverBehaviorSettings(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Obx(() => SwitchListTile(
            title: Text('Behavior Monitoring'),
            subtitle: Text('Track and analyze driving patterns'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
              ),
            ),
            value: driverController.isMonitoring.value,
            onChanged: (value) {
              if (value) {
                driverController.startMonitoring();
              } else {
                driverController.stopMonitoring();
              }
            },
          )),
          Divider(height: 1),
          Obx(() => SwitchListTile(
            title: Text('Voice Feedback'),
            subtitle: Text('Spoken alerts for driving events'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.record_voice_over,
                color: theme.colorScheme.primary,
              ),
            ),
            value: driverController.voiceFeedbackEnabled.value,
            onChanged: (value) {
              driverController.updateFeedbackSettings(voiceFeedback: value);
            },
          )),
          Divider(height: 1),
          Obx(() => SwitchListTile(
            title: Text('Vibration Alerts'),
            subtitle: Text('Haptic feedback for critical events'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vibration,
                color: theme.colorScheme.primary,
              ),
            ),
            value: driverController.hapticFeedbackEnabled.value,
            onChanged: (value) {
              driverController.updateFeedbackSettings(hapticFeedback: value);
            },
          )),
          Divider(height: 1),
          ListTile(
            title: Text('Sensitivity Settings'),
            subtitle: Text('Adjust event detection thresholds'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tune,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Navigate to sensitivity settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Location Sharing'),
            subtitle: Text('Share location with community'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
              ),
            ),
            value: true,
            onChanged: (value) {
              // Toggle location sharing
            },
          ),
          Divider(height: 1),
          SwitchListTile(
            title: Text('Data Collection'),
            subtitle: Text('Collect anonymous usage data'),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.data_usage,
                color: theme.colorScheme.primary,
              ),
            ),
            value: true,
            onChanged: (value) {
              // Toggle data collection
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Privacy Policy'),
            subtitle: Text('Read our privacy policy'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.privacy_tip,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Open privacy policy
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Delete Account'),
            subtitle: Text('Permanently delete your account'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Show delete account confirmation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: Text('Help & Support'),
            subtitle: Text('Get assistance with the app'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Navigate to help & support
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Terms of Service'),
            subtitle: Text('Read our terms of service'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Open terms of service
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('Rate the App'),
            subtitle: Text('Share your feedback'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rate,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Open app store for rating
            },
          ),
          Divider(height: 1),
          ListTile(
            title: Text('About'),
            subtitle: Text('Learn more about the app'),
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info,
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            onTap: () {
              // Show about dialog
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform logout
                Navigator.of(context).pop();
                // Navigate to login screen
                Get.offAllNamed(Routes.loginScreen);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
