import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not supported.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured yet.');
      default:
        throw UnsupportedError(
            '${defaultTargetPlatform.name} is not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDI3EsZskYRMphIaezFI7p-MmXPAqWMwU8',
    appId: '1:260302773984:android:8a830438168cf95125ba85',
    messagingSenderId: '260302773984',
    projectId: 'priora-app-b7015',
    storageBucket: 'priora-app-b7015.firebasestorage.app',
  );
}
