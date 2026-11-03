// lib/state/challenges_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adapters/mock/challenges_service_mock.dart';
import '../data/services/challenges_service.dart';

final challengesServiceProvider =
    Provider<ChallengesService>((_) => const ChallengesServiceMock());
