import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to profile settings
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Navigation Settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to navigation settings
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help & support
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to about screen
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Logout functionality
            },
          ),
        ],
      ),
    );
  }
}
