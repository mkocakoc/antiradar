import 'dart:math' as math;

import '../../domain/entities/geo_point.dart';
import '../domain/proximity_result.dart';
import '../domain/radar_zone.dart';

class ProximityEvaluator {
  const ProximityEvaluator({
    this.triggerDistanceMeters = 1000,
    this.zoneCorridorMeters = 60,
    this.minMovementMeters = 5,
  });

  final double triggerDistanceMeters;
  final double zoneCorridorMeters;
  final double minMovementMeters;

  ProximityResult evaluate({
    required GeoPoint currentPosition,
    required RadarZone radarZone,
    GeoPoint? previousPosition,
  }) {
    final distanceToStart = _distanceMeters(currentPosition, radarZone.startPoint);

    if (distanceToStart > triggerDistanceMeters) {
      return ProximityResult(
        decision: ProximityDecision.tooFar,
        distanceToStartMeters: distanceToStart,
        reason: 'outside_trigger_radius',
      );
    }

    if (_isInsideRadarZone(currentPosition, radarZone)) {
      return ProximityResult(
        decision: ProximityDecision.insideZone,
        distanceToStartMeters: distanceToStart,
        reason: 'already_inside_zone',
      );
    }

    if (previousPosition == null) {
      return ProximityResult(
        decision: ProximityDecision.insufficientMovement,
        distanceToStartMeters: distanceToStart,
        reason: 'missing_previous_position',
      );
    }

    final movement = _distanceMeters(previousPosition, currentPosition);
    if (movement < minMovementMeters) {
      return ProximityResult(
        decision: ProximityDecision.insufficientMovement,
        distanceToStartMeters: distanceToStart,
        reason: 'movement_below_threshold',
      );
    }

    if (_isReverseDirection(previousPosition, currentPosition, radarZone)) {
      return ProximityResult(
        decision: ProximityDecision.reverseDirection,
        distanceToStartMeters: distanceToStart,
        reason: 'reverse_vector_detected',
      );
    }

    return ProximityResult(
      decision: ProximityDecision.notify,
      distanceToStartMeters: distanceToStart,
      reason: 'approaching_start_point',
    );
  }

  bool _isReverseDirection(
    GeoPoint previous,
    GeoPoint current,
    RadarZone zone,
  ) {
    final movement = _toVector(previous, current);
    final radarDirection = _toVector(zone.startPoint, zone.endPoint);

    final dot = movement.$1 * radarDirection.$1 + movement.$2 * radarDirection.$2;
    return dot <= 0;
  }

  bool _isInsideRadarZone(GeoPoint point, RadarZone zone) {
    if (zone.path.length < 2) {
      return false;
    }

    for (var i = 0; i < zone.path.length - 1; i++) {
      final a = zone.path[i];
      final b = zone.path[i + 1];
      final distanceToSegment = _distanceToSegmentMeters(point, a, b);
      if (distanceToSegment <= zoneCorridorMeters) {
        return true;
      }
    }

    return false;
  }

  (double, double) _toVector(GeoPoint from, GeoPoint to) {
    final x = to.lng - from.lng;
    final y = to.lat - from.lat;
    return (x, y);
  }

  double _distanceToSegmentMeters(GeoPoint p, GeoPoint a, GeoPoint b) {
    final ax = a.lng;
    final ay = a.lat;
    final bx = b.lng;
    final by = b.lat;
    final px = p.lng;
    final py = p.lat;

    final abx = bx - ax;
    final aby = by - ay;
    final abSquared = abx * abx + aby * aby;

    if (abSquared == 0) {
      return _distanceMeters(p, a);
    }

    final apx = px - ax;
    final apy = py - ay;
    final t = ((apx * abx) + (apy * aby)) / abSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final closestX = ax + (abx * clampedT);
    final closestY = ay + (aby * clampedT);

    return _distanceMeters(
      p,
      GeoPoint(lat: closestY, lng: closestX),
    );
  }

  double _distanceMeters(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000.0;

    final dLat = _toRadians(b.lat - a.lat);
    final dLng = _toRadians(b.lng - a.lng);
    final lat1 = _toRadians(a.lat);
    final lat2 = _toRadians(b.lat);

    final haversine =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
            (math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2));
    final c = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 0.017453292519943295;
}
