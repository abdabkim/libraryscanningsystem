import 'package:flutter/material.dart';
import 'package:library_scanning_system/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({Key? key}) : super(key: key);

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  // User information
  String _fullName = 'User';

  // Today's date
  DateTime _today = DateTime.now();

  // Activity statistics
  int _lockersBooked = 0;
  List<Map<String, dynamic>> _lockerHistory = [];
  List<Map<String, dynamic>> _roomHistory = [];
  Map<String, int> _roomVisits = {};
  int _totalRoomsVisited = 0;
  String _mostVisitedRoom = 'None';

  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _loadUserName();
      await _loadActivityData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading data: $e';
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      // Try to get name from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First check display name
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            _fullName = user.displayName!;
          });
          return;
        }

        // If display name not available, try to fetch from Firestore users collection
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data()?['fullName'] != null) {
            setState(() {
              _fullName = userDoc.data()!['fullName'];
            });
          }
        } catch (e) {
          print('Error fetching user profile from Firestore: $e');
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
      rethrow;
    }
  }

  Future<void> _loadActivityData() async {
    try {
      await _loadLockerHistory();
      await _loadRoomHistory();
      _calculateStatistics();
    } catch (e) {
      print('Error loading activity data: $e');
      rethrow;
    }
  }

  Future<void> _loadLockerHistory() async {
    try {
      final formattedToday = DateFormat('yyyy-MM-dd').format(_today);
      _lockerHistory = [];

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lockerHistory')
            .where('date', isEqualTo: formattedToday)
            .get();

        for (var doc in querySnapshot.docs) {
          _lockerHistory.add(doc.data());
        }
      }
    } catch (e) {
      print('Error loading locker history: $e');
      rethrow;
    }
  }

  Future<void> _loadRoomHistory() async {
    try {
      final formattedToday = DateFormat('yyyy-MM-dd').format(_today);
      _roomHistory = [];

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('roomHistory')
            .where('date', isEqualTo: formattedToday)
            .get();

        for (var doc in querySnapshot.docs) {
          _roomHistory.add(doc.data());
        }
      }
    } catch (e) {
      print('Error loading room history: $e');
      rethrow;
    }
  }

  void _calculateStatistics() {
    // Calculate locker statistics
    _lockersBooked = _lockerHistory.length;

    // Calculate room statistics
    _roomVisits = {};
    for (var visit in _roomHistory) {
      final roomName = visit['roomName'] as String;
      _roomVisits[roomName] = (_roomVisits[roomName] ?? 0) + 1;
    }

    _totalRoomsVisited = _roomVisits.length;

    // Find most visited room
    if (_roomVisits.isNotEmpty) {
      _mostVisitedRoom =
          _roomVisits.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    } else {
      _mostVisitedRoom = 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
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
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _hasError
                  ? _buildErrorView()
                  : _buildContentView(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTodaySummary(),
            const SizedBox(height: 16),
            _buildLockerUsage(),
            const SizedBox(height: 16),
            _buildRoomUsage(),
            // Extra space to ensure bottom content isn't hidden
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                    Colors.indigo.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue.shade800, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        'Hello, $_fullName',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        'Today: ${DateFormat('EEEE, MMMM d, yyyy').format(_today)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
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
                Text(
                  'Today\'s Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Lockers Used',
                      '$_lockersBooked',
                      Icons.lock,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Rooms Visited',
                      '$_totalRoomsVisited',
                      Icons.meeting_room,
                      Colors.teal,
                    ),
                  ],
                ),
                if (_totalRoomsVisited > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.teal.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Most Visited Room Today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                _mostVisitedRoom,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_roomVisits[_mostVisitedRoom]}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.38,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockerUsage() {
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
                    Colors.purple.withOpacity(0.1),
                    Colors.purple.withOpacity(0.3),
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
                  children: [
                    Icon(Icons.lock_outline, color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Locker Usage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _lockerHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No locker usage recorded today',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int index = 0;
                              index < _lockerHistory.length;
                              index++)
                            _buildLockerHistoryItem(
                                index, _lockerHistory[index]),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockerHistoryItem(int index, Map<String, dynamic> usage) {
    final timestamp = usage['timestamp'] is Timestamp
        ? (usage['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple.shade100,
            child: Icon(Icons.lock, color: Colors.purple.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Locker Usage #${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'Time: ${DateFormat('hh:mm a').format(timestamp)}',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomUsage() {
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
                    Colors.teal.withOpacity(0.1),
                    Colors.teal.withOpacity(0.3),
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
                  children: [
                    Icon(Icons.meeting_room, color: Colors.teal.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Room Visits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _roomHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No room visits recorded today',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var roomName in _roomVisits.keys)
                            _buildRoomVisitItem(
                                roomName, _roomVisits[roomName]!),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomVisitItem(String roomName, int visitCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            child: Icon(Icons.meeting_room, color: Colors.teal.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  'Visits today: $visitCount',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
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

// Add a method to handle logout
Future<void> handleLogout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  } catch (e) {
    print('Error during logout: $e');
  }
}
