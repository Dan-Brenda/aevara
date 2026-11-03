// lib/features/experiments/experiment_detail_page.dart
import 'package:flutter/material.dart';

import '../../core/demo.dart';
import '../../data/models/experiment.dart';
import 'components/experiment_progress_bar.dart';
import 'components/experiment_result_summary.dart';
import 'sheets/how_results_calculated_sheet.dart';
import 'sheets/limitations_sheet.dart';

class ExperimentDetailPage extends StatelessWidget {
  const ExperimentDetailPage({super.key, required this.experiment});

  final Experiment experiment;

  @override
  Widget build(BuildContext context) {
    final e = experiment;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(e.isActive ? 'Active experiment' : 'Experiment result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(e.title, style: tt.headlineSmall),
          const SizedBox(height: 4),
          Text(e.habit, style: tt.bodyMedium),
          const SizedBox(height: 16),
          if (e.isActive) ...[
            ExperimentProgressBar(experiment: e),
            const SizedBox(height: 16),
          ],
          ExperimentResultSummary(experiment: e),
          const SizedBox(height: 16),
          Text('Hypothesis', style: tt.titleSmall),
          const SizedBox(height: 4),
          Text(e.hypothesis, style: tt.bodyMedium),
          const SizedBox(height: 16),
          Text('Check-ins', style: tt.titleSmall),
          const SizedBox(height: 4),
          Text('${e.checkinsDone} of ${e.dayNumber} days logged', style: tt.bodyMedium),
          const SizedBox(height: 20),
          if (e.isActive) ...[
            FilledButton.icon(
              onPressed: () => showDemoReadOnlyMessage(),
              icon: const Icon(Icons.check),
              label: const Text("Log today's check-in"),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => HowResultsCalculatedSheet.show(context),
            child: const Text('How results are calculated'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => LimitationsSheet.show(context),
            child: const Text('Limitations'),
          ),
        ],
      ),
    );
  }
}
