'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { repository, ValidationError } = require('./lost_found');
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
