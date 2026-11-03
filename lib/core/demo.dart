// lib/core/demo.dart
//
// A demo session is an anonymous sign-in on a build made with DEMO_ENABLED=true.
// It reads sample data from data/demo_data.dart and never touches Firestore.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env.dart' as env;

const _sessionActiveKey = 'demo_session_active';
bool _restoring = false;
Future<User?>? _restore;

bool get isDemoSession =>
    env.DEMO_ENABLED && (FirebaseAuth.instance.currentUser?.isAnonymous ?? _restoring);

/// Starts a demo session. Everything after this comes from sample data.
Future<void> startDemoSession() async {
  await FirebaseAuth.instance.signInAnonymously();
  await _setSessionActive(true);
}

/// Ends a demo session because the visitor asked to.
Future<void> exitDemoSession() async {
  await _setSessionActive(false);
  await FirebaseAuth.instance.signOut();
}

/// The app's auth stream. On a demo build, a demo session that ends without
/// Exit demo (say its token can't be refreshed) is replaced by a new one, so
/// the visitor stays on the current screen. Listeners never see the gap.
Stream<User?> authChanges() {
  final changes = FirebaseAuth.instance.authStateChanges();
  if (!env.DEMO_ENABLED) return changes;
  return changes.asyncMap((user) async {
    if (user != null) return user;
    return _restore ??= _restoreDemoSession().whenComplete(() => _restore = null);
  });
}

Future<User?> _restoreDemoSession() async {
  if (!await _isSessionActive()) return null;
  _restoring = true;
  try {
    return (await FirebaseAuth.instance.signInAnonymously()).user;
  } catch (_) {
    await _setSessionActive(false);
    return null;
  } finally {
    _restoring = false;
  }
}

// Browser storage can be blocked. The demo still works, it just can't restore.
Future<bool> _isSessionActive() async {
  try {
    return (await SharedPreferences.getInstance()).getBool(_sessionActiveKey) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> _setSessionActive(bool active) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await (active ? prefs.setBool(_sessionActiveKey, true) : prefs.remove(_sessionActiveKey));
  } catch (_) {}
}

/// Shown for a moment in the demo strip, which sits above every screen and
/// covers no controls.
final ValueNotifier<String?> demoNotice = ValueNotifier<String?>(null);
Timer? _noticeTimer;

void showDemoReadOnlyMessage() {
  demoNotice.value = 'Disabled in demo. Nothing is saved here.';
  _noticeTimer?.cancel();
  _noticeTimer = Timer(const Duration(seconds: 3), () => demoNotice.value = null);
}
