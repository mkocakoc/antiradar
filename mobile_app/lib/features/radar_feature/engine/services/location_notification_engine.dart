import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import '../domain/radar_zone.dart';
import '../storage/notification_cooldown_store.dart';
import 'adaptive_location_service.dart';
import 'notification_orchestrator.dart';
import 'proximity_evaluator.dart';

class LocationNotificationEngine {
  LocationNotificationEngine({
    required AdaptiveLocationService locationService,
    required ProximityEvaluator proximityEvaluator,
    required NotificationOrchestrator orchestrator,
    required NotificationCooldownStore cooldownStore,
    DateTime Function()? now,
  })  : _locationService = locationService,
        _proximityEvaluator = proximityEvaluator,
        _orchestrator = orchestrator,
        _cooldownStore = cooldownStore,
        _now = now ?? DateTime.now;

  final AdaptiveLocationService _locationService;
  final ProximityEvaluator _proximityEvaluator;
  final NotificationOrchestrator _orchestrator;
  final NotificationCooldownStore _cooldownStore;
  final DateTime Function() _now;

  final List<RadarZone> _zones = [];

  GeoPoint? _previousPosition;
  StreamSubscription<Position>? _subscription;

  Future<void> initialize() async {
    await _orchestrator.initialize();
    await _locationService.start();

    _subscription = _locationService.stream.listen(_onPosition);
  }

  void setZones(List<RadarZone> zones) {
    _zones
      ..clear()
      ..addAll(zones);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _locationService.dispose();
  }

  Future<void> _onPosition(Position position) async {
    if (_zones.isEmpty) {
      _previousPosition = GeoPoint(lat: position.latitude, lng: position.longitude);
      return;
    }

    final current = GeoPoint(lat: position.latitude, lng: position.longitude);

    for (final zone in _zones) {
      final result = _proximityEvaluator.evaluate(
        currentPosition: current,
        previousPosition: _previousPosition,
        radarZone: zone,
      );

      if (!result.shouldNotify) {
        continue;
      }

      final now = _now();
      final canNotify = await _cooldownStore.canNotify(radarId: zone.id, now: now);

      if (!canNotify) {
        continue;
      }

      await _orchestrator.showRadarAlert(
        radarId: zone.id,
        title: 'Radar Uyarısı',
        body:
            '${zone.label ?? zone.id} başlangıç noktasına ${result.distanceToStartMeters.round()} m kaldı.',
      );

      await _cooldownStore.markNotified(radarId: zone.id, now: now);
    }

    _previousPosition = current;
  }
}
