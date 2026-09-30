import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/widgets/dashboard_search.dart';

void main() {
  group('searchDestinations', () {
    test('an empty term matches nothing', () {
      expect(searchDestinations(''), isEmpty);
      expect(searchDestinations('   '), isEmpty);
    });

    test('finds a section by its label', () {
      expect(
        searchDestinations('notes').map((d) => d.label),
        contains('Notes'),
      );
    });

    test('finds a section by a related word, not just its label', () {
      // Typing what you want, rather than the section name, must still work.
      expect(searchDestinations('food').map((d) => d.label),
          contains('Restaurants'));
      expect(searchDestinations('room').map((d) => d.label),
          contains('Hostels'));
      expect(searchDestinations('vacancy').map((d) => d.label),
          contains('Jobs'));
      expect(searchDestinations('wallet').map((d) => d.label),
          contains('Lost & Found'));
    });

    test('is case insensitive', () {
      expect(searchDestinations('HOSTEL'), isNotEmpty);
    });

    test('ranks a label that starts with the term first', () {
      final results = searchDestinations('note');
      expect(results.first.label, 'Notes');
    });

    test('returns nothing for a term that matches no section', () {
      expect(searchDestinations('qqzzxx'), isEmpty);
    });
  });

  group('destination wiring', () {
    test('every destination has exactly one target', () {
      for (final destination in kSearchDestinations) {
        final hasTab = destination.tabIndex != null;
        final hasRoute = destination.route != null;
        expect(hasTab != hasRoute, isTrue, reason: destination.label);
      }
    });

    test('tab indexes stay inside MainLayout\'s five screens', () {
      for (final destination in kSearchDestinations) {
        if (destination.tabIndex != null) {
          expect(destination.tabIndex, inInclusiveRange(0, 4));
        }
      }
    });
  });

  group('DashboardSearch widget', () {
    testWidgets('typing shows suggestions and tapping one navigates', (
      tester,
    ) async {
      var tappedTab = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardSearch(onNavigateTab: (index) => tappedTab = index),
          ),
        ),
      );

      // The bug this covers: the field had no controller and no callbacks,
      // so typing in it did nothing whatsoever.
      await tester.enterText(find.byType(TextField), 'notes');
      await tester.pumpAndSettle();
      expect(find.text('Notes'), findsOneWidget);

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(tappedTab, 1);
    });

    testWidgets('an unmatched term says so instead of failing silently', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DashboardSearch(onNavigateTab: (_) {})),
        ),
      );
      await tester.enterText(find.byType(TextField), 'qqzzxx');
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing matches that'), findsOneWidget);
    });

    testWidgets('clearing the field hides the suggestions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DashboardSearch(onNavigateTab: (_) {})),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hostel');
      await tester.pumpAndSettle();
      expect(find.text('Hostels'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Hostels'), findsNothing);
    });
  });
}
