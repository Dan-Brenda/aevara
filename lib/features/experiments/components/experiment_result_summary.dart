// lib/features/experiments/components/experiment_result_summary.dart
//
// Before and after averages, plus the plain-language result.

import 'package:flutter/material.dart';

import '../../../data/models/experiment.dart';

class ExperimentResultSummary extends StatelessWidget {
  const ExperimentResultSummary({super.key, required this.experiment});

  final Experiment experiment;

  @override
  Widget build(BuildContext context) {
    final e = experiment;
    final tt = Theme.of(context).textTheme;

    Widget column(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.metricLabel, style: tt.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                column('Before', e.formatValue(e.baseline)),
                column(e.isActive ? 'So far' : 'During', e.formatValue(e.current)),
                column('Change', e.changeLabel),
              ],
            ),
            const SizedBox(height: 12),
            Text(e.summary, style: tt.bodyMedium),
          ],
        ),
      ),
    );
  }
}
