// lib/core/guards/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart' as env;
import '../../routing/route_paths.dart';
import '../../state/app_providers.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authUserProvider);
    return auth.when(
      data: (user) {
        if (user == null) {
          // Not signed in → push to sign-in (the landing page in demo builds)
          final target = env.DEMO_ENABLED ? RoutePaths.demoLanding : RoutePaths.signin;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != target) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                target,
                (r) => false,
              );
            }
          });
          return const SizedBox.shrink();
        }
        return child;
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
