// lib/features/experiments/sheets/limitations_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/widgets/info_sheet.dart';

class LimitationsSheet {
  const LimitationsSheet._();

  static Future<void> show(BuildContext context) => InfoSheet.show(
        context,
        title: 'Limitations',
        body: 'A personal experiment shows what happened alongside a habit, not what caused it. '
            'Travel, illness or a stressful week can move the same numbers. Results are for '
            'curiosity and aren\'t medical advice.',
      );
}
