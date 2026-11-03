import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/demo.dart';
import '../../data/models/experiment.dart';
import '../../state/experiments_providers.dart';
import 'components/experiment_card.dart';
import 'experiment_detail_page.dart';
import 'sheets/what_is_experiment_sheet.dart';

class ExperimentsPage extends StatelessWidget {
  const ExperimentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (isDemoSession) return const _DemoExperiments();
    return const Center(
      child: Text('Experiments placeholder'),
    );
  }
}

class _DemoExperiments extends ConsumerWidget {
  const _DemoExperiments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final experiments = ref.watch(experimentsServiceProvider).list();
    final active = experiments.where((e) => e.isActive);
    final finished = experiments.where((e) => !e.isActive);

    Widget card(Experiment e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ExperimentCard(
            experiment: e,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ExperimentDetailPage(experiment: e)),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Experiments', style: tt.headlineSmall)),
            IconButton(
              tooltip: 'What is an experiment?',
              icon: const Icon(Icons.info_outline),
              onPressed: () => WhatIsExperimentSheet.show(context),
            ),
          ],
        ),
        Text('Test a habit, then see what it did to your own numbers.', style: tt.bodyMedium),
        const SizedBox(height: 16),
        Text('Active', style: tt.titleMedium),
        const SizedBox(height: 8),
        ...active.map(card),
        const SizedBox(height: 8),
        Text('Finished', style: tt.titleMedium),
        const SizedBox(height: 8),
        ...finished.map(card),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => showDemoReadOnlyMessage(),
          icon: const Icon(Icons.add),
          label: const Text('Start a new experiment'),
        ),
      ],
    );
  }
}
