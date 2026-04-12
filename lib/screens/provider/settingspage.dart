import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _autoAcceptBookings = false;
  bool _showOnlineStatus = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _settingsSection('Account Settings', [
              _settingsItem(
                Icons.person_outline,
                'Personal Information',
                'Update your name, phone, and email',
                () {},
              ),
              _settingsItem(
                Icons.lock_outline,
                'Password & Security',
                'Change password and security settings',
                () {},
              ),
              _settingsItem(
                Icons.payment,
                'Payment Methods',
                'Manage your payment options',
                () {},
              ),
              _settingsItem(
                Icons.location_on_outlined,
                'Service Locations',
                'Update your service areas',
                () {},
              ),
            ]),

            SizedBox(height: 24),

            // Notification Settings
            _settingsSection('Notifications', [
              SwitchListTile(
                title: Text(
                  'Enable Notifications',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Receive important updates and alerts'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                secondary: Icon(Icons.notifications_outlined, color: Colors.blue.shade700),
              ),
              if (_notificationsEnabled) ...[
                Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Email Notifications'),
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text('Push Notifications'),
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: Text('SMS Notifications'),
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() {
                            _smsNotifications = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ]),

            SizedBox(height: 24),

            // Service Settings
            _settingsSection('Service Settings', [
              SwitchListTile(
                title: Text(
                  'Auto-accept Bookings',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Automatically accept new booking requests'),
                value: _autoAcceptBookings,
                onChanged: (value) {
                  setState(() {
                    _autoAcceptBookings = value;
                  });
                },
                secondary: Icon(Icons.auto_awesome, color: Colors.blue.shade700),
              ),
              SwitchListTile(
                title: Text(
                  'Show Online Status',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Show customers when you\'re available'),
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
                secondary: Icon(Icons.online_prediction, color: Colors.blue.shade700),
              ),
              _settingsItem(
                Icons.schedule,
                'Working Hours',
                'Set your availability schedule',
                () {},
              ),
              _settingsItem(
                Icons.attach_money_outlined,
                'Pricing',
                'Update your service rates',
                () {},
              ),
            ]),

            SizedBox(height: 24),

            // App Settings
            _settingsSection('App Settings', [
              _settingsItem(
                Icons.language,
                'Language',
                'English (US)',
                () {},
              ),
              _settingsItem(
                Icons.format_paint_outlined,
                'Theme',
                'Light',
                () {},
              ),
              _settingsItem(
                Icons.storage_outlined,
                'Storage',
                'Manage cache and data',
                () {},
              ),
            ]),

            SizedBox(height: 24),

            // Support & About
            _settingsSection('Support & About', [
              _settingsItem(
                Icons.help_outline,
                'Help Center',
                'Get help and support',
                () {},
              ),
              _settingsItem(
                Icons.description_outlined,
                'Terms of Service',
                'Read our terms and conditions',
                () {},
              ),
              _settingsItem(
                Icons.security_outlined,
                'Privacy Policy',
                'Learn about our privacy practices',
                () {},
              ),
              _settingsItem(
                Icons.info_outline,
                'About SaidiA',
                'Version 1.0.0',
                () {},
              ),
            ]),

            SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Logout
                },
                icon: Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Delete Account
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Delete account
                },
                child: Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children.map((child) {
              final isLast = children.last == child;
              return Column(
                children: [
                  child,
                  if (!isLast) Divider(height: 1, indent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _settingsItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue.shade700, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}