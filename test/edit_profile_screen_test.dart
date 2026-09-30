import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/screens/profile/edit_profile_screen.dart';

void main() {
  for (final role in ['Guest', 'Recruiter', null, 'Unknown']) {
    testWidgets('Edit profile handles loaded role $role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(
            loadProfile: () async => {
              'name': 'Test user',
              'email': 'test@sltc.ac.lk',
              'role': role,
              'birthday': '',
              'year': '',
              'district': '',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(field.initialValue, role == 'Recruiter' ? 'Recruiter' : isNull);
    });
  }
}
