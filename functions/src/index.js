'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { repository, ValidationError } = require('./lost_found');
const { backups } = require('./backup');
const { jobFeed } = require('./job_feed');
const { Storage } = require('@google-cloud/storage');
initializeApp();
const store = repository(getFirestore(), Timestamp);
// Whether to reject requests that carry no App Check attestation.
//
// Off by default so the backend keeps working until the app has been
// registered in the Firebase console and builds ship a reCAPTCHA key.
// Turn it on with: firebase functions:config or an env var
// ENFORCE_APP_CHECK=true, once attested builds are out.
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true';

const callable = handler =>
  onCall({ enforceAppCheck: ENFORCE_APP_CHECK }, async request => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
    // Auth says who is calling. App Check says what is calling. Without it a
    // stolen ID token can be replayed from any script, so log the gap even
    // while enforcement is still off.
    if (!request.app && !ENFORCE_APP_CHECK) {
      console.warn(`Unattested call to a callable by uid ${request.auth.uid}`);
    }
    try { return await handler(request.auth.uid, request.data ?? {}); }
    catch (error) {
      if (error instanceof ValidationError) throw new HttpsError(error.code, error.message);
      throw new HttpsError('internal', 'Unable to update the report. Please retry.');
    }
  });
exports.createLostFoundPost = callable((uid, data) => store.create(uid, data));
exports.respondLostFound = callable((uid, data) => store.answer(uid, data));
exports.lostFoundFollowups = onSchedule({ schedule: 'every 15 minutes', timeZone: 'Etc/UTC', retryCount: 3, timeoutSeconds: 300 }, () => store.runDue());
exports.cleanupLostFoundFollowup = onDocumentWritten('lostFound/{itemId}', event => store.cleanup(event.params.itemId, event.data?.before.data()?.userId));

// Daily Firestore backup. Firestore keeps no copy of a deleted or overwritten
// document, so without this a mistake is unrecoverable. Runs at 18:30 UTC,
// which is midnight in Sri Lanka, so a day's data is complete before it runs.
// Defaults to a folder in the project's existing Cloud Storage bucket, so no
// separate bucket has to be created first. storage.rules denies clients any
// path it does not explicitly allow, and backups/ is explicitly denied too.
const backupBucket = process.env.BACKUP_BUCKET
  || `gs://${process.env.GCLOUD_PROJECT}.firebasestorage.app/backups`;
const backup = backups({
  projectId: process.env.GCLOUD_PROJECT,
  bucket: backupBucket,
  // Without a storage client prune() is a no-op, so old exports would pile up
  // in the bucket forever and the 30-day retention would never apply.
  storage: new Storage(),
});

exports.dailyFirestoreBackup = onSchedule(
  {
    schedule: '30 18 * * *',
    timeZone: 'Etc/UTC',
    retryCount: 3,
    timeoutSeconds: 540,
  },
  async () => {
    const result = await backup.run();
    console.log(`Firestore exported to ${result.outputUriPrefix}`);
    const pruned = await backup.prune();
    if (pruned.deleted.length) {
      console.log(`Pruned ${pruned.deleted.length} expired backup files`);
    }
  },
);

// Imports vacancies from a published job feed every six hours.
//
// A feed, not a scraper: LinkedIn's robots.txt states that automated access
// without their permission is strictly prohibited, and a scraper breaks the
// moment a site changes its markup. Set JOB_FEED_URL to any RSS, Atom or JSON
// feed you are permitted to use; with none set the import does nothing.
const feed = jobFeed({ db: getFirestore() });

exports.importJobFeed = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'Etc/UTC',
    retryCount: 2,
    timeoutSeconds: 300,
  },
  async () => {
    const result = await feed.run();
    console.log(
      result.skipped
        ? `Job feed import skipped: ${result.skipped}`
        : `Imported ${result.imported} vacancies from the job feed`,
    );
  },
);
