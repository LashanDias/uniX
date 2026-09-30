import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_models.dart';
import 'app_access_service.dart';
import 'auth_service.dart';

class NotesService {
  static Stream<List<NoteItem>> watchNotes() => FirebaseFirestore.instance
      .collection('notes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return NoteItem(
            id: doc.id,
            title: data['title'] as String? ?? 'Untitled note',
            subject: data['subject'] as String? ?? 'General',
            fileType: data['fileType'] as String? ?? 'PDF',
            uploadedDate: data['uploadedDate'] as String? ??
                DateTime.now().toLocal().toString().split(' ')[0],
            description: data['description'] as String? ?? '',
            ownerId: data['ownerId'] as String? ?? '',
            fileUrl: data['fileUrl'] as String? ?? '',
          );
        }).toList(),
      );

  static Future<void> addNote({
    required String title,
    required String subject,
    required String description,
    required String fileType,
    String fileUrl = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in to upload notes.');
    }

    await FirebaseFirestore.instance.collection('notes').add({
      'title': title.trim(),
      'subject': subject,
      'description': description.trim(),
      'fileType': fileType,
      'fileUrl': fileUrl,
      'ownerId': user.uid,
      'uploadedDate': DateTime.now().toLocal().toString().split(' ')[0],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNote(String noteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in to delete this note.');
    }

    final doc = await FirebaseFirestore.instance.collection('notes').doc(noteId).get();
    final ownerId = doc.data()?['ownerId'] as String? ?? '';
    final isAdmin = AuthService.isCurrentUserAdmin();
    if (!AppAccessService.canManageOwnedResource(user.uid, ownerId, isAdmin: isAdmin)) {
      throw StateError('Only the note owner or admin can remove this item.');
    }

    await FirebaseFirestore.instance.collection('notes').doc(noteId).delete();
  }

  static bool canManageNote(NoteItem note) {
    final user = FirebaseAuth.instance.currentUser;
    return user != null &&
        (user.uid == note.ownerId || AuthService.isCurrentUserAdmin());
  }
}
