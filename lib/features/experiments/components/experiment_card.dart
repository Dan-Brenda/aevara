// lib/features/experiments/components/experiment_card.dart
import 'package:flutter/material.dart';

import '../../../data/models/experiment.dart';
import 'experiment_progress_bar.dart';

class ExperimentCard extends StatelessWidget {
  const ExperimentCard({super.key, required this.experiment, required this.onTap});

  final Experiment experiment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = experiment;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.title, style: tt.titleMedium)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 2),
              Text(e.habit, style: tt.bodySmall),
              const SizedBox(height: 12),
              if (e.isActive)
                ExperimentProgressBar(experiment: e)
              else
                Text(
                  '${e.metricLabel}: ${e.changeLabel}',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
