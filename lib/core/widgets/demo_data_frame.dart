// lib/core/widgets/demo_data_frame.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/user_providers.dart' as user_state;
import '../demo.dart';
import '../env.dart' as env;

/// Keeps a "Demo data" strip above every route and sheet during a demo session.
class DemoDataFrame extends ConsumerWidget {
  const DemoDataFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!env.DEMO_ENABLED) return child;

    ref.watch(user_state.currentUserIdProvider);
    final cs = Theme.of(context).colorScheme;

    // Laid out bottom-up so the strip paints after the routes. A route's modal
    // barrier hides anything painted before it from screen readers.
    return Column(
      verticalDirection: VerticalDirection.up,
      children: [
        Expanded(
          key: const ValueKey('demo_frame_child'),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: isDemoSession,
            child: child,
          ),
        ),
        if (isDemoSession)
          ValueListenableBuilder<String?>(
            valueListenable: demoNotice,
            builder: (context, notice, _) {
              final fg = notice == null ? cs.onTertiaryContainer : cs.onPrimary;
              return Material(
                color: notice == null ? cs.tertiaryContainer : cs.primary,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(notice == null ? Icons.science_outlined : Icons.block, size: 14, color: fg),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Semantics(
                            liveRegion: notice != null,
                            child: Text(
                              notice ??
                                  (MediaQuery.sizeOf(context).width < 360
                                      ? 'Demo data. Nothing is saved.'
                                      : 'Demo data. Sample values only, nothing is saved.'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
