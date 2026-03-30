import 'package:dio/dio.dart';

abstract interface class RadarRemoteDataSource {
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
    String? requestId,
  });
}

class RadarRemoteDataSourceDio implements RadarRemoteDataSource {
  RadarRemoteDataSourceDio(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> fetchRoute({
    required String fromDistrict,
    required String toDistrict,
    String? requestId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/route',
      data: {
        'fromDistrict': fromDistrict,
        'toDistrict': toDistrict,
      },
      options: Options(
        headers: {
          if (requestId != null && requestId.isNotEmpty) 'x-request-id': requestId,
        },
      ),
    );

    final payload = Map<String, dynamic>.from(response.data ?? const {});
    final responseRequestId = response.headers.value('x-request-id');
    if (responseRequestId != null && responseRequestId.isNotEmpty) {
      payload['__requestId'] = responseRequestId;
    }

    return payload;
  }
}
