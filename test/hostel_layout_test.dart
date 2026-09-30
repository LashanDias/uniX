import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/hostels/hostels_screen.dart';

void main() {
  testWidgets('Girls hostel detail shows contact and map block', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final girlsHostel = HostelsScreen.hostels.firstWhere(
      (hostel) => hostel.gender == 'Girls',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HostelDetailsScreen(hostel: girlsHostel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contact Us'), findsOneWidget);
    expect(find.text('0112 100 5000'), findsOneWidget);
    expect(find.textContaining('Ingiriya Road'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
