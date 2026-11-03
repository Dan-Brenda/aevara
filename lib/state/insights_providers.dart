// lib/state/insights_providers.dart
//
// Demo-only sources for the Home and Data tabs.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adapters/mock/daily_service_mock.dart';
import '../data/adapters/mock/devices_service_mock.dart';

final demoDailyProvider = Provider<DailyServiceMock>((_) => const DailyServiceMock());
final demoDevicesProvider = Provider<DevicesServiceMock>((_) => const DevicesServiceMock());
