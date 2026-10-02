import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/activity/recent_activity_screen.dart';
import 'package:unix_app/services/activity_service.dart';

/// "Nothing has happened yet" and "we could not look" are different things.
///
/// The feed used to swallow every per-source error and then render the empty
/// state, so a student whose reads were denied -- or who was simply offline --
/// was told nothing had happened. That is a claim the app had not checked, and
/// it left them with nothing to act on.
void main() {
  ActivityEvent event(String title) => ActivityEvent(
    title: title,
    happenedAt: DateTime(2026, 10, 2, 9),
    icon: Icons.note_add_outlined,
    route: '/notes',
  );

  Future<void> pump(WidgetTester tester, ActivityFeed feed) async {
    await tester.pumpWidget(
      MaterialApp(home: RecentActivityScreen(loader: () async => feed)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty feed that read cleanly says nothing has happened', (
    tester,
  ) async {
    await pump(tester, const ActivityFeed(events: [], unreadable: []));

    expect(find.text('Nothing has happened yet'), findsOneWidget);
    expect(find.text('Could not load activity'), findsNothing);
  });

  testWidgets('an empty feed whose sources all failed says so instead', (
    tester,
  ) async {
    await pump(
      tester,
      const ActivityFeed(events: [], unreadable: ['notes', 'products']),
    );

    expect(find.text('Could not load activity'), findsOneWidget);
    expect(find.text('Nothing has happened yet'), findsNothing);
  });

  testWidgets('a thrown loader does not claim nothing has happened', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecentActivityScreen(
          loader: () async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load activity'), findsOneWidget);
    expect(find.text('Nothing has happened yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('events are listed when everything read', (tester) async {
    await pump(
      tester,
      ActivityFeed(
        events: [event('New note: Statistics'), event('New listing: Desk')],
        unreadable: const [],
      ),
    );

    expect(find.text('New note: Statistics'), findsOneWidget);
    expect(find.text('New listing: Desk'), findsOneWidget);
    expect(find.textContaining('could not be loaded'), findsNothing);
  });

  testWidgets('a partly loaded feed shows what it has and admits the gap', (
    tester,
  ) async {
    // Showing the rows without a word about the failure would quietly pass a
    // partial list off as the whole picture.
    await pump(
      tester,
      ActivityFeed(
        events: [event('New note: Statistics')],
        unreadable: const ['jobs'],
      ),
    );

    expect(find.text('New note: Statistics'), findsOneWidget);
    expect(find.textContaining('could not be loaded'), findsOneWidget);
  });

  group('ActivityFeed', () {
    test('failedEntirely only when empty and something failed', () {
      expect(
        const ActivityFeed(events: [], unreadable: ['notes']).failedEntirely,
        isTrue,
      );
      expect(
        const ActivityFeed(events: [], unreadable: []).failedEntirely,
        isFalse,
      );
    });

    test('a partial read is not a total failure', () {
      expect(
        ActivityFeed(
          events: [event('New note: Statistics')],
          unreadable: const ['jobs'],
        ).failedEntirely,
        isFalse,
      );
    });
  });
}
