import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/hostels/hostels_screen.dart';
import 'package:unix_app/screens/hostels/girls_hostel_screen.dart';

void main() {
  testWidgets('accommodation options open their own screens', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HostelsScreen()));
    await tester.ensureVisible(find.text('Annex Houses'));
    await tester.tap(find.text('Annex Houses'));
    await tester.pumpAndSettle();
    expect(find.text('Annex Houses listings coming soon'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Boarding'));
    await tester.tap(find.text('Boarding'));
    await tester.pumpAndSettle();
    expect(find.text('Boarding listings coming soon'), findsOneWidget);
  });
  testWidgets('girls flow fits a narrow screen and opens date range picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: HostelListScreen(gender: 'Girls')),
    );
    expect(find.byType(GirlsHostelScreen), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Check availability'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Choose your dates'));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });
}
