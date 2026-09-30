import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/auth_service.dart';

void main() {
  test('Institutional email is normalized', () {
    expect(
      AuthService.institutionalEmail(' Student@SLTC.ac.lk '),
      'student@sltc.ac.lk',
    );
  });

  test('Admin emails are allowed through the whitelist', () {
    const adminEmails = [
      'amashanki191@gmail.com',
      'Cit-24-01-0361@sltc.ac.lk',
      'malshikulasekara4816@gmail.com',
      'sandupamabimandhi@gmail.com',
      'jaksikasivakumar@gmail.com',
    ];

    for (final email in adminEmails) {
      expect(AuthService.isAdminEmail(email), isTrue);
      expect(AuthService.institutionalEmail(email), email.toLowerCase());
    }
    expect(AuthService.isAdminEmail('student@gmail.com'), isFalse);
  });

  test('Recruiter role is recognized and recruiter emails bypass SLTC restrictions', () {
    expect(AuthService.isRecruiterRole('Recruiter'), isTrue);
    expect(AuthService.isRecruiterRole(' recruiter '), isTrue);
    expect(AuthService.isRecruiterRole('Student'), isFalse);
    expect(AuthService.isRecruiterRole(null), isFalse);
    expect(
      AuthService.institutionalEmail('hr.manager@company.com', role: 'Recruiter'),
      'hr.manager@company.com',
    );
  });

  test('Rejects external domains and malformed institutional addresses for students', () {
    for (final email in [
      'user@gmail.com',
      'user@sltc.ac.lk.evil.com',
      '@sltc.ac.lk',
      'two@@sltc.ac.lk',
      'two words@sltc.ac.lk',
    ]) {
      expect(
        () => AuthService.institutionalEmail(email),
        throwsA(isA<AuthException>()),
      );
    }
  });
}
