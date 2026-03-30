import 'package:flutter_test/flutter_test.dart';
import 'package:antiradar_mobile_app/features/radar_feature/radar_feature.dart';

class _FakeRemoteDataSource implements RadarRemoteDataSource {
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
  }) async {
    callCount += 1;

    return {
      'success': true,
      'data': {
        'radars': [
          {
            'id': 'r-$callCount',
            'path': [
              {'x': '32.0', 'y': '39.0'}
            ]
          }
        ],
        'speedTunnels': []
      }
    };
  }
}

void main() {
  test('Repository should serve cached data before ttl expiration', () async {
    final fakeSource = _FakeRemoteDataSource();
    var now = DateTime(2026, 3, 29, 10, 0, 0);

    final repository = RadarRepositoryImpl(
      remoteDataSource: fakeSource,
      cacheTtl: const Duration(minutes: 1),
      now: () => now,
    );

    final first = await repository.fetchByDistrictRoute(
      fromDistrict: 'Ankara',
      toDistrict: 'Eskisehir',
    );

    final second = await repository.fetchByDistrictRoute(
      fromDistrict: 'Ankara',
      toDistrict: 'Eskisehir',
    );

    expect(first.isRight(), isTrue);
    expect(second.isRight(), isTrue);
    expect(fakeSource.callCount, 1);

    now = now.add(const Duration(minutes: 2));

    final third = await repository.fetchByDistrictRoute(
      fromDistrict: 'Ankara',
      toDistrict: 'Eskisehir',
    );

    expect(third.isRight(), isTrue);
    expect(fakeSource.callCount, 2);
  });

  test('Repository should map EMPTY_DATA as failure', () async {
    final repository = RadarRepositoryImpl(
      remoteDataSource: _EmptyRemoteDataSource(),
      cacheTtl: const Duration(minutes: 1),
    );

    final result = await repository.fetchByDistrictRoute(
      fromDistrict: 'A',
      toDistrict: 'B',
    );

    expect(result.isLeft(), isTrue);
    final failure = result.match((l) => l, (r) => throw StateError('Expected left, got $r'));
    expect(failure.type, RadarFailureType.emptyData);
  });
}

class _EmptyRemoteDataSource implements RadarRemoteDataSource {
  @override
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
  }) async {
    return {
      'success': false,
      'error': {
        'code': 'EMPTY_DATA',
        'message': 'No data',
      }
    };
  }
}
