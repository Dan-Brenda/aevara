// test/demo_guards_test.dart
import 'dart:io';

import 'package:aevara_app/core/demo.dart';
import 'package:aevara_app/core/guards/demo_route_gate.dart';
import 'package:aevara_app/routing/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Direct links on a demo build', () {
    const blocked = [
      RoutePaths.signup,
      RoutePaths.verify,
      RoutePaths.identity,
      RoutePaths.demographics,
      RoutePaths.consent,
      RoutePaths.connect,
      RoutePaths.about,
      RoutePaths.aboutTerms,
      RoutePaths.methodsDoc,
      RoutePaths.profileEdit,
      RoutePaths.updateProfile,
      RoutePaths.settingsUsername,
      RoutePaths.settingsEmail,
      RoutePaths.settingsPassword,
      RoutePaths.settingsDevices,
      RoutePaths.settingsNotifs,
      RoutePaths.profilePrivacy,
      RoutePaths.profileExport,
      RoutePaths.profileDelete,
    ];

    test('a demo visitor goes back to Home', () {
      for (final route in [...blocked, RoutePaths.signin, RoutePaths.demoLanding, RoutePaths.forgot]) {
        expect(demoRedirectFor(route, signedIn: true, anonymous: true), RoutePaths.home, reason: route);
      }
    });

    test('a demo visitor can stay on Home and the privacy note', () {
      for (final route in [RoutePaths.home, RoutePaths.aboutPrivacy]) {
        expect(demoRedirectFor(route, signedIn: true, anonymous: true), isNull, reason: route);
      }
    });

    test('a signed-out visitor goes to the landing page', () {
      for (final route in [...blocked, RoutePaths.aboutPrivacy]) {
        expect(demoRedirectFor(route, signedIn: false, anonymous: false), RoutePaths.demoLanding, reason: route);
      }
    });

    test('a signed-out visitor can reach the landing page and sign-in', () {
      for (final route in [RoutePaths.demoLanding, RoutePaths.signin, RoutePaths.forgot, RoutePaths.home]) {
        expect(demoRedirectFor(route, signedIn: false, anonymous: false), isNull, reason: route);
      }
    });

    test('a real account is left alone', () {
      for (final route in blocked) {
        expect(demoRedirectFor(route, signedIn: true, anonymous: false), isNull, reason: route);
      }
    });
  });

  testWidgets('the read-only notice shows for a moment, and another tap extends it', (tester) async {
    expect(demoNotice.value, isNull);
    showDemoReadOnlyMessage();
    expect(demoNotice.value, contains('Disabled in demo'));
    await tester.pump(const Duration(seconds: 2));
    showDemoReadOnlyMessage();
    await tester.pump(const Duration(seconds: 2));
    expect(demoNotice.value, contains('Disabled in demo'));
    await tester.pump(const Duration(seconds: 1));
    expect(demoNotice.value, isNull);
  });

  test('no em dashes in any Dart string', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].trimLeft();
        if (code.startsWith('//') || code.startsWith('*')) continue;
        final beforeComment = code.split(' // ').first;
        if (beforeComment.contains('—')) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
