import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/app_access_service.dart';

void main() {
  group('AppAccessService', () {
    test('accepts SLTC institutional email addresses', () {
      expect(AppAccessService.isInstitutionalEmail('student@sltc.ac.lk'), isTrue);
      expect(AppAccessService.isInstitutionalEmail('student@gmail.com'), isFalse);
    });

    test('recognizes admin emails', () {
      expect(AppAccessService.isAdminEmail('amashanki191@gmail.com'), isTrue);
      expect(AppAccessService.isAdminEmail('student@sltc.ac.lk'), isFalse);
    });

    test('allows ownership or admin access for managed records', () {
      expect(
        AppAccessService.canManageOwnedResource('user-1', 'user-1'),
        isTrue,
      );
      expect(
        AppAccessService.canManageOwnedResource('user-2', 'user-1'),
        isFalse,
      );
    });
  });
}
