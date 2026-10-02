import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_app/screens/lost_found/lost_found_screen.dart';

/// Widths worth checking: a small Android phone, a typical phone, and a large
/// phone. Content clipped on the right edge shows up here as a RenderFlex
/// overflow, which the framework reports as a test exception.
const _phoneWidths = [320.0, 360.0, 430.0];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final width in _phoneWidths) {
    testWidgets('Lost & Found list fits at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: LostFoundScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Lost item detail fits at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: LostItemDetailScreen.example(title: 'Black wallet')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Report item form fits at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: ReportItemScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Lost item detail keeps its details and button reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: LostItemDetailScreen.example(title: 'Black wallet')),
    );
    await tester.pumpAndSettle();

    // The screenshot that prompted this test showed the image, then a large
    // empty gap, then the button -- with the details missing entirely.
    expect(find.text('Black wallet'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);

    await tester.ensureVisible(find.text('Copy details to share'));
    expect(tester.takeException(), isNull);
  });
}
