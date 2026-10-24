import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated with authentic credentials from Firebase Project lav-school-sms-2026.
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAR60C9elZEe5U88CAJa31xgpWPUpPEK6U',
    appId: '1:981819763614:web:e68be78233459631dd848f',
    messagingSenderId: '981819763614',
    projectId: 'lav-school-sms-2026',
    authDomain: 'lav-school-sms-2026.firebaseapp.com',
    storageBucket: 'lav-school-sms-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDv0rIbdEkcLjZeUa_J8hw70vyFln4AZ2Q',
    appId: '1:981819763614:android:3f59d3b5b43b6ad0dd848f',
    messagingSenderId: '981819763614',
    projectId: 'lav-school-sms-2026',
    storageBucket: 'lav-school-sms-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDBmIxpKl1thXQINn5vhnbInL0NNSxxGwQ',
    appId: '1:981819763614:ios:c235348fdc5ddd8fdd848f',
    messagingSenderId: '981819763614',
    projectId: 'lav-school-sms-2026',
    storageBucket: 'lav-school-sms-2026.firebasestorage.app',
    iosBundleId: 'com.lav.schoolsms',
  );
}
