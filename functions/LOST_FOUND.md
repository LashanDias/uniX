# UNIX Lost & Found follow-ups

## Architecture

The existing Firebase Auth, Firestore project, Lost & Found form, image previews and Notifications screen are reused. Previously, reports were only anonymous device-local JSON and notifications were static samples; there was no Lost & Found collection, service or backend scheduler.

- `lostFound/{itemId}` holds the report, owner UID, `type` (`lost`/`found`), status, timestamps and current stage.
- `createLostFoundPost` validates fields and initializes stage 2 using server time. A stable item ID makes a retried create idempotent.
- `lostFoundFollowups` runs every 15 minutes using Firebase Cloud Scheduler. A transaction rereads each due active record and creates one inbox document at `users/{uid}/notifications/lostFound_{itemId}`.
- The reminder carries a unique `checkToken` for that item, stage and scheduled timestamp. Concurrent scheduler retries produce only one reminder. There is no app timer.
- On delivery, `lastCheckAt` is set, `awaitingResponse` becomes true and `nextCheckAt` is cleared until the owner answers. An unanswered question stays in the inbox; the cycle does not advance without NO.
- `respondLostFound` validates the authenticated owner and current token inside a transaction. NO advances 2→4→8→2 and sets `nextCheckAt` to server response time plus that many days. YES resolves the record, sets `resolvedAt`, clears scheduling and deletes the inbox question atomically.
- Owner-initiated Resolve/Remove use the same transaction. Remove is a soft deletion (`status: deleted`, `deletedAt`), preserving admin history. A Firestore trigger also cleans up questions after administrative hard deletion/status changes. The inbox UI checks the live server-backed post before displaying a question.
- Security rules deny direct client writes to reports and reminders. Owners can read their own history; existing admins can read all history. Other signed-in students can read active posts only.

This implementation delivers persistent **in-app inbox notifications**. The scheduler continues while the user is logged out or the app is closed; questions appear when the user returns. OS push/email delivery is not configured in this project.

## Existing local drafts

Existing `lostFound.reports.v1` data stays on the device and is explicitly labeled as local drafts without automatic follow-ups. These records lack trustworthy owner IDs, so they are not silently assigned to whichever account signs in. New reports can still be saved as drafts; publishing while authenticated starts the server cycle. Photos remain attached. Image payloads are capped at 600 KB total to stay within Firestore's document size limit.

## Validation and tests

`node --test functions/test/lost_found.test.js` covers every requested YES/NO path for Lost and Found, wrap-around, missing/deleted/resolved posts, owner enforcement, duplicate/stale answers, late answers, and invalid creation fields.

With Java 21 and the Firebase CLI installed:

```
firebase emulators:exec --only firestore --project demo-unix-recruiter --config firebase.recruiter.test.json "node --test functions/test/lost_found.test.js && node test/lost_found_rules_test.mjs"
```

The integration test exercises the production repository against real emulator transactions, including concurrent creates, scheduler invocations and answers. The rules test verifies private history/inbox reads and rejection of direct client writes.

## Activation

Source and configuration are ready for review; they have not been deployed. The Flutter client calls the configured Firebase project `my-unix-app-17-d8a63`. Until deployment, Publish can fail and the user can save a local draft instead.

After explicit approval of the previously blocked live deployment, deploy the functions, Firestore rules and indexes together:

```
firebase deploy --only functions:unix,firestore:rules,firestore:indexes --project my-unix-app-17-d8a63
```

Cloud Functions/Scheduler require an appropriately enabled Firebase billing plan. Confirm the scheduler job is enabled after deployment. No service-account credentials belong in the repository. Images, code and local test fixtures are not a migration of real user records.

Reference: [Firebase scheduled functions](https://firebase.google.com/docs/functions/schedule-functions).
