import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileStorage {
  static User get _user =>
      FirebaseAuth.instance.currentUser ??
      (throw StateError('Please sign in to access your profile.'));

  static Future<Map<String, dynamic>> load() async {
    final user = _user;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return {
      'name': user.displayName ?? '',
      'role': 'Student',
      'birthday': '',
      'year': '',
      'district': '',
      'image': user.photoURL,
      ...?snapshot.data(),
      'email': user.email ?? '',
    };
  }

  static Future<void> save(Map<String, String> values, Uint8List? image) async {
    final user = _user;
    if (values['email']?.trim().toLowerCase() != user.email?.toLowerCase()) {
      throw StateError('Your sign-in email cannot be changed from this form.');
    }
    String? imageUrl;
    if (image != null) {
      if (image.length > 5 * 1024 * 1024) {
        throw StateError('Choose a profile photo smaller than 5 MB.');
      }
      final ref = FirebaseStorage.instance.ref(
        'users/${user.uid}/profile/avatar',
      );
      final codec = await ui.instantiateImageCodec(image, targetWidth: 512);
      Uint8List encoded;
      try {
        final frame = await codec.getNextFrame();
        try {
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (data == null) throw StateError('Unable to read this photo.');
          encoded = data.buffer.asUint8List();
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
      await ref.putData(encoded, SettableMetadata(contentType: 'image/png'));
      imageUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      for (final key in ['name', 'role', 'birthday', 'year', 'district'])
        if (values.containsKey(key)) key: values[key]!.trim(),
      'email': user.email,
      'image': ?imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
