import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/jobs/skill_match_screen.dart';

void main() {
  for (final width in [320.0, 430.0, 1440.0]) {
    testWidgets('Skill match fits at width $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var next = false;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SkillMatchScreen(
        onNext: () => next = true, onPrev: () {},
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Analyses MY CV'));
      await tester.tap(find.text('Analyses MY CV'));
      expect(next, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
