// lib/features/data_hub/sheets/metric_details_sheet.dart
//
// One metric's value, history and source.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/vitality_metrics.dart';

class MetricDetailsSheet extends StatefulWidget {
  const MetricDetailsSheet({super.key, required this.snapshot});

  final MetricSnapshot snapshot;

  static Future<void> show(BuildContext context, MetricSnapshot snapshot) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MetricDetailsSheet(snapshot: snapshot),
    );
  }

  @override
  State<MetricDetailsSheet> createState() => _MetricDetailsSheetState();
}

class _MetricDetailsSheetState extends State<MetricDetailsSheet> {
  int _days = 14;

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final points = s.history.sublist(s.history.length - _days);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.label, style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(s.displayWithUnit, style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('30-day average: ${s.format(s.average30)} ${s.unit}', style: tt.bodyMedium),
          const SizedBox(height: 16),
          Center(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 d')),
                ButtonSegment(value: 14, label: Text('14 d')),
                ButtonSegment(value: 30, label: Text('30 d')),
              ],
              selected: {_days},
              onSelectionChanged: (v) => setState(() => _days = v.first),
            ),
          ),
          const SizedBox(height: 16),
          _HistoryBars(points: points, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat.MMMd().format(points.first.date), style: tt.labelSmall),
              Text(DateFormat.MMMd().format(points.last.date), style: tt.labelSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(s.about, style: tt.bodyMedium),
          const SizedBox(height: 12),
          Text('Source: ${s.source}', style: tt.bodySmall),
        ],
      ),
    );
  }
}

class _HistoryBars extends StatelessWidget {
  const _HistoryBars({required this.points, required this.color});

  final List<MetricPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.value).toList();
    final hi = values.reduce(math.max);
    final lo = values.reduce(math.min);
    // Keep a visible floor so small day-to-day changes still read as bars.
    final floor = lo - (hi - lo).clamp(1.0, double.infinity) * 0.5;

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: FractionallySizedBox(
                  heightFactor: ((v - floor) / (hi - floor)).clamp(0.05, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
