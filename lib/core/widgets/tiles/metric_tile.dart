// lib/core/widgets/tiles/metric_tile.dart
import 'package:flutter/material.dart';

/// A compact metric: icon and label, a large value, and a one-line caption.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.unit,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelMedium),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      if (unit != null) TextSpan(text: ' $unit', style: tt.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
