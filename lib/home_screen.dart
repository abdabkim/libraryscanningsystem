import 'package:flutter/material.dart';
//import 'package:library_scanning_system/login_screen.dart';
//import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) {
    // Add your logout logic here
    // For example:
    //authservice.logout();
    Navigator.pushReplacementNamed(
        context, 'LoginScreen()'); // Navigate to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white), // Set Dashboard text to white
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white, // Set logout icon to white
            ),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard('Locker Availability',
                'Scan ID\nCheck your locker Information', Icons.qr_code, () {}),
            const SizedBox(height: 16),
            _buildInfoCard('Arrival ID', 'Scan ID\nArrival and departure',
                Icons.qr_code_scanner, () {}),
            const SizedBox(height: 16),
            _buildLockerDashboard(),
            const SizedBox(height: 16),
            _buildInfoCard('Library Reservation System', 'View available slots',
                Icons.library_books, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String description, IconData icon, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildLockerDashboard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Locker Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Locker Status:',
                  style: TextStyle(fontSize: 16),
                ),
                Chip(
                  label: Text('10:29',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
