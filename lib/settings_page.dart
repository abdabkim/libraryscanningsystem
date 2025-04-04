import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _selectedLanguage = prefs.getString('selected_language') ?? 'English';
        _fontSize = prefs.getDouble('font_size') ?? 16.0;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settings updated')),
      );
    } catch (e) {
      print('Error saving setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  void _showDemoDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
              'This is a demo feature. This dialog would contain $title settings in a real application.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelector() {
    final languages = [
      'English',
      'Spanish',
      'French',
      'German',
      'Chinese',
      'Japanese'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(languages[index]),
                  value: languages[index],
                  groupValue: _selectedLanguage,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                      _saveSetting('selected_language', value);
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notifications Section
              _buildSectionCard(
                'Notifications',
                Icons.notifications,
                [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text(
                        'Receive notifications about library events and reservations'),
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSetting('notifications_enabled', value);
                    },
                  ),
                  ListTile(
                    title: const Text('Notification Frequency'),
                    subtitle: const Text(
                        'Control how often you receive notifications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showDemoDialog('Notification Frequency Settings');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Appearance Section
              _buildSectionCard(
                'Appearance',
                Icons.palette,
                [
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text('Currently set to: $_selectedLanguage'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageSelector();
                    },
                  ),
                  ListTile(
                    title: const Text('Font Size'),
                    subtitle: Text('${_fontSize.toInt()} px'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 24.0,
                        divisions: 6,
                        label: _fontSize.toInt().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _fontSize = value;
                          });
                        },
                        onChangeEnd: (double value) {
                          _saveSetting('font_size', value);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Support Section
              _buildSectionCard(
                'Support & About',
                Icons.help_outline,
                [
                  ListTile(
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showDemoDialog('Help Center');
                    },
                  ),
                  ListTile(
                    title: const Text('Report a Problem'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showDemoDialog('Report a Problem');
                    },
                  ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('Version 1.0.0'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showDemoDialog('About App');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Reset Settings Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showResetSettingsConfirmation();
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset All Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetSettingsConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to their default values?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  setState(() {
                    _notificationsEnabled = true;
                    _selectedLanguage = 'English';
                    _fontSize = 16.0;
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error resetting settings: $e');
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(leading: Icon(icon), title: Text(title)),
          ...children,
        ],
      ),
    );
  }
}
