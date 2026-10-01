# Local student and recruiter logins

The local `.env` contains `UNIX_TEST_STUDENT_EMAIL`, `UNIX_TEST_STUDENT_PASSWORD`, `UNIX_TEST_RECRUITER_EMAIL`, and `UNIX_TEST_RECRUITER_PASSWORD`. It is ignored by Git. `.env.example` contains disposable example values and is safe to commit.

The credentials are read only by the account-seeding script, never bundled into Flutter or used to bypass authentication. Both accounts sign in with normal Firebase email/password authentication. Their profiles store `Student` and `Recruiter`, so the usual app routing and permissions apply.

## Start the local backend

Requires Node.js, the Firebase CLI, and Java 21. Install functions dependencies once with `npm install --prefix functions`.

In a terminal at the project root:

```powershell
# Set these two lines if Java 21 is not already on your PATH.
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-21'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:start --project demo-unix-local --config firebase.local.json --only auth,firestore,functions,storage
```

Leave that terminal running. The Auth, Firestore, Functions and Storage emulators listen on 9099, 8089, 5001 and 9199 respectively. The demo project cannot access live Firebase resources.

## Create accounts and open the app

In a second terminal:

```powershell
# Only on the first run, if .env does not exist:
Copy-Item .env.example .env

node scripts/seed_local_users.mjs
flutter run -d chrome --web-port 5175 --dart-define=USE_FIREBASE_EMULATORS=true
```

Enter the email/password from `.env` on the normal login form. The seeder verifies both password logins and stored profile roles. It only contacts fixed localhost emulator endpoints; it never creates production accounts or prints auth tokens/passwords.

Emulator accounts are in memory by default. Run the seeder after restarting the emulators. It is safe to repeat with unchanged credentials; if you change a password, restart the emulators to clear the previous test accounts before reseeding. Do not overwrite your customized `.env` with the example on each run.

Without `USE_FIREBASE_EMULATORS=true`, the app continues using its existing Firebase project, where these test accounts do not exist. Emulator mode is restricted to debug builds. App Check is skipped only for the local demo project. For an Android emulator, add `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`.

Google, Apple and LinkedIn are separate social sign-in flows. Use the email/password form for these sample accounts.
