// lib/state/experiments_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adapters/mock/experiments_service_mock.dart';
import '../data/services/experiments_service.dart';

final experimentsServiceProvider =
    Provider<ExperimentsService>((_) => const ExperimentsServiceMock());
