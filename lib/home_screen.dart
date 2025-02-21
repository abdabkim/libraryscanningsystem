import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = 'User'; // Default value
  String _lockerStatus = 'Inactive';
  String _lockerTime = '--:--';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Try to get name from SharedPreferences first
      String? storedName = prefs.getString('fullName');
      print('Name from SharedPreferences: $storedName'); // Debug print

      if (storedName != null && storedName.isNotEmpty) {
        setState(() {
          _fullName = storedName;
          print(
              'Setting name from SharedPreferences: $_fullName'); // Debug print
        });
        return;
      }

      // If not in SharedPreferences, try Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        setState(() {
          _fullName = user.displayName!;
          print('Setting name from Firebase: $_fullName'); // Debug print
        });
        // Save to SharedPreferences for future use
        await prefs.setString('fullName', user.displayName!);
        return;
      }

      // If we get here, no name was found
      print('No name found in either location'); // Debug print
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _showQRScanner(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Demo $title Scanner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Scanning QR Code...'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (title == 'Locker') {
                    setState(() {
                      _lockerStatus = 'Active';
                      _lockerTime = '10:29';
                    });
                  }
                  Navigator.pop(context);
                  _showSuccessDialog(context, title);
                },
                child: const Text('Simulate Successful Scan'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: Text('$feature scan completed successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLibraryReservation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Library Slots'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Study Room 1'),
                subtitle: const Text('Available'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessDialog(context, 'Reservation');
                  },
                  child: const Text('Book'),
                ),
              ),
              ListTile(
                title: const Text('Study Room 2'),
                subtitle: const Text('Occupied until 2:00 PM'),
                trailing: ElevatedButton(
                  onPressed: null,
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, $_fullName',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
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
            _buildInfoCard(
              'Locker Availability',
              'Scan ID\nCheck your locker Information',
              Icons.qr_code,
              () => _showQRScanner(context, 'Locker'),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Arrival ID',
              'Scan ID\nArrival and departure',
              Icons.qr_code_scanner,
              () => _showQRScanner(context, 'Arrival'),
            ),
            const SizedBox(height: 16),
            _buildLockerDashboard(),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Library Reservation System',
              'View available slots',
              Icons.library_books,
              () => _showLibraryReservation(context),
            ),
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
              children: [
                const Text(
                  'Locker Status:',
                  style: TextStyle(fontSize: 16),
                ),
                Chip(
                  label: Text(_lockerTime,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor:
                      _lockerStatus == 'Active' ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            Text(
              'Status: $_lockerStatus',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
