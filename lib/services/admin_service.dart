import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_access_service.dart';
import 'auth_service.dart';

/// A registered account as the admin panel sees it.
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.blocked,
    this.district = '',
    this.year = '',
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool blocked;
  final String district;
  final String year;

  bool get isAdmin => AppAccessService.isAdminEmail(email);

  /// Name to show when the profile has no name saved yet.
  String get displayName => name.trim().isEmpty ? '(no name set)' : name.trim();

  /// First letter for the avatar circle.
  ///
  /// Prefers the name, falls back to the email so a profile saved without a
  /// name still gets a meaningful letter rather than the bracket from
  /// [displayName]'s placeholder, and finally to '?'.
  ///
  /// Built from runes rather than `[0]` so a name starting with an emoji or
  /// other astral character does not render as half a surrogate pair.
  String get initial {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    return String.fromCharCode(source.runes.first).toUpperCase();
  }

  /// True when [term] matches the name, email or role.
  bool matches(String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        email.toLowerCase().contains(needle) ||
        role.toLowerCase().contains(needle);
  }

  static AdminUser fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AdminUser(
      uid: doc.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'Student').toString(),
      blocked: data['blocked'] == true,
      district: (data['district'] ?? '').toString(),
      year: (data['year'] ?? '').toString(),
    );
  }
}

/// One row in a moderation list, normalised across collections.
class ModeratedItem {
  const ModeratedItem({
    required this.id,
    required this.collection,
    required this.title,
    required this.subtitle,
    required this.ownerLabel,
  });

  final String id;
  final String collection;
  final String title;
  final String subtitle;
  final String ownerLabel;
}

/// Everything the admin panel is allowed to read and change.
///
/// Every method guards on [AuthService.isCurrentUserAdmin] before touching
/// Firestore. That is a convenience so the UI can fail fast with a clear
/// message -- the real enforcement lives in firestore.rules, because a client
/// check alone can be bypassed.
class AdminService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const usersCollection = 'users';
  static const productsCollection = 'products';
  static const notesCollection = 'notes';
  static const jobsCollection = 'jobs';

  static bool get isAdmin => AuthService.isCurrentUserAdmin();

  static void _requireAdmin() {
    if (!isAdmin) {
      throw StateError('Sign in with an approved admin account to do this.');
    }
  }

  /// Live document count for [collection]; 0 while loading or on error.
  static Stream<int> watchCount(String collection) {
    _requireAdmin();
    return _db.collection(collection).snapshots().map((s) => s.size);
  }

  /// Every registered account, newest profile updates first.
  static Stream<List<AdminUser>> watchUsers() {
    _requireAdmin();
    return _db
        .collection(usersCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(AdminUser.fromDoc).toList()
            ..sort(
              (a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
            ),
        );
  }

  /// Marketplace listings awaiting moderation.
  static Stream<List<ModeratedItem>> watchProducts() {
    _requireAdmin();
    return _db
        .collection(productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] as num?)?.toStringAsFixed(0) ?? '0';
            return ModeratedItem(
              id: doc.id,
              collection: productsCollection,
              title: (data['title'] ?? 'Untitled listing').toString(),
              subtitle: 'LKR $price  •  ${(data['category'] ?? '').toString()}',
              ownerLabel: (data['sellerName'] ?? 'Unknown seller').toString(),
            );
          }).toList(),
        );
  }

  /// Uploaded study notes awaiting moderation.
  static Stream<List<ModeratedItem>> watchNotes() {
    _requireAdmin();
    return _db
        .collection(notesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ModeratedItem(
              id: doc.id,
              collection: notesCollection,
              title: (data['title'] ?? 'Untitled note').toString(),
              subtitle:
                  '${(data['subject'] ?? 'General')}  •  ${(data['fileType'] ?? 'PDF')}',
              ownerLabel: (data['uploadedDate'] ?? '').toString(),
            );
          }).toList(),
        );
  }

  /// Posted vacancies awaiting moderation.
  static Stream<List<ModeratedItem>> watchJobs() {
    _requireAdmin();
    return _db
        .collection(jobsCollection)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ModeratedItem(
              id: doc.id,
              collection: jobsCollection,
              title: (data['title'] ?? 'Untitled vacancy').toString(),
              subtitle:
                  '${(data['company'] ?? 'Unknown')}  •  ${(data['location'] ?? '')}',
              ownerLabel: (data['type'] ?? '').toString(),
            );
          }).toList(),
        );
  }

  /// Permanently removes a moderated item.
  static Future<void> remove(ModeratedItem item) async {
    _requireAdmin();
    await _db.collection(item.collection).doc(item.id).delete();
  }

  /// Blocks or unblocks [user], stopping them signing in while blocked.
  ///
  /// Admins cannot block themselves or another admin, so the panel can never
  /// lock every administrator out of the app.
  static Future<void> setBlocked(AdminUser user, bool blocked) async {
    _requireAdmin();
    if (user.isAdmin) {
      throw StateError('Admin accounts cannot be blocked.');
    }
    if (user.uid == FirebaseAuth.instance.currentUser?.uid) {
      throw StateError('You cannot block your own account.');
    }
    await _db.collection(usersCollection).doc(user.uid).set({
      'blocked': blocked,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
