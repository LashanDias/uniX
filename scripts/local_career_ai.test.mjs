import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCareerServer } from './local_career_ai.mjs';

async function runWith(t, fetchModel) {
  const server = createCareerServer({model: 'test-model', fetchModel});
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  return `http://127.0.0.1:${server.address().port}`;
}

test('Local adapter sends grounded context to the local model and returns its reply', async t => {
  const url = await runWith(t, async (endpoint, options) => {
    assert.equal(endpoint, 'http://127.0.0.1:11434/api/chat');
    const body = JSON.parse(options.body);
    assert.equal(body.stream, false);
    assert.equal(body.model, 'test-model');
    assert.match(body.messages[1].content, /SQL/);
    return Response.json({message: {content: 'Practise SQL joins.'}});
  });
  const response = await fetch(`${url}/career/chat`, {method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'http://localhost:5175'},
    body: JSON.stringify({question: 'What should I learn?', context: {missingSkills: ['SQL']}})});
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), 'http://localhost:5175');
  assert.equal((await response.json()).answer, 'Practise SQL joins.');
});

test('Unavailable local model is explicit and the adapter stays healthy', async t => {
  const url = await runWith(t, async () => { throw new Error('offline'); });
  assert.equal((await (await fetch(`${url}/health`)).json()).modelAvailable, false);
  const response = await fetch(`${url}/career/chat`, {method: 'POST', body: JSON.stringify({question: 'Help', context: {}})});
  assert.equal(response.status, 503);
});

test('Rejects invalid requests and nonlocal web origins without contacting a model', async t => {
  const url = await runWith(t, () => { throw new Error('Should not be called'); });
  assert.equal((await fetch(`${url}/career/chat`, {method: 'POST', body: '{bad'})).status, 400);
  assert.equal((await fetch(`${url}/career/chat`, {method: 'POST', body: JSON.stringify({question: '', context: {}})})).status, 400);
  assert.equal((await fetch(`${url}/career/chat`, {method: 'POST', headers: {Origin: 'https://example.com'}, body: '{}'})).status, 403);
});
