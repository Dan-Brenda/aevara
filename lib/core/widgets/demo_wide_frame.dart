// lib/core/widgets/demo_wide_frame.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../env.dart' as env;

/// On wide screens, demo builds show the app as a centered phone-sized panel.
/// Phones and normal builds get the app unchanged.
class DemoWideFrame extends StatelessWidget {
  const DemoWideFrame({super.key, required this.child});
  final Widget child;

  static const double _wideFrom = 600;
  static const double _panelWidth = 430;
  static const double _panelMaxHeight = 900;
  static const double _margin = 24;

  @override
  Widget build(BuildContext context) {
    if (!env.DEMO_ENABLED) return child;

    final media = MediaQuery.of(context);
    if (media.size.width < _wideFrom) return child;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final height = math.min(media.size.height - _margin * 2, _panelMaxHeight);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(cs.primary.withOpacity(0.16), theme.scaffoldBackgroundColor),
            theme.scaffoldBackgroundColor,
            Color.alphaBlend(cs.tertiary.withOpacity(0.14), theme.scaffoldBackgroundColor),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: _panelWidth,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          // Everything inside lays out as if the screen were the panel.
          child: MediaQuery(
            data: media.copyWith(
              size: Size(_panelWidth, height),
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
