// lib/data/models/device_source.dart
import '../../core/widgets/tiles/sync_status_dot.dart' show SyncStatus;

class DeviceSource {
  const DeviceSource({
    required this.id,
    required this.name,
    required this.status,
    required this.dataTypes,
    this.lastSync,
  });

  final String id;
  final String name;
  final SyncStatus status;
  final List<String> dataTypes;
  final DateTime? lastSync;

  bool get isConnected => status == SyncStatus.connected;
}

class SyncEvent {
  const SyncEvent({required this.at, required this.title, required this.detail});

  final DateTime at;
  final String title;
  final String detail;
}
