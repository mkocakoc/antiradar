import 'package:dio/dio.dart';

abstract interface class RadarRemoteDataSource {
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
  });
}

class RadarRemoteDataSourceDio implements RadarRemoteDataSource {
  RadarRemoteDataSourceDio(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/route',
      data: {
        'fromDistrict': fromDistrict,
        'toDistrict': toDistrict,
      },
    );

    return response.data ?? const {};
  }
}
