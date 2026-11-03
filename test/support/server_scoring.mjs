// test/support/server_scoring.mjs
//
// Runs sample inputs through the real scoring functions in
// functions/ddc/vitality_all_in_one.js, for test/demo_scoring_parity_test.dart.
//
// The file can't be imported directly, because it starts Firebase Admin on load and
// keeps these functions private. So this lifts them out of the source text unchanged
// and runs them in a sandbox. The step order below follows runVitalityForDay.
//
// Usage: node test/support/server_scoring.mjs <input.json>
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync('functions/ddc/vitality_all_in_one.js', 'utf8');

function functionText(name) {
  const start = source.search(new RegExp(`^function ${name}\\(`, 'm'));
  if (start < 0) throw new Error(`server function not found: ${name}`);
  let depth = 0;
  let inBody = false;
  for (let i = source.indexOf(')', start); i < source.length; i++) {
    const c = source[i];
    if (c === '{') { depth++; inBody = true; }
    if (c === '}') depth--;
    if (inBody && depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unterminated function: ${name}`);
}

function constantText(name) {
  const m = new RegExp(`^const ${name}\\s*=\\s*[\\s\\S]*?;`, 'm').exec(source);
  if (!m) throw new Error(`server constant not found: ${name}`);
  return m[0];
}

const FUNCTIONS = [
  'isDateKey', 'parseDateKey', 'toKey', 'prevDateKey', 'dateKeyInTZ', 'round', 'clamp', 'clamp01', 'isNum',
  'average', 'sigmoid', 'asymSigmoid', 'stepsPctHumane', 'mvpaPctHumane', 'computeGroups', 'aggregateRisk',
  'toVitalityDeltaYears', 'blendTodayWithEMA', 'updateEMA7', 'daysBetweenKeys', 'staleDaysForMetric',
  'applyContextDampeners', 'confidence0to100_v1', 'computeDrivers',
];
const CONSTANTS = [
  'DAILY_DELTA_CAP_YEARS', 'TOTAL_DELTA_CAP_FROM_BASELINE', 'EMA7_ALPHA', 'TODAY_WEIGHT', 'EMA_WEIGHT',
  'CONF_MAX', 'CONF_CORE', 'CONF_EXTRAS_BONUS_MAX', 'CTX_PENALTIES', 'CTX_PENALTY_CAP', 'DY_NEUTRAL_RISK_DEFAULT',
];

const code = [
  ...CONSTANTS.map(constantText),
  ...FUNCTIONS.map(functionText),
  `this.server = { ${FUNCTIONS.join(', ')}, DAILY_DELTA_CAP_YEARS, TOTAL_DELTA_CAP_FROM_BASELINE, DY_NEUTRAL_RISK_DEFAULT };`,
].join('\n');

const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(code, sandbox);
const s = sandbox.server;

const { baseline, days } = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const tz = 'America/Los_Angeles';
const weights = { recovery: 0.35, sleep: 0.30, activity: 0.20, affect: 0.0 };
const pivot_risk = s.clamp(s.DY_NEUTRAL_RISK_DEFAULT, 0.20, 0.60);
const scale_years = 12;

let ema7Prev = null;
let prevAge = null;
const results = [];
for (const day of days) {
  const today = {
    hrv_rmssd_ms: day.hrv,
    rhr_bpm: day.rhr,
    sleep_total_hours: day.sleep,
    steps_count: day.steps,
    mvpa_minutes: day.mvpa,
  };
  const ema7 = s.updateEMA7(ema7Prev, today);
  const blended = {
    hrv_rmssd_ms: s.blendTodayWithEMA(ema7Prev?.hrv_rmssd_ms, today.hrv_rmssd_ms),
    rhr_bpm: s.blendTodayWithEMA(ema7Prev?.rhr_bpm, today.rhr_bpm),
    sleep_total_hours: s.blendTodayWithEMA(ema7Prev?.sleep_total_hours, today.sleep_total_hours),
    steps_count: s.blendTodayWithEMA(ema7Prev?.steps_count, today.steps_count),
    mvpa_minutes: s.blendTodayWithEMA(ema7Prev?.mvpa_minutes, today.mvpa_minutes),
    ema7_hrv: ema7Prev?.hrv_rmssd_ms,
    ema7_rhr: ema7Prev?.rhr_bpm,
  };
  const groups = s.computeGroups(blended);
  const risk = s.aggregateRisk(groups, weights);
  const drivers = s.computeDrivers(groups, weights, risk);

  const dateKey = '2026-06-15';
  const fresh = '2026-06-15T15:00:00Z';
  const confidence = s.confidence0to100_v1({
    inputs: blended,
    lastMetricUtc: { sleep_total_hours: fresh, steps_count: fresh, rhr_bpm: fresh, hrv_rmssd_ms: fresh },
    dateKey,
    tz,
    isProvisional: false,
    activity_policy: 'lag_yesterday',
    activity_from_date: '2026-06-14',
    anchorsExtrasPresence: 0,
    context: null,
  });

  const deltaRaw = s.toVitalityDeltaYears(risk, { pivot_risk, scale_years });
  const delta = s.round(deltaRaw * s.clamp(confidence / 100, 0, 1), 2);
  let age = s.round(baseline + delta, 1);
  age = s.clamp(age, baseline - s.TOTAL_DELTA_CAP_FROM_BASELINE, baseline + s.TOTAL_DELTA_CAP_FROM_BASELINE);
  if (prevAge != null) {
    const d = age - prevAge;
    if (Math.abs(d) > s.DAILY_DELTA_CAP_YEARS) age = s.round(prevAge + Math.sign(d) * s.DAILY_DELTA_CAP_YEARS, 1);
  }

  results.push({ recovery: groups.recovery, sleep: groups.sleep, activity: groups.activity, risk, drivers, confidence, delta, age });
  ema7Prev = ema7;
  prevAge = age;
}
console.log(JSON.stringify(results));
