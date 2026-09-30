import 'auth_service.dart';

/// Turns a sign-in failure into something a student can act on.
///
/// Both auth screens previously caught every failure and showed the same
/// "Google sign-in could not be completed", so a blocked pop-up, a provider
/// that was never switched on in Firebase, and a wrong email address all
/// looked identical and gave no clue what to do next.
String socialAuthMessage(Object error, {required String provider}) {
  if (error is! AuthException) {
    return '$provider sign-in could not be completed. Please try again.';
  }

  switch (error.code) {
    case 'operation-not-allowed':
    case 'auth/operation-not-allowed':
      // The provider exists in the app but is off in the Firebase console.
      return '$provider sign-in is not switched on for this app yet. '
          'Sign in with your email and password instead.';

    case 'popup-blocked':
    case 'auth/popup-blocked':
      return 'Your browser blocked the $provider window. Allow pop-ups for '
          'this site, then try again.';

    case 'popup-closed-by-user':
    case 'auth/popup-closed-by-user':
    case 'cancelled-popup-request':
    case 'web-context-canceled':
      return 'The $provider window closed before sign-in finished. '
          'Try again.';

    case 'account-exists-with-different-credential':
      return 'That email is already registered with a different sign-in '
          'method. Use your email and password.';

    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';

    case 'unauthorized-domain':
      return '$provider sign-in is not allowed from this address. Open the '
          'app from an approved link, or sign in with your email.';

    default:
      // invalid-email and account-blocked already carry wording written for
      // students, so pass those through unchanged.
      return error.message;
  }
}
