// lib/features/data_hub/components/sync_timeline.dart
//
// Newest-first list of sync and scoring events.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/device_source.dart';

class SyncTimeline extends StatelessWidget {
  final List<SyncEvent> events;

  const SyncTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                      if (i < events.length - 1)
                        Expanded(child: VerticalDivider(width: 2, color: theme.dividerColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(events[i].title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(events[i].detail, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, h:mm a').format(events[i].at),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
