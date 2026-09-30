'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { repository, ValidationError } = require('./lost_found');
const { backups } = require('./backup');
initializeApp();
const store = repository(getFirestore(), Timestamp);
const callable = handler => onCall(async request => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
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
const backupBucket = process.env.BACKUP_BUCKET
  || `gs://${process.env.GCLOUD_PROJECT}-backups`;
const backup = backups({
  projectId: process.env.GCLOUD_PROJECT,
  bucket: backupBucket,
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
