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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCDlzTpXx0TWZJow9XaP1bcddQueZxNFjA',
    appId: '1:1036908914828:web:4853c68fe7b4476083b3a9',
    messagingSenderId: '1036908914828',
    projectId: 'instagram-90b61',
    authDomain: 'instagram-90b61.firebaseapp.com',
    storageBucket: 'instagram-90b61.appspot.com',
    measurementId: 'G-VHK15FZS8J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC43fPR-di1yYOpTrBpbKf9TQ5nqv4IjbQ',
    appId: '1:1036908914828:android:37b135f21d74b56983b3a9',
    messagingSenderId: '1036908914828',
    projectId: 'instagram-90b61',
    storageBucket: 'instagram-90b61.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFmfN-a1s5GicoTNZqcy3sns0fIskdFR4',
    appId: '1:1036908914828:ios:ac52c75484a784dd83b3a9',
    messagingSenderId: '1036908914828',
    projectId: 'instagram-90b61',
    storageBucket: 'instagram-90b61.appspot.com',
    iosBundleId: 'com.example.instagram',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCDlzTpXx0TWZJow9XaP1bcddQueZxNFjA',
    appId: '1:1036908914828:web:9e9c01b1ea01694483b3a9',
    messagingSenderId: '1036908914828',
    projectId: 'instagram-90b61',
    authDomain: 'instagram-90b61.firebaseapp.com',
    storageBucket: 'instagram-90b61.appspot.com',
    measurementId: 'G-BM8S41V3J8',
  );
}