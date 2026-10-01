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
 * Splits `gs://bucket/some/prefix` into its parts.
 *
 * Backups live under a prefix in the project's existing bucket, so the
 * pruner has to know where the dated folders start. Reading the first path
 * segment instead would see the prefix and never match a date.
 */
function parseBucketUri(uri) {
  const withoutScheme = uri.replace(/^gs:\/\//, '');
  const [name, ...rest] = withoutScheme.split('/').filter(Boolean);
  return { bucketName: name, prefix: rest.join('/') };
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
 * The dated folder a stored object belongs to, or null if it is not under a
 * dated backup folder.
 */
function folderOf(objectName, prefix) {
  let rest = objectName;
  if (prefix) {
    if (!objectName.startsWith(`${prefix}/`)) return null;
    rest = objectName.slice(prefix.length + 1);
  }
  const first = rest.split('/')[0];
  return first || null;
}

/**
 * Builds the backup runner.
 *
 * @param {object} deps
 * @param {string} deps.projectId
 * @param {string} deps.bucket     destination, e.g. `gs://my-bucket/backups`
 * @param {object} [deps.client]   injectable for tests
 * @param {object} [deps.storage]  injectable for tests
 */
function backups({ projectId, bucket, client, storage }) {
  const admin = client ?? new FirestoreAdminClient();
  const { bucketName, prefix } = parseBucketUri(bucket);

  return {
    folderFor,
    isExpired,
    folderOf,
    bucketName,
    prefix,

    /** Exports the database into a dated folder under the bucket. */
    async run(now = new Date()) {
      const name = admin.databasePath(projectId, '(default)');
      const outputUriPrefix = `${bucket.replace(/\/$/, '')}/${folderFor(now)}`;
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
      // Only list what is under the backup prefix, so nothing else in the
      // bucket -- user uploads live here too -- is ever considered.
      const [files] = await storage
        .bucket(bucketName)
        .getFiles(prefix ? { prefix: `${prefix}/` } : {});
      const deleted = [];
      for (const file of files) {
        const folder = folderOf(file.name, prefix);
        if (folder && isExpired(folder, now)) {
          await file.delete();
          deleted.push(file.name);
        }
      }
      return { deleted };
    },
  };
}

module.exports = {
  backups,
  folderFor,
  isExpired,
  folderOf,
  parseBucketUri,
  KEEP_DAYS,
};
