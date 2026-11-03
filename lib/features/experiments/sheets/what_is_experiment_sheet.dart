// lib/features/experiments/sheets/what_is_experiment_sheet.dart
import 'package:flutter/material.dart';

import '../../../core/widgets/info_sheet.dart';

class WhatIsExperimentSheet {
  const WhatIsExperimentSheet._();

  static Future<void> show(BuildContext context) => InfoSheet.show(
        context,
        title: 'What is an experiment?',
        body: 'Pick one habit, keep it up for a set number of days, and compare your '
            'numbers with the weeks before you started. It answers a personal question: '
            'did this change anything for me?',
      );
}
