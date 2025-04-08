import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:library_scanning_system/profile_page.dart';
import 'package:library_scanning_system/settings_page.dart';
import 'package:library_scanning_system/status_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fullName = 'User'; // Default value
  String _lockerStatus = 'Inactive';
  String _lockerTime = '--:--';
  int _currentIndex = 0; // For bottom navigation
  DateTime _selectedDate = DateTime.now();

  // Locker information
  int _totalLockers = 114;
  int _usedLockers = 0;
  int _availableLockers = 114;

  // Library rooms with capacity
  final Map<String, Map<String, dynamic>> _libraryRooms = {
    'The Ralph Burgess Reading Room': {'capacity': 20, 'current': 0},
    'The W.D. Carter Library Co-operator': {'capacity': 15, 'current': 0},
    'Merle Bennett Reference Room': {'capacity': 15, 'current': 0},
    'Graduate / Faculty Room': {'capacity': 6, 'current': 0},
    'Periodicals': {'capacity': 20, 'current': 0},
  };

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadLockerInformation();
    _loadRoomInformation();
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

  Future<void> _loadLockerInformation() async {
    try {
      // Get locker information from Firestore
      final lockerDoc = await FirebaseFirestore.instance
          .collection('lockers')
          .doc('status')
          .get();

      if (lockerDoc.exists) {
        setState(() {
          _usedLockers = lockerDoc.data()?['usedLockers'] ?? 0;
          _availableLockers = _totalLockers - _usedLockers;
        });
      } else {
        // Initialize the document if it doesn't exist
        await FirebaseFirestore.instance
            .collection('lockers')
            .doc('status')
            .set({
          'totalLockers': _totalLockers,
          'usedLockers': 0,
        });
      }
    } catch (e) {
      print('Error loading locker information: $e');
    }
  }

  Future<void> _loadRoomInformation() async {
    try {
      // Get room information from Firestore
      final roomsCollection =
          await FirebaseFirestore.instance.collection('libraryRooms').get();

      if (roomsCollection.docs.isNotEmpty) {
        for (var doc in roomsCollection.docs) {
          final roomName = doc.id;
          final current = doc.data()['current'] ?? 0;

          if (_libraryRooms.containsKey(roomName)) {
            setState(() {
              _libraryRooms[roomName]!['current'] = current;
            });
          }
        }
      } else {
        // Initialize room documents if they don't exist
        for (var room in _libraryRooms.entries) {
          await FirebaseFirestore.instance
              .collection('libraryRooms')
              .doc(room.key)
              .set({
            'capacity': room.value['capacity'],
            'current': 0,
          });
        }
      }
    } catch (e) {
      print('Error loading room information: $e');
    }
  }

  Future<void> _updateLockerCount(bool increase) async {
    try {
      // Update in Firestore
      final lockerRef =
          FirebaseFirestore.instance.collection('lockers').doc('status');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(lockerRef);
        final currentUsed = snapshot.data()?['usedLockers'] ?? 0;
        final newUsed = increase ? currentUsed + 1 : currentUsed - 1;

        transaction.update(lockerRef, {'usedLockers': newUsed});
      });

      // Update local state
      setState(() {
        if (increase) {
          _usedLockers++;
          _availableLockers--;
        } else {
          _usedLockers--;
          _availableLockers++;
        }
      });

      // Save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('usedLockers', _usedLockers);
      prefs.setInt('availableLockers', _availableLockers);

      // Record this locker usage in user history
      _recordLockerUsage();
    } catch (e) {
      print('Error updating locker count: $e');
    }
  }

  Future<void> _recordLockerUsage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timestamp = DateTime.now();

      // Add to user's history in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lockerHistory')
          .add({
        'date': formattedDate,
        'timestamp': timestamp,
        'selectedDate': _selectedDate,
      });

      // Also store in SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('lockerHistory') ?? '[]';
      List<dynamic> history = [];
      try {
        history = List<dynamic>.from(jsonDecode(historyJson));
      } catch (e) {
        print('Error parsing locker history: $e');
      }

      history.add({
        'date': formattedDate,
        'timestamp': timestamp.toIso8601String(),
        'selectedDate': _selectedDate.toIso8601String(),
      });

      prefs.setString('lockerHistory', jsonEncode(history));
    } catch (e) {
      print('Error recording locker usage: $e');
    }
  }

  Future<void> _updateRoomOccupancy(String roomName, bool join) async {
    try {
      if (!_libraryRooms.containsKey(roomName)) return;

      final roomRef =
          FirebaseFirestore.instance.collection('libraryRooms').doc(roomName);

      bool success = true;

      // Update in Firestore using transaction to ensure atomic operation
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        final currentCount = snapshot.data()?['current'] ?? 0;
        final capacity = snapshot.data()?['capacity'] ??
            _libraryRooms[roomName]!['capacity'];

        if (join) {
          // Check if room is full
          if (currentCount >= capacity) {
            success = false;
            return;
          }
          transaction.update(roomRef, {'current': currentCount + 1});
        } else {
          // Don't go below 0
          final newCount = currentCount > 0 ? currentCount - 1 : 0;
          transaction.update(roomRef, {'current': newCount});
        }
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$roomName is at full capacity')),
        );
        return;
      }

      // Update local state
      setState(() {
        if (join) {
          _libraryRooms[roomName]!['current']++;
        } else if (_libraryRooms[roomName]!['current'] > 0) {
          _libraryRooms[roomName]!['current']--;
        }
      });

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('room_$roomName', _libraryRooms[roomName]!['current']);

      if (join) {
        _recordRoomUsage(roomName);
        _showSuccessDialog(context, 'Room Reservation');
      }
    } catch (e) {
      print('Error updating room occupancy: $e');
    }
  }

  Future<void> _recordRoomUsage(String roomName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timestamp = DateTime.now();

      // Add to user's history in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('roomHistory')
          .add({
        'date': formattedDate,
        'timestamp': timestamp,
        'roomName': roomName,
        'selectedDate': _selectedDate,
      });

      // Also store in SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('roomHistory') ?? '[]';
      List<dynamic> history = [];
      try {
        history = List<dynamic>.from(jsonDecode(historyJson));
      } catch (e) {
        print('Error parsing room history: $e');
      }

      history.add({
        'date': formattedDate,
        'timestamp': timestamp.toIso8601String(),
        'roomName': roomName,
        'selectedDate': _selectedDate.toIso8601String(),
      });

      prefs.setString('roomHistory', jsonEncode(history));
    } catch (e) {
      print('Error recording room usage: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored data
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushReplacementNamed(context, 'LoginScreen()');
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
                    _updateLockerCount(true); // Increase used lockers
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // Save selected date to preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('selectedDate', picked.toIso8601String());

      // Also save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastSelectedDate': picked,
        }, SetOptions(merge: true));
      }
    }
  }

  void _showLibraryReservation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Library Reservation and Status Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLockerAvailability(),
              const Divider(),
              Row(
                children: [
                  const Text('Selected Date: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change'),
                    onPressed: () {
                      Navigator.pop(context);
                      _selectDate(context).then((_) {
                        _showLibraryReservation(context);
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              const Text(
                'Select Room:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: _libraryRooms.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final room = _libraryRooms.keys.elementAt(index);
                    final details = _libraryRooms[room]!;
                    final isFull = details['current'] >= details['capacity'];

                    return ListTile(
                      title: Text(room),
                      subtitle: Text(
                          'Occupancy: ${details['current']}/${details['capacity']}'),
                      trailing: ElevatedButton(
                        onPressed: isFull
                            ? null
                            : () {
                                _updateRoomOccupancy(room, true);
                                Navigator.pop(context);
                              },
                        child: const Text('Book'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockerAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Locker Availability',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Lockers:'),
            Text('$_totalLockers',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available:'),
            Text(
              '$_availableLockers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('In Use:'),
            Text(
              '$_usedLockers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _usedLockers >= _totalLockers ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of pages for bottom navigation
    final List<Widget> _pages = [
      _buildHomePage(),
      ProfilePage(),
      StatusPage(),
      SettingsPage(),
    ];

    return Scaffold(
      extendBody: true, // Allows the body to extend behind the bottom nav bar
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
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        // Background with blue gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep blue
                Color(0xFF1E88E5), // Medium blue
              ],
              stops: const [0.2, 1.0],
            ),
          ),
        ),
        // Image positioned on bottom half with curve
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.55,
          child: ClipPath(
            clipper: BackgroundImageClipper(),
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCardVariant(
                  'Locker Availability',
                  'Scan ID\nCheck your locker Information',
                  Icons.qr_code,
                  () => _showQRScanner(context, 'Locker'),
                  Colors.purple.withOpacity(0.3),
                  alignment: Alignment.topRight,
                  height: 120,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInfoCardVariant(
                        'Arrival ID',
                        'Scan ID\nArrival & departure',
                        Icons.qr_code_scanner,
                        () => _showQRScanner(context, 'Arrival'),
                        Colors.teal.withOpacity(0.3),
                        alignment: Alignment.centerLeft,
                        height: 145,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _buildInfoCardVariant(
                        'Select Date',
                        'Current: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                        Icons.calendar_month,
                        () => _selectDate(context),
                        Colors.indigo.withOpacity(0.3),
                        height: 145,
                        alignment: Alignment.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLockerDashboardVariant(),
                const SizedBox(height: 16),
                _buildInfoCardVariant(
                  'Library Reservation',
                  'View available slots & rooms',
                  Icons.library_books,
                  () => _showLibraryReservation(context),
                  Colors.amber.withOpacity(0.3),
                  alignment: Alignment.bottomLeft,
                  height: 110,
                ),
                // Extra space to ensure bottom content isn't hidden by nav bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCardVariant(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
    Color overlayColor, {
    Alignment alignment = Alignment.center,
    double height = 100,
  }) {
    return Container(
      height: height,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // Using a transparent card with a colored overlay
        color: Colors.white.withOpacity(0.85),
        child: Stack(
          children: [
            // Colored overlay with gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      overlayColor.withOpacity(0.1),
                      overlayColor,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.blue.shade800, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            // Make the entire card clickable
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Arrow icon
            Positioned(
              right: 10,
              bottom: 10,
              child: Icon(
                Icons.arrow_forward,
                color: Colors.blue.shade800,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockerDashboardVariant() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white.withOpacity(0.85),
      child: Stack(
        children: [
          // Colored overlay with gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Locker Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    Chip(
                      label: Text(_lockerTime,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      backgroundColor: _lockerStatus == 'Active'
                          ? Colors.blue.shade800
                          : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: $_lockerStatus',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            buildStatColumn('Total', '$_totalLockers',
                                Colors.blue.shade900),
                            const SizedBox(width: 16),
                            buildStatColumn('Available', '$_availableLockers',
                                Colors.green),
                            const SizedBox(width: 16),
                            buildStatColumn(
                                'In Use',
                                '$_usedLockers',
                                _usedLockers >= _totalLockers
                                    ? Colors.red
                                    : Colors.blue.shade700),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.lock_outline,
                      color: _lockerStatus == 'Active'
                          ? Colors.blue.shade800
                          : Colors.grey,
                      size: 40,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// Custom clipper for curved background image in bottom half
class BackgroundImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.3); // Start from 30% down on left side
    path.quadraticBezierTo(
        size.width * 0.3, 0, size.width * 0.6, 0); // Curve upward
    path.lineTo(size.width, 0); // Top right corner
    path.lineTo(size.width, size.height); // Bottom right corner
    path.lineTo(0, size.height); // Bottom left corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
