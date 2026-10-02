import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// A collection that fails (offline, or rules deny it) is skipped rather
  /// than failing the whole feed, so one broken source cannot empty the list.
  static Future<List<ActivityEvent>> recent({int limit = 12}) async {
    final events = <ActivityEvent>[];

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
              onError: (_) {},
            ),
    ]);

    events.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return events.take(limit).toList();
  }
}
