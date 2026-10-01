import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_storage.dart';
import 'app_access_service.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException({required this.code, required this.message});
}

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  AuthUser({required this.uid, required this.email, required this.displayName});
}

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static Future<void>? _googleInitialization;

  static bool isAdminEmail(String? email) =>
      AppAccessService.isAdminEmail(email);

  static bool isCurrentUserAdmin() => isAdminEmail(_auth.currentUser?.email);

  static bool isRecruiterRole(String? role) =>
      role?.trim().toLowerCase() == 'recruiter';

  static String validEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      throw AuthException(
        code: 'invalid-email',
        message: 'Enter a valid email address.',
      );
    }
    return normalized;
  }

  static String institutionalEmail(String email, {String? role}) {
    final normalized = validEmail(email);
    if (!isRecruiterRole(role) &&
        !isAdminEmail(normalized) &&
        !RegExp(r'^[^\s@]+@sltc\.ac\.lk$').hasMatch(normalized)) {
      throw AuthException(
        code: 'invalid-email',
        message: 'Use your SLTC institutional email address.',
      );
    }
    return normalized;
  }

  static Future<String> homeRoute() async {
    final profile = await ProfileStorage.load();
    return isRecruiterRole(profile['role']?.toString())
        ? '/recruiter'
        : '/main';
  }

  static Future<void> _checkAccount(User user) async {
    try {
      final profile = await ProfileStorage.load();
      // An admin can block an account from the admin panel; enforce it here
      // so a blocked student cannot keep using an existing session.
      if (profile['blocked'] == true) {
        throw AuthException(
          code: 'account-blocked',
          message:
              'This account has been blocked by an administrator. '
              'Contact the UNIX team if you think this is a mistake.',
        );
      }
      institutionalEmail(user.email ?? '', role: profile['role']?.toString());
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  static AuthUser _user(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName ?? '',
  );

  static Future<T> _translate<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        code: error.code,
        message: error.message ?? 'Authentication failed. Please try again.',
      );
    }
  }

  static Future<AuthUser> signIn({
    required String email,
    required String password,
  }) => _translate(() async {
    final result = await _auth.signInWithEmailAndPassword(
      email: validEmail(email),
      password: password,
    );
    await _checkAccount(result.user!);
    return _user(result.user!);
  });

  static Future<AuthUser?> signInWithGoogle({String? signupRole}) =>
      _translate(() async {
        UserCredential result;
        if (kIsWeb) {
          final provider = GoogleAuthProvider()
            ..setCustomParameters({'prompt': 'select_account'});
          result = await _auth.signInWithPopup(provider);
        } else {
          _googleInitialization ??= GoogleSignIn.instance.initialize();
          await _googleInitialization;
          final account = await GoogleSignIn.instance.authenticate();
          result = await _auth.signInWithCredential(
            GoogleAuthProvider.credential(
              idToken: account.authentication.idToken,
            ),
          );
        }
        return _finishSocialSignIn(result, signupRole: signupRole);
      });

  static Future<AuthUser> _finishSocialSignIn(
    UserCredential result, {
    String? signupRole,
  }) async {
    try {
      final user = result.user!;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!profile.exists) {
        final role = isRecruiterRole(signupRole) ? 'Recruiter' : 'Student';
        institutionalEmail(user.email ?? '', role: role);
        await ProfileStorage.save({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'role': role,
        }, null);
      }
      await _checkAccount(user);
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
    return _user(result.user!);
  }

  static const linkedInProviderId = String.fromEnvironment(
    'LINKEDIN_PROVIDER_ID',
    defaultValue: 'oidc.linkedin',
  );

  static Future<AuthUser> signInWithApple() => _signInWithProvider(
    AppleAuthProvider()
      ..addScope('email')
      ..addScope('name'),
  );

  static Future<AuthUser> signInWithLinkedIn() => _signInWithProvider(
    OAuthProvider(linkedInProviderId)
      ..addScope('openid')
      ..addScope('profile')
      ..addScope('email'),
  );

  static Future<AuthUser> _signInWithProvider(
    AuthProvider provider,
  ) => _translate(() async {
    // Start the popup directly from the tap; do not await anything before this.
    final result = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    return _finishSocialSignIn(result);
  });

  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) => _translate(() async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: institutionalEmail(email, role: role),
      password: password,
    );
    await result.user!.updateDisplayName(name.trim());
    try {
      await ProfileStorage.save({
        'name': name.trim(),
        'email': institutionalEmail(email, role: role),
        'role': isRecruiterRole(role) ? 'Recruiter' : 'Student',
      }, null);
    } catch (_) {
      await _auth.signOut();
      throw AuthException(
        code: 'profile-save-failed',
        message:
            'Your account was created, but your profile could not be saved. Sign in and complete your profile.',
      );
    }
  });

  static Future<void> sendPasswordReset(String email) =>
      _translate(() => _auth.sendPasswordResetEmail(email: validEmail(email)));

  static Future<void> signOut() => _auth.signOut();
}
