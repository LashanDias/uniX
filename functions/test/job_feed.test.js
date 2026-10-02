'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  jobFeed,
  parseFeed,
  documentId,
  isUsable,
  jobType,
  clean,
  MAX_ITEMS,
} = require('../src/job_feed');

const RSS = `<?xml version="1.0"?>
<rss><channel>
  <item>
    <title>Software Engineering Intern</title>
    <author>Zetta B (Pvt) Ltd</author>
    <category>Kandy</category>
    <description><![CDATA[<p>Entry level role for <b>junior</b> developers.</p>]]></description>
    <link>https://example.lk/jobs/1</link>
  </item>
  <item>
    <title>Senior Python Engineer</title>
    <author>PetDesk</author>
    <category>Colombo</category>
    <description>Full stack development using Python.</description>
    <link>https://example.lk/jobs/2</link>
  </item>
</channel></rss>`;

const JSON_FEED = JSON.stringify({
  jobs: [
    {
      title: 'Data Analyst',
      company: 'Dialog Axiata',
      location: 'Colombo',
      description: 'Part-time analytics role.',
      url: 'https://example.lk/jobs/3',
    },
  ],
});

test('parses an RSS feed into vacancies', () => {
  const jobs = parseFeed(RSS);
  assert.equal(jobs.length, 2);
  assert.equal(jobs[0].title, 'Software Engineering Intern');
  assert.equal(jobs[0].company, 'Zetta B (Pvt) Ltd');
  assert.equal(jobs[0].location, 'Kandy');
  assert.equal(jobs[0].url, 'https://example.lk/jobs/1');
});

test('strips HTML and CDATA out of descriptions', () => {
  const jobs = parseFeed(RSS);
  assert.ok(!jobs[0].description.includes('<'));
  assert.ok(jobs[0].description.includes('junior'));
});

test('parses a JSON feed', () => {
  const jobs = parseFeed(JSON_FEED, 'application/json');
  assert.equal(jobs.length, 1);
  assert.equal(jobs[0].company, 'Dialog Axiata');
});

test('detects the job type from the text', () => {
  assert.equal(jobType('Software Engineering Intern'), 'Internship');
  assert.equal(jobType('Part-time tutor'), 'Part-time');
  assert.equal(jobType('Contract developer'), 'Contract');
  assert.equal(jobType('Senior Engineer'), 'Full-time');
});

test('only accepts the four types the rules allow', () => {
  const allowed = ['Full-time', 'Part-time', 'Internship', 'Contract'];
  for (const text of ['intern', 'part time', 'contract', 'anything else']) {
    assert.ok(allowed.includes(jobType(text)), text);
  }
});

test('drops an entry a student could not act on', () => {
  // No link means nowhere to apply, so showing it would waste their time.
  assert.equal(isUsable({ title: 'X', company: 'Y', url: '' }), false);
  assert.equal(isUsable({ title: '', company: 'Y', url: 'u' }), false);
  assert.equal(isUsable({ title: 'X', company: '', url: 'u' }), false);
  assert.equal(isUsable({ title: 'X', company: 'Y', url: 'u' }), true);
});

test('clean caps a field at the length the rules allow', () => {
  assert.equal(clean('a'.repeat(500), 200).length, 200);
});

test('the same posting always gets the same id', () => {
  // Otherwise every run would post the whole feed again as duplicates.
  const job = { url: 'https://example.lk/jobs/1' };
  assert.equal(documentId(job), documentId({ ...job }));
});

test('different postings get different ids', () => {
  assert.notEqual(
    documentId({ url: 'https://example.lk/jobs/1' }),
    documentId({ url: 'https://example.lk/jobs/2' }),
  );
});

test('caps how many vacancies one run can import', () => {
  const many = Array.from({ length: 200 }, (_, i) => ({
    title: `Job ${i}`,
    company: 'Co',
    url: `https://example.lk/${i}`,
  }));
  assert.equal(parseFeed(JSON.stringify(many), 'application/json').length, MAX_ITEMS);
});

test('does nothing when no feed is configured', async () => {
  const feed = jobFeed({ db: null, feedUrl: '' });
  assert.equal(feed.isConfigured, false);
  const result = await feed.run();
  assert.equal(result.imported, 0);
});

test('writes each vacancy once, in a single batch', async () => {
  const written = [];
  let committed = 0;
  const db = {
    collection: () => ({ doc: (id) => ({ id }) }),
    batch: () => ({
      set: (ref, data) => written.push({ id: ref.id, data }),
      commit: async () => { committed += 1; },
    }),
  };
  const fetchFn = async () => ({
    ok: true,
    headers: { get: () => 'application/rss+xml' },
    text: async () => RSS,
  });

  const feed = jobFeed({ db, fetchFn, feedUrl: 'https://example.lk/feed' });
  const result = await feed.run(new Date('2026-10-02T00:00:00Z'));

  assert.equal(result.imported, 2);
  assert.equal(written.length, 2);
  assert.equal(committed, 1);
  assert.equal(written[0].data.source, 'feed');
  // The rules pin these two on create, so the import must not invent them.
  assert.equal(written[0].data.matchPercentage, 0);
  assert.equal(written[0].data.logoUrl, '');
});

test('a second run updates rather than duplicating', async () => {
  const ids = [];
  const db = {
    collection: () => ({ doc: (id) => ({ id }) }),
    batch: () => ({
      set: (ref) => ids.push(ref.id),
      commit: async () => {},
    }),
  };
  const fetchFn = async () => ({
    ok: true,
    headers: { get: () => 'application/rss+xml' },
    text: async () => RSS,
  });
  const feed = jobFeed({ db, fetchFn, feedUrl: 'https://example.lk/feed' });

  await feed.run();
  const afterFirst = [...ids];
  await feed.run();

  assert.deepEqual(ids.slice(afterFirst.length), afterFirst);
});

test('raises a failing feed rather than importing nothing silently', async () => {
  const fetchFn = async () => ({ ok: false, status: 503 });
  const feed = jobFeed({ db: null, fetchFn, feedUrl: 'https://example.lk/feed' });
  await assert.rejects(() => feed.run(), /503/);
});
