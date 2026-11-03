// Emulator-only end-to-end test of the ship copy on Node 22. Project is demo-*, so production is unreachable.
// Fitbit and Cloud Storage are faked; everything else is the real code against the Firestore and Auth emulators.
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const P = 'demo-aevara-node22';
const FN = `http://127.0.0.1:5301/${P}/us-central1`;
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.GCLOUD_PROJECT?.startsWith('demo-')) throw new Error('refusing: not emulator');

const SRC = path.resolve(process.cwd(), 'functions');
const load = (rel) => import(pathToFileURL(path.join(SRC, rel)).href);
const { db } = await load('core/firebase_admin.js');
const { Storage } = await load('storage_for_test.mjs');
const fns = await load('index.js');

const realFetch = globalThis.fetch;
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const until = async (fn, label, ms = 45000) => {
  const end = Date.now() + ms;
  while (Date.now() < end) { const v = await fn(); if (v) return v; await wait(500); }
  throw new Error('timed out waiting for ' + label);
};
const key = (n, tz = 'America/Los_Angeles') => new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(Date.now() - n * 864e5));
const get = async (p) => (await db.doc(p).get()).data();

let pass = 0, fail = 0;
async function check(name, fn) {
  try { const note = await fn(); pass++; console.log('PASS', name, note ? `(${note})` : ''); }
  catch (e) { fail++; console.log('FAIL', name, String(e.message).replace(/\s+/g, ' ').slice(0, 220)); }
}
const post = (fn, body, headers = {}) => realFetch(`${FN}/${fn}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(body) });
const secret = { 'x-sync-secret': 'emulator-only-sync' };

async function seedUser(uid, days = 20) {
  await db.doc(`users/${uid}`).set({ first_name: 'Test', dob: '1988-01-01', dob_iso: '1988-01-01', calibration_status: 'running', calibration_day: 1 });
  for (let i = 0; i < days; i++) {
    const k = key(i), iso = `${k}T12:00:00Z`;
    await db.doc(`users/${uid}/sync_days/fitbit_${k}`).set({
      provider: 'fitbit', date_local: k,
      sleep_total_hours: 7.2 + (i % 3) * 0.2, last_sleep_total_hours_utc: iso,
      hrv_rmssd_ms: 45 + (i % 5), last_hrv_rmssd_ms_utc: iso,
      rhr_bpm: 58 + (i % 4), last_rhr_bpm_utc: iso,
      steps_count: 8000 + i * 50, last_steps_count_utc: iso,
      mvpa_minutes: 30, last_mvpa_minutes_utc: iso,
    });
  }
}

/* HTTP and scoring */
await seedUser('u1');
await check('vitalityMethodsHttp is public and returns the model', async () => {
  const r = await realFetch(`${FN}/vitalityMethodsHttp`);
  assert.equal(r.status, 200);
  const j = await r.json();
  return `engine ${j.compute_engine_version || j.methods?.compute_engine_version}`;
});
await check('vitalityComputeHttp without credentials is refused', async () => {
  assert.equal((await post('vitalityComputeHttp', { uid: 'u1' })).status, 401);
});
await check('vitalityComputeHttp scores a day at users/{uid}/days/{date}', async () => {
  const t = Date.now();
  const r = await post('vitalityComputeHttp', { uid: 'u1', date_local: key(1), force: true }, secret);
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.equal(j.ok, true);
  const d = await get(`users/u1/days/${key(1)}`);
  for (const f of ['vitality_age', 'risk_index', 'score_confidence', 'healthy_days_30', 'inputs', 'sources', 'compute_signature', 'compute_engine_version', 'wused', 'drivers', 'display', 'fresh', 'stale_days', 'ema7']) {
    assert.ok(d[f] !== undefined, `missing ${f}`);
  }
  assert.ok(Number.isFinite(d.vitality_age));
  // lag_yesterday policy: the day's activity comes from the day before it (i=2 in the seed).
  assert.equal(d.activity_policy, 'lag_yesterday');
  assert.equal(d.inputs.used.steps_count, 8100);
  return `vitality_age ${d.vitality_age}, risk ${d.risk_index}, ${Date.now() - t}ms`;
});
await check('the same inputs score the same on a second run', async () => {
  const a = await get(`users/u1/days/${key(1)}`);
  await post('vitalityComputeHttp', { uid: 'u1', date_local: key(1), force: true }, secret);
  const b = await get(`users/u1/days/${key(1)}`);
  assert.equal(b.risk_index, a.risk_index);
  assert.equal(b.vitality_age, a.vitality_age);
});
await check('vitalityComputeRangeHttp computes five days', async () => {
  const r = await post('vitalityComputeRangeHttp', { uid: 'u1', days: 5, force: true }, secret);
  const j = await r.json();
  assert.equal(r.status, 200);
  assert.equal(j.errors, 0);
  return `computed ${j.computed}`;
});
await check('ensureCoverageHttp works', async () => {
  assert.equal((await post('ensureCoverageHttp', { uid: 'u1' }, secret)).status, 200);
});

/* Callables */
const su = await (await realFetch('http://127.0.0.1:9301/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'jobs@example.test', password: 'emulator-only-pw', returnSecureToken: true }) })).json();
const call = async (fn, data) => {
  const r = await post(fn, { data }, { Authorization: `Bearer ${su.idToken}` });
  const b = await r.json();
  return { status: r.status, result: b.result, error: b.error };
};
for (const [fn, data, expect] of [
  ['getMyUsername', {}, (x) => x.ok === true],
  ['reserveUsername', { handle: 'jobs_handle' }, (x) => x.username === 'jobs_handle'],
  ['markNotificationRead', { id: 'n1' }, (x) => x.ok === true],
  ['notificationsDevAdd', {}, (x) => x.ok === true],
  ['setIntegrationStatus', { providerId: 'fitbit', connected: false }, (x) => x.ok === true],
  ['fitbitFetchNowCall', { days: 1 }, (x) => x.reason === 'not_connected'],
  ['fitbitOAuthStateCall', {}, (x) => typeof x.state === 'string'],
  ['disconnectProviderCall', { providerId: 'fitbit' }, (x) => x.ok === true],
  ['buildLeaderboardsCall', {}, (x) => x.ok === true],
]) {
  await check(`callable ${fn}`, async () => {
    const r = await call(fn, data);
    assert.equal(r.status, 200, JSON.stringify(r.error));
    assert.ok(expect(r.result), JSON.stringify(r.result));
  });
}

/* Firestore triggers */
await db.doc('users/t1').set({ first_name: 'Trig', username: 'trig_handle', dob: '1990-01-01' });
await db.doc('users/t1/friends/incoming/items/f1').set({ since: 1 });
await db.doc('groups/g1').set({ name: 'G', visibility: 'public' });
await db.doc('groups/g1/members/t1').set({ role: 'member' });
await db.doc('challenges/c1').set({ name: 'C', visibility: 'public' });
await db.doc('challenges/c1/participants/t1').set({ progress: { days_ok: 0 } });
await db.doc('community_events/e1').set({ name: 'E', visibility: 'public' });
await db.doc('community_events/e1/rsvps/t1').set({ going: true });
await check('trigger startCalibrationIfMissing', async () => {
  const u = await until(async () => { const x = await get('users/t1'); return x?.calibration_status ? x : null; }, 'calibration');
  assert.equal(u.calibration_status, 'running');
  assert.equal(u.calibration_day, 1);
});
await check('trigger reserveUsernameOnCreate', async () => assert.equal((await until(() => get('usernames/trig_handle'), 'mapping')).uid, 't1'));
await check('trigger updateUsernameOnChange', async () => {
  await db.doc('users/t1').set({ username: 'trig_two' }, { merge: true });
  assert.equal((await until(() => get('usernames/trig_two'), 'new mapping')).uid, 't1');
  await until(async () => (await get('usernames/trig_handle')) === undefined, 'old mapping removed');
});
await check('trigger friendsCounters', async () => assert.ok(await until(() => get('users/t1/friends_meta/counts'), 'counts')));
const counted = async (p) => until(async () => { const d = await get(p); return Object.entries(d || {}).some(([k, v]) => /count$/i.test(k) && v === 1); }, p + ' count');
await check('trigger groupMembersCounter', () => counted('groups/g1'));
await check('trigger challengeParticipantsCounter', () => counted('challenges/c1'));
await check('trigger eventRsvpsCounter', () => counted('community_events/e1'));

/* Scheduled jobs, run directly in this Node 22 process */
await check('vitalityFinalizeDaily finalizes a provisional earlier day', async () => {
  const k = key(2);
  await db.doc(`users/f1/days/${k}`).set({ date_local: k, tz: 'America/Los_Angeles', display: { status: 'provisional' }, vitality_age: 40 });
  const out = await fns.vitalityFinalizeDaily.run({});
  assert.equal(out.ok, true);
  const d = await get(`users/f1/days/${k}`);
  assert.equal(d.display.status, 'final');
  assert.ok(d.finalized_at_utc);
  assert.equal(d.vitality_age, 40);
  return `touched ${out.daysTouched}`;
});
await check('tickCalibrationDaily advances and completes users', async () => {
  await db.doc('users/c1').set({ calibration_status: 'running', calibration_day: 3 });
  await db.doc('users/c2').set({ calibration_status: 'running', calibration_day: 14 });
  await fns.tickCalibrationDaily.run({});
  assert.equal((await get('users/c1')).calibration_day, 4);
  assert.equal((await get('users/c2')).calibration_status, 'complete');
  assert.ok((await db.collection('users/c2/notifications').get()).size >= 1, 'completion notice');
});
await check('buildLeaderboards credits each user with real steps', async () => {
  const k = key(0, 'Etc/UTC');
  await db.doc(`users/l1/days/${k}`).set({ date_local: k, inputs: { used: { steps_count: 9000 } } });
  await db.doc(`users/l2/days/${k}`).set({ date_local: k, inputs: { used: { steps_count: 4000 } } });
  await db.doc(`users/l3/days/${k}`).set({ date_local: k, steps_count: 1500 });
  const out = await fns.buildLeaderboards.run({});
  assert.equal(out.ok, true);
  const e = 'leaderboards/weekly_steps/entries';
  assert.equal((await get(`${e}/l1`))?.score, 9000);
  assert.equal((await get(`${e}/l2`))?.score, 4000);
  assert.equal((await get(`${e}/l3`))?.score, 1500);
  assert.equal(await get(`${e}/users`), undefined, 'must not credit an entry called users');
  return `users ${out.users}`;
});
await check('cleanupExpiredExports deletes an expired export', async () => {
  const deleted = [];
  const realBucket = Storage.prototype.bucket;
  Storage.prototype.bucket = () => ({ file: (p) => ({ delete: async () => deleted.push(p) }) });
  try {
    await db.doc('users/x1').set({ first_name: 'X' });
    await db.doc('users/x1/exports/j1').set({ storage_path: 'bucket/exports/x1/a.zip', expires_at_utc: new Date(Date.now() - 864e5) });
    const out = await fns.cleanupExpiredExports.run({});
    assert.equal(out.ok, true);
    assert.deepEqual(deleted, ['exports/x1/a.zip']);
    assert.equal((await get('users/x1/exports/j1')).cleaned, true);
  } finally { Storage.prototype.bucket = realBucket; }
});
await check('fitbitDailySweep pulls Fitbit data and scores it through the compute endpoint', async () => {
  const computes = [];
  let fitbitCalls = 0;
  globalThis.fetch = async (url, init) => {
    const u = String(url);
    if (u.includes('/vitalityComputeHttp')) {
      const r = await realFetch(`${FN}/vitalityComputeHttp`, init);
      computes.push(r.status);
      return r;
    }
    if (u.startsWith('https://api.fitbit.com/')) {
      fitbitCalls++;
      return new Response(JSON.stringify({
        summary: { steps: 9100, caloriesOut: 2300, distances: [{ activity: 'total', distance: 6.5 }], restingHeartRate: 57, fairlyActiveMinutes: 15, veryActiveMinutes: 20 },
        'activities-heart': [{ value: { restingHeartRate: 57 } }],
        hrv: [{ value: { dailyRmssd: 48 } }],
        sleep: [{ isMainSleep: true, minutesAsleep: 440, endTime: '2026-01-01T07:00:00.000' }],
        user: { timezone: 'America/Los_Angeles' },
      }), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }
    if (u.startsWith('http://127.0.0.1')) return realFetch(url, init);
    throw new Error('Blocked outbound request in test: ' + u);
  };
  try {
    await db.doc('users/s1').set({ first_name: 'S', dob: '1985-01-01', dob_iso: '1985-01-01', tz: 'America/Los_Angeles' });
    await db.doc('integrations/fitbit/users/s1').set({
      connected: true, access_token: 'fake-access', refresh_token: 'fake-refresh',
      expires_at_utc: new Date(Date.now() + 36e5).toISOString(), scopes: ['activity', 'sleep'],
    });
    const out = await Promise.race([fns.fitbitDailySweep.run({}), wait(240000).then(() => ({ timeout: true }))]);
    assert.ok(!out.timeout, 'sweep timed out');
    assert.equal(out.fail_count, 0);
    assert.ok(fitbitCalls > 0, 'no Fitbit calls');
    assert.ok((await db.collection('users/s1/sync_days').get()).size > 0, 'no sync_days written');
    assert.ok(computes.length > 0, 'compute never called');
    const bad = computes.filter((c) => c !== 200);
    assert.equal(bad.length, 0, `compute statuses ${[...new Set(computes)].join(',')}`);
    const scored = (await db.collection('users/s1/days').get()).docs.filter((d) => Number.isFinite(d.data().vitality_age));
    assert.ok(scored.length > 0, 'no scored days');
    return `fitbit calls ${fitbitCalls}, computes ${computes.length}, scored days ${scored.length}`;
  } finally { globalThis.fetch = realFetch; }
});

console.log(`RESULT pass=${pass} fail=${fail} node=${process.version}`);
process.exit(0);
