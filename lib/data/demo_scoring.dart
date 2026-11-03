// lib/data/demo_scoring.dart
//
// Demo only. A port of the scoring steps in functions/ddc/vitality_all_in_one.js,
// so the demo's sample numbers relate to each other the way real ones do.
// test/demo_scoring_parity_test.dart runs the same inputs through the server's own
// functions and fails if this drifts.
//
// Left out because the sample user doesn't need them: the first-30-days ramp,
// dynamic sensitivity, slow anchors and context dampeners.
import 'dart:math' as math;

/// One day's values as the server reads them. Activity comes from the day before.
class ScoreInputs {
  const ScoreInputs({
    required this.hrvMs,
    required this.restingHrBpm,
    required this.sleepHours,
    required this.steps,
    required this.activeMinutes,
  });

  final double hrvMs;
  final double restingHrBpm;
  final double sleepHours;
  final double steps;
  final double activeMinutes;
}

class Ema7 {
  const Ema7({
    required this.hrvMs,
    required this.restingHrBpm,
    required this.sleepHours,
    required this.steps,
    required this.activeMinutes,
  });

  final double hrvMs;
  final double restingHrBpm;
  final double sleepHours;
  final double steps;
  final double activeMinutes;
}

class DayScore {
  const DayScore({
    required this.ema7,
    required this.recovery,
    required this.sleep,
    required this.activity,
    required this.risk,
    required this.drivers,
    required this.confidence,
    required this.deltaYears,
    required this.vitalityAge,
  });

  final Ema7 ema7;

  /// Group scores, 0 to 1.
  final double recovery;
  final double sleep;
  final double activity;

  /// Risk index, 0 to 1.
  final double risk;

  /// Each group's share of [risk], in risk units.
  final Map<String, double> drivers;
  final int confidence;
  final double deltaYears;
  final double vitalityAge;
}

class DemoScoring {
  const DemoScoring._();

  // Server defaults when no model config overrides them.
  static const double weightRecovery = 0.35;
  static const double weightSleep = 0.30;
  static const double weightActivity = 0.20;
  static const double pivotRisk = 0.22;
  static const double scaleYears = 12;
  static const double dailyCapYears = 1.25;
  static const double totalCapYears = 10;

  static const double _ema7Alpha = 2 / (7 + 1);
  static const double _todayWeight = 0.70;
  static const double _emaWeight = 0.30;

  // Points each up-to-date core input adds to confidence.
  static const int confidenceSleep = 30;
  static const int confidenceHrv = 21;
  static const int confidenceSteps = 20;
  static const int confidenceRestingHr = 14;

  /// Matches JavaScript's Math.round, which rounds halves up.
  static double _round(double x, int digits) {
    final p = math.pow(10, digits).toDouble();
    return (x * p + 0.5).floorToDouble() / p;
  }

  static double _clamp01(double x) => x.clamp(0.0, 1.0);
  static double _sigmoid(double x) => 1 / (1 + math.exp(-x));

  static double _blend(double? prev, double today) =>
      prev == null ? today : _round(_emaWeight * prev + _todayWeight * today, 3);

  static double _updateEma(double? prev, double x) =>
      prev == null ? _round(x, 3) : _round(prev + _ema7Alpha * (x - prev), 3);

  static DayScore scoreDay({
    required ScoreInputs inputs,
    required Ema7? previousEma,
    required double? previousVitalityAge,
    required double baselineVitalityAge,
  }) {
    final ema7 = Ema7(
      hrvMs: _updateEma(previousEma?.hrvMs, inputs.hrvMs),
      restingHrBpm: _updateEma(previousEma?.restingHrBpm, inputs.restingHrBpm),
      sleepHours: _updateEma(previousEma?.sleepHours, inputs.sleepHours),
      steps: _updateEma(previousEma?.steps, inputs.steps),
      activeMinutes: _updateEma(previousEma?.activeMinutes, inputs.activeMinutes),
    );

    final hrv = _blend(previousEma?.hrvMs, inputs.hrvMs);
    final rhr = _blend(previousEma?.restingHrBpm, inputs.restingHrBpm);
    final sleepHours = _blend(previousEma?.sleepHours, inputs.sleepHours);
    final steps = _blend(previousEma?.steps, inputs.steps);
    final activeMinutes = _blend(previousEma?.activeMinutes, inputs.activeMinutes);

    // Recovery compares against the previous average, with the server's defaults on day one.
    final baseHrv = previousEma?.hrvMs ?? 50;
    final baseRhr = previousEma?.restingHrBpm ?? 65;
    final hrvP = _clamp01(_sigmoid((math.log(hrv) - math.log(baseHrv)) / 0.35));
    final rhrP = _clamp01(_sigmoid((baseRhr - rhr) / 6.0));
    final recovery = math.max(0.05, (hrvP + rhrP) / 2);

    final sleepWidth = sleepHours < 7.5 ? 1.6 : 2.2;
    final sleep = math.max(0.05, _clamp01(_sigmoid((sleepHours - 7.5) / sleepWidth)));

    final stepsP = _clamp01(1 - math.exp(-steps / 6500));
    final activeP = _clamp01(1 - math.exp(-activeMinutes / 30));
    var activity = activeMinutes == 0 ? stepsP : 0.7 * stepsP + 0.3 * activeP;
    if (activeMinutes == 0 && steps >= 7500) activity = math.max(activity, 0.40);

    const totalWeight = weightRecovery + weightSleep + weightActivity;
    final score = (recovery * weightRecovery + sleep * weightSleep + activity * weightActivity) / totalWeight;
    final risk = _round(_clamp01(1 - score), 3);

    final rawDrivers = <String, double>{
      'recovery': (1 - recovery) * (weightRecovery / totalWeight),
      'sleep': (1 - sleep) * (weightSleep / totalWeight),
      'activity': (1 - activity) * (weightActivity / totalWeight),
    };
    final rawSum = rawDrivers.values.reduce((a, b) => a + b);
    final drivers = rawSum > 0
        ? rawDrivers.map((k, v) => MapEntry(k, _round(risk * (v / rawSum), 3)))
        : <String, double>{};

    // Every core input is present and up to date in the sample data.
    const confidence = confidenceSleep + confidenceHrv + confidenceSteps + confidenceRestingHr;

    final deltaRaw = _round((risk - pivotRisk) * scaleYears, 2);
    final delta = _round(deltaRaw * (confidence / 100), 2);

    var age = _round(baselineVitalityAge + delta, 1);
    age = age.clamp(baselineVitalityAge - totalCapYears, baselineVitalityAge + totalCapYears);
    if (previousVitalityAge != null) {
      final d = age - previousVitalityAge;
      if (d.abs() > dailyCapYears) {
        age = _round(previousVitalityAge + d.sign * dailyCapYears, 1);
      }
    }

    return DayScore(
      ema7: ema7,
      recovery: recovery,
      sleep: sleep,
      activity: activity,
      risk: risk,
      drivers: drivers,
      confidence: confidence,
      deltaYears: delta,
      vitalityAge: age,
    );
  }
}
