// lib/features/experiments/components/experiment_progress_bar.dart
import 'package:flutter/material.dart';

import '../../../data/models/experiment.dart';

class ExperimentProgressBar extends StatelessWidget {
  const ExperimentProgressBar({super.key, required this.experiment});

  final Experiment experiment;

  @override
  Widget build(BuildContext context) {
    final e = experiment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: e.progress, minHeight: 8),
        ),
        const SizedBox(height: 6),
        Text('Day ${e.dayNumber} of ${e.totalDays}', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
