// test/demo_scoring_parity_test.dart
//
// The demo's ported scoring must give the same answers as the real server functions.
// Needs Node on PATH, and is skipped without it.
import 'dart:convert';
import 'dart:io';

import 'package:aevara_app/data/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the ported scoring matches the server functions on every sample day', () async {
    final hasNode = await Process.run('node', ['--version'], runInShell: true)
        .then((r) => r.exitCode == 0)
        .catchError((_) => false);
    if (!hasNode) {
      markTestSkipped('Node is not on PATH');
      return;
    }

    final days = DemoData.debugAllDays();
    final input = File('${Directory.systemTemp.createTempSync('aevara_parity').path}/input.json');
    input.writeAsStringSync(jsonEncode({
      'baseline': DemoData.baselineVitalityAge,
      'days': [
        for (final (day, previous, _) in days)
          {
            'hrv': day.hrvMs,
            'rhr': day.restingHrBpm,
            'sleep': day.sleepHours,
            'steps': previous.steps,
            'mvpa': previous.activeMinutes,
          },
      ],
    }));

    final run = await Process.run('node', ['test/support/server_scoring.mjs', input.path], runInShell: true);
    expect(run.exitCode, 0, reason: run.stderr.toString());
    final server = (jsonDecode(run.stdout.toString()) as List).cast<Map<String, dynamic>>();
    expect(server, hasLength(days.length));

    for (var i = 0; i < days.length; i++) {
      final mine = days[i].$3;
      final theirs = server[i];
      final at = 'day $i';
      expect(mine.recovery, closeTo((theirs['recovery'] as num).toDouble(), 1e-9), reason: '$at recovery');
      expect(mine.sleep, closeTo((theirs['sleep'] as num).toDouble(), 1e-9), reason: '$at sleep');
      expect(mine.activity, closeTo((theirs['activity'] as num).toDouble(), 1e-9), reason: '$at activity');
      expect(mine.risk, closeTo((theirs['risk'] as num).toDouble(), 0.0011), reason: '$at risk');
      expect(mine.confidence, theirs['confidence'], reason: '$at confidence');
      expect(mine.deltaYears, closeTo((theirs['delta'] as num).toDouble(), 0.011), reason: '$at delta');
      expect(mine.vitalityAge, closeTo((theirs['age'] as num).toDouble(), 0.11), reason: '$at vitality age');
      final drivers = (theirs['drivers'] as Map).cast<String, dynamic>();
      for (final key in ['recovery', 'sleep', 'activity']) {
        expect(mine.drivers[key], closeTo((drivers[key] as num).toDouble(), 0.0011), reason: '$at driver $key');
      }
    }
  });
}
