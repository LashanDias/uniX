import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/services/auth_error_messages.dart';
import 'package:unix_app/services/auth_service.dart';

AuthException error(String code, [String message = 'raw message']) =>
    AuthException(code: code, message: message);

void main() {
  group('socialAuthMessage', () {
    test('explains a provider that is switched off in Firebase', () {
      // The real cause of "Google did not work": the project had no OAuth
      // providers enabled, so Firebase returns operation-not-allowed.
      final message = socialAuthMessage(
        error('operation-not-allowed'),
        provider: 'Google',
      );
      expect(message, contains('not switched on'));
      expect(message, contains('email and password'));
    });

    test('tells the user to allow pop-ups when the browser blocked one', () {
      final message = socialAuthMessage(
        error('popup-blocked'),
        provider: 'Google',
      );
      expect(message.toLowerCase(), contains('pop-up'));
    });

    test('says the window closed early rather than blaming the user', () {
      final message = socialAuthMessage(
        error('popup-closed-by-user'),
        provider: 'Google',
      );
      expect(message, contains('closed before sign-in finished'));
    });

    test('explains an email already registered another way', () {
      final message = socialAuthMessage(
        error('account-exists-with-different-credential'),
        provider: 'Google',
      );
      expect(message, contains('different sign-in method'));
    });

    test('names the network as the problem when offline', () {
      final message = socialAuthMessage(
        error('network-request-failed'),
        provider: 'Google',
      );
      expect(message, contains('No internet connection'));
    });

    test('passes through wording already written for students', () {
      const wording = 'Use your SLTC institutional email address.';
      expect(
        socialAuthMessage(error('invalid-email', wording), provider: 'Google'),
        wording,
      );
    });

    test('names the provider it was asked about', () {
      expect(
        socialAuthMessage(error('operation-not-allowed'), provider: 'Apple'),
        startsWith('Apple'),
      );
    });

    test('falls back safely for an error that is not an AuthException', () {
      final message = socialAuthMessage(
        StateError('something else'),
        provider: 'Google',
      );
      expect(message, 'Google sign-in could not be completed. Please try again.');
    });

    test('never returns an empty message', () {
      for (final code in [
        'operation-not-allowed',
        'popup-blocked',
        'unauthorized-domain',
        'something-unmapped',
      ]) {
        expect(
          socialAuthMessage(error(code), provider: 'Google'),
          isNotEmpty,
          reason: code,
        );
      }
    });
  });
}
