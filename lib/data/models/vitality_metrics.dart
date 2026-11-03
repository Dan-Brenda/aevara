// lib/data/models/vitality_metrics.dart
//
// A daily wearable metric as shown on the Home and Data tabs, and the fields that
// explain a day's Vitality Age.

enum VitalityMetric { sleep, hrv, restingHr, steps }

class MetricPoint {
  const MetricPoint(this.date, this.value);
  final DateTime date;
  final double value;
}

class MetricSnapshot {
  const MetricSnapshot({
    required this.metric,
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.unit,
    required this.average30,
    required this.source,
    required this.about,
    required this.lowerIsBetter,
    required this.history,
  });

  final VitalityMetric metric;
  final String label;
  final String shortLabel;
  final double value;
  final String unit;
  final double average30;
  final String source;
  final String about;
  final bool lowerIsBetter;

  /// Last 30 values, oldest first.
  final List<MetricPoint> history;

  String format(double v) => metric == VitalityMetric.sleep
      ? v.toStringAsFixed(1)
      : metric == VitalityMetric.steps
          ? _withCommas(v.round())
          : v.round().toString();

  String get display => format(value);

  String get displayWithUnit =>
      metric == VitalityMetric.steps ? display : '$display $unit';

  static String _withCommas(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}

/// Why a day's Vitality Age is what it is. Built from fields the server writes on
/// the day doc, so a demo session and a real one fill it the same way.
class VitalityWhy {
  const VitalityWhy({
    required this.drivers,
    this.hrvMs,
    this.restingHrBpm,
    this.sleepHours,
    this.steps,
    this.staleDays = const {},
    this.activityFromYesterday = false,
  });

  /// Keys are recovery, sleep and activity. Values add up to the day's risk index.
  final Map<String, double> drivers;
  final double? hrvMs;
  final double? restingHrBpm;
  final double? sleepHours;
  final int? steps;

  /// Keys are sleep, hrv, restingHr and steps. A missing key means no data.
  final Map<String, int> staleDays;
  final bool activityFromYesterday;

  static String groupLabel(String key) => switch (key) {
        'recovery' => 'Recovery',
        'sleep' => 'Sleep',
        'activity' => 'Activity',
        _ => key,
      };

  /// Null when the doc has no drivers to explain.
  static VitalityWhy? fromDayDoc(Map<String, dynamic> doc) {
    final rawDrivers = doc['drivers'];
    if (rawDrivers is! Map) return null;
    final drivers = <String, double>{
      for (final e in rawDrivers.entries)
        if (e.value is num) e.key.toString(): (e.value as num).toDouble(),
    };
    if (drivers.values.fold<double>(0, (a, b) => a + b) <= 0) return null;

    final inputs = doc['inputs'];
    final used = inputs is Map ? inputs['used'] : null;
    double? input(String key) {
      final v = used is Map ? used[key] : null;
      return v is num ? v.toDouble() : null;
    }

    final rawStale = doc['stale_days'];
    int? stale(String key) {
      final v = rawStale is Map ? rawStale[key] : null;
      return v is num && v.isFinite ? v.toInt() : null;
    }

    final staleDays = <String, int>{
      if (stale('sleep_total_hours') != null) 'sleep': stale('sleep_total_hours')!,
      if (stale('hrv_rmssd_ms') != null) 'hrv': stale('hrv_rmssd_ms')!,
      if (stale('rhr_bpm') != null) 'restingHr': stale('rhr_bpm')!,
      if (stale('steps_count') != null) 'steps': stale('steps_count')!,
    };

    return VitalityWhy(
      drivers: drivers,
      hrvMs: input('hrv_rmssd_ms'),
      restingHrBpm: input('rhr_bpm'),
      sleepHours: input('sleep_total_hours'),
      steps: input('steps_count')?.round(),
      staleDays: staleDays,
      activityFromYesterday: doc['activity_policy'] == 'lag_yesterday',
    );
  }

  /// Largest share first.
  List<MapEntry<String, double>> get rankedDrivers =>
      drivers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  double get totalRisk => drivers.values.fold<double>(0, (a, b) => a + b);

  int sharePercent(double value) => totalRisk <= 0 ? 0 : (value / totalRisk * 100).round();

  /// True when a metric counts as up to date for confidence, as the server decides it.
  bool isFresh(String key) {
    if (key == 'steps' && activityFromYesterday && steps != null) return true;
    final d = staleDays[key];
    return d != null && d <= 1;
  }

  static const Map<String, String> _inputNames = {
    'sleep': 'Sleep',
    'hrv': 'HRV',
    'restingHr': 'Resting HR',
    'steps': 'Steps',
  };

  /// Inputs that are missing or out of date.
  List<String> get notFresh =>
      [for (final e in _inputNames.entries) if (!isFresh(e.key)) e.value];
}
