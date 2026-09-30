'use strict';

/**
 * Daily Firestore backup to Cloud Storage.
 *
 * Firestore keeps no copy of a document you delete or overwrite. A bad rule,
 * a wrong admin click or a buggy script can lose data with nothing to restore
 * from, so the database is exported once a day and old exports are pruned.
 *
 * Exports are managed by Firestore itself rather than read document by
 * document, so the cost does not grow with the size of the database and the
 * export is consistent.
 */

const { FirestoreAdminClient } = require('@google-cloud/firestore').v1;

/** Collections worth keeping. Empty means the whole database. */
const COLLECTIONS = [];

/** How many daily exports to keep before pruning. */
const KEEP_DAYS = 30;

/** Folder name for a backup taken at [at], e.g. `2026-10-01`. */
function folderFor(at) {
  return at.toISOString().slice(0, 10);
}

/**
 * Whether a backup folder is older than [keepDays].
 *
 * Folder names are ISO dates, so a string compare against the cutoff date is
 * enough and avoids parsing every name.
 */
function isExpired(folderName, now, keepDays = KEEP_DAYS) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(folderName)) return false;
  const cutoff = new Date(now.getTime() - keepDays * 24 * 60 * 60 * 1000);
  return folderName < folderFor(cutoff);
}

/**
 * Builds the backup runner.
 *
 * @param {object} deps
 * @param {string} deps.projectId
 * @param {string} deps.bucket        destination, e.g. `gs://my-app-backups`
 * @param {object} [deps.client]      injectable for tests
 * @param {object} [deps.storage]     injectable for tests
 */
function backups({ projectId, bucket, client, storage }) {
  const admin = client ?? new FirestoreAdminClient();

  return {
    folderFor,
    isExpired,

    /** Exports the database into a dated folder under the bucket. */
    async run(now = new Date()) {
      const name = admin.databasePath(projectId, '(default)');
      const outputUriPrefix = `${bucket}/${folderFor(now)}`;
      const [response] = await admin.exportDocuments({
        name,
        outputUriPrefix,
        collectionIds: COLLECTIONS,
      });
      return { outputUriPrefix, operation: response.name ?? null };
    },

    /**
     * Deletes exports older than [KEEP_DAYS].
     *
     * Keeping every export forever turns a backup into a storage bill, and a
     * month of daily copies is enough to recover from a mistake that was not
     * noticed immediately.
     */
    async prune(now = new Date()) {
      if (!storage) return { deleted: [] };
      const bucketName = bucket.replace('gs://', '').split('/')[0];
      const [files] = await storage.bucket(bucketName).getFiles();
      const deleted = [];
      for (const file of files) {
        const folder = file.name.split('/')[0];
        if (isExpired(folder, now)) {
          await file.delete();
          deleted.push(file.name);
        }
      }
      return { deleted };
    },
  };
}

module.exports = { backups, folderFor, isExpired, KEEP_DAYS };
