// lib/features/experiments/sheets/how_results_calculated_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/widgets/info_sheet.dart';

class HowResultsCalculatedSheet {
  const HowResultsCalculatedSheet._();

  static Future<void> show(BuildContext context) => InfoSheet.show(
        context,
        title: 'How results are calculated',
        body: 'We average the metric over the days of the experiment and compare that with '
            'your average from the weeks just before it. Changes under 1% count as no clear '
            'change, because that is within normal day-to-day variation.',
      );
}
