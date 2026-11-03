// lib/core/widgets/info_sheet.dart
import 'package:flutter/material.dart';

/// A short title-and-paragraph explanation in a bottom sheet.
class InfoSheet {
  const InfoSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final tt = Theme.of(context).textTheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: tt.bodyMedium),
          ],
        ),
      ),
    );
  }
}
