import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/utils/time_ago.dart';

/// Something that actually happened in the app, shown in Recent Activity.
class ActivityEvent {
  const ActivityEvent({
    required this.title,
    required this.happenedAt,
    required this.icon,
    required this.route,
  });

  final String title;
  final DateTime happenedAt;
  final IconData icon;

  /// Where tapping the row should go.
  final String route;

  String age({DateTime? now}) => timeAgo(happenedAt, now: now);
}

/// Builds the Recent Activity feed from what is really in Firestore.
///
/// The feed used to be four hardcoded rows that always claimed a note was
/// uploaded "2 minutes ago", whatever had actually happened.
class ActivityService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Collections to draw from: collection, timestamp field, title field,
  /// label, icon and the route to open.
  static const _sources = [
    ('notes', 'createdAt', 'title', 'New note', Icons.note_add_outlined, '/notes'),
    (
      'products',
      'createdAt',
      'title',
      'New listing',
      Icons.storefront_outlined,
      '/marketplace',
    ),
    ('jobs', 'postedAt', 'title', 'New vacancy', Icons.work_outline, '/jobs'),
    (
      'notices',
      'postedAt',
      'title',
      'Notice',
      Icons.campaign_outlined,
      '/notice_board',
    ),
    (
      'tickets',
      'createdAt',
      'title',
      'New event',
      Icons.confirmation_number_outlined,
      '/tickets',
    ),
  ];

  /// Merges the newest entries from each collection, newest first.
  ///
  /// A collection that fails is skipped rather than failing the whole feed,
  /// so one broken source cannot empty the list -- but the names of the
  /// failed sources come back with the result. Swallowing them silently made
  /// an unreadable feed look like an empty one: a student whose reads were
  /// denied, or who was offline, was told "Nothing has happened yet", which
  /// is a different thing entirely and gave them nothing to act on.
  static Future<ActivityFeed> load({int limit = 12}) async {
    if (Firebase.apps.isEmpty) {
      return const ActivityFeed(events: [], unreadable: []);
    }
    final events = <ActivityEvent>[];
    final unreadable = <String>[];

    await Future.wait([
      for (final (collection, timeField, titleField, label, icon, route)
          in _sources)
        _db
            .collection(collection)
            .orderBy(timeField, descending: true)
            .limit(limit)
            .get()
            .then(
              (snapshot) {
                for (final doc in snapshot.docs) {
                  final data = doc.data();
                  final at = (data[timeField] as Timestamp?)?.toDate();
                  if (at == null) continue; // Write still pending on the server.
                  final name = (data[titleField] ?? '').toString().trim();
                  events.add(
                    ActivityEvent(
                      title: name.isEmpty ? label : '$label: $name',
                      happenedAt: at,
                      icon: icon,
                      route: route,
                    ),
                  );
                }
              },
              onError: (_) => unreadable.add(collection),
            ),
    ]);

    events.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return ActivityFeed(
      events: events.take(limit).toList(),
      unreadable: unreadable,
    );
  }

  /// Just the events, for callers that only show the newest one.
  static Future<List<ActivityEvent>> recent({int limit = 12}) async =>
      (await load(limit: limit)).events;
}

/// The feed plus which sources could not be read.
class ActivityFeed {
  const ActivityFeed({required this.events, required this.unreadable});

  final List<ActivityEvent> events;

  /// Collections that failed to load, by name. Empty when everything read.
  final List<String> unreadable;

  /// True when there is nothing to show *and* a source failed, which means
  /// "we could not look", not "nothing has happened".
  bool get failedEntirely => events.isEmpty && unreadable.isNotEmpty;
}
