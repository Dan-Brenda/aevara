// lib/data/adapters/mock/devices_service_mock.dart
import '../../../core/widgets/tiles/sync_status_dot.dart' show SyncStatus;
import '../../demo_data.dart';
import '../../models/device_source.dart';

class DevicesServiceMock {
  const DevicesServiceMock();

  /// Matches the two-hour-old sync the status light reports in a demo session.
  DateTime get _lastSync => DateTime.now().subtract(const Duration(hours: 2));

  List<DeviceSource> sources() => [
        DeviceSource(
          id: 'fitbit',
          name: 'Fitbit',
          status: SyncStatus.connected,
          lastSync: _lastSync,
          dataTypes: const ['Sleep', 'HRV', 'Resting heart rate', 'Steps', 'Active minutes'],
        ),
        const DeviceSource(
          id: 'apple_health',
          name: 'Apple Health',
          status: SyncStatus.none,
          dataTypes: ['Sleep', 'HRV', 'Resting heart rate', 'Steps'],
        ),
        const DeviceSource(
          id: 'oura',
          name: 'Oura',
          status: SyncStatus.none,
          dataTypes: ['Sleep', 'HRV', 'Resting heart rate'],
        ),
        const DeviceSource(
          id: 'garmin',
          name: 'Garmin',
          status: SyncStatus.none,
          dataTypes: ['Sleep', 'Resting heart rate', 'Steps', 'Active minutes'],
        ),
        const DeviceSource(
          id: 'whoop',
          name: 'WHOOP',
          status: SyncStatus.none,
          dataTypes: ['Sleep', 'HRV', 'Resting heart rate'],
        ),
      ];

  List<SyncEvent> syncEvents() {
    final last = _lastSync;
    return [
      SyncEvent(
        at: last.add(const Duration(minutes: 1)),
        title: 'Vitality Age updated',
        detail: 'Today\'s score is ${DemoData.vitalityAge.toStringAsFixed(1)}, with ${DemoData.confidence}% confidence.',
      ),
      SyncEvent(
        at: last,
        title: 'Fitbit synced',
        detail: 'Sleep, HRV, resting heart rate and steps for the last 4 days.',
      ),
      SyncEvent(
        at: last.subtract(const Duration(hours: 24)),
        title: 'Yesterday finalized',
        detail: 'The day\'s score is locked and counts toward Healthy Days.',
      ),
      SyncEvent(
        at: last.subtract(const Duration(hours: 26)),
        title: 'Fitbit synced',
        detail: 'Daily sweep with a 14-day repair window.',
      ),
    ];
  }
}
