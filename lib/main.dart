import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:library_scanning_system/firebase_options.dart';
import 'package:library_scanning_system/home_screen.dart';
import 'package:library_scanning_system/services/settings_provider.dart';
import 'package:library_scanning_system/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StudentApp());
}

class StudentApp extends StatefulWidget {
  const StudentApp({Key? key}) : super(key: key);

  @override
  State<StudentApp> createState() => _StudentAppState();
}

class _StudentAppState extends State<StudentApp> {
  late Widget firstScreen;

  Future<Widget> isLogged() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey("fullName")) {
      return HomeScreen();
    }
    return WelcomeScreen();
  }

  @override
  void initState() {
    super.initState();
    isLogged().then((value) {
      setState(() {
        firstScreen = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final double fontSize = settings.fontSize ?? 16.0;

          return MaterialApp(
            title: 'Student ID',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: settings.darkModeEnabled ? Brightness.dark : Brightness.light,
              primarySwatch: Colors.teal,
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(fontSize: fontSize),
                bodyMedium: TextStyle(fontSize: fontSize - 2),
                titleLarge: TextStyle(fontSize: fontSize + 2),
              ),
            ),
            home: firstScreen,
          );
        },
      ),
    );
  }
}
