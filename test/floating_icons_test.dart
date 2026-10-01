import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/widgets/floating_icons.dart';

Widget wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: SizedBox(height: 200, width: 400, child: child),
    ),
  ),
);

void main() {
  group('rendering', () {
    testWidgets('draws every icon it is given', (tester) async {
      await tester.pumpWidget(
        wrap(const FloatingIcons(icons: FloatingIcons.food)),
      );
      await tester.pump();

      expect(
        find.byType(Icon),
        findsNWidgets(FloatingIcons.food.length),
      );
    });

    testWidgets('does not intercept taps meant for what is underneath', (
      tester,
    ) async {
      // The icons are decoration over a banner; swallowing a tap would make
      // part of the banner mysteriously dead.
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  // Opaque, because an empty SizedBox paints nothing and so
                  // is not hit-testable under the default deferToChild.
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped = true,
                  child: const SizedBox(height: 200, width: 400),
                ),
                const Positioned.fill(
                  child: FloatingIcons(icons: FloatingIcons.food),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tapAt(const Offset(100, 100));
      expect(tapped, isTrue);
    });
  });

  group('motion', () {
    testWidgets('icons move over time', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FloatingIcons(
            icons: [FloatingIcon(icon: Icons.star, left: 0.5, top: 0.5)],
          ),
        ),
      );
      await tester.pump();
      final first = tester.getTopLeft(find.byType(Icon));

      await tester.pump(const Duration(milliseconds: 1500));
      final later = tester.getTopLeft(find.byType(Icon));

      expect(later.dy, isNot(first.dy));
      // Only the vertical drift moves; nothing slides sideways.
      expect(later.dx, first.dx);
    });

    testWidgets('respects the reduce-motion accessibility setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const FloatingIcons(
            icons: [FloatingIcon(icon: Icons.star, left: 0.5, top: 0.5)],
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      final first = tester.getTopLeft(find.byType(Icon));

      await tester.pump(const Duration(milliseconds: 1500));
      final later = tester.getTopLeft(find.byType(Icon));

      // Someone who asked for stillness must not be given movement anyway.
      expect(later, first);
    });

    testWidgets('settles rather than animating forever in a test', (
      tester,
    ) async {
      // A repeating controller makes pumpAndSettle time out, which would
      // break every widget test on a screen that uses this.
      await tester.pumpWidget(
        wrap(
          const FloatingIcons(icons: FloatingIcons.sparkles),
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('icon sets', () {
    test('the food set is positioned inside the box', () {
      for (final item in FloatingIcons.food) {
        expect(item.left, inInclusiveRange(0, 1), reason: '${item.icon}');
        expect(item.top, inInclusiveRange(0, 1), reason: '${item.icon}');
      }
    });

    test('icons are faint enough to sit behind text', () {
      for (final item in [...FloatingIcons.food, ...FloatingIcons.sparkles]) {
        expect(item.opacity, lessThan(0.3), reason: '${item.icon}');
      }
    });

    test('phases are spread so they do not move in lockstep', () {
      final phases = FloatingIcons.food.map((i) => i.phase).toSet();
      expect(phases.length, greaterThan(1));
    });
  });
}
