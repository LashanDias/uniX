import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/time_ago.dart';
import 'auth_service.dart';
import 'event_date_parser.dart';

/// A campus announcement shown on the notice board.
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.postedBy,
    required this.postedAt,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final String postedBy;
  final DateTime postedAt;

  /// Pinned notices stay at the top of the board.
  final bool pinned;

  /// Categories a notice can be filed under.
  static const categories = [
    'Academic',
    'Events',
    'Facilities',
    'Exams',
    'General',
  ];

  /// Short relative age, e.g. "2h ago", for the card.
  String get age => timeAgo(postedAt);

  /// When the event happens, read out of the notice text, or null if the
  /// notice is not about a dated event.
  EventSchedule? get schedule => EventDateParser.parse('$title $body');

  /// How soon this event is, for ordering and for the badge.
  EventUrgency urgency({DateTime? now}) =>
      schedule?.urgency(now ?? DateTime.now()) ?? EventUrgency.undated;

  /// True once the event has finished. Such notices drop off the board.
  bool hasExpired({DateTime? now}) =>
      schedule?.isPast(now ?? DateTime.now()) ?? false;

  /// Badge text for the card, e.g. "Today", or null when undated.
  String? get whenLabel => switch (urgency()) {
    EventUrgency.today => 'Today',
    EventUrgency.tomorrow => 'Tomorrow',
    EventUrgency.thisWeek => 'This week',
    EventUrgency.later => 'Upcoming',
    EventUrgency.past => 'Finished',
    EventUrgency.undated => null,
  };

  bool matches(String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return title.toLowerCase().contains(needle) ||
        body.toLowerCase().contains(needle) ||
        category.toLowerCase().contains(needle);
  }

  static Notice fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Notice(
      id: doc.id,
      title: (data['title'] ?? 'Untitled notice').toString(),
      body: (data['body'] ?? '').toString(),
      category: (data['category'] ?? 'General').toString(),
      postedBy: (data['postedBy'] ?? 'Campus admin').toString(),
      postedAt:
          (data['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pinned: data['pinned'] == true,
    );
  }
}

/// Reads and writes the campus notice board.
///
/// Students read; only an approved admin can post or remove a notice. The
/// client check here is for a clear message in the UI -- firestore.rules is
/// what actually enforces it.
class NoticeBoardService {
  static const collection = 'notices';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static bool get canPost => AuthService.isCurrentUserAdmin();

  /// Shown when Firestore is unreachable, so the board is never blank.
  static List<Notice> sampleNotices() {
    final now = DateTime.now();
    return [
      Notice(
        id: 'sample-1',
        title: 'Semester 2 results released',
        body: 'Results are now on the student portal. Raise any query with '
            'your department within 14 days.',
        category: 'Exams',
        postedBy: 'Examinations Office',
        postedAt: now.subtract(const Duration(hours: 3)),
        pinned: true,
      ),
      Notice(
        id: 'sample-2',
        title: 'Library open late during study week',
        body: 'The library stays open until midnight from Monday to Friday '
            'for the whole of study week.',
        category: 'Facilities',
        postedBy: 'Library',
        postedAt: now.subtract(const Duration(hours: 9)),
      ),
      Notice(
        id: 'sample-3',
        title: 'Tech Society hackathon, Saturday',
        body: 'Teams of up to four. Register at the Tech Society desk before '
            'Friday noon. Food provided.',
        category: 'Events',
        postedBy: 'Tech Society',
        postedAt: now.subtract(const Duration(days: 1)),
      ),
      Notice(
        id: 'sample-4',
        title: 'Hostel maintenance on Sunday',
        body: 'Water will be off in HUB 02 between 9am and 1pm on Sunday for '
            'tank cleaning.',
        category: 'Facilities',
        postedBy: 'Hostel Warden',
        postedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Live notices, pinned first and newest first within each group.
  static Stream<List<Notice>> watchNotices() => _db
      .collection(collection)
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((snapshot) => sortForBoard(snapshot.docs.map(Notice.fromDoc)));

  /// Orders the board and drops events that have already happened.
  ///
  /// Pinned notices lead. After that, the soonest event wins: something on
  /// today comes before tomorrow, which comes before next week. Notices with
  /// no date at all sit below dated ones, newest first.
  ///
  /// Finished events are filtered out rather than deleted, so nothing is lost
  /// -- [includePast] brings them back.
  static List<Notice> sortForBoard(
    Iterable<Notice> notices, {
    DateTime? now,
    bool includePast = false,
  }) {
    final reference = now ?? DateTime.now();
    final kept = notices
        .where((n) => includePast || !n.hasExpired(now: reference))
        .toList();
    kept.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;

      final aUrgency = a.urgency(now: reference);
      final bUrgency = b.urgency(now: reference);
      if (aUrgency != bUrgency) {
        return aUrgency.index.compareTo(bUrgency.index);
      }

      // Same bucket: the one happening sooner goes first.
      final aStart = a.schedule?.start;
      final bStart = b.schedule?.start;
      if (aStart != null && bStart != null && aStart != bStart) {
        return aStart.compareTo(bStart);
      }
      return b.postedAt.compareTo(a.postedAt);
    });
    return kept;
  }

  static Future<void> post({
    required String title,
    required String body,
    required String category,
    bool pinned = false,
  }) async {
    if (!canPost) {
      throw StateError('Only an admin can post to the notice board.');
    }
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty) throw StateError('Enter a title.');
    if (trimmedBody.isEmpty) throw StateError('Enter the notice text.');
    if (!Notice.categories.contains(category)) {
      throw StateError('Choose a category.');
    }
    final user = FirebaseAuth.instance.currentUser;
    await _db.collection(collection).add({
      'title': trimmedTitle,
      'body': trimmedBody,
      'category': category,
      'pinned': pinned,
      'postedBy': user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!.trim()
          : (user?.email ?? 'Campus admin'),
      'postedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> remove(String id) async {
    if (!canPost) {
      throw StateError('Only an admin can remove a notice.');
    }
    await _db.collection(collection).doc(id).delete();
  }
}
