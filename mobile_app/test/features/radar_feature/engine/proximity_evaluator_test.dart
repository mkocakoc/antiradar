import 'package:flutter_test/flutter_test.dart';
import 'package:antiradar_mobile_app/features/radar_feature/radar_feature.dart';

void main() {
  final evaluator = const ProximityEvaluator(
    triggerDistanceMeters: 1000,
    zoneCorridorMeters: 60,
    minMovementMeters: 5,
  );

  final zone = RadarZone.fromPath(
    id: 'radar-1',
    label: 'Radar A',
    path: const [
      GeoPoint(lat: 39.9200, lng: 32.8500),
      GeoPoint(lat: 39.9300, lng: 32.8600),
    ],
  );

  test('returns notify when user approaches start point in correct direction', () {
    const previous = GeoPoint(lat: 39.9100, lng: 32.8400);
    const current = GeoPoint(lat: 39.9140, lng: 32.8440);

    final result = evaluator.evaluate(
      currentPosition: current,
      previousPosition: previous,
      radarZone: zone,
    );

    expect(result.shouldNotify, isTrue);
    expect(result.decision, ProximityDecision.notify);
  });

  test('returns reverseDirection when movement vector is opposite', () {
    const previous = GeoPoint(lat: 39.9240, lng: 32.8540);
    const current = GeoPoint(lat: 39.9180, lng: 32.8480);

    final result = evaluator.evaluate(
      currentPosition: current,
      previousPosition: previous,
      radarZone: zone,
    );

    expect(result.shouldNotify, isFalse);
    expect(result.decision, ProximityDecision.reverseDirection);
  });

  test('returns insideZone for positions within zone corridor', () {
    const previous = GeoPoint(lat: 39.9140, lng: 32.8440);
    const current = GeoPoint(lat: 39.9250, lng: 32.8550);

    final result = evaluator.evaluate(
      currentPosition: current,
      previousPosition: previous,
      radarZone: zone,
    );

    expect(result.shouldNotify, isFalse);
    expect(result.decision, ProximityDecision.insideZone);
  });
}
