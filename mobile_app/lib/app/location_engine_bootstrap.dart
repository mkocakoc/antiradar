import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/radar_feature/radar_feature.dart';

class LocationEngineBootstrap {
  const LocationEngineBootstrap._();

  static Future<LocationNotificationEngine> build({
    required List<RadarZone> zones,
  }) async {
    final preferences = await SharedPreferences.getInstance();

    final engine = LocationNotificationEngine(
      locationService: AdaptiveLocationService(),
      proximityEvaluator: const ProximityEvaluator(
        triggerDistanceMeters: 1000,
        zoneCorridorMeters: 60,
        minMovementMeters: 5,
      ),
      orchestrator: NotificationOrchestrator(FlutterLocalNotificationsPlugin()),
      cooldownStore: SharedPrefsNotificationCooldownStore(preferences: preferences),
    );

    engine.setZones(zones);
    return engine;
  }
}
