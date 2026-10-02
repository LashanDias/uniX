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
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5175 --no-web-resources-cdn --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=LOCAL_CAREER_AI=true
```

Enter the email/password from `.env` on the normal login form. The seeder verifies both password logins and stored profile roles. It only contacts fixed localhost emulator endpoints; it never creates production accounts or prints auth tokens/passwords.

Emulator accounts are in memory by default. Run the seeder after restarting the emulators. It is safe to repeat with unchanged credentials; if you change a password, restart the emulators to clear the previous test accounts before reseeding. Do not overwrite your customized `.env` with the example on each run.

Without `USE_FIREBASE_EMULATORS=true`, the app continues using its existing Firebase project, where these test accounts do not exist. Emulator mode is restricted to debug builds. App Check is skipped only for the local demo project. For an Android emulator, add `--dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2`.

Google, Apple and LinkedIn are separate social sign-in flows. Use the email/password form for these sample accounts.

## CV analysis and local career requests

Open http://localhost:5175 in your browser and choose the Jobs tab. The web-server device avoids requiring a Chrome debugger connection. `--no-web-resources-cdn` serves Flutter's graphics engine from the installed SDK rather than downloading it at startup. Firebase's web SDK still needs network access on its first load.

The four steps are Upload CV → Review extracted information → Skill match → Ranked jobs. PDF, DOCX and TXT are supported; scanned PDFs need pasted text. The sample CV button lets you test immediately. Four clearly labelled sample HR requirements are added once without replacing existing requirements. HR documents saved from the existing recruiter workspace are also available to the student on the same browser/origin. Sample applications are never submitted.

Matching and extraction work without a network or model. Section extraction uses CV headings; review/edit the extracted text. The score uses recognised skills (70%), plus explicitly specified education, experience and location (10% each), excluding unspecified criteria. Uploaded free-text HR requirements currently use skill coverage unless structured criteria are provided. Experience requires explicit years in the Experience section. Scores are document coverage, not a hiring prediction or applicant percentile.

For the optional local language model, start this adapter in another terminal:

```powershell
node --env-file=.env scripts/local_career_ai.mjs
```

The adapter listens only on `127.0.0.1:8787` and calls an already-running Ollama instance on `127.0.0.1:11434`. Set `UNIX_LOCAL_AI_MODEL` in `.env` to an installed model name (default `qwen2.5:0.5b`). It does not install/download a model or send requests to a hosted service. Check `http://127.0.0.1:8787/health` for `modelAvailable`. See the [Ollama chat API](https://docs.ollama.com/api/chat).

Ask AI sends the selected job and extracted skill-match evidence, not the whole CV, to this local adapter. If the model is absent, stopped or returns an invalid answer, the UI explicitly switches to offline guidance for scores, learning plans and interview preparation. There is no simulated model response. On this PC no Ollama executable was found during setup, so the tested runtime uses that fallback.

Keep the same browser address (use `localhost:5175` consistently); `127.0.0.1:5175` has separate browser storage. Local CVs/HR requirements are not synced across devices.

Checks:

```powershell
node --test scripts/local_career_ai.test.mjs
flutter test test/career_flow_test.dart test/recruitment_comparison_test.dart
```
