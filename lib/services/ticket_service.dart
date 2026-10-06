import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_service.dart';

/// One campus event students can get a ticket for.
///
/// Before this existed the Tickets screen showed two events written into the
/// source code, so nobody could add an event and there was nothing for an
/// admin to remove. Events now live in Firestore, which is what makes
/// deleting one possible at all.
class TicketEvent {
  const TicketEvent({
    required this.id,
    required this.title,
    required this.details,
    required this.price,
    required this.imageUrl,
    this.postedBy = '',
    this.createdAt,
  });

  final String id;
  final String title;

  /// Date and venue as one line, e.g. "Sep 18 - Main Auditorium".
  final String details;

  /// Shown as typed, so an admin can write "Free" as well as "LKR 750".
  final String price;
  final String imageUrl;
  final String postedBy;
  final DateTime? createdAt;

  static TicketEvent fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TicketEvent(
      id: doc.id,
      title: (data['title'] ?? 'Untitled event').toString(),
      details: (data['details'] ?? '').toString(),
      price: (data['price'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      postedBy: (data['postedBy'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Reads and writes the campus events students buy tickets for.
///
/// Reading is open to any signed-in student; writing is admin-only. As
/// everywhere else in this app the checks here are a convenience so the UI can
/// fail fast with a readable message -- the real enforcement is in
/// firestore.rules, because a client-side check alone can be bypassed.
class TicketService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const collection = 'tickets';

  /// Field limits, kept in step with the tickets rules in firestore.rules.
  static const titleLimit = 150;
  static const detailsLimit = 200;
  static const priceLimit = 40;
  static const imageUrlLimit = 500;

  /// Preview events keep the page useful before an admin publishes live
  /// events or while Firestore cannot be reached. These are never written to
  /// Firestore and must not be treated as purchasable tickets.
  static List<TicketEvent> sampleEvents() => const [
    TicketEvent(
      id: 'sample-campus-music-night',
      title: 'Campus Music Night',
      details: 'Oct 24, 2026 · Main Auditorium',
      price: 'LKR 500',
      imageUrl: '',
      postedBy: 'Campus Events',
    ),
    TicketEvent(
      id: 'sample-interfaculty-sports',
      title: 'Inter-Faculty Sports Festival',
      details: 'Nov 7, 2026 · University Sports Grounds',
      price: 'Free',
      imageUrl: '',
      postedBy: 'Sports Council',
    ),
    TicketEvent(
      id: 'sample-career-tech-expo',
      title: 'Career and Technology Expo',
      details: 'Nov 19, 2026 · Innovation Hub',
      price: 'Free',
      imageUrl: '',
      postedBy: 'Career Services',
    ),
    TicketEvent(
      id: 'sample-international-food-fair',
      title: 'International Food Fair',
      details: 'Dec 3, 2026 · Central Courtyard',
      price: 'LKR 300',
      imageUrl: '',
      postedBy: 'Student Union',
    ),
  ];

  static void _requireAdmin() {
    if (!AuthService.isCurrentUserAdmin()) {
      throw StateError('Sign in with an approved admin account to do this.');
    }
  }

  /// Rejects anything the rules would refuse, so a student sees a sentence
  /// they can act on rather than a raw permission-denied error.
  static String? validationError({
    required String title,
    required String details,
    required String price,
    required String imageUrl,
  }) {
    if (title.trim().isEmpty) return 'Give the event a title.';
    if (title.trim().length > titleLimit) {
      return 'Keep the title under $titleLimit characters.';
    }
    if (details.trim().length > detailsLimit) {
      return 'Keep the date and venue under $detailsLimit characters.';
    }
    if (price.trim().length > priceLimit) {
      return 'Keep the price under $priceLimit characters.';
    }
    if (imageUrl.trim().length > imageUrlLimit) {
      return 'That image link is too long.';
    }
    final link = imageUrl.trim();
    if (link.isNotEmpty && !link.startsWith('https://')) {
      return 'An image link must start with https://';
    }
    return null;
  }

  /// Every published event, newest first. Sorting locally includes older
  /// events that were saved before the `createdAt` field was introduced.
  ///
  /// With no Firebase app configured this yields an empty list rather than
  /// throwing, so the screen shows its "no events" state instead of a red
  /// error box -- the same way the app treats an unavailable Firebase
  /// everywhere else.
  static Stream<List<TicketEvent>> watch() {
    if (Firebase.apps.isEmpty) return Stream.value(const []);
    return _db.collection(collection).snapshots().map((snapshot) {
      final events = snapshot.docs.map(TicketEvent.fromDoc).toList();
      events.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return events;
    });
  }

  /// Publishes an event. Admins only.
  static Future<void> create({
    required String title,
    required String details,
    required String price,
    required String imageUrl,
  }) async {
    _requireAdmin();
    final problem = validationError(
      title: title,
      details: details,
      price: price,
      imageUrl: imageUrl,
    );
    if (problem != null) throw StateError(problem);
    await _db.collection(collection).add({
      'title': title.trim(),
      'details': details.trim(),
      'price': price.trim(),
      'imageUrl': imageUrl.trim(),
      'postedBy': FirebaseAuth.instance.currentUser?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes an event. Admins only, and allowed at any time -- there is no
  /// window after which an event becomes undeletable.
  static Future<void> remove(String id) async {
    _requireAdmin();
    await _db.collection(collection).doc(id).delete();
  }
}
