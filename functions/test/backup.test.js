'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { backups, folderFor, isExpired, KEEP_DAYS } = require('../src/backup');

const NOW = new Date('2026-10-01T18:30:00Z');

test('folderFor names a backup after its date', () => {
  assert.equal(folderFor(NOW), '2026-10-01');
});

test('folders sort chronologically as plain strings', () => {
  // The retention check compares folder names directly, which is only safe
  // because an ISO date sorts the same way as the date it represents.
  const names = ['2026-10-01', '2026-09-30', '2026-01-05'];
  assert.deepEqual([...names].sort(), ['2026-01-05', '2026-09-30', '2026-10-01']);
});

test('keeps a backup taken today', () => {
  assert.equal(isExpired('2026-10-01', NOW), false);
});

test('keeps a backup inside the retention window', () => {
  assert.equal(isExpired('2026-09-15', NOW), false);
});

test('expires a backup older than the window', () => {
  assert.equal(isExpired('2026-01-01', NOW), true);
});

test('keeps a backup exactly on the boundary', () => {
  // Deleting the oldest copy a day early would quietly shorten the window.
  const boundary = new Date(NOW.getTime() - KEEP_DAYS * 24 * 60 * 60 * 1000);
  assert.equal(isExpired(folderFor(boundary), NOW), false);
});

test('ignores anything that is not a dated folder', () => {
  // A stray file must never be deleted by the pruner.
  for (const name of ['README', 'logs', '2026-13-99', '', 'backup-2026-01-01']) {
    assert.equal(isExpired(name, NOW), false, name);
  }
});

test('run exports the whole database into a dated folder', async () => {
  const calls = [];
  const client = {
    databasePath: (project, database) => `projects/${project}/databases/${database}`,
    exportDocuments: async (request) => {
      calls.push(request);
      return [{ name: 'operations/abc' }];
    },
  };

  const backup = backups({ projectId: 'demo', bucket: 'gs://demo-backups', client });
  const result = await backup.run(NOW);

  assert.equal(calls.length, 1);
  assert.equal(calls[0].name, 'projects/demo/databases/(default)');
  assert.equal(calls[0].outputUriPrefix, 'gs://demo-backups/2026-10-01');
  assert.deepEqual(calls[0].collectionIds, []);
  assert.equal(result.operation, 'operations/abc');
});

test('two runs on different days write to different folders', async () => {
  const seen = [];
  const client = {
    databasePath: () => 'projects/demo/databases/(default)',
    exportDocuments: async (request) => {
      seen.push(request.outputUriPrefix);
      return [{}];
    },
  };
  const backup = backups({ projectId: 'demo', bucket: 'gs://b', client });
  await backup.run(new Date('2026-10-01T18:30:00Z'));
  await backup.run(new Date('2026-10-02T18:30:00Z'));
  assert.deepEqual(seen, ['gs://b/2026-10-01', 'gs://b/2026-10-02']);
});

test('prune deletes only expired folders', async () => {
  const deleted = [];
  const files = [
    { name: '2026-01-01/output-0', delete: async () => deleted.push('2026-01-01/output-0') },
    { name: '2026-09-30/output-0', delete: async () => deleted.push('2026-09-30/output-0') },
    { name: 'README', delete: async () => deleted.push('README') },
  ];
  const storage = { bucket: () => ({ getFiles: async () => [files] }) };

  const backup = backups({
    projectId: 'demo',
    bucket: 'gs://demo-backups',
    client: { databasePath: () => '', exportDocuments: async () => [{}] },
    storage,
  });
  const result = await backup.prune(NOW);

  assert.deepEqual(deleted, ['2026-01-01/output-0']);
  assert.deepEqual(result.deleted, ['2026-01-01/output-0']);
});

test('prune does nothing when no storage client is configured', async () => {
  const backup = backups({
    projectId: 'demo',
    bucket: 'gs://demo-backups',
    client: { databasePath: () => '', exportDocuments: async () => [{}] },
  });
  assert.deepEqual((await backup.prune(NOW)).deleted, []);
});
