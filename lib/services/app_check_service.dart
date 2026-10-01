import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Proves to the backend that a request came from the real app.
///
/// This is the answer to "did this really come from my app?", and it is a
/// different question from "who is signed in?". Firebase Auth proves the
/// second; anyone can take a valid ID token and call Firestore from a script.
/// App Check attests the *client*: the web build is checked with reCAPTCHA,
/// Android with Play Integrity and iOS with Device Check, and the backend can
/// refuse anything without a valid attestation.
///
/// Note on CSRF: this app holds no cookies. Firebase sends the ID token in an
/// Authorization header that the client sets explicitly, so a browser never
/// attaches credentials to a cross-site request on its own. That is what makes
/// CSRF possible, so there is nothing here for a CSRF token or a SameSite
/// attribute to protect. App Check covers the real risk instead.
class AppCheckService {
  /// reCAPTCHA v3 site key for the web build.
  ///
  /// Supplied at build time so no key is committed:
  ///   flutter build web --dart-define=RECAPTCHA_SITE_KEY=...
  static const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

  /// Whether this build has what it needs to attest itself.
  ///
  /// Only the web build needs a key; the mobile providers are configured in
  /// the Firebase console rather than in the binary.
  static bool get isConfigured => !kIsWeb || recaptchaSiteKey.isNotEmpty;

  /// Turns App Check on, if this build is configured for it.
  ///
  /// Activation is skipped rather than allowed to throw when no key is set,
  /// so a developer build without one still runs. Enforcement lives in the
  /// Firebase console and in the callable functions, so skipping here cannot
  /// quietly weaken a deployed backend.
  static Future<void> activate() async {
    if (!isConfigured) {
      debugPrint(
        'App Check not activated: no RECAPTCHA_SITE_KEY in this build. '
        'Requests will be unattested.',
      );
      return;
    }
    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: kIsWeb ? ReCaptchaV3Provider(recaptchaSiteKey) : null,
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleDeviceCheckProvider(),
      );
    } catch (error) {
      // A failed activation must not stop the app starting. The backend is
      // what decides whether an unattested request is allowed.
      debugPrint('App Check activation failed: $error');
    }
  }
}
