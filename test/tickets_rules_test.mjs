import assert from 'node:assert/strict';

// Run only against the disposable local Firestore emulator.
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host));
const project = 'demo-unix-tickets';
const database = `projects/${project}/databases/(default)`;
const base = `http://${host}/v1/${database}/documents`;
const now = Math.floor(Date.now() / 1000);

function token(uid, email) {
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    sub: uid, user_id: uid, email, email_verified: true, iat: now, exp: now + 3600,
    aud: project, iss: `https://securetoken.google.com/${project}`,
    firebase: { sign_in_provider: 'password', identities: { email: [email] } },
  })}.`;
}

// One of the five approved admin emails in firestore.rules, and an ordinary
// student who must not be able to publish or delete an event.
const admin = token('admin-1', 'amashanki191@gmail.com');
const student = token('student-1', 'student@sltc.ac.lk');

function headers(auth) {
  return { 'Content-Type': 'application/json', ...(auth ? { Authorization: `Bearer ${auth}` } : {}) };
}

/** Writes a ticket document, letting the server stamp createdAt. */
async function save(path, data, auth) {
  const fields = Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, { stringValue: value }]),
  );
  const response = await fetch(`${base}:commit`, {
    method: 'POST', headers: headers(auth), body: JSON.stringify({ writes: [{
      update: { name: `${database}/documents/${path}`, fields },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }],
    }] }),
  });
  return response.status;
}

async function remove(path, auth) {
  const response = await fetch(`${base}:commit`, {
    method: 'POST', headers: headers(auth),
    body: JSON.stringify({ writes: [{ delete: `${database}/documents/${path}` }] }),
  });
  return response.status;
}

async function read(path, auth) {
  return (await fetch(`${base}/${path}`, { headers: headers(auth) })).status;
}

const event = {
  title: 'Talent Night 2026',
  details: 'Sep 18 - Main Auditorium',
  price: 'LKR 750',
  imageUrl: '',
  postedBy: 'amashanki191@gmail.com',
};

// An admin publishes an event.
assert.equal(await save('tickets/talent-night', event, admin), 200);

// A student may browse it but may not publish one.
assert.equal(await read('tickets/talent-night', student), 200);
assert.equal(await save('tickets/student-event', event, student), 403);

// Nobody signed out gets to read the board.
assert.equal(await read('tickets/talent-night', null), 403);

// A student cannot delete someone else's event, however long it has been up.
assert.equal(await remove('tickets/talent-night', student), 403);

// An admin can delete at any time -- this is the whole point of the feature.
assert.equal(await remove('tickets/talent-night', admin), 200);
assert.equal(await read('tickets/talent-night', admin), 404);

// Field limits the admin form also enforces, so a bad write fails closed.
assert.equal(await save('tickets/empty-title', { ...event, title: '' }, admin), 403);
assert.equal(await save('tickets/long-title', { ...event, title: 'x'.repeat(151) }, admin), 403);
assert.equal(await save('tickets/long-details', { ...event, details: 'x'.repeat(201) }, admin), 403);
assert.equal(await save('tickets/long-price', { ...event, price: 'x'.repeat(41) }, admin), 403);
assert.equal(await save('tickets/long-url', { ...event, imageUrl: `https://${'x'.repeat(500)}` }, admin), 403);

// An unexpected key is refused, so nothing can smuggle extra data in.
assert.equal(await save('tickets/extra-key', { ...event, sneaky: 'yes' }, admin), 403);

console.log('tickets rules: all assertions passed');
