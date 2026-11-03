// lib/features/auth/demo_landing_page.dart
//
// First screen of the demo build. Only reachable when DEMO_ENABLED is set.
import 'package:flutter/material.dart';

import '../../core/demo.dart';
import '../../core/widgets/avatar/coach_avatar.dart';
import '../../routing/route_paths.dart';

class DemoLandingPage extends StatefulWidget {
  const DemoLandingPage({super.key});

  @override
  State<DemoLandingPage> createState() => _DemoLandingPageState();
}

class _DemoLandingPageState extends State<DemoLandingPage> {
  bool _busy = false;
  String? _error;

  Future<void> _tryDemo() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await startDemoSession();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(RoutePaths.home, (r) => false);
    } catch (_) {
      if (mounted) setState(() => _error = "The demo couldn't start. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CoachAvatar(size: 96, padding: 0, semanticLabel: 'Aevara logo'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aevara',
                    textAlign: TextAlign.center,
                    style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Turns your wearable data into one daily number: your Vitality Age.',
                    textAlign: TextAlign.center,
                    style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _busy ? null : _tryDemo,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('Try the demo'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No account needed. Sample data only.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(color: cs.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.of(context).pushNamed(RoutePaths.signin),
                    child: const Text('Sign in to an account'),
                  ),
                  Text(
                    'Accounts need the backend, which is offline.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
