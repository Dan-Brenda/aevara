// functions/test/auth_paths.test.mjs
// Local tests for the Fitbit OAuth and scheduler auth paths.
// Run from functions/:  node --test test/auth_paths.test.mjs
//
// Nothing here reaches production: Firestore, Firebase Auth, App Check and Google's
// signing certs are stubbed, ID tokens are signed with a throwaway local key (the real
// google-auth-library verification still runs), and any other outbound fetch throws.

import { after, before, beforeEach, describe, mock, test } from "node:test";
import assert from "node:assert/strict";
import { createHmac, createSign, generateKeyPairSync } from "node:crypto";

process.env.GCLOUD_PROJECT = "demo-aevara-test";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:9";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9";
delete process.env.GOOGLE_APPLICATION_CREDENTIALS;
delete process.env.SYNC_SHARED_SECRET;
delete process.env.SYNC_SECRET;

const FITBIT_SECRET = "test-fitbit-client-secret";
const SYNC_SECRET = "test-sync-secret";
process.env.FITBIT_CLIENT_ID = "test-client-id";
process.env.FITBIT_CLIENT_SECRET = FITBIT_SECRET;
process.env.FITBIT_SYNC_SECRET = SYNC_SECRET;

/* ─────────────── Network guard and fake Fitbit ─────────────── */

const realFetch = globalThis.fetch;
let fitbitCalls = [];
let fitbitResponse = null;
globalThis.fetch = async (url, init) => {
  const u = String(url);
  if (u.startsWith("http://127.0.0.1")) return realFetch(url, init);
  if (u === "https://api.fitbit.com/oauth2/token") {
    const params = Object.fromEntries(new URLSearchParams(init.body));
    fitbitCalls.push(params);
    return fitbitResponse
      ? fitbitResponse(params)
      : new Response(
          JSON.stringify({
            access_token: "new-access",
            refresh_token: "new-refresh",
            expires_in: 3600,
            scope: "activity sleep",
            user_id: "FITBIT1",
            token_type: "Bearer",
          }),
          { status: 200 }
        );
  }
  throw new Error(`Blocked outbound request in test: ${u}`);
};

/* ─────────────── Load code under test ─────────────── */

const { db, getAuth } = await import("../core/firebase_admin.js");
const { getAppCheck } = await import("firebase-admin/app-check");
const { OAuth2Client } = await import("google-auth-library");
const { default: express } = await import("express");
const { fitbitOAuthStateCall, fitbitCallback, fitbitExchange, fitbitRefresh } = await import(
  "../vendor/fitbit_oauth.js"
);
const { fitbitEnsureCoverageHttp } = await import("../vendor/fitbit_fetch.js");
const { vitalityComputeHttp, vitalityComputeRangeHttp, ensureCoverageHttp } = await import(
  "../ddc/vitality_all_in_one.js"
);

/* ─────────────── Stubs ─────────────── */

const store = new Map();
mock.method(db, "doc", (path) => ({
  path,
  async get() {
    const d = store.get(path);
    return { exists: d !== undefined, data: () => d };
  },
  async set(v, opts) {
    store.set(path, opts?.merge ? { ...store.get(path), ...v } : v);
  },
  async create(v) {
    if (store.has(path)) throw Object.assign(new Error("ALREADY_EXISTS"), { code: 6 });
    store.set(path, v);
  },
}));

mock.method(getAuth(), "verifyIdToken", async (token) => {
  const m = /^firebase-id-token:(.+)$/.exec(token);
  if (!m) throw new Error("invalid id token");
  return { uid: m[1] };
});

mock.method(getAppCheck(), "verifyToken", async (token) => {
  if (token !== "valid-app-check") throw new Error("invalid app check token");
  return { appId: "test-app" };
});

const KID = "local-test-key";
const signing = generateKeyPairSync("rsa", { modulusLength: 2048 });
const otherKey = generateKeyPairSync("rsa", { modulusLength: 2048 });
mock.method(OAuth2Client.prototype, "getFederatedSignonCertsAsync", async () => ({
  certs: { [KID]: signing.publicKey.export({ type: "spki", format: "pem" }) },
}));

function signOidc(claims, { key = signing.privateKey } = {}) {
  const now = Math.floor(Date.now() / 1000);
  const enc = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const head = enc({ alg: "RS256", kid: KID, typ: "JWT" });
  const body = enc({
    iss: "https://accounts.google.com",
    sub: "1234567890",
    email_verified: true,
    iat: now,
    exp: now + 600,
    ...claims,
  });
  const sig = createSign("RSA-SHA256").update(`${head}.${body}`).sign(key, "base64url");
  return `${head}.${body}.${sig}`;
}

/* ─────────────── Local HTTP server ─────────────── */

let server;
let base;
before(async () => {
  const app = express();
  app.use(express.json());
  const routes = {
    fitbitCallback,
    fitbitExchange,
    fitbitRefresh,
    fitbitEnsureCoverageHttp,
    vitalityComputeHttp,
    vitalityComputeRangeHttp,
    ensureCoverageHttp,
  };
  for (const [name, fn] of Object.entries(routes)) app.all(`/${name}`, fn);
  await new Promise((resolve) => {
    server = app.listen(0, "127.0.0.1", resolve);
  });
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

beforeEach(() => {
  store.clear();
  fitbitCalls = [];
  fitbitResponse = null;
  process.env.FITBIT_CLIENT_SECRET = FITBIT_SECRET;
  process.env.FITBIT_SYNC_SECRET = SYNC_SECRET;
  delete process.env.SCHEDULER_SA_EMAIL;
});

const tokensFor = (uid) => store.get(`integrations/fitbit/users/${uid}`);
const callback = (query) => fetch(`${base}/fitbitCallback?${new URLSearchParams(query)}`);
const postJson = (path, body, headers = {}) =>
  fetch(`${base}/${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify(body),
  });

async function issuedState(uid) {
  return (await fitbitOAuthStateCall.run({ auth: { uid }, data: {} })).state;
}
function stateSignedWith(secret, payload) {
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const key = createHmac("sha256", secret).update("aevara:fitbit-oauth-state:v1").digest();
  return `${body}.${createHmac("sha256", key).update(body).digest("base64url")}`;
}

/* ─────────────── fitbitOAuthStateCall ─────────────── */

describe("fitbitOAuthStateCall", () => {
  test("rejects unauthenticated callers", async () => {
    await assert.rejects(
      async () => fitbitOAuthStateCall.run({ data: { uid: "victim" } }),
      (e) => e.code === "unauthenticated"
    );
  });

  test("binds state to the caller and ignores a uid in the request", async () => {
    const res = await fitbitOAuthStateCall.run({ auth: { uid: "alice" }, data: { uid: "victim" } });
    const payload = JSON.parse(Buffer.from(res.state.split(".")[0], "base64url").toString());
    assert.equal(payload.uid, "alice");
    assert.ok(payload.exp > Date.now() && payload.exp <= Date.now() + 10 * 60 * 1000);
    assert.match(res.state, /^[A-Za-z0-9_.-]+$/);
  });
});

/* ─────────────── fitbitCallback ─────────────── */

describe("fitbitCallback", () => {
  test("real flow: signed state connects the signed-in user", async () => {
    const res = await callback({ code: "abc", state: await issuedState("alice") });
    assert.equal(res.status, 200);
    assert.equal(tokensFor("alice").access_token, "new-access");
    assert.equal(fitbitCalls[0].code, "abc");
  });

  test("ignores a uid query parameter next to a valid state", async () => {
    const res = await callback({ code: "abc", state: await issuedState("attacker"), uid: "victim" });
    assert.equal(res.status, 200);
    assert.ok(tokensFor("attacker"));
    assert.equal(tokensFor("victim"), undefined);
  });

  const rejected = {
    "uid query parameter with no state": () => ({ code: "abc", uid: "victim" }),
    "legacy unsigned state": () => ({
      code: "abc",
      state: Buffer.from(JSON.stringify({ uid: "victim" })).toString("base64url"),
    }),
    "state signed with the wrong key": () => ({
      code: "abc",
      state: stateSignedWith("wrong-secret", { uid: "victim", nonce: "n1", exp: Date.now() + 60000 }),
    }),
    "expired state": () => ({
      code: "abc",
      state: stateSignedWith(FITBIT_SECRET, { uid: "victim", nonce: "n2", exp: Date.now() - 1 }),
    }),
    "state with no expiry": () => ({
      code: "abc",
      state: stateSignedWith(FITBIT_SECRET, { uid: "victim", nonce: "n3" }),
    }),
    "garbage state": () => ({ code: "abc", state: "not.a.state" }),
  };
  for (const [name, query] of Object.entries(rejected)) {
    test(`rejects ${name}`, async () => {
      const res = await callback(query());
      assert.equal(res.status, 400);
      assert.equal(fitbitCalls.length, 0);
      assert.equal(tokensFor("victim"), undefined);
    });
  }

  test("rejects a tampered uid that keeps the original signature", async () => {
    const [body, sig] = (await issuedState("attacker")).split(".");
    const payload = JSON.parse(Buffer.from(body, "base64url").toString());
    const forged = Buffer.from(JSON.stringify({ ...payload, uid: "victim" })).toString("base64url");
    const res = await callback({ code: "abc", state: `${forged}.${sig}` });
    assert.equal(res.status, 400);
    assert.equal(fitbitCalls.length, 0);
    assert.equal(tokensFor("victim"), undefined);
  });

  test("rejects a replayed state", async () => {
    const state = await issuedState("alice");
    assert.equal((await callback({ code: "first", state })).status, 200);
    assert.equal((await callback({ code: "attacker-code", state })).status, 400);
    assert.equal(fitbitCalls.length, 1);
    assert.equal(fitbitCalls[0].code, "first");
  });

  test("fails closed when the signing secret is missing", async () => {
    const state = await issuedState("alice");
    delete process.env.FITBIT_CLIENT_SECRET;
    const res = await callback({ code: "abc", state });
    assert.equal(res.status, 500);
    assert.equal(fitbitCalls.length, 0);
    assert.equal(tokensFor("alice"), undefined);
  });

  test("does not reflect Fitbit error text into the HTML response", async () => {
    fitbitResponse = (p) =>
      new Response(JSON.stringify({ errors: [{ message: `Invalid code: ${p.code}` }] }), { status: 400 });
    const res = await callback({ code: "<script>x</script>", state: await issuedState("alice") });
    assert.equal(res.status, 500);
    assert.ok(!(await res.text()).includes("<script>"));
  });
});

/* ─────────────── fitbitExchange ─────────────── */

describe("fitbitExchange", () => {
  const body = { code: "abc", redirect_uri: "aevara://cb" };
  const asAlice = { Authorization: "Bearer firebase-id-token:alice" };

  test("rejects a request with no ID token, even with a uid in the body", async () => {
    const res = await postJson("fitbitExchange", { ...body, uid: "victim" });
    assert.equal(res.status, 401);
    assert.equal(fitbitCalls.length, 0);
    assert.equal(tokensFor("victim"), undefined);
  });

  test("rejects an invalid ID token", async () => {
    const res = await postJson("fitbitExchange", body, { Authorization: "Bearer forged" });
    assert.equal(res.status, 401);
    assert.equal(fitbitCalls.length, 0);
  });

  test("rejects a body uid that differs from the token", async () => {
    const res = await postJson("fitbitExchange", { ...body, uid: "victim" }, asAlice);
    assert.equal(res.status, 403);
    assert.equal(fitbitCalls.length, 0);
    assert.equal(tokensFor("victim"), undefined);
  });

  test("connects the token's user", async () => {
    const res = await postJson("fitbitExchange", body, asAlice);
    assert.equal(res.status, 200);
    assert.ok(tokensFor("alice"));
  });

  test("still accepts a matching body uid from existing callers", async () => {
    const res = await postJson("fitbitExchange", { ...body, uid: "alice" }, asAlice);
    assert.equal(res.status, 200);
    assert.ok(tokensFor("alice"));
  });
});

/* ─────────────── fitbitRefresh ─────────────── */

describe("fitbitRefresh", () => {
  const seed = () =>
    store.set("integrations/fitbit/users/alice", { connected: true, refresh_token: "old-refresh" });

  for (const value of [undefined, ""]) {
    test(`fails closed when FITBIT_SYNC_SECRET is ${value === undefined ? "unset" : "empty"}`, async () => {
      seed();
      if (value === undefined) delete process.env.FITBIT_SYNC_SECRET;
      else process.env.FITBIT_SYNC_SECRET = value;
      const res = await postJson("fitbitRefresh", { uid: "alice" }, { "x-sync-secret": "anything" });
      assert.equal(res.status, 503);
      assert.equal(fitbitCalls.length, 0);
    });
  }

  test("rejects a missing header", async () => {
    seed();
    assert.equal((await postJson("fitbitRefresh", { uid: "alice" })).status, 401);
    assert.equal(fitbitCalls.length, 0);
  });

  test("rejects a wrong secret", async () => {
    seed();
    const res = await postJson("fitbitRefresh", { uid: "alice" }, { "x-sync-secret": "wrong" });
    assert.equal(res.status, 401);
    assert.equal(fitbitCalls.length, 0);
  });

  test("the correct secret refreshes tokens", async () => {
    seed();
    const res = await postJson("fitbitRefresh", { uid: "alice" }, { "x-sync-secret": SYNC_SECRET });
    assert.equal(res.status, 200);
    assert.equal(fitbitCalls[0].refresh_token, "old-refresh");
    assert.equal(tokensFor("alice").refresh_token, "new-refresh");
  });
});

/* ─────────────── verifyAppCheckOrScheduler, through each gated endpoint ─────────────── */

const SCHEDULER_SA =
  process.env.TEST_SCHEDULER_SA_EMAIL || "scheduler@demo-aevara-test.iam.gserviceaccount.com";
const OTHER_SA = "anyone@some-other-project.iam.gserviceaccount.com";

// An empty body stops at the uid check, so 400 proves the gate passed without doing any work.
const PASSED_GATE = 400;

for (const name of [
  "vitalityComputeHttp",
  "vitalityComputeRangeHttp",
  "ensureCoverageHttp",
  "fitbitEnsureCoverageHttp",
]) {
  describe(`${name} gate`, () => {
    const url = () => `${base}/${name}`;
    const withBearer = (token) => postJson(name, {}, { Authorization: `Bearer ${token}` });

    test("rejects no credentials", async () => {
      assert.equal((await postJson(name, { uid: "victim" })).status, 401);
    });

    for (const value of [undefined, "", "  "]) {
      test(`fails closed for any Google token when SCHEDULER_SA_EMAIL is ${JSON.stringify(value)}`, async () => {
        if (value !== undefined) process.env.SCHEDULER_SA_EMAIL = value;
        const res = await withBearer(signOidc({ aud: url(), email: OTHER_SA }));
        assert.equal(res.status, 401);
      });
    }

    test("rejects a different service account", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      assert.equal((await withBearer(signOidc({ aud: url(), email: OTHER_SA }))).status, 401);
    });

    test("the scheduler's service account passes", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      assert.equal((await withBearer(signOidc({ aud: url(), email: SCHEDULER_SA }))).status, PASSED_GATE);
    });

    test("tolerates surrounding whitespace in the configured email", async () => {
      process.env.SCHEDULER_SA_EMAIL = ` ${SCHEDULER_SA}\r`;
      assert.equal((await withBearer(signOidc({ aud: url(), email: SCHEDULER_SA }))).status, PASSED_GATE);
    });

    test("rejects the scheduler's account with the wrong audience", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      const res = await withBearer(signOidc({ aud: "https://example.com/other", email: SCHEDULER_SA }));
      assert.equal(res.status, 401);
    });

    test("rejects the scheduler's account with an expired token", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      const old = Math.floor(Date.now() / 1000) - 7200;
      const res = await withBearer(signOidc({ aud: url(), email: SCHEDULER_SA, iat: old, exp: old + 600 }));
      assert.equal(res.status, 401);
    });

    test("rejects a token not signed by Google", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      const forged = signOidc({ aud: url(), email: SCHEDULER_SA }, { key: otherKey.privateKey });
      assert.equal((await withBearer(forged)).status, 401);
    });

    test("rejects a non-Google issuer", async () => {
      process.env.SCHEDULER_SA_EMAIL = SCHEDULER_SA;
      const res = await withBearer(signOidc({ aud: url(), email: SCHEDULER_SA, iss: "https://evil.example" }));
      assert.equal(res.status, 401);
    });

    test("App Check still passes with no scheduler configured", async () => {
      const res = await postJson(name, {}, { "X-Firebase-AppCheck": "valid-app-check" });
      assert.equal(res.status, PASSED_GATE);
    });

    test("rejects an invalid App Check token", async () => {
      const res = await postJson(name, {}, { "X-Firebase-AppCheck": "forged" });
      assert.equal(res.status, 401);
    });
  });
}
