#!/usr/bin/env bash
# Runs jobs.test.mjs against one commit's functions in local emulators. Needs Java 21+ on PATH.
#
#   tools/emulator_test/run.sh <commit>
#
# Uses a demo-* project and fake values, so production can't be reached. Fitbit and Cloud Storage are faked.
set -euo pipefail

COMMIT="${1:?commit required}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || git rev-parse --show-toplevel)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git -C "$REPO" archive "$COMMIT" functions tools/emulator_test | tar -xf - -C "$WORK"
cd "$WORK"
cp tools/emulator_test/jobs.test.mjs jobs.test.mjs
(cd functions && npm ci --no-audit --no-fund --loglevel=error)
node tools/emulator_test/shim_for_emulator.cjs functions
printf '%s\n' 'export { Storage } from "@google-cloud/storage";' > functions/storage_for_test.mjs

cat > firebase.json <<'JSON'
{
  "functions": [{ "source": "functions", "codebase": "default", "ignore": ["node_modules"] }],
  "firestore": { "rules": "open.rules" },
  "emulators": {
    "functions": { "host": "127.0.0.1", "port": 5301 },
    "firestore": { "host": "127.0.0.1", "port": 8301 },
    "auth": { "host": "127.0.0.1", "port": 9301 },
    "ui": { "enabled": false },
    "singleProjectMode": true
  }
}
JSON
cat > open.rules <<'RULES'
rules_version = '2';
service cloud.firestore { match /databases/{d}/documents { match /{document=**} { allow read, write: if request.auth != null; } } }
RULES
cat > functions/.env <<'ENV'
SYNC_SHARED_SECRET=emulator-only-sync
FITBIT_SYNC_SECRET=emulator-only-sync
SCHEDULER_SA_EMAIL=scheduler@demo-aevara-node22.iam.gserviceaccount.com
EXPORTS_BUCKET=demo-aevara-node22.appspot.com
ENV
cat > functions/.secret.local <<'SECRET'
FITBIT_CLIENT_ID=emulator-only-id
FITBIT_CLIENT_SECRET=emulator-only-secret
SECRET

export GCLOUD_PROJECT=demo-aevara-node22 FITBIT_SYNC_SECRET=emulator-only-sync SYNC_SHARED_SECRET=emulator-only-sync
export FITBIT_CLIENT_ID=emulator-only-id FITBIT_CLIENT_SECRET=emulator-only-secret EXPORTS_BUCKET=demo-aevara-node22.appspot.com
firebase emulators:exec --only functions,firestore,auth --project demo-aevara-node22 "node jobs.test.mjs"
