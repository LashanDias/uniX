import assert from 'node:assert/strict';

// Run only against the disposable local Firestore emulator.
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host));
const project = 'demo-unix-recruiter';
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
const hr = token('hr-1', 'hr@company.com');
const student = token('student-1', 'student@sltc.ac.lk');
const other = token('hr-2', 'other@company.com');
function headers(auth) {
  return { 'Content-Type': 'application/json', ...(auth ? { Authorization: `Bearer ${auth}` } : {}) };
}
async function save(path, data, auth, timestamps = ['updatedAt']) {
  const fields = Object.fromEntries(Object.entries(data).map(([key, value]) =>
    [key, typeof value === 'number' ? { integerValue: String(value) } : { stringValue: value }]));
  const response = await fetch(`${base}:commit`, {
    method: 'POST', headers: headers(auth), body: JSON.stringify({ writes: [{
      update: { name: `${database}/documents/${path}`, fields },
      updateTransforms: timestamps.map((fieldPath) => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
    }] }),
  });
  return response.status;
}
assert.equal(await save('users/hr-1', { name: 'HR', email: 'hr@company.com', role: 'Recruiter' }, hr), 200);
assert.equal(await save('users/student-1', { name: 'Student', email: 'student@sltc.ac.lk', role: 'Student' }, student), 200);
assert.equal(await save('users/hr-2', { name: 'Other HR', email: 'other@company.com', role: 'Recruiter' }, other), 200);
assert.equal(await save('users/hr-2', { name: 'Other', email: 'other@company.com', role: 'Student' }, other), 403);
const vacancy = {
  title: 'Flutter Developer', company: 'Example', location: 'Colombo', type: 'Full-time',
  matchPercentage: 0, logoUrl: '', recruiterId: 'hr-1', description: 'Build apps.',
  requirements: 'Dart, Flutter and teamwork.', contactEmail: 'hr@company.com',
};
const dates = ['postedAt', 'updatedAt'];
assert.equal(await save('jobs/first', vacancy, hr, dates), 200);
assert.equal(await save('jobs/student', { ...vacancy, recruiterId: 'student-1' }, student, dates), 403);
assert.equal(await save('jobs/spoofed', vacancy, other, dates), 403);
assert.equal(await save('jobs/missing', { ...vacancy, requirements: '' }, hr, dates), 403);
assert.equal(await save('jobs/first', { ...vacancy, title: 'Changed by another user' }, other, dates), 403);
assert.equal((await fetch(`${base}/jobs/first`)).status, 403);
const response = await fetch(`${base}/jobs/first`, { headers: headers(student) });
assert.equal(response.status, 200);
const stored = await response.json();
assert.equal(stored.fields.requirements.stringValue, vacancy.requirements);
assert.equal(stored.fields.recruiterId.stringValue, 'hr-1');
console.log('Passed: recruiter profile, job publishing, student read, ownership, validation and denied writes.');
