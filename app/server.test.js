const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('./server');

let server;
let baseUrl;

before(async () => {
  await new Promise((resolve) => {
    server = app.listen(0, '127.0.0.1', resolve);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

test('GET / returns service metadata', async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.status, 'ok');
  assert.ok(body.version);
  assert.ok(body.environment);
});

test('GET /health returns healthy (ALB / CodeDeploy health check)', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.status, 'healthy');
});

test('GET /info returns runtime info', async () => {
  const res = await fetch(`${baseUrl}/info`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.node_version, process.version);
});

test('unknown route returns 404 JSON', async () => {
  const res = await fetch(`${baseUrl}/does-not-exist`);
  assert.equal(res.status, 404);
  const body = await res.json();
  assert.equal(body.error, 'Not Found');
});
