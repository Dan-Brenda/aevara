// lib/features/home/components/metrics_row.dart
//
// Sleep, HRV, resting heart rate and steps, each opening its history.
// One row of four, or two rows of two on very narrow phones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/tiles/metric_tile.dart';
import '../../../data/models/vitality_metrics.dart';
import '../../../state/insights_providers.dart';
import '../../data_hub/sheets/metric_details_sheet.dart';

class MetricsRow extends ConsumerWidget {
  const MetricsRow({super.key});

  static const double _twoByTwoBelow = 328;

  IconData _icon(VitalityMetric m) => switch (m) {
        VitalityMetric.sleep => Icons.bedtime_outlined,
        VitalityMetric.hrv => Icons.monitor_heart_outlined,
        VitalityMetric.restingHr => Icons.favorite_border,
        VitalityMetric.steps => Icons.directions_walk,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(demoDailyProvider).snapshots();

    Widget tile(MetricSnapshot s) => MetricTile(
          icon: _icon(s.metric),
          label: s.shortLabel,
          value: s.display,
          unit: s.metric == VitalityMetric.steps ? null : s.unit,
          caption: 'avg ${s.format(s.average30)}',
          onTap: () => MetricDetailsSheet.show(context, s),
        );

    Widget row(List<MetricSnapshot> items) => Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: tile(items[i])),
            ],
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _twoByTwoBelow) return row(snapshots);
          return Column(
            children: [
              row(snapshots.sublist(0, 2)),
              const SizedBox(height: 8),
              row(snapshots.sublist(2)),
            ],
          );
        },
      ),
    );
  }
}
