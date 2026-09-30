import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class LostFoundService {
  static String? get userId =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;
  static String newId() =>
      FirebaseFirestore.instance.collection('lostFound').doc().id;
  static Stream<List<Map<String, dynamic>>> active() => FirebaseFirestore
      .instance
      .collection('lostFound')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'itemId': doc.id})
            .toList(),
      );
  static Stream<List<Map<String, dynamic>>> history() => FirebaseFirestore
      .instance
      .collection('lostFound')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.data()['status'] != 'active')
            .map((doc) => {...doc.data(), 'itemId': doc.id})
            .toList(),
      );
  static Stream<List<Map<String, dynamic>>> reminders() => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.data()['kind'] == 'lostFoundValidation')
            .map((doc) => doc.data())
            .toList(),
      );
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String itemId) =>
      FirebaseFirestore.instance
          .collection('lostFound')
          .doc(itemId)
          .snapshots(includeMetadataChanges: true);
  static Future<void> create(Map<String, dynamic> report) async {
    if (userId == null) throw StateError('Please sign in to publish a report.');
    await FirebaseFunctions.instance
        .httpsCallable('createLostFoundPost')
        .call(report);
  }

  static Future<void> respond(
    String itemId,
    String action, {
    String? checkToken,
  }) async {
    if (userId == null) {
      throw StateError('Please sign in to update this report.');
    }
    await FirebaseFunctions.instance.httpsCallable('respondLostFound').call({
      'itemId': itemId,
      'action': action,
      'checkToken': checkToken,
    });
  }
}
