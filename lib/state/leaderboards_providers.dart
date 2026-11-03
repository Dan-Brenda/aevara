// lib/state/leaderboards_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adapters/mock/leaderboard_service_mock.dart';
import '../data/services/leaderboard_service.dart';

final leaderboardServiceProvider =
    Provider<LeaderboardService>((_) => const LeaderboardServiceMock());
