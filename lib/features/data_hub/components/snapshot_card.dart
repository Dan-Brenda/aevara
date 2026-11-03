// lib/features/data_hub/components/snapshot_card.dart
//
// Shows a single metric snapshot with value + sync status.

import 'package:flutter/material.dart';
import '../../../core/widgets/tiles/sync_status_dot.dart';

class SnapshotCard extends StatelessWidget {
  final String title;
  final String value;
  final SyncStatus status;
  final VoidCallback? onTap;

  const SnapshotCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
              Text(value, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              SyncStatusDot(status: status),
            ],
          ),
        ),
      ),
    );
  }
}
