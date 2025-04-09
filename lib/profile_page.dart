import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = 'User';
  String _email = 'user@example.com';
  String _studyProgram = '';
  String _schoolName = '';
  final _studyProgramController = TextEditingController();
  final _schoolNameController = TextEditingController();
  bool _isEditingProgram = false;
  bool _isEditingSchool = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _studyProgramController.dispose();
    _schoolNameController.dispose();
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
      String? storedSchool = prefs.getString('schoolName');

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

      if (storedSchool != null) {
        setState(() {
          _schoolName = storedSchool;
          _schoolNameController.text = storedSchool;
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

        // Try to get study program and school name from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          if (userData.containsKey('studyProgram')) {
            final program = userData['studyProgram'];
            setState(() {
              _studyProgram = program;
              _studyProgramController.text = program;
            });
            prefs.setString('studyProgram', program);
          }

          if (userData.containsKey('schoolName')) {
            final school = userData['schoolName'];
            setState(() {
              _schoolName = school;
              _schoolNameController.text = school;
            });
            prefs.setString('schoolName', school);
          }
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
        _isEditingProgram = false;
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

  Future<void> _saveSchoolName() async {
    try {
      final school = _schoolNameController.text.trim();
      final user = FirebaseAuth.instance.currentUser;

      // Save to Firestore if user is logged in
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'schoolName': school,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('schoolName', school);

      setState(() {
        _schoolName = school;
        _isEditingSchool = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School name updated successfully')),
      );
    } catch (e) {
      print('Error saving school name: $e');
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

  Widget _buildEditableField(
      String label,
      bool isEditing,
      TextEditingController controller,
      String currentValue,
      Function() onEdit,
      Function() onSave,
      Function() onCancel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isEditing)
              TextButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
          ],
        ),
        isEditing
            ? Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your $label',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onSave,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  currentValue.isEmpty ? 'Not specified' : currentValue,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
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
                        _buildEditableField(
                          'Study Program',
                          _isEditingProgram,
                          _studyProgramController,
                          _studyProgram,
                          () {
                            setState(() {
                              _isEditingProgram = true;
                            });
                          },
                          _saveStudyProgram,
                          () {
                            setState(() {
                              _isEditingProgram = false;
                              _studyProgramController.text = _studyProgram;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildEditableField(
                          'School Name',
                          _isEditingSchool,
                          _schoolNameController,
                          _schoolName,
                          () {
                            setState(() {
                              _isEditingSchool = true;
                            });
                          },
                          _saveSchoolName,
                          () {
                            setState(() {
                              _isEditingSchool = false;
                              _schoolNameController.text = _schoolName;
                            });
                          },
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
                      await prefs.remove('studyProgram');
                      await prefs.remove('schoolName');

                      // Navigate to login page (fixed navigation)
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, 'LoginScreen');
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Logged out successfully')),
                        );
                      }
                    } catch (e) {
                      print('Error signing out: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error signing out: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                // Add padding at the bottom to ensure content doesn't get cut off by navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
