import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/auth/login_screen.dart';
import 'package:unix_app/services/auth_service.dart';

void main() {
  for (final provider in ['Apple', 'LinkedIn']) {
    testWidgets(
      '$provider button starts sign-in, prevents repeated taps and recovers from errors',
      (tester) async {
        final pending = Completer<AuthUser?>();
        final calls = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(
              socialSignIn: (name) {
                calls.add(name);
                return pending.future;
              },
            ),
          ),
        );
        final button = find.byTooltip('Continue with $provider');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        expect(calls, [provider]);
        pending.completeError(
          AuthException(code: 'operation-not-allowed', message: 'Disabled'),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('$provider sign-in is not switched on'),
          findsOneWidget,
        );
        expect(find.text('Login'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
