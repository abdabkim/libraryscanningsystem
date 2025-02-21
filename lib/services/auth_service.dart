import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:library_scanning_system/home_screen.dart';
import 'package:library_scanning_system/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<void> register({
    required String email,
    required String password,
    required String fullName, // Added fullName parameter
    required BuildContext context,
  }) async {
    try {
      // Create the user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save the display name to Firebase
      await userCredential.user?.updateDisplayName(fullName);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', fullName);

      print('Name saved to SharedPreferences: $fullName'); // Debug print

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      print('Error during registration: $e'); // Debug print
    }
  }

  Future<void> login(
      {required String email,
      required String password,
      required BuildContext context}) async {
    try {
      // Fix the method name typo and call
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // After successful login, get user's name and save to SharedPreferences
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', user!.displayName!);
        print('Name saved during login: ${user.displayName}'); // Debug print
      }

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      print('Error during login: $e'); // Debug print
    }
  }

  Future<void> signout({required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fullName');

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) => LoginScreen()));
    } catch (e) {
      print('Error during signout: $e'); // Debug print
    }
  }
}

// Remove this extension as we're using the correct signInWithEmailAndPassword method
// extension on FirebaseAuth {
//   loginInWithEmailAndPassword({required String email, required String password}) {}
// }
