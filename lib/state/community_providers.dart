// lib/state/community_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adapters/mock/community_feed_service_mock.dart';
import '../data/services/community_feed_service.dart';

final communityFeedServiceProvider =
    Provider<CommunityFeedService>((_) => const CommunityFeedServiceMock());
