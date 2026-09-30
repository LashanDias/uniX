'use strict';

const DAY = 24 * 60 * 60 * 1000;
class ValidationError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const fail = (code, message) => { throw new ValidationError(code, message); };
function requireOwner(post, uid) {
  if (!uid) fail('unauthenticated', 'Please sign in.');
  if (!post) fail('not-found', 'This report no longer exists.');
  if (post.userId !== uid) fail('permission-denied', 'Only the post owner can change this report.');
}
function id(value) {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(value)) fail('invalid-argument', 'Invalid item ID.');
  return value;
}
function text(value, label, max, required = true) {
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) fail('invalid-argument', `Enter a valid ${label}.`);
  return value.trim();
}
function newPost(input, uid, now) {
  if (!uid) fail('unauthenticated', 'Please sign in to publish a report.');
  if (!['lost', 'found'].includes(input.type)) fail('invalid-argument', 'Choose Lost or Found.');
  if (!['Wallet', 'Electronics', 'Keys', 'ID Card', 'Other'].includes(input.category)) fail('invalid-argument', 'Choose a valid category.');
  const images = input.images ?? [];
  if (!Array.isArray(images) || images.length > 3 || images.some(s => typeof s !== 'string' || !/^[A-Za-z0-9+/]*={0,2}$/.test(s)) || images.reduce((n,s) => n + s.length, 0) > 800000) fail('invalid-argument', 'Attach up to 3 photos, 600 KB total.');
  // Images remain in the existing report representation; reject non-image payloads.
  for (const image of images) {
    const b = Buffer.from(image, 'base64');
    const png = b.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
    const jpg = b[0] === 255 && b[1] === 216 && b[2] === 255;
    const webp = b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP';
    if (!png && !jpg && !webp) fail('invalid-argument', 'Use PNG, JPEG or WebP photos.');
  }
  return { itemId: id(input.itemId), userId: uid, type: input.type,
    title: text(input.title, 'item title', 150), location: text(input.location, 'location', 250),
    description: text(input.description ?? '', 'description', 3000, false), category: input.category, images,
    status: 'active', validationStage: 2, lastCheckAt: null, nextCheckAt: now + 2 * DAY,
    resolvedAt: null, deletedAt: null, createdAt: now, updatedAt: now, awaitingResponse: false, checkToken: null };
}
function question(post) {
  return post.type === 'found' ? `Has the owner collected your ‘${post.title}’?` : `Still looking for your ‘${post.title}’?\nYou reported this item as lost. Have you found it?`;
}
function due(post, now) {
  return !!post && post.status === 'active' && !post.deletedAt && !post.awaitingResponse && post.nextCheckAt != null && post.nextCheckAt <= now;
}
function respond(post, uid, input, now) {
  requireOwner(post, uid);
  if (!['yes', 'no', 'resolve', 'delete'].includes(input.action)) fail('invalid-argument', 'Invalid response.');
  if (post.status !== 'active' || post.deletedAt) fail('failed-precondition', 'This report is no longer active.');
  if (['yes', 'no'].includes(input.action) && (!post.awaitingResponse || !input.checkToken || input.checkToken !== post.checkToken)) fail('failed-precondition', 'This follow-up has already been answered or is not due.');
  const base = { updatedAt: now, awaitingResponse: false, checkToken: null };
  if (input.action === 'delete') return { ...base, status: 'deleted', deletedAt: now, nextCheckAt: null };
  if (input.action !== 'no') return { ...base, status: 'resolved', resolvedAt: now, nextCheckAt: null };
  const stage = { 2: 4, 4: 8, 8: 2 }[post.validationStage];
  if (!stage) fail('failed-precondition', 'Invalid follow-up stage.');
  return { ...base, validationStage: stage, nextCheckAt: now + stage * DAY };
}

// Inject Firestore and its Timestamp type so tests exercise these exact transactions.
function repository(db, Timestamp) {
  const dateKeys = ['lastCheckAt','nextCheckAt','resolvedAt','deletedAt','createdAt','updatedAt'];
  const encode = data => Object.fromEntries(Object.entries(data).map(([k,v]) => [k, dateKeys.includes(k) && v != null ? Timestamp.fromMillis(v) : v]));
  const decode = data => data && Object.fromEntries(Object.entries(data).map(([k,v]) => [k, dateKeys.includes(k) && v != null ? v.toMillis() : v]));
  const postRef = itemId => db.collection('lostFound').doc(id(itemId));
  const notificationRef = (uid, itemId) => db.collection('users').doc(uid).collection('notifications').doc(`lostFound_${itemId}`);
  return {
    async create(uid, input, now = Date.now()) {
      const post = newPost(input, uid, now);
      return db.runTransaction(async tx => {
        const ref = postRef(post.itemId);
        const existing = await tx.get(ref);
        if (existing.exists) { requireOwner(existing.data(), uid); return { itemId: ref.id }; }
        tx.create(ref, encode(post));
        return { itemId: ref.id };
      });
    },
    async answer(uid, input, now = Date.now()) {
      const ref = postRef(input.itemId);
      return db.runTransaction(async tx => {
        const snapshot = await tx.get(ref);
        const post = decode(snapshot.data());
        const patch = respond(post, uid, input, now);
        tx.update(ref, encode(patch));
        tx.delete(notificationRef(uid, ref.id));
        return { status: patch.status ?? 'active', validationStage: patch.validationStage ?? post.validationStage };
      });
    },
    async enqueue(itemId, now = Date.now()) {
      return db.runTransaction(async tx => {
        const ref = postRef(itemId);
        const snapshot = await tx.get(ref);
        const post = decode(snapshot.data());
        if (!due(post, now)) return false;
        const checkToken = `${post.itemId}_${post.validationStage}_${post.nextCheckAt}`;
        tx.update(ref, encode({ awaitingResponse: true, checkToken, lastCheckAt: now, nextCheckAt: null, updatedAt: now }));
        tx.set(notificationRef(post.userId, itemId), { kind: 'lostFoundValidation', itemId, userId: post.userId, checkToken, message: question(post), createdAt: Timestamp.fromMillis(now) });
        return true;
      });
    },
    async runDue(now = Date.now()) {
      // Process in bounded pages. Queued items leave this query, so outages catch up.
      for (let page = 0; page < 20; page++) {
        const batch = await db.collection('lostFound').where('status', '==', 'active').where('awaitingResponse', '==', false).where('nextCheckAt', '<=', Timestamp.fromMillis(now)).orderBy('nextCheckAt').limit(100).get();
        if (batch.empty) break;
        await Promise.all(batch.docs.map(doc => this.enqueue(doc.id, now)));
        if (batch.size < 100) break;
      }
    },
    async cleanup(itemId, previousOwner) {
      if (!previousOwner) return;
      await db.runTransaction(async tx => {
        const post = await tx.get(postRef(itemId));
        const data = post.data();
        if (!data || data.status !== 'active' || data.deletedAt) tx.delete(notificationRef(previousOwner, itemId));
      });
    },
  };
}
module.exports = { DAY, ValidationError, newPost, respond, due, question, repository };
