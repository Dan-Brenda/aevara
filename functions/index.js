// functions/index.js
// ESM barrel for Firebase Functions (Node 22 / Gen2)
// Vitality all-in-one is the single source of truth. The old split endpoints are removed.

export {
  vitalityComputeHttp,
  vitalityComputeRangeHttp,
  vitalityFinalizeDaily,
  ensureCoverageHttp,
  vitalityMethodsHttp,
} from "./ddc/vitality_all_in_one.js";

// Vendors / OAuth
export * from "./vendor/fitbit_fetch.js";
export * from "./vendor/fitbit_oauth.js";

// Notifications / Community / Misc
export * from "./notifications.js";
export * from "./community/index.js";
export { disconnectProviderCall } from "./disconnectProvider.js";
export { setIntegrationStatus } from "./setIntegrationStatus.js";
export { default as processUserExport } from "./exports/process_user_export.js";
export { cleanupExpiredExports } from "./exports/cleanup.js";
