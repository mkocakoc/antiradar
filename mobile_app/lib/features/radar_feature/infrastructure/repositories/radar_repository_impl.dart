import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/radar_bundle.dart';
import '../../domain/failures/radar_failure.dart';
import '../../domain/repositories/radar_repository.dart';
import '../datasources/radar_remote_data_source.dart';
import '../sync/radar_request_queue.dart';

class RadarRepositoryImpl implements RadarRepository {
  RadarRepositoryImpl({
    required RadarRemoteDataSource remoteDataSource,
    RadarRequestQueue? requestQueue,
    this.cacheTtl = const Duration(minutes: 1),
    this.maxRetryCount = 3,
    DateTime Function()? now,
  })  : _remoteDataSource = remoteDataSource,
    _requestQueue = requestQueue,
        _now = now ?? DateTime.now;

  final RadarRemoteDataSource _remoteDataSource;
  final RadarRequestQueue? _requestQueue;
  final Duration cacheTtl;
  final int maxRetryCount;
  final DateTime Function() _now;

  final Map<String, _MemoryCacheEntry> _cache = {};

  @override
  Future<Either<RadarFailure, RadarBundle>> fetchByDistrictRoute({
    required String fromDistrict,
    required String toDistrict,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${fromDistrict.trim().toLowerCase()}::${toDistrict.trim().toLowerCase()}';

    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && !_isExpired(cached)) {
        return right(cached.data);
      }
    }

    try {
      final payload = await _fetchWithRetry(
        fromDistrict: fromDistrict,
        toDistrict: toDistrict,
      );

      final success = payload['success'] == true;
      if (!success) {
        final error = payload['error'];
        final code = error is Map ? error['code']?.toString() : null;
        final message = error is Map
            ? (error['message']?.toString() ?? 'Backend isteği başarısız döndü.')
            : 'Backend isteği başarısız döndü.';

        final type = code == 'EMPTY_DATA' ? RadarFailureType.emptyData : RadarFailureType.server;

        return left(RadarFailure(type: type, message: message, code: code));
      }

      final bundle = RadarBundle.fromBackendJson(payload);
      if (bundle.isEmpty) {
        return left(
          const RadarFailure(
            type: RadarFailureType.emptyData,
            message: 'Rota için radar veya hız tüneli verisi bulunamadı.',
            code: 'EMPTY_DATA',
          ),
        );
      }

      _cache[cacheKey] = _MemoryCacheEntry(data: bundle, createdAt: _now());

      return right(bundle);
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final errorMap = responseData['error'];
        final code = errorMap is Map ? errorMap['code']?.toString() : null;
        final message = errorMap is Map
            ? (errorMap['message']?.toString() ?? 'Backend isteği başarısız döndü.')
            : 'Backend isteği başarısız döndü.';

        return left(
          RadarFailure(
            type: RadarFailureType.server,
            message: message,
            code: code,
          ),
        );
      }

      if (_isOfflineLikeError(error)) {
        await _requestQueue?.enqueue(
          fromDistrict: fromDistrict,
          toDistrict: toDistrict,
        );
      }

      return left(
        RadarFailure(
          type: RadarFailureType.network,
          message: _isOfflineLikeError(error)
              ? 'Ağ bağlantısı yok. İstek kuyruğa alındı ve bağlantı gelince tekrar denenecek.'
              : 'Ağ hatası: backend servisine erişilemedi.',
          code: error.type.name,
        ),
      );
    } on FormatException catch (error) {
      return left(
        RadarFailure(
          type: RadarFailureType.parsing,
          message: 'Radar verisi parse edilemedi: ${error.message}',
          code: 'PARSE_ERROR',
        ),
      );
    } catch (_) {
      return left(
        const RadarFailure(
          type: RadarFailureType.unknown,
          message: 'Beklenmeyen bir hata oluştu.',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry({
    required String fromDistrict,
    required String toDistrict,
  }) async {
    var attempt = 0;
    DioException? lastError;

    while (attempt < maxRetryCount) {
      try {
        return await _remoteDataSource.fetchRoute(
          fromDistrict: fromDistrict,
          toDistrict: toDistrict,
        );
      } on DioException catch (error) {
        lastError = error;
        attempt += 1;

        if (!_isRetryable(error) || attempt >= maxRetryCount) {
          rethrow;
        }

        final delay = _retryDelay(attempt);
        await Future.delayed(delay);
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: '/api/route'),
          type: DioExceptionType.unknown,
          message: 'Retry mechanism failed without explicit DioException.',
        );
  }

  bool _isRetryable(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  bool _isOfflineLikeError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown;
  }

  Duration _retryDelay(int attempt) {
    final milliseconds = switch (attempt) {
      1 => 400,
      2 => 900,
      _ => 1800,
    };

    return Duration(milliseconds: milliseconds);
  }

  bool _isExpired(_MemoryCacheEntry entry) => _now().difference(entry.createdAt) > cacheTtl;
}

class _MemoryCacheEntry {
  _MemoryCacheEntry({
    required this.data,
    required this.createdAt,
  });

  final RadarBundle data;
  final DateTime createdAt;
}
