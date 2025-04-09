import 'package:flutter/material.dart';
import 'package:library_scanning_system/services/settings_provider.dart';
import 'package:provider/provider.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.darkModeEnabled;
    final fontSize = settingsProvider.fontSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              image: !isDarkMode
                  ? const DecorationImage(
                image: AssetImage("assets/bg.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
              )
                  : null,
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
                        color: isDarkMode ? Colors.white : Colors.white,
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
                      context,
                      'Notifications',
                      Icons.notifications,
                      [
                        SwitchListTile(
                          title: Text('Push Notifications',
                              style: TextStyle(fontSize: fontSize)),
                          subtitle: Text(
                              'Receive notifications about library events and reservations',
                              style: TextStyle(fontSize: fontSize - 2)),
                          value: settingsProvider.notificationsEnabled,
                          onChanged: (bool value) {
                            settingsProvider.setNotificationsEnabled(value);
                          },
                        ),
                        ListTile(
                          title: Text('Notification Frequency',
                              style: TextStyle(fontSize: fontSize)),
                          subtitle: Text(
                              'Control how often you receive notifications',
                              style: TextStyle(fontSize: fontSize - 2)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showDemoDialog(context, 'Notification Frequency Settings');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Appearance Section
                    _buildSectionCard(
                      context,
                      'Appearance',
                      Icons.palette,
                      [
                        SwitchListTile(
                          title: Text('Dark Mode',
                              style: TextStyle(fontSize: fontSize)),
                          subtitle: Text('Switch between light and dark theme',
                              style: TextStyle(fontSize: fontSize - 2)),
                          value: settingsProvider.darkModeEnabled,
                          onChanged: (bool value) {
                            settingsProvider.setDarkModeEnabled(value);
                          },
                        ),
                        ListTile(
                          title: Text('Font Size',
                              style: TextStyle(fontSize: fontSize)),
                          subtitle: Text('${fontSize.toInt()} px',
                              style: TextStyle(fontSize: fontSize - 2)),
                          trailing: SizedBox(
                            width: 150,
                            child: Slider(
                              value: fontSize,
                              min: 12.0,
                              max: 24.0,
                              divisions: 6,
                              label: fontSize.toInt().toString(),
                              onChanged: (double value) {
                                settingsProvider.setFontSize(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Support Section
                    _buildSectionCard(
                      context,
                      'Support & About',
                      Icons.help_outline,
                      [
                        ListTile(
                          title: Text('Help Center',
                              style: TextStyle(fontSize: fontSize)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showDemoDialog(context, 'Help Center');
                          },
                        ),
                        ListTile(
                          title: Text('Report a Problem',
                              style: TextStyle(fontSize: fontSize)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showDemoDialog(context, 'Report a Problem');
                          },
                        ),
                        ListTile(
                          title: Text('About',
                              style: TextStyle(fontSize: fontSize)),
                          subtitle: Text('Version 1.0.0',
                              style: TextStyle(fontSize: fontSize - 2)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            _showDemoDialog(context, 'About App');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Reset Settings Button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showResetSettingsConfirmation(context, settingsProvider);
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
          ),

          // Loading indicator
          if (settingsProvider.isLoading)
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

  Widget _buildSectionCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    final isDarkMode = Provider.of<SettingsProvider>(context).darkModeEnabled;

    return Card(
      elevation: 4,
      color: isDarkMode ? Colors.grey[800] : Colors.white.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: isDarkMode ? Colors.white70 : null),
            title: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showDemoDialog(BuildContext context, String title) {
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

  void _showResetSettingsConfirmation(BuildContext context, SettingsProvider provider) {
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
                await provider.resetSettings();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}