import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyApS-zhVhYU0WGoSe6B30UjzSouJEWJX3Q',
    appId: '1:780751184961:web:3ef7d56e07bbef9ede12c0',
    messagingSenderId: '780751184961',
    projectId: 'test-e45d6',
    authDomain: 'test-e45d6.firebaseapp.com',
    storageBucket: 'test-e45d6.firebasestorage.app',
    measurementId: 'G-GKZHK101K9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWBYFKUUyyfPV442uCQW8Q8j0JQyIPp1k',
    appId: '1:780751184961:android:3abb4ef2c0ae0982de12c0',
    messagingSenderId: '780751184961',
    projectId: 'test-e45d6',
    storageBucket: 'test-e45d6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApS-zhVhYU0WGoSe6B30UjzSouJEWJX3Q',
    appId: '1:780751184961:ios:TODO_REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '780751184961',
    projectId: 'test-e45d6',
    storageBucket: 'test-e45d6.firebasestorage.app',
    iosBundleId: 'com.example.obstawiator',
  );
}
