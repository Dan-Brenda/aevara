// lib/core/guards/demo_route_gate.dart
//
// On demo builds, sends direct links to pages a visitor shouldn't reach back to where
// they belong. Normal builds never use this.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/route_paths.dart';
import '../../state/app_providers.dart';

/// Where to send a visitor instead of [route], or null if they can stay.
String? demoRedirectFor(String? route, {required bool signedIn, required bool anonymous}) {
  if (!signedIn) {
    const open = {
      RoutePaths.demoLanding,
      RoutePaths.signin,
      RoutePaths.forgot,
      RoutePaths.home,
    };
    return open.contains(route) ? null : RoutePaths.demoLanding;
  }
  if (anonymous) {
    const open = {RoutePaths.home, RoutePaths.aboutPrivacy};
    return open.contains(route) ? null : RoutePaths.home;
  }
  return null;
}

class DemoRouteGate extends ConsumerWidget {
  const DemoRouteGate({super.key, required this.routeName, required this.child});

  final String? routeName;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authUserProvider).when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (user) {
            final target = demoRedirectFor(
              routeName,
              signedIn: user != null,
              anonymous: user?.isAnonymous ?? false,
            );
            if (target == null) return child;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
            });
            return const SizedBox.shrink();
          },
        );
  }
}
