# Firebase authentication and profiles

Implemented: Firebase email/password signup and login, Google login (web popup;
native Google Sign-In), password reset emails, Firebase logout, private Firestore
profiles at `users/{uid}`, and profile photos in Firebase Storage.

## Console setup required

1. In project `my-unix-app-17-d8a63`, enable Email/Password and Google under
   Authentication > Sign-in method. Set the Google support email.
2. Add your web deployment domain and `localhost` to Authentication's authorized
   domains. For Android, register your signing SHA fingerprints and download the
   updated google-services.json. Configure the Google URL scheme for iOS.
   See https://firebase.google.com/docs/auth/flutter/federated-auth.
3. Create the default Firestore database and initialize the Storage bucket using
   the existing Firebase project. Confirm any billing requirements in the console.
4. Review and deploy the included rules with:
   `firebase deploy --only firestore:rules,storage --project my-unix-app-17-d8a63`
   These rules allow only each user's own profile and photo; other paths are denied.
   Compare against any existing deployed rules before deployment.

No console settings or rules have been deployed by this change.

## Behavior and verification

- Local demo accounts are not Firebase accounts. Register a new test account;
  do not migrate the old locally stored passwords. Clear old browser app storage
  to remove credentials left by the previous prototype.
- Use an SLTC institutional email. Confirm the new user in Authentication, and
  their profile in Firestore. Roles are descriptive profile fields, not permissions.
- Log out, log back in, edit the profile, upload a photo, then check it on a second
  browser after login. Try a second account to check profile isolation.
- Password reset sends Firebase's email link. Complete the change through that
  link, then verify the old password fails and the new password succeeds. The
  prototype's four-digit-code screens do not implement custom email OTP.
- Changing the login email requires a separate verified email-change flow;
  the profile form rejects changing it.
- Test Google sign-in using an institutional Google account. Desktop native
  Google sign-in depends on platform plugin support; Chrome is the web test target.

## Still outside this implementation

Marketplace, notes, jobs, gigs, hostel applications, bookings, notifications,
and AI still need real data flows. Their mock services are unchanged.
The unused Express package in `functions` still has no server entry file.
Neither production runtime behavior nor deployed Firebase settings are verified
by static analysis or the local widget/unit tests.

Marketplace now reads the Firestore products collection and posts real products with optional Storage photos. Deploy the updated Firestore and Storage rules before testing. Books and other category filters apply to saved products; no sample catalog is seeded.
