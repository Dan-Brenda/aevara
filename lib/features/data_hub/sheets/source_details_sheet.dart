// lib/features/data_hub/sheets/source_details_sheet.dart
//
// One wearable source's connection status and data types.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/tiles/sync_status_dot.dart';
import '../../../data/models/device_source.dart';

class SourceDetailsSheet extends StatelessWidget {
  const SourceDetailsSheet({super.key, required this.source});

  final DeviceSource source;

  static Future<void> show(BuildContext context, DeviceSource source) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SourceDetailsSheet(source: source),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lastSync = source.lastSync;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(source.name, style: tt.titleLarge)),
              SyncStatusDot(status: source.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lastSync != null
                ? 'Connected. Last synced ${DateFormat.jm().format(lastSync)}.'
                : 'Not connected in this demo.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Data it provides', style: tt.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final d in source.dataTypes) Chip(label: Text(d))],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: null,
              child: Text(source.isConnected ? 'Disconnecting is disabled in demo' : 'Connecting is disabled in demo'),
            ),
          ),
        ],
      ),
    );
  }
}
