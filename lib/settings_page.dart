import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _fontSize = 16.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _fontSize = prefs.getDouble('font_size') ?? 16.0;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }

    setState(() => _isSaving = false);
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    setState(() => _isSaving = true);

    try {
      // Update state
      setState(() {
        if (key == 'notifications_enabled') {
          _notificationsEnabled = value as bool;
        } else if (key == 'dark_mode_enabled') {
          _darkModeEnabled = value as bool;
        } else if (key == 'font_size') {
          _fontSize = value as double;
        }
      });

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated')),
      );
    } catch (e) {
      print('Error saving setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }

    setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? Colors.grey[900] : Colors.white,
        image: !_darkModeEnabled
            ? const DecorationImage(
                image: AssetImage("assets/bg.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
              )
            : null,
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
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
                      color: _darkModeEnabled ? Colors.white : Colors.white,
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
                        title: Text('Push Notifications',
                            style: TextStyle(fontSize: _fontSize)),
                        subtitle: Text(
                            'Receive notifications about library events and reservations',
                            style: TextStyle(fontSize: _fontSize - 2)),
                        value: _notificationsEnabled,
                        onChanged: (bool value) {
                          _saveSetting('notifications_enabled', value);
                        },
                      ),
                      ListTile(
                        title: Text('Notification Frequency',
                            style: TextStyle(fontSize: _fontSize)),
                        subtitle: Text(
                            'Control how often you receive notifications',
                            style: TextStyle(fontSize: _fontSize - 2)),
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
                      SwitchListTile(
                        title: Text('Dark Mode',
                            style: TextStyle(fontSize: _fontSize)),
                        subtitle: Text('Switch between light and dark theme',
                            style: TextStyle(fontSize: _fontSize - 2)),
                        value: _darkModeEnabled,
                        onChanged: (bool value) {
                          _saveSetting('dark_mode_enabled', value);
                        },
                      ),
                      ListTile(
                        title: Text('Font Size',
                            style: TextStyle(fontSize: _fontSize)),
                        subtitle: Text('${_fontSize.toInt()} px',
                            style: TextStyle(fontSize: _fontSize - 2)),
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
                        title: Text('Help Center',
                            style: TextStyle(fontSize: _fontSize)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showDemoDialog('Help Center');
                        },
                      ),
                      ListTile(
                        title: Text('Report a Problem',
                            style: TextStyle(fontSize: _fontSize)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showDemoDialog('Report a Problem');
                        },
                      ),
                      ListTile(
                        title: Text('About',
                            style: TextStyle(fontSize: _fontSize)),
                        subtitle: Text('Version 1.0.0',
                            style: TextStyle(fontSize: _fontSize - 2)),
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

          // Loading indicator
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
                setState(() => _isSaving = true);

                try {
                  // Reset local values
                  setState(() {
                    _notificationsEnabled = true;
                    _darkModeEnabled = false;
                    _fontSize = 16.0;
                  });

                  // Update SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications_enabled', true);
                  await prefs.setBool('dark_mode_enabled', false);
                  await prefs.setDouble('font_size', 16.0);

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to defaults')),
                  );
                } catch (e) {
                  print('Error resetting settings: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error resetting settings: $e')),
                  );
                }

                setState(() => _isSaving = false);
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
      color:
          _darkModeEnabled ? Colors.grey[800] : Colors.white.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading:
                Icon(icon, color: _darkModeEnabled ? Colors.white70 : null),
            title: Text(
              title,
              style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: _darkModeEnabled ? Colors.white : Colors.black87),
            ),
          ),
          ...children.map((child) {
            // Apply dark mode styling to all children if they are ListTile or SwitchListTile
            if (_darkModeEnabled) {
              if (child is SwitchListTile) {
                return SwitchListTile(
                  title: DefaultTextStyle(
                    style: TextStyle(color: Colors.white, fontSize: _fontSize),
                    child: child.title!,
                  ),
                  subtitle: child.subtitle != null
                      ? DefaultTextStyle(
                          style: TextStyle(
                              color: Colors.white70, fontSize: _fontSize - 2),
                          child: child.subtitle!,
                        )
                      : null,
                  value: child.value,
                  onChanged: child.onChanged,
                  activeColor: Colors.tealAccent,
                );
              } else if (child is ListTile) {
                return ListTile(
                  title: child.title != null
                      ? DefaultTextStyle(
                          style: TextStyle(
                              color: Colors.white, fontSize: _fontSize),
                          child: child.title!,
                        )
                      : null,
                  subtitle: child.subtitle != null
                      ? DefaultTextStyle(
                          style: TextStyle(
                              color: Colors.white70, fontSize: _fontSize - 2),
                          child: child.subtitle!,
                        )
                      : null,
                  trailing: child.trailing,
                  onTap: child.onTap,
                );
              }
            }
            return child;
          }).toList(),
        ],
      ),
    );
  }
}
