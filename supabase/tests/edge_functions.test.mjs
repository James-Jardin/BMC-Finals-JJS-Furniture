// Offline handler checks. Database/provider responses are test doubles.
// Run: node --experimental-vm-modules --test supabase/tests/edge_functions.test.mjs
// These checks do not replace PostgreSQL/RLS tests or Xendit sandbox acceptance.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';
import { webcrypto } from 'node:crypto';
import { test } from 'node:test';
import vm from 'node:vm';

const functions = new URL('../functions/', import.meta.url);
const customer = {
  name: 'Test Customer', email: 'fixture@example.invalid',
  phone: '09123456789', address: 'Test address',
};
const checkout = () => ({
  request_id: 'fixture-request-0001', customer: { ...customer },
  items: [{ product_id: 1, quantity: 1, finish: '' }],
});
const json = data => new Response(JSON.stringify(data), {
  headers: { 'Content-Type': 'application/json' },
});
const clone = value => JSON.parse(JSON.stringify(value));

async function harness(name) {
  const state = {
    authValid: true, claimed: true, rpcCalls: [], queries: [], requests: [],
    order: {
      id: '10000000-0000-0000-0000-000000000001', status: 'PENDING',
      total_cents: 5723892, customer: { ...customer }, invoice_id: null,
      invoice_url: null, expires_at: new Date(Date.now() + 900000).toISOString(),
    },
  };
  state.invoice = {
    id: 'test_invoice_1', external_id: state.order.id, currency: 'PHP',
    amount: 57238.92, status: 'PENDING',
    invoice_url: 'https://checkout.xendit.co/test_invoice_1',
  };
  const env = new Map(Object.entries({
    SUPABASE_URL: 'https://supabase.example.invalid',
    SUPABASE_ANON_KEY: 'test-anon', SUPABASE_SERVICE_ROLE_KEY: 'test-service',
    XENDIT_SECRET_KEY: 'xnd_development_fixture_only',
    XENDIT_WEBHOOK_TOKEN: 'fixture-callback-token',
    RECONCILE_SECRET: 'fixture-scheduler-secret',
    ALLOWED_ORIGINS: 'http://localhost:57398',
  }));
  const admin = {
    async rpc(name, args) {
      state.rpcCalls.push({ name, args: clone(args) });
      if (state.rpc) return await state.rpc(name, args);
      if (name === 'jj_reserve_order') return { data: clone(state.order), error: null };
      if (name === 'jj_claim_invoice') return { data: state.claimed, error: null };
      return { data: null, error: null };
    },
    from(table) {
      const query = { table, operation: 'select', filters: [] };
      const builder = {
        select() { return builder; },
        update(values) { query.operation = 'update'; query.values = clone(values); return builder; },
        eq(key, value) { query.filters.push([key, value]); return builder; },
        lt(key, value) { query.filters.push([key, value]); return builder; },
        limit(value) { query.limit = value; return builder; },
        single() { query.single = true; return builder; },
        then(resolve, reject) {
          state.queries.push(clone(query));
          const result = state.query ? state.query(query) : {
            data: query.operation === 'update' ? null : query.single ? clone(state.order) : [clone(state.order)],
            error: null,
          };
          return Promise.resolve(result).then(resolve, reject);
        },
      };
      return builder;
    },
  };
  let handler;
  const context = vm.createContext({
    Request, Response, Headers, URL, AbortSignal, TextEncoder, crypto: webcrypto,
    btoa, console,
    Deno: { env: { get: key => env.get(key) }, serve: fn => { handler = fn; } },
    __createClient: (_url, key) => key === 'test-service' ? admin : {
      auth: { getUser: async () => ({
        data: { user: state.authValid ? { id: 'test-user' } : null },
        error: state.authValid ? null : new Error('Invalid session'),
      }) },
    },
    fetch: async (url, init = {}) => {
      state.requests.push({ url, method: init.method ?? 'GET',
        body: init.body ? JSON.parse(init.body) : null });
      if (state.fetch) return await state.fetch(url, init);
      return json(url.includes('?external_id=') ? [state.invoice] : state.invoice);
    },
  });
  const modules = new Map();
  async function load(url) {
    if (modules.has(url)) return modules.get(url);
    const source = url === 'supabase-test-double'
      ? 'export const createClient = globalThis.__createClient;'
      : stripTypeScriptTypes(await readFile(new URL(url), 'utf8'));
    const module = new vm.SourceTextModule(source, { context, identifier: url });
    modules.set(url, module);
    await module.link((specifier, importer) => load(specifier.startsWith('npm:')
      ? 'supabase-test-double' : new URL(specifier, importer.identifier).href));
    return module;
  }
  const module = await load(new URL(`${name}/index.ts`, functions).href);
  await module.evaluate();
  return {
    state, env,
    async request(body = checkout(), options = {}) {
      const headers = new Headers({
        Origin: 'http://localhost:57398', 'Content-Type': 'application/json',
        Authorization: 'Bearer fixture-session',
        'x-callback-token': 'fixture-callback-token',
      });
      for (const [key, value] of Object.entries(options.headers ?? {})) {
        value === null ? headers.delete(key) : headers.set(key, value);
      }
      const method = options.method ?? 'POST';
      return await handler(new Request('https://functions.example.invalid/' + name, {
        method, headers,
        ...(['GET', 'HEAD', 'OPTIONS'].includes(method) ? {} : {
          body: options.raw ?? JSON.stringify(body),
        }),
      }));
    },
  };
}

test('checkout requires a verified session before reserving stock', async () => {
  const h = await harness('create-invoice');
  assert.equal((await h.request(checkout(), { headers: { Authorization: null } })).status, 401);
  h.state.authValid = false;
  assert.equal((await h.request()).status, 401);
  assert.equal(h.state.rpcCalls.length, 0);
});

test('checkout preflight allows the configured website origin only', async () => {
  const h = await harness('create-invoice');
  const allowed = await h.request(null, { method: 'OPTIONS' });
  assert.equal(allowed.headers.get('Access-Control-Allow-Origin'), 'http://localhost:57398');
  const other = await h.request(null, { method: 'OPTIONS', headers: { Origin: 'https://other.example.invalid' } });
  assert.equal(other.headers.get('Access-Control-Allow-Origin'), null);
  assert.equal((await h.request(null, { method: 'GET' })).status, 405);
});

for (const [label, payload] of [
  ['null payload', null], ['array payload', []], ['empty cart', { ...checkout(), items: [] }],
  ['null cart item', { ...checkout(), items: [null] }],
  ['zero quantity', { ...checkout(), items: [{ product_id: 1, quantity: 0, finish: '' }] }],
  ['invalid email', { ...checkout(), customer: { ...customer, email: 'invalid' } }],
]) {
  test(`checkout rejects ${label} without reserving stock`, async () => {
    const h = await harness('create-invoice');
    assert.equal((await h.request(payload)).status, 400);
    assert.equal(h.state.rpcCalls.length, 0);
  });
}

test('malformed JSON is a client error and does not reserve stock', async () => {
  const h = await harness('create-invoice');
  assert.equal((await h.request(null, { raw: '{broken' })).status, 400);
  assert.equal(h.state.rpcCalls.length, 0);
});

test('oversized checkout body is rejected before reserving stock', async () => {
  const h = await harness('create-invoice');
  assert.equal((await h.request(null, { raw: 'x'.repeat(20001) })).status, 413);
  assert.equal(h.state.rpcCalls.length, 0);
});

test('invoice uses the reserved server total instead of tampered client prices', async () => {
  const h = await harness('create-invoice');
  const body = checkout();
  body.amount = 1;
  body.items[0].unit_price = 1;
  const response = await h.request(body);
  assert.equal(response.status, 200);
  assert.equal(h.state.requests[0].body.amount, 57238.92);
  assert.equal(h.state.requests[0].body.external_id, h.state.order.id);
  assert.deepEqual(h.state.requests[0].body.payment_methods, ['GCASH']);
  assert.equal((await response.json()).total_cents, h.state.order.total_cents);
  assert.equal(h.state.rpcCalls[0].args.p_user_id, 'test-user');
});

test('retry reuses the recorded invoice without creating another', async () => {
  const h = await harness('create-invoice');
  h.state.order.invoice_url = h.state.invoice.invoice_url;
  assert.equal((await h.request()).status, 200);
  assert.equal(h.state.requests.length, 0);
  assert.equal(h.state.rpcCalls.length, 1);
});

test('caller that does not own the invoice claim looks up the existing invoice', async () => {
  const h = await harness('create-invoice');
  h.state.claimed = false;
  assert.equal((await h.request()).status, 200);
  assert.equal(h.state.requests.length, 1);
  assert.equal(h.state.requests[0].method, 'GET');
});

test('pending invoice recovery never issues a second invoice POST', async () => {
  const h = await harness('create-invoice');
  h.state.claimed = false;
  h.state.fetch = async () => json([]);
  assert.equal((await h.request()).status, 409);
  assert.equal(h.state.requests.filter(r => r.method === 'POST').length, 0);
});

test('definite provider rejection releases the reservation as failed', async () => {
  const h = await harness('create-invoice');
  h.state.fetch = async () => new Response('Rejected', { status: 400 });
  assert.equal((await h.request()).status, 503);
  assert.equal(h.state.rpcCalls.at(-1).name, 'jj_finish_order');
  assert.equal(h.state.rpcCalls.at(-1).args.p_status, 'FAILED');
});

test('uncertain provider timeout retains stock for reconciliation', async () => {
  const h = await harness('create-invoice');
  h.state.fetch = async () => { throw new Error('Timeout'); };
  assert.equal((await h.request()).status, 503);
  assert.equal(h.state.rpcCalls.some(c => c.name === 'jj_finish_order'), false);
});

for (const [label, changes] of [
  ['wrong amount', { amount: 1 }], ['wrong currency', { currency: 'USD' }],
  ['wrong order', { external_id: 'another-order' }],
  ['missing invoice ID', { id: undefined }],
  ['untrusted checkout URL', { invoice_url: 'https://attacker.example.invalid/pay' }],
]) {
  test(`checkout refuses provider invoice with ${label}`, async () => {
    const h = await harness('create-invoice');
    Object.assign(h.state.invoice, changes);
    assert.equal((await h.request()).status, 503);
    assert.equal(h.state.queries.some(q => q.operation === 'update'), false);
  });
}

test('live Xendit credentials are rejected without calling the provider', async () => {
  const h = await harness('create-invoice');
  h.env.set('XENDIT_SECRET_KEY', 'xnd_production_fixture_only');
  assert.equal((await h.request()).status, 503);
  assert.equal(h.state.requests.length, 0);
});

test('webhook rejects a wrong callback token before touching the order', async () => {
  const h = await harness('xendit-webhook');
  assert.equal((await h.request({}, { headers: { 'x-callback-token': 'wrong' } })).status, 401);
  assert.equal(h.state.queries.length, 0);
  assert.equal(h.state.requests.length, 0);
});

test('webhook refetches provider status instead of trusting a PAID callback', async () => {
  const h = await harness('xendit-webhook');
  const payload = { id: h.state.invoice.id, external_id: h.state.order.id, status: 'PAID', amount: 1 };
  assert.equal((await h.request(payload)).status, 200);
  assert.equal(h.state.requests.length, 1);
  assert.equal(h.state.rpcCalls.length, 0);
});

test('verified SETTLED payment is recorded as PAID using the server total', async () => {
  const h = await harness('xendit-webhook');
  h.state.invoice.status = 'SETTLED';
  assert.equal((await h.request({ id: h.state.invoice.id, external_id: h.state.order.id })).status, 200);
  assert.deepEqual(h.state.rpcCalls[0], { name: 'jj_finish_order', args: {
    p_order_id: h.state.order.id, p_status: 'PAID',
    p_invoice_id: h.state.invoice.id, p_amount_cents: h.state.order.total_cents,
  } });
});

test('webhook does not acknowledge a mismatched payment amount', async () => {
  const h = await harness('xendit-webhook');
  h.state.invoice.status = 'PAID'; h.state.invoice.amount = 1;
  assert.equal((await h.request({ id: h.state.invoice.id, external_id: h.state.order.id })).status, 503);
  assert.equal(h.state.rpcCalls.length, 0);
});

test('webhook returns an error when recording a payment fails, allowing retry', async () => {
  const h = await harness('xendit-webhook');
  h.state.invoice.status = 'PAID';
  h.state.rpc = async () => ({ error: new Error('Database unavailable') });
  assert.equal((await h.request({ id: h.state.invoice.id, external_id: h.state.order.id })).status, 503);
});

test('reconciliation requires the scheduler secret', async () => {
  const h = await harness('reconcile-orders');
  assert.equal((await h.request()).status, 401);
  assert.equal(h.state.queries.length, 0);
});

test('reconciliation refetches an expiring invoice and preserves a racing payment', async () => {
  const h = await harness('reconcile-orders');
  h.state.order.invoice_id = h.state.invoice.id;
  let reads = 0;
  h.state.fetch = async (_url, init) => {
    if (init.method === 'POST') return json({});
    reads++;
    return json({ ...h.state.invoice, status: reads === 1 ? 'PENDING' : 'PAID' });
  };
  const response = await h.request(null, { headers: { Authorization: 'Bearer fixture-scheduler-secret' } });
  assert.equal(response.status, 200);
  assert.equal(h.state.rpcCalls.at(-1).args.p_status, 'PAID');
  assert.equal(h.state.requests.length, 3);
});

test('reconciliation releases an abandoned order only after a successful empty lookup', async () => {
  const h = await harness('reconcile-orders');
  h.state.fetch = async () => json([]);
  assert.equal((await h.request(null, { headers: { Authorization: 'Bearer fixture-scheduler-secret' } })).status, 200);
  assert.equal(h.state.rpcCalls.at(-1).args.p_status, 'EXPIRED');
});

test('provider lookup failure cannot release reserved stock', async () => {
  const h = await harness('reconcile-orders');
  h.state.fetch = async () => new Response('Unavailable', { status: 503 });
  assert.equal((await h.request(null, { headers: { Authorization: 'Bearer fixture-scheduler-secret' } })).status, 503);
  assert.equal(h.state.rpcCalls.length, 0);
});
