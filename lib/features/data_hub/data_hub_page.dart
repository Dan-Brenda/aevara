import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/demo.dart';
import '../../core/widgets/tiles/sync_status_dot.dart';
import '../../state/insights_providers.dart';
import 'components/snapshot_card.dart';
import 'components/sources_status_row.dart';
import 'components/sync_timeline.dart';
import 'sheets/metric_details_sheet.dart';
import 'sheets/source_details_sheet.dart';

class DataHubPage extends StatelessWidget {
  const DataHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (isDemoSession) return const _DemoDataHub();
    return const Center(
      child: Text('Data Hub placeholder'),
    );
  }
}

class _DemoDataHub extends ConsumerWidget {
  const _DemoDataHub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final snapshots = ref.watch(demoDailyProvider).snapshots();
    final devices = ref.watch(demoDevicesProvider);
    final sources = devices.sources();
    final lastSync = sources.first.lastSync!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Your data', style: tt.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Last synced ${DateFormat.jm().format(lastSync)}. Tap any metric for its history.',
          style: tt.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text("Today's snapshot", style: tt.titleMedium),
        const SizedBox(height: 8),
        for (final s in snapshots) ...[
          SnapshotCard(
            title: s.label,
            value: s.displayWithUnit,
            status: SyncStatus.connected,
            onTap: () => MetricDetailsSheet.show(context, s),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Text('Sources', style: tt.titleMedium),
        const SizedBox(height: 8),
        SourcesStatusRow(
          sources: {for (final s in sources) s.name: s.status},
          onTap: (name) => SourceDetailsSheet.show(
            context,
            sources.firstWhere((s) => s.name == name),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sync activity', style: tt.titleMedium),
        const SizedBox(height: 8),
        SyncTimeline(events: devices.syncEvents()),
      ],
    );
  }
}
