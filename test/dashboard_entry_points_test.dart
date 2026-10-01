import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/widgets/dashboard_search.dart';

void main() {
  group('every section is reachable from the dashboard search', () {
    // The AI Assistant card was lost from the dashboard during a layout
    // change and nothing caught it, because no test asserted the entry
    // points exist. These check the search index, which is the other way
    // into every section.
    const expected = {
      'Notes',
      'Marketplace',
      'Jobs',
      'Hostels',
      'Restaurants',
      'Lost & Found',
      'Notice Board',
      'Tickets',
      'Settings',
      'Formula sheets',
      'Short notes from a PDF',
      'My profile',
    };

    test('the search index covers each section', () {
      final labels = kSearchDestinations.map((d) => d.label).toSet();
      for (final section in expected) {
        expect(labels, contains(section), reason: 'missing: $section');
      }
    });

    test('each destination is reachable by a plain word', () {
      for (final destination in kSearchDestinations) {
        final firstWord = destination.label.split(' ').first.toLowerCase();
        expect(
          searchDestinations(firstWord),
          contains(destination),
          reason: destination.label,
        );
      }
    });

    test('no two destinations share a label', () {
      final labels = kSearchDestinations.map((d) => d.label).toList();
      expect(labels.toSet().length, labels.length);
    });

    test('routes all start with a slash', () {
      for (final destination in kSearchDestinations) {
        final route = destination.route;
        if (route != null) {
          expect(route, startsWith('/'), reason: destination.label);
        }
      }
    });
  });
}
