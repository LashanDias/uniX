import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/app_check_service.dart';

void main() {
  group('App Check configuration', () {
    test('no reCAPTCHA key is committed to the repository', () {
      // The key is supplied at build time with --dart-define, so a checkout of
      // this repository never carries one.
      expect(AppCheckService.recaptchaSiteKey, isEmpty);
    });

    test('a web build without a key reports itself as unconfigured', () {
      // Only the web build needs a key in the binary; the mobile providers are
      // configured in the Firebase console.
      expect(AppCheckService.isConfigured, kIsWeb ? isFalse : isTrue);
    });

    test('activate completes rather than throwing when unconfigured', () async {
      // A developer build with no key must still start. Enforcement is the
      // backend's job, so skipping activation here cannot weaken it.
      await expectLater(AppCheckService.activate(), completes);
    });
  });
}
