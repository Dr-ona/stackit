// Generated from the Firebase Android app registered for Stackit.
// Firebase configuration values identify the project and are not secrets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase has not been configured for web yet. Run FlutterFire '
        'configuration when the web app is registered.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase is currently configured for Android only.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzjKXrDSJwHIjJOqmBB3AodDtjsr5c2Jk',
    appId: '1:792898120987:android:12b6b765481fd026dbb7be',
    messagingSenderId: '792898120987',
    projectId: 'stackit-368da',
    storageBucket: 'stackit-368da.firebasestorage.app',
  );
}
