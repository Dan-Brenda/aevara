// lib/features/home/sheets/info_healthy_days.dart
// Explains the Healthy Days chart: the count, what each color means, and in a demo
// session the roughest recent day.

import 'package:flutter/material.dart';

class InfoHealthyDaysSheet extends StatelessWidget {
  const InfoHealthyDaysSheet({
    super.key,
    this.healthyDays,
    this.roughestDate,
    this.roughestNote,
  });

  final int? healthyDays;
  final String? roughestDate;
  final String? roughestNote;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget color(Color c, String name, String meaning) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ': $meaning'),
                    ],
                  ),
                  style: tt.bodyMedium,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text('Healthy Days', style: tt.titleLarge)),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close)),
              ]),
              if (healthyDays != null) ...[
                Text(
                  '$healthyDays of the last 30 days were healthy.',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Each bar is one day. A taller bar means a lower risk index, which is built from '
                'recovery, sleep and activity.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('What the colors mean', style: tt.titleMedium),
              const SizedBox(height: 8),
              color(const Color(0xFF24A699), 'Healthy', 'risk index under 0.45'),
              color(const Color(0xFFF6B56B), 'Borderline', 'risk index from 0.45 to 0.55'),
              color(const Color(0xFFBF4A4A), 'Not healthy', 'risk index over 0.55'),
              Text('A faded bar means there was no data that day.', style: tt.bodySmall),
              if (roughestDate != null && roughestNote != null) ...[
                const SizedBox(height: 16),
                Text('Roughest day: $roughestDate', style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(roughestNote!, style: tt.bodyMedium),
              ],
              const SizedBox(height: 16),
              Text(
                'Hover over a bar, or press and hold it, to see that day.',
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
