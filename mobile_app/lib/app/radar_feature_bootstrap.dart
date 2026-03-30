import 'package:dio/dio.dart';

import '../features/radar_feature/radar_feature.dart';

class RadarFeatureBootstrap {
  const RadarFeatureBootstrap._();

  static RadarRepository buildRepository({required String bffBaseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: bffBaseUrl,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 7),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final remoteDataSource = RadarRemoteDataSourceDio(dio);
    return RadarRepositoryImpl(
      remoteDataSource: remoteDataSource,
      cacheTtl: const Duration(minutes: 1),
    );
  }
}
