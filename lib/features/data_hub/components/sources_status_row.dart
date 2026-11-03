// lib/features/data_hub/components/sources_status_row.dart
//
// Horizontal row of provider sync status chips.

import 'package:flutter/material.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class SourcesStatusRow extends StatelessWidget {
  final Map<String, SyncStatus> sources; // providerName → status
  final ValueChanged<String>? onTap;

  const SourcesStatusRow({super.key, required this.sources, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sources.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap == null ? null : () => onTap!(e.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      SyncStatusDot(status: e.value, size: 10),
                      const SizedBox(width: 6),
                      Text(e.key, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
