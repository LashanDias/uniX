import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class LocalFirebase {
  static const enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static const options = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:1234567890:web:unix-local',
    messagingSenderId: '1234567890',
    projectId: 'demo-unix-local',
    authDomain: 'demo-unix-local.firebaseapp.com',
    storageBucket: 'demo-unix-local.appspot.com',
  );
  static Future<void> connect() async {
    if (!kDebugMode) {
      throw StateError('Firebase emulators are allowed only in debug builds.');
    }
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8089);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
}
