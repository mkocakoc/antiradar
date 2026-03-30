import '../../domain/entities/radar.dart';
import '../domain/radar_zone.dart';
import 'location_notification_engine.dart';

class GeofencingService {
  GeofencingService({
    required LocationNotificationEngine engine,
  }) : _engine = engine;

  final LocationNotificationEngine _engine;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _engine.initialize();
    _initialized = true;
  }

  void syncTrackedRadars(List<Radar> radars) {
    final zones = radars
        .where((radar) => radar.path.length >= 2)
        .map(
          (radar) => RadarZone.fromPath(
            id: radar.id,
            label: radar.label,
            path: radar.path,
          ),
        )
        .toList(growable: false);

    _engine.setZones(zones);
  }

  Future<void> onAppResumed() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> dispose() => _engine.dispose();
}
