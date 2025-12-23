import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calibration_page.dart';
import 'main.dart'; 
import 'database_helper.dart';
import 'home_page.dart'; 
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // General
  bool _darkMode = false;
  String _unit = 'dB A';
  
  // App Info
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _unit = prefs.getString('unit') ?? 'dB A';
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  Future<void> _clearHistory() async {
    await DatabaseHelper().clearAll();

    // Force the History Page to refresh its state
    historyPageKey.currentState?.loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('General'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: _darkMode,
            onChanged: (bool value) {
              setState(() {
                _darkMode = value;
                _saveSetting('dark_mode', value);
                MyApp.setTheme(context, value);
              });
            },
          ),
          ListTile(
            title: const Text('Units'),
            leading: const Icon(Icons.speed),
            trailing: DropdownButton<String>(
              value: _unit,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _unit = newValue;
                    _saveSetting('unit', newValue);
                  });
                }
              },
              items: <String>['dB A', 'dB C']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          const Divider(),
          _buildSectionHeader('Calibration'),
          ListTile(
            title: const Text('Re-calibrate Sound Meter'),
            leading: const Icon(Icons.tune),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CalibrationPage()),
              );
            },
          ),

          const Divider(),
          _buildSectionHeader('Data'),
          ListTile(
            title: const Text('Clear History'),
            leading: const Icon(Icons.delete_forever),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text('Are you sure you want to delete all measurement history? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            leading: const Icon(Icons.info),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
