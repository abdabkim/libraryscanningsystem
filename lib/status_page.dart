import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  DateTime _selectedDate = DateTime.now();

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
      await _loadSelectedDate();
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
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Try to get name from SharedPreferences first
      String? storedName = prefs.getString('fullName');

      if (storedName != null && storedName.isNotEmpty) {
        setState(() {
          _fullName = storedName;
        });
        return;
      }

      // If not in SharedPreferences, try Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        setState(() {
          _fullName = user.displayName!;
        });
        // Save to SharedPreferences for future use
        await prefs.setString('fullName', user.displayName!);
      }
    } catch (e) {
      print('Error loading user name: $e');
      rethrow;
    }
  }

  Future<void> _loadSelectedDate() async {
    try {
      // Try to get selected date from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedDateStr = prefs.getString('selectedDate');

      if (storedDateStr != null) {
        setState(() {
          _selectedDate = DateTime.parse(storedDateStr);
        });
        return;
      }

      // If not in SharedPreferences, try Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['lastSelectedDate'] != null) {
          final timestamp = userDoc.data()?['lastSelectedDate'] as Timestamp;
          setState(() {
            _selectedDate = timestamp.toDate();
          });
          // Save to SharedPreferences for future use
          await prefs.setString(
              'selectedDate', _selectedDate.toIso8601String());
        }
      }
    } catch (e) {
      print('Error loading selected date: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final formattedSelectedDate =
          DateFormat('yyyy-MM-dd').format(_selectedDate);
      _lockerHistory = [];

      // Try to get from SharedPreferences first
      final historyJson = prefs.getString('lockerHistory');
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        for (var item in history) {
          if (item['date'] == formattedSelectedDate) {
            _lockerHistory.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // If empty or not available, try Firebase
      if (_lockerHistory.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final startOfDay = DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day);
          // ignore: unused_local_variable
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('lockerHistory')
              .where('date', isEqualTo: formattedSelectedDate)
              .get();

          for (var doc in querySnapshot.docs) {
            _lockerHistory.add(doc.data());
          }

          // Save to SharedPreferences for offline access
          List<dynamic> allHistory = [];
          final allHistoryJson = prefs.getString('lockerHistory');
          if (allHistoryJson != null) {
            allHistory = jsonDecode(allHistoryJson);
            // Remove entries for this date to avoid duplicates
            allHistory
                .removeWhere((item) => item['date'] == formattedSelectedDate);
          }
          // Add new entries
          allHistory.addAll(_lockerHistory);
          prefs.setString('lockerHistory', jsonEncode(allHistory));
        }
      }
    } catch (e) {
      print('Error loading locker history: $e');
      rethrow;
    }
  }

  Future<void> _loadRoomHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formattedSelectedDate =
          DateFormat('yyyy-MM-dd').format(_selectedDate);
      _roomHistory = [];

      // Try to get from SharedPreferences first
      final historyJson = prefs.getString('roomHistory');
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        for (var item in history) {
          if (item['date'] == formattedSelectedDate) {
            _roomHistory.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // If empty or not available, try Firebase
      if (_roomHistory.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('roomHistory')
              .where('date', isEqualTo: formattedSelectedDate)
              .get();

          for (var doc in querySnapshot.docs) {
            _roomHistory.add(doc.data());
          }

          // Save to SharedPreferences for offline access
          List<dynamic> allHistory = [];
          final allHistoryJson = prefs.getString('roomHistory');
          if (allHistoryJson != null) {
            allHistory = jsonDecode(allHistoryJson);
            // Remove entries for this date to avoid duplicates
            allHistory
                .removeWhere((item) => item['date'] == formattedSelectedDate);
          }
          // Add new entries
          allHistory.addAll(_roomHistory);
          prefs.setString('roomHistory', jsonEncode(allHistory));
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now()
          .subtract(const Duration(days: 30)), // Allow viewing past 30 days
      lastDate: DateTime.now(),
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

      // Reload data for the new date
      _loadActivityData();
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
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildDailySummary(),
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
                        'Daily Activity Status',
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

  Widget _buildDateSelector() {
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
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue.shade800),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.blue.shade800, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary() {
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
                  'Daily Summary',
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
                      'Lockers',
                      '$_lockersBooked',
                      Icons.lock,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Rooms',
                      '$_totalRoomsVisited',
                      Icons.meeting_room,
                      Colors.teal,
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
                            'No locker usage recorded for this date',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lockerHistory.length,
                        itemBuilder: (context, index) {
                          final usage = _lockerHistory[index];
                          final timestamp = usage['timestamp'] is Timestamp
                              ? (usage['timestamp'] as Timestamp).toDate()
                              : usage['timestamp'] is String
                                  ? DateTime.parse(usage['timestamp'])
                                  : DateTime.now();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.shade100,
                              child: Icon(Icons.lock,
                                  color: Colors.purple.shade700),
                            ),
                            title: Text(
                              'Locker Usage #${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            subtitle: Text(
                              'Time: ${DateFormat('hh:mm a').format(timestamp)}',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          );
                        },
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
                      'Room Usage',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                if (_totalRoomsVisited > 0) ...[
                  const SizedBox(height: 12),
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
                                'Most Visited Room',
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
                const SizedBox(height: 12),
                _roomHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No room usage recorded for this date',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _roomHistory.length,
                        itemBuilder: (context, index) {
                          final usage = _roomHistory[index];
                          final roomName = usage['roomName'] as String;
                          final timestamp = usage['timestamp'] is Timestamp
                              ? (usage['timestamp'] as Timestamp).toDate()
                              : usage['timestamp'] is String
                                  ? DateTime.parse(usage['timestamp'])
                                  : DateTime.now();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Icon(Icons.meeting_room,
                                  color: Colors.teal.shade700),
                            ),
                            title: Text(
                              roomName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            subtitle: Text(
                              'Time: ${DateFormat('hh:mm a').format(timestamp)}',
                              style: TextStyle(color: Colors.blue.shade800),
                            ),
                          );
                        },
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
