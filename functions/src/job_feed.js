'use strict';

/**
 * Scheduled import of vacancies from a job feed into Firestore.
 *
 * Deliberately reads a *feed* rather than scraping a careers site. A feed is
 * published to be consumed, so importing it is permitted, stable and cheap.
 * Scraping a site that has not published one is neither reliable nor allowed:
 * LinkedIn's robots.txt states that automated access without permission is
 * strictly prohibited, and a scraper also breaks the moment the site's markup
 * changes.
 *
 * Point JOB_FEED_URL at any RSS, Atom or JSON feed you are permitted to use:
 * a university careers feed, a partner board's API, or a file you publish
 * yourself. With no URL set the import does nothing.
 */

/** Vacancies to keep from one run, so a huge feed cannot flood the board. */
const MAX_ITEMS = 50;

/** Field limits, matching the jobs rules in firestore.rules. */
const LIMITS = { title: 200, company: 200, location: 200, description: 5000 };

/** Job types the app and the rules accept. */
const TYPES = ['Full-time', 'Part-time', 'Internship', 'Contract'];

/** Strips tags and collapses whitespace from feed text. */
function clean(value, max) {
  if (typeof value !== 'string') return '';
  return value
    .replace(/<!\[CDATA\[|\]\]>/g, '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}

/** Reads the first `<tag>` from an XML fragment. */
function tag(xml, name) {
  const match = xml.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, 'i'));
  return match ? match[1] : '';
}

/**
 * Picks a job type from free text.
 *
 * Feeds rarely label the type, and the rules only accept the four the app
 * offers, so anything unrecognised becomes Full-time rather than being
 * rejected.
 */
function jobType(text) {
  const lower = (text || '').toLowerCase();
  if (lower.includes('intern')) return 'Internship';
  if (lower.includes('part-time') || lower.includes('part time')) {
    return 'Part-time';
  }
  if (lower.includes('contract') || lower.includes('temporary')) {
    return 'Contract';
  }
  return 'Full-time';
}

/** Parses an RSS or Atom document into vacancy records. */
function parseXmlFeed(xml) {
  const blocks = xml.match(/<(item|entry)[\s>][\s\S]*?<\/(item|entry)>/gi) ?? [];
  return blocks.map((block) => {
    const link =
      clean(tag(block, 'link'), 500) ||
      (block.match(/<link[^>]*href="([^"]+)"/i)?.[1] ?? '');
    const description = clean(
      tag(block, 'description') || tag(block, 'summary') || tag(block, 'content'),
      LIMITS.description,
    );
    return {
      title: clean(tag(block, 'title'), LIMITS.title),
      company: clean(
        tag(block, 'author') || tag(block, 'dc:creator') || tag(block, 'source'),
        LIMITS.company,
      ),
      location: clean(tag(block, 'category'), LIMITS.location),
      description,
      url: clean(link, 500),
      type: jobType(`${tag(block, 'title')} ${description}`),
    };
  });
}

/** Parses a JSON feed into vacancy records. */
function parseJsonFeed(body) {
  const data = typeof body === 'string' ? JSON.parse(body) : body;
  const list = Array.isArray(data)
    ? data
    : data.jobs ?? data.items ?? data.results ?? [];
  return list.map((item) => {
    const description = clean(
      item.description ?? item.summary ?? '',
      LIMITS.description,
    );
    return {
      title: clean(item.title ?? item.name ?? '', LIMITS.title),
      company: clean(item.company ?? item.organisation ?? '', LIMITS.company),
      location: clean(item.location ?? item.city ?? '', LIMITS.location),
      description,
      url: clean(item.url ?? item.link ?? item.applyUrl ?? '', 500),
      type: TYPES.includes(item.type)
        ? item.type
        : jobType(`${item.title ?? ''} ${description}`),
    };
  });
}

/**
 * A vacancy is only worth importing if a student could act on it.
 *
 * Without a title, a company and a link there is nothing to show and nowhere
 * to apply, so a half-empty feed entry is dropped rather than posted.
 */
function isUsable(job) {
  return Boolean(job.title && job.company && job.url);
}

/**
 * Stable document id for a vacancy.
 *
 * Derived from the source URL, so re-running the import updates the existing
 * entry instead of posting a duplicate every day.
 */
function documentId(job) {
  let hash = 7;
  for (const unit of job.url) hash = (hash * 31 + unit.charCodeAt(0)) & 0x7fffffff;
  return `feed-${hash.toString(36)}`;
}

/** Turns raw feed text into vacancies ready for Firestore. */
function parseFeed(body, contentType = '') {
  const looksJson =
    contentType.includes('json') || body.trimStart().startsWith('{') ||
    body.trimStart().startsWith('[');
  const parsed = looksJson ? parseJsonFeed(body) : parseXmlFeed(body);
  return parsed.filter(isUsable).slice(0, MAX_ITEMS);
}

/**
 * Builds the importer.
 *
 * @param {object} deps
 * @param {object} deps.db          Firestore instance
 * @param {Function} [deps.fetchFn] injectable for tests
 * @param {string} [deps.feedUrl]
 */
function jobFeed({ db, fetchFn = fetch, feedUrl = process.env.JOB_FEED_URL }) {
  return {
    parseFeed,
    documentId,
    isUsable,
    get isConfigured() {
      return Boolean(feedUrl);
    },

    /** Fetches the feed and writes each vacancy into `jobs`. */
    async run(now = new Date()) {
      if (!feedUrl) return { imported: 0, skipped: 'no JOB_FEED_URL set' };

      const response = await fetchFn(feedUrl, {
        headers: { 'User-Agent': 'UnixApp-JobFeed/1.0' },
      });
      if (!response.ok) {
        throw new Error(`Job feed returned ${response.status}`);
      }
      const body = await response.text();
      const jobs = parseFeed(body, response.headers?.get?.('content-type') ?? '');

      // One batch, so a partial failure does not leave the board half updated.
      const batch = db.batch();
      for (const job of jobs) {
        batch.set(
          db.collection('jobs').doc(documentId(job)),
          {
            title: job.title,
            company: job.company,
            location: job.location || 'Sri Lanka',
            type: job.type,
            description: job.description || job.title,
            requirements: job.description || 'See the original posting.',
            contactEmail: '',
            applyUrl: job.url,
            source: 'feed',
            matchPercentage: 0,
            logoUrl: '',
            recruiterId: 'feed',
            postedAt: now,
            updatedAt: now,
          },
          { merge: true },
        );
      }
      await batch.commit();
      return { imported: jobs.length };
    },
  };
}

module.exports = {
  jobFeed,
  parseFeed,
  parseXmlFeed,
  parseJsonFeed,
  documentId,
  isUsable,
  jobType,
  clean,
  MAX_ITEMS,
};
