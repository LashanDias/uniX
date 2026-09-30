import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/notes/reference_sheet_screen.dart';
import 'package:unix_app/services/reference_sheets.dart';

void main() {
  group('sheet content', () {
    test('every sheet has a subject, a summary and formulas', () {
      for (final sheet in ReferenceSheets.all) {
        expect(sheet.subject, isNotEmpty, reason: sheet.id);
        expect(sheet.summary, isNotEmpty, reason: sheet.id);
        expect(sheet.entries, isNotEmpty, reason: sheet.id);
      }
    });

    test('every formula entry explains when to use it', () {
      // A formula with no guidance is just a symbol; the "when to use it"
      // bullets are what make the sheet useful for revision.
      for (final sheet in ReferenceSheets.all) {
        for (final entry in sheet.entries) {
          expect(entry.whenToUse, isNotEmpty, reason: '${sheet.id}/${entry.title}');
          expect(entry.formulas, isNotEmpty, reason: '${sheet.id}/${entry.title}');
        }
      }
    });

    test('sheet ids are unique', () {
      final ids = ReferenceSheets.all.map((s) => s.id).toSet();
      expect(ids.length, ReferenceSheets.all.length);
    });
  });

  group('statistics sheet matches the printed reference', () {
    final sheet = ReferenceSheets.statistics;

    test('covers the six core measures', () {
      expect(sheet.entries.map((e) => e.title), [
        'Mean',
        'Weighted Mean',
        'Range',
        'Variance',
        'Standard Deviation',
        'Coefficient of Variation',
      ]);
    });

    test('gives both the ungrouped and frequency forms of the mean', () {
      final mean = sheet.entries.first;
      expect(mean.formulas['For ungrouped data'], 'x̄ = Σx / n');
      expect(mean.formulas['For frequency data'], 'x̄ = Σfx / Σf');
    });

    test('separates population and sample variance', () {
      final variance = sheet.entries.firstWhere((e) => e.title == 'Variance');
      expect(variance.formulas['Population'], contains('N'));
      expect(variance.formulas['Sample'], contains('n − 1'));
    });

    test('carries the quick reminder from the sheet footer', () {
      expect(sheet.quickReminder['Mean'], 'Average');
      expect(sheet.quickReminder['Variance'], 'Spread squared');
      expect(sheet.quickReminder['Standard deviation'], 'Spread');
    });
  });

  group('search', () {
    test('finds a sheet by a formula name inside it', () {
      expect(ReferenceSheets.statistics.matches('variance'), isTrue);
      expect(ReferenceSheets.bigO.matches('quadratic'), isTrue);
    });

    test('finds a sheet by subject', () {
      expect(ReferenceSheets.probability.matches('statistics'), isTrue);
    });

    test('an empty search keeps every sheet', () {
      expect(ReferenceSheets.statistics.matches('  '), isTrue);
    });

    test('rejects an unrelated term', () {
      expect(ReferenceSheets.statistics.matches('hostel'), isFalse);
    });
  });

  group('forSubject', () {
    test('returns only that subject\'s sheets', () {
      final stats = ReferenceSheets.forSubject('Statistics');
      expect(stats, isNotEmpty);
      expect(stats.every((s) => s.subject == 'Statistics'), isTrue);
    });

    test('returns everything when no subject is given', () {
      expect(ReferenceSheets.forSubject(null).length, ReferenceSheets.all.length);
    });
  });

  group('rendering', () {
    testWidgets('a sheet shows its formulas and guidance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReferenceSheetScreen(sheet: ReferenceSheets.statistics),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('x̄ = Σx / n'), findsOneWidget);
      expect(find.text('When to use it?'), findsWidgets);

      // The reminder sits at the foot of a long sheet, so scroll to it the
      // way a student revising would.
      await tester.scrollUntilVisible(
        find.text('Quick Reminder'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Quick Reminder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a small phone without clipping', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: ReferenceSheetScreen(sheet: ReferenceSheets.bigO)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the list screen filters as you search', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReferenceSheetsScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Statistics'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'complexity');
      await tester.pumpAndSettle();
      expect(find.text('Time Complexity'), findsOneWidget);
      expect(find.text('Statistics'), findsNothing);
    });
  });
}
