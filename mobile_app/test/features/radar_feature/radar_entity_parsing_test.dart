import 'package:flutter_test/flutter_test.dart';
import 'package:antiradar_mobile_app/features/radar_feature/radar_feature.dart';

void main() {
  test('Radar.fromJson should parse mixed coordinate formats safely', () {
    final radar = Radar.fromJson({
      'Id': 10,
      'Name': 'Radar X',
      'Coordinates': [
        {'x': '32.85', 'y': '39.92'},
        {'x': 32.86, 'y': 39.93},
        {'x': 'bad', 'y': '39.95'},
      ],
    });

    expect(radar.id, '10');
    expect(radar.path.length, 2);
    expect(radar.path.first.lat, 39.92);
    expect(radar.path.first.lng, 32.85);
  });

  test('RadarBundle.fromBackendJson should read nested data payload', () {
    final bundle = RadarBundle.fromBackendJson({
      'success': true,
      'data': {
        'radars': [
          {
            'id': 'r1',
            'path': [
              {'x': '30.0', 'y': '40.0'}
            ]
          }
        ],
        'speedTunnels': [
          {
            'id': 's1',
            'coordinates': [
              {'x': 29.0, 'y': 39.0}
            ]
          }
        ],
        'controlPoints': [
          {
            'id': 'c1',
            'path': [
              {'x': 31.0, 'y': 38.0}
            ]
          }
        ],
      }
    });

    expect(bundle.isEmpty, isFalse);
    expect(bundle.radars.length, 1);
    expect(bundle.speedTunnels.length, 1);
    expect(bundle.controlPoints.length, 1);
  });

  test('RadarBundle.fromBackendJson should respect summary/count fields when arrays are empty', () {
    final bundle = RadarBundle.fromBackendJson({
      'success': true,
      'data': {
        'RadarCount': 19,
        'ControlPointCount': 47,
        'CorridorCount': 59,
        'Radars': [],
        'SpeedTunnels': [],
      },
    });

    expect(bundle.radars.length, 0);
    expect(bundle.speedTunnels.length, 0);
    expect(bundle.controlPoints.length, 0);
    expect(bundle.effectiveRadarCount, 19);
    expect(bundle.effectiveControlPointCount, 47);
    expect(bundle.effectiveSpeedTunnelCount, 59);
    expect(bundle.isEmpty, isFalse);
  });
}
