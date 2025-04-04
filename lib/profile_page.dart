import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = 'User';
  String _email = 'user@example.com';
  String _studyProgram = '';
  final _studyProgramController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _studyProgramController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();

      // Load name from SharedPreferences first
      String? storedName = prefs.getString('fullName');
      String? storedEmail = prefs.getString('email');
      String? storedProgram = prefs.getString('studyProgram');

      if (storedName != null && storedName.isNotEmpty) {
        setState(() {
          _fullName = storedName;
        });
      }

      if (storedEmail != null && storedEmail.isNotEmpty) {
        setState(() {
          _email = storedEmail;
        });
      }

      if (storedProgram != null) {
        setState(() {
          _studyProgram = storedProgram;
          _studyProgramController.text = storedProgram;
        });
      }

      // If we have a logged in user, get and store their info
      if (user != null) {
        // Get display name from Firebase Auth
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            _fullName = user.displayName!;
          });
          prefs.setString('fullName', user.displayName!);
        }

        // Get email from Firebase Auth
        if (user.email != null && user.email!.isNotEmpty) {
          setState(() {
            _email = user.email!;
          });
          prefs.setString('email', user.email!);
        }

        // Try to get study program from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()!.containsKey('studyProgram')) {
          final program = userDoc.data()!['studyProgram'];
          setState(() {
            _studyProgram = program;
            _studyProgramController.text = program;
          });
          prefs.setString('studyProgram', program);
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _saveStudyProgram() async {
    try {
      final program = _studyProgramController.text.trim();
      final user = FirebaseAuth.instance.currentUser;

      // Save to Firestore if user is logged in
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'studyProgram': program,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('studyProgram', program);

      setState(() {
        _studyProgram = program;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study program updated successfully')),
      );
    } catch (e) {
      print('Error saving study program: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profile picture placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade700.withOpacity(0.8),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('Full Name', _fullName),
                      _buildInfoRow('Email', _email),
                      _buildInfoRow('Status', 'NCU Student'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Study Program:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEditing)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: const Text('Edit'),
                            ),
                        ],
                      ),
                      _isEditing
                          ? Column(
                              children: [
                                TextField(
                                  controller: _studyProgramController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter your study program',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = false;
                                          _studyProgramController.text =
                                              _studyProgram;
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _saveStudyProgram,
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                _studyProgram.isEmpty
                                    ? 'Not specified'
                                    : _studyProgram,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();

                    // Clear user-specific data from SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('fullName');
                    await prefs.remove('email');

                    // Navigate to login page (you'll need to implement this)
                    // Navigator.of(context).pushReplacementNamed('/login');

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  } catch (e) {
                    print('Error signing out: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
