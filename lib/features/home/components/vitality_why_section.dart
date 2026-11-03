// lib/features/home/components/vitality_why_section.dart
//
// Explains a day's Vitality Age from what the server recorded for that day: each
// group's share of the risk index, how recent the inputs are, and confidence.

import 'package:flutter/material.dart';

import '../../../data/models/vitality_metrics.dart';

class VitalityWhySection extends StatelessWidget {
  const VitalityWhySection({
    super.key,
    required this.why,
    required this.vitalityAge,
    required this.chronoAge,
    this.confidence,
  });

  final VitalityWhy why;
  final double vitalityAge;
  final double chronoAge;
  final int? confidence;

  String get _gapLine {
    final gap = chronoAge - vitalityAge;
    final age = chronoAge.toStringAsFixed(0);
    if (gap.abs() < 0.05) return 'Right at your age of $age.';
    final years = gap.abs().toStringAsFixed(1);
    return gap > 0 ? '$years years below your age of $age.' : '$years years above your age of $age.';
  }

  String _driverDetail(String key) {
    switch (key) {
      case 'recovery':
        final parts = [
          if (why.hrvMs != null) 'HRV ${why.hrvMs!.round()} ms',
          if (why.restingHrBpm != null) 'resting HR ${why.restingHrBpm!.round()} bpm',
        ];
        return parts.join(', ');
      case 'sleep':
        return why.sleepHours == null ? '' : '${why.sleepHours!.toStringAsFixed(1)} h';
      case 'activity':
        if (why.steps == null) return '';
        return why.activityFromYesterday ? 'Steps ${_commas(why.steps!)} yesterday' : 'Steps ${_commas(why.steps!)}';
      default:
        return '';
    }
  }

  static String _commas(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  String _age(String key) {
    if (key == 'steps' && why.activityFromYesterday && why.steps != null) {
      return "yesterday's total, by design";
    }
    final d = why.staleDays[key];
    if (d == null) return 'no data';
    if (d == 0) return 'today';
    if (d == 1) return 'yesterday';
    return '$d days ago';
  }

  /// One line per distinct age, so matching inputs share a line.
  List<String> get _freshnessLines {
    const names = {'sleep': 'Sleep', 'hrv': 'HRV', 'restingHr': 'Resting HR', 'steps': 'Steps'};
    final grouped = <String, List<String>>{};
    names.forEach((key, name) => (grouped[_age(key)] ??= []).add(name));
    return [for (final e in grouped.entries) '${e.value.join(', ')}: ${e.key}'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final cs = theme.colorScheme;
    final ranked = why.rankedDrivers;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(text, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Why ${vitalityAge.toStringAsFixed(1)} today",
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(_gapLine, style: tt.bodyMedium),

        heading('Main drivers'),
        Text('Share of today\'s risk index. A higher risk index raises Vitality Age.', style: tt.bodySmall),
        const SizedBox(height: 8),
        for (var i = 0; i < ranked.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        i == 0
                            ? '${VitalityWhy.groupLabel(ranked[i].key)} (largest)'
                            : VitalityWhy.groupLabel(ranked[i].key),
                        style: tt.bodyMedium?.copyWith(fontWeight: i == 0 ? FontWeight.w600 : null),
                      ),
                    ),
                    Text('${why.sharePercent(ranked[i].value)}%', style: tt.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: why.sharePercent(ranked[i].value) / 100,
                    minHeight: 6,
                    color: cs.primary,
                    backgroundColor: cs.primary.withOpacity(0.14),
                  ),
                ),
                if (_driverDetail(ranked[i].key).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(_driverDetail(ranked[i].key), style: tt.bodySmall),
                ],
              ],
            ),
          ),

        heading('Data freshness'),
        for (final line in _freshnessLines) Text(line, style: tt.bodyMedium),

        if (confidence != null) ...[
          heading('Confidence $confidence%'),
          Text(
            why.notFresh.isEmpty
                ? 'All four core inputs are present and up to date.'
                : 'Missing or out of date: ${why.notFresh.join(', ')}.',
            style: tt.bodyMedium,
          ),
        ],
      ],
    );
  }
}
