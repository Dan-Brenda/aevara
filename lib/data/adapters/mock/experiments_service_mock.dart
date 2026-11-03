// lib/data/adapters/mock/experiments_service_mock.dart
//
// Baselines and results are real averages over DemoData's history, so they agree
// with the Data tab's charts.
import '../../demo_data.dart';
import '../../models/experiment.dart';
import '../../services/experiments_service.dart';

class ExperimentsServiceMock implements ExperimentsService {
  const ExperimentsServiceMock();

  @override
  List<Experiment> list() => [bedtime(), walk(), caffeine()];

  Experiment bedtime() {
    const day = 9;
    final baseline = DemoData.average((d) => d.sleepHours, fromDaysAgo: day + 14, toDaysAgo: day);
    final current = DemoData.average((d) => d.sleepHours, fromDaysAgo: day);
    final draft = _experiment(
      id: 'earlier_bedtime',
      title: 'Earlier bedtime',
      habit: 'In bed by 10:30 pm on weeknights',
      hypothesis: 'A consistent, earlier bedtime will add sleep and lift recovery.',
      metricLabel: 'Average sleep',
      unit: 'h',
      lowerIsBetter: false,
      status: ExperimentStatus.active,
      dayNumber: day,
      totalDays: 21,
      checkinsDone: 8,
      baseline: baseline,
      current: current,
      decimals: 1,
    );
    return _withSummary(
      draft,
      'Day $day of 21. So far, average sleep is ${draft.formatValue(current)}, '
      'compared with ${draft.formatValue(baseline)} before you started. '
      'It\'s too early to call this a result.',
    );
  }

  Experiment walk() {
    final baseline = DemoData.average((d) => d.restingHrBpm, fromDaysAgo: 68, toDaysAgo: 40);
    final current = DemoData.average((d) => d.restingHrBpm, fromDaysAgo: 40, toDaysAgo: 12);
    final draft = _experiment(
      id: 'morning_walk',
      title: '10-minute morning walk',
      habit: 'Walk for 10 minutes before breakfast',
      hypothesis: 'A short daily walk will lower resting heart rate over four weeks.',
      metricLabel: 'Average resting heart rate',
      unit: 'bpm',
      lowerIsBetter: true,
      status: ExperimentStatus.completed,
      dayNumber: 28,
      totalDays: 28,
      checkinsDone: 25,
      baseline: baseline,
      current: current,
      decimals: 1,
    );
    return _withSummary(draft, _resultSummary(draft, 25));
  }

  Experiment caffeine() {
    final baseline = DemoData.average((d) => d.hrvMs, fromDaysAgo: 72, toDaysAgo: 58);
    final current = DemoData.average((d) => d.hrvMs, fromDaysAgo: 58, toDaysAgo: 44);
    final draft = _experiment(
      id: 'no_late_caffeine',
      title: 'No caffeine after 2 pm',
      habit: 'Last coffee before 2 pm',
      hypothesis: 'Cutting afternoon caffeine will raise overnight HRV.',
      metricLabel: 'Average HRV',
      unit: 'ms',
      lowerIsBetter: false,
      status: ExperimentStatus.completed,
      dayNumber: 14,
      totalDays: 14,
      checkinsDone: 12,
      baseline: baseline,
      current: current,
      decimals: 1,
    );
    return _withSummary(draft, _resultSummary(draft, 12));
  }

  String _resultSummary(Experiment e, int checkins) {
    final moved = e.change.abs().toStringAsFixed(e.decimals);
    final metric = e.metricLabel[0].toLowerCase() + e.metricLabel.substring(1);
    if (e.percentChange.abs() < 1.0) {
      return 'No clear change: $metric moved by $moved ${e.unit}, which is within normal day-to-day variation. '
          'You logged $checkins of ${e.totalDays} days.';
    }
    final direction = e.change < 0 ? 'fell' : 'rose';
    return 'While you kept this habit, $metric $direction by $moved ${e.unit}. '
        'You logged $checkins of ${e.totalDays} days.';
  }

  Experiment _withSummary(Experiment e, String summary) => _experiment(
        id: e.id,
        title: e.title,
        habit: e.habit,
        hypothesis: e.hypothesis,
        metricLabel: e.metricLabel,
        unit: e.unit,
        lowerIsBetter: e.lowerIsBetter,
        status: e.status,
        dayNumber: e.dayNumber,
        totalDays: e.totalDays,
        checkinsDone: e.checkinsDone,
        baseline: e.baseline,
        current: e.current,
        decimals: e.decimals,
        summary: summary,
      );

  Experiment _experiment({
    required String id,
    required String title,
    required String habit,
    required String hypothesis,
    required String metricLabel,
    required String unit,
    required bool lowerIsBetter,
    required ExperimentStatus status,
    required int dayNumber,
    required int totalDays,
    required int checkinsDone,
    required double baseline,
    required double current,
    required int decimals,
    String summary = '',
  }) =>
      Experiment(
        id: id,
        title: title,
        habit: habit,
        hypothesis: hypothesis,
        metricLabel: metricLabel,
        unit: unit,
        lowerIsBetter: lowerIsBetter,
        status: status,
        dayNumber: dayNumber,
        totalDays: totalDays,
        checkinsDone: checkinsDone,
        baseline: baseline,
        current: current,
        decimals: decimals,
        summary: summary,
      );
}
