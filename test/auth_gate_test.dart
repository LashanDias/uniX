import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/main.dart';
import 'package:unix_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('the app opens on AuthGate rather than a hardcoded login route', (
    tester,
  ) async {
    await tester.pumpWidget(const UnixApp());

    // Before this gate existed, MaterialApp had initialRoute: '/login', so a
    // student who was already signed in had to log in again on every launch.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.initialRoute, isNull);
    expect(app.home, isA<AuthGate>());
  });

  testWidgets('falls back to the login screen when Firebase is unavailable', (
    tester,
  ) async {
    // Nothing calls Firebase.initializeApp here, so FirebaseAuth.instance
    // throws. The gate must degrade to the login form instead of crashing.
    await tester.pumpWidget(const UnixApp());
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
