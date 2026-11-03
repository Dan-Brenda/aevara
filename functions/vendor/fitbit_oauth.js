import { db, FieldValue, Timestamp, getAuth } from "../core/firebase_admin.js";
/**
 * Fitbit OAuth (start handled client-side via WebView) + token exchange + refresh
 * Node 22 / ESM / Firebase Functions v2
 *
 * Changes:
 *  - Uses FITBIT_REDIRECT_URI from env (fallback to Hosting URL)
 *  - Mirrors a lean status doc to users/{uid}/integrations/fitbit so the app listens there
 *  - The target uid only ever comes from a verified source: a server-signed state
 *    (web flow, see fitbitOAuthStateCall) or a Firebase ID token (fitbitExchange)
 */

import { createHash, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
const TOKEN_URL = "https://api.fitbit.com/oauth2/token";
const AUTH_URL  = "https://www.fitbit.com/oauth2/authorize";
const STATE_TTL_MS = 10 * 60 * 1000;

const DEFAULT_REDIRECT =
  process.env.FITBIT_REDIRECT_URI ||
  "https://your-firebase-project.web.app/fitbit/callback";

function basicAuthHeader() {
  const id = process.env.FITBIT_CLIENT_ID;
  const sec = process.env.FITBIT_CLIENT_SECRET;
  const b64 = Buffer.from(`${id}:${sec}`).toString("base64");
  return `Basic ${b64}`;
}

function nowPlusSeconds(sec) {
  return new Date(Date.now() + (Number(sec) || 0) * 1000).toISOString();
}

function safeEqual(a, b) {
  const hash = (v) => createHash("sha256").update(String(v)).digest();
  return timingSafeEqual(hash(a), hash(b));
}

function stateSignature(body) {
  const secret = process.env.FITBIT_CLIENT_SECRET;
  if (!secret) throw new Error("FITBIT_CLIENT_SECRET is not configured");
  const key = createHmac("sha256", secret).update("aevara:fitbit-oauth-state:v1").digest();
  return createHmac("sha256", key).update(body).digest("base64url");
}

function createSignedState(uid) {
  const body = Buffer.from(
    JSON.stringify({
      uid,
      nonce: randomBytes(16).toString("hex"),
      exp: Date.now() + STATE_TTL_MS,
    })
  ).toString("base64url");
  return `${body}.${stateSignature(body)}`;
}

/** Returns { uid, nonce, exp } for a correctly signed, unexpired state; otherwise null. */
function readSignedState(raw) {
  const [body, signature, extra] = String(raw || "").split(".");
  if (!body || !signature || extra !== undefined) return null;
  if (!safeEqual(signature, stateSignature(body))) return null;

  const obj = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
  if (!obj?.uid || !obj?.nonce || !(Number(obj?.exp) > Date.now())) return null;
  return obj;
}

/** Marks a state as used. Returns false if it was already used. */
async function consumeStateNonce({ uid, nonce, exp }) {
  try {
    await db.doc(`integrations/fitbit/oauth_states/${nonce}`).create({
      uid,
      expires_at: Timestamp.fromMillis(Number(exp)),
      used_at_utc: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    if (e?.code === 6) return false; // gRPC ALREADY_EXISTS
    throw e;
  }
}

/** Returns the uid of a valid `Authorization: Bearer <Firebase ID token>`, or null. */
async function uidFromIdToken(req) {
  const m = /^Bearer\s+(.+)$/.exec(String(req.get("authorization") || ""));
  if (!m) return null;
  try {
    return (await getAuth().verifyIdToken(m[1])).uid || null;
  } catch (e) {
    return null;
  }
}

async function fitbitTokenRequest(params) {
  const body = new URLSearchParams(params);
  const resp = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: basicAuthHeader(),
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });
  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    const msg = json?.errors?.[0]?.message || resp.statusText || "token_error";
    throw new Error(`Fitbit token error: ${msg}`);
  }
  return json;
}

async function mirrorUserIntegrationStatus(uid, patch) {
  // Lean, UI-facing status doc
  await db
    .doc(`users/${uid}/integrations/fitbit`)
    .set(
      {
        provider: "fitbit",
        updated_at_utc: FieldValue.serverTimestamp(),
        ...patch,
      },
      { merge: true }
    );
}

async function writeTokens({ uid, payload }) {
  const {
    access_token,
    refresh_token,
    expires_in,
    scope,
    user_id,
    token_type,
  } = payload;

  const scopes = String(scope || "").split(" ").filter(Boolean);
  const docRef = db.doc(`integrations/fitbit/users/${uid}`);
  const prev = (await docRef.get()).data() || {};

  await docRef.set(
    {
      connected: true,
      provider_user_id: user_id || null,
      token_type: token_type || "Bearer",
      access_token,
      refresh_token: refresh_token || null,
      scopes,
      expires_at_utc: nowPlusSeconds(expires_in || 3600),
      last_status: "ok",
      last_sync_utc: FieldValue.serverTimestamp(),
      updated_at_utc: FieldValue.serverTimestamp(),
      ...(prev?.connected ? {} : { just_connected_at_utc: FieldValue.serverTimestamp() }),
      ...(prev?.last_backfill_at_utc ? {} : { last_backfill_at_utc: null }), // set by fetcher after first backfill
    },
    { merge: true }
  );

  // Mirror a lean status doc to the user-scoped location the app reads
  await mirrorUserIntegrationStatus(uid, {
    connected: true,
    last_status: "ok",
    last_sync_utc: FieldValue.serverTimestamp(),
    scopes,
    error_msg: null,
  });

  return { scopes };
}

/** Callable: signed OAuth state for the signed-in user; the client puts it in the authorize URL. */
export const fitbitOAuthStateCall = onCall(
  { region: "us-central1", secrets: ["FITBIT_CLIENT_SECRET"] },
  (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required");
    return { state: createSignedState(uid) };
  }
);

/** GET /fitbit/callback (Hosting redirects here) */
export const fitbitCallback = onRequest(
  { region: "us-central1", secrets: ["FITBIT_CLIENT_ID", "FITBIT_CLIENT_SECRET"] },
  async (req, res) => {
    try {
      if (req.method !== "GET") return res.status(405).send("Use GET");
      const code = String(req.query.code || "");
      if (!code) return res.status(400).send("Missing code");

      const state = readSignedState(req.query.state);
      if (!state) {
        logger.warn("fitbitCallback rejected invalid or expired state");
        return res.status(400).send("This Fitbit link is invalid or expired. Please start again from the app.");
      }
      if (!(await consumeStateNonce(state))) {
        logger.warn("fitbitCallback rejected reused state", { uid: state.uid });
        return res.status(400).send("This Fitbit link was already used. Please start again from the app.");
      }
      const { uid } = state;

      const tokenJson = await fitbitTokenRequest({
        grant_type: "authorization_code",
        code,
        client_id: process.env.FITBIT_CLIENT_ID,
        redirect_uri: DEFAULT_REDIRECT,
      });
      const { scopes } = await writeTokens({ uid, payload: tokenJson });
      logger.info("Fitbit connected (web)", { uid, scopes });

      res
        .status(200)
        .set("Content-Type", "text/html")
        .send(`<!doctype html>
<html><head><meta charset="utf-8"><title>Aevara "¢ Fitbit Connected</title>
<meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="font-family: system-ui, -apple-system, Segoe UI, Roboto, 'Helvetica Neue', Arial; padding:24px;">
  <h2>Fitbit Connected âœ...</h2>
  <p>You can close this window and return to the app.</p>
</body></html>`);
    } catch (e) {
      logger.error("fitbitCallback error", { message: e?.message });
      res.status(500).send("Could not connect Fitbit. Please start again from the app.");
    }
  }
);

/** POST /fitbit/exchange (mobile flow; optional PKCE; requires a Firebase ID token) */
export const fitbitExchange = onRequest(
  { region: "us-central1", cors: true, secrets: ["FITBIT_CLIENT_ID", "FITBIT_CLIENT_SECRET"] },
  async (req, res) => {
    try {
      if (req.method !== "POST")
        return res.status(405).json({ ok: false, error: "Use POST" });

      const uid = await uidFromIdToken(req);
      if (!uid) return res.status(401).json({ ok: false, error: "Unauthorized" });

      const { code, uid: requestedUid, redirect_uri, code_verifier } = req.body || {};
      if (requestedUid && String(requestedUid) !== uid) {
        return res.status(403).json({ ok: false, error: "Forbidden" });
      }
      if (!code || !redirect_uri) {
        return res
          .status(400)
          .json({ ok: false, error: "Missing code/redirect_uri" });
      }

      const params = {
        grant_type: "authorization_code",
        code,
        client_id: process.env.FITBIT_CLIENT_ID,
        redirect_uri,
      };
      if (code_verifier) params.code_verifier = code_verifier;

      const tokenJson = await fitbitTokenRequest(params);
      const { scopes } = await writeTokens({ uid, payload: tokenJson });
      logger.info("Fitbit connected (mobile)", { uid, scopes });
      return res.status(200).json({
        ok: true,
        scopes,
        provider_user_id: tokenJson?.user_id || null,
      });
    } catch (e) {
      logger.error("fitbitExchange error", { message: e?.message });
      return res.status(500).json({ ok: false, error: String(e?.message || e) });
    }
  }
);

/** POST /fitbit/refresh (server-to-server; requires FITBIT_SYNC_SECRET, fails closed) */
export const fitbitRefresh = onRequest(
  { region: "us-central1", secrets: ["FITBIT_CLIENT_ID", "FITBIT_CLIENT_SECRET"] },
  async (req, res) => {
    try {
      if (req.method !== "POST")
        return res.status(405).json({ ok: false, error: "Use POST" });

      const SYNC_SECRET = process.env.FITBIT_SYNC_SECRET || null;
      if (!SYNC_SECRET) {
        logger.error("fitbitRefresh rejected request: FITBIT_SYNC_SECRET is not configured");
        return res.status(503).json({ ok: false, error: "Unavailable" });
      }
      const got = req.headers["x-sync-secret"];
      if (!got || !safeEqual(got, SYNC_SECRET)) {
        return res.status(401).json({ ok: false, error: "Unauthorized" });
      }

      const uid = String(req.body?.uid || "");
      if (!uid) return res.status(400).json({ ok: false, error: "Missing uid" });

      const ref = db.doc(`integrations/fitbit/users/${uid}`);
      const snap = await ref.get();
      const data = snap.exists ? snap.data() || {} : {};
      const refresh_token = data?.refresh_token;
      if (!refresh_token)
        return res.status(400).json({ ok: false, error: "No refresh_token" });

      const tokenJson = await fitbitTokenRequest({
        grant_type: "refresh_token",
        refresh_token,
        client_id: process.env.FITBIT_CLIENT_ID,
      });

      await writeTokens({ uid, payload: tokenJson });
      logger.info("Fitbit token refreshed", { uid });

      // Mirror status for the UI
      await mirrorUserIntegrationStatus(uid, {
        connected: true,
        last_status: "ok",
        last_sync_utc: FieldValue.serverTimestamp(),
        error_msg: null,
      });

      return res.status(200).json({ ok: true });
    } catch (e) {
      logger.error("fitbitRefresh error", { message: e?.message });
      return res.status(500).json({ ok: false, error: String(e?.message || e) });
    }
  }
);



