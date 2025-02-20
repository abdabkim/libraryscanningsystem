// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcM0JdNiXapd_o6EUy-zAHC2vlbMTUKcM',
    appId: '1:625983243130:web:0a12cbd609969638bd0cc3',
    messagingSenderId: '625983243130',
    projectId: 'libraryscanningsystem',
    authDomain: 'libraryscanningsystem.firebaseapp.com',
    storageBucket: 'libraryscanningsystem.firebasestorage.app',
    measurementId: 'G-2HTCQV78BR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8KsC6OlOcwtLel9bh30dbDJqN2u2imTw',
    appId: '1:625983243130:android:ae206265fd482f18bd0cc3',
    messagingSenderId: '625983243130',
    projectId: 'libraryscanningsystem',
    storageBucket: 'libraryscanningsystem.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5aNB4yXyKJLHbd1Z9LYBgSaIj8L7BSEI',
    appId: '1:625983243130:ios:3795b766d59fc8c1bd0cc3',
    messagingSenderId: '625983243130',
    projectId: 'libraryscanningsystem',
    storageBucket: 'libraryscanningsystem.firebasestorage.app',
    iosBundleId: 'com.example.libraryScanningSystem',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB5aNB4yXyKJLHbd1Z9LYBgSaIj8L7BSEI',
    appId: '1:625983243130:ios:3795b766d59fc8c1bd0cc3',
    messagingSenderId: '625983243130',
    projectId: 'libraryscanningsystem',
    storageBucket: 'libraryscanningsystem.firebasestorage.app',
    iosBundleId: 'com.example.libraryScanningSystem',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCcM0JdNiXapd_o6EUy-zAHC2vlbMTUKcM',
    appId: '1:625983243130:web:199dca377d00d7eebd0cc3',
    messagingSenderId: '625983243130',
    projectId: 'libraryscanningsystem',
    authDomain: 'libraryscanningsystem.firebaseapp.com',
    storageBucket: 'libraryscanningsystem.firebasestorage.app',
    measurementId: 'G-EN31XX37DP',
  );
}
