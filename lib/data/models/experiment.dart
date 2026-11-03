// lib/data/models/experiment.dart

enum ExperimentStatus { active, completed }

class Experiment {
  const Experiment({
    required this.id,
    required this.title,
    required this.habit,
    required this.hypothesis,
    required this.metricLabel,
    required this.unit,
    required this.lowerIsBetter,
    required this.status,
    required this.dayNumber,
    required this.totalDays,
    required this.checkinsDone,
    required this.baseline,
    required this.current,
    required this.decimals,
    required this.summary,
  });

  final String id;
  final String title;
  final String habit;
  final String hypothesis;
  final String metricLabel;
  final String unit;
  final bool lowerIsBetter;
  final ExperimentStatus status;
  final int dayNumber;
  final int totalDays;
  final int checkinsDone;

  /// Average before the experiment started.
  final double baseline;

  /// Average since it started.
  final double current;
  final int decimals;
  final String summary;

  bool get isActive => status == ExperimentStatus.active;
  double get progress => (dayNumber / totalDays).clamp(0.0, 1.0);
  double get change => current - baseline;
  double get percentChange => baseline == 0 ? 0 : change / baseline * 100;

  /// True when the metric moved the way the habit was meant to move it.
  bool get improved => lowerIsBetter ? change < 0 : change > 0;

  String formatValue(double v) => '${v.toStringAsFixed(decimals)} $unit';

  String get changeLabel {
    final sign = change >= 0 ? '+' : '-';
    return '$sign${change.abs().toStringAsFixed(decimals)} $unit';
  }
}
