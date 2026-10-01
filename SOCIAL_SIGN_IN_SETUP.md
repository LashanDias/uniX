# Apple and LinkedIn sign-in

The login buttons now invoke Firebase authentication instead of displaying a placeholder. They keep existing UNIX account restrictions, blocked-account checks, profile creation, and student/recruiter routing. Google continues to use its existing provider.

## Apple

Enable Apple in Firebase Authentication → Sign-in method. Configure Sign in with Apple in the Apple Developer account, including the Services ID, Team ID, Key ID and private key in the Firebase console. Add the Firebase callback URL shown by that console to the Apple service. Native iOS builds also require the Sign in with Apple capability.

Students must share the eligible SLTC email associated with the Apple account. Apple's Hide My Email relay address does not meet the existing institutional-email restriction; the app will reject it rather than bypass that restriction.

[Firebase Apple setup](https://firebase.google.com/docs/auth/ios/apple)

## LinkedIn

This implementation uses Firebase's generic OpenID Connect integration, which requires Firebase Authentication with Identity Platform. Create a LinkedIn developer app and enable the “Sign In with LinkedIn using OpenID Connect” product. In Firebase, add an OIDC provider with:

- Provider ID: `oidc.linkedin` (or set the public `LINKEDIN_PROVIDER_ID` Dart define to your existing ID).
- Issuer: `https://www.linkedin.com`.
- Authorization-code flow, using the LinkedIn client ID and client secret stored in the Firebase console.
- Copy the Firebase callback URL into LinkedIn's authorized redirect URLs.

The app requests `openid`, `profile`, and `email`. Keep client secrets and Apple private keys out of Dart source and Git. Add the actual app host to Firebase's authorized domains; add localhost explicitly for local browser testing when necessary.

[Firebase OIDC setup](https://firebase.google.com/docs/auth/web/openid-connect)

[LinkedIn OIDC setup](https://learn.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/sign-in-with-linkedin-v2)

Provider configuration and successful real-account sign-in have not been verified. The focused widget tests verify both buttons dispatch sign-in, disable repeat taps while pending, and recover with a clear provider-specific error when configuration is missing.
