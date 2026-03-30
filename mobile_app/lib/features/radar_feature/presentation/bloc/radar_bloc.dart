import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/radar_bundle.dart';
import '../../domain/failures/radar_failure.dart';
import '../../domain/repositories/radar_repository.dart';

part 'radar_event.dart';
part 'radar_state.dart';

class RadarBloc extends Bloc<RadarEvent, RadarState> {
  RadarBloc({required RadarRepository repository})
      : _repository = repository,
        super(const RadarState()) {
    on<RadarRequested>(_onRequested);
    on<RadarRefreshed>(_onRefreshed);
  }

  final RadarRepository _repository;

  Future<void> _onRequested(
    RadarRequested event,
    Emitter<RadarState> emit,
  ) async {
    final startedAt = DateTime.now();
    final requestId = _createRequestId();
    _logTelemetry(
      eventName: 'route_request_started',
      fromDistrict: event.fromDistrict,
      toDistrict: event.toDistrict,
      forceRefresh: event.forceRefresh,
      requestId: requestId,
    );

    emit(state.copyWith(status: RadarLoadStatus.loading, clearFailure: true));

    final result = await _repository.fetchByDistrictRoute(
      fromDistrict: event.fromDistrict,
      toDistrict: event.toDistrict,
      forceRefresh: event.forceRefresh,
      requestId: requestId,
    );

    result.match(
      (failure) {
        final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
        _logTelemetry(
          eventName: 'route_request_completed',
          fromDistrict: event.fromDistrict,
          toDistrict: event.toDistrict,
          forceRefresh: event.forceRefresh,
          durationMs: durationMs,
          resultType: failure.type == RadarFailureType.emptyData ? 'empty' : 'error',
          requestId: requestId,
          errorCode: failure.code,
          errorMessage: failure.message,
        );

        emit(
          state.copyWith(
            status: RadarLoadStatus.failure,
            failure: failure,
            data: const RadarBundle(radars: [], speedTunnels: [], controlPoints: []),
          ),
        );
      },
      (data) {
        final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
        _logTelemetry(
          eventName: 'route_request_completed',
          fromDistrict: event.fromDistrict,
          toDistrict: event.toDistrict,
          forceRefresh: event.forceRefresh,
          durationMs: durationMs,
          resultType: data.isEmpty ? 'empty' : 'success',
          requestId: requestId,
          radarCount: data.effectiveRadarCount,
          speedTunnelCount: data.effectiveSpeedTunnelCount,
          controlPointCount: data.effectiveControlPointCount,
        );

        emit(
          state.copyWith(
            status: RadarLoadStatus.success,
            data: data,
            clearFailure: true,
          ),
        );
      },
    );
  }

  void _logTelemetry({
    required String eventName,
    required String fromDistrict,
    required String toDistrict,
    required bool forceRefresh,
    required String requestId,
    int? durationMs,
    String? resultType,
    int? radarCount,
    int? speedTunnelCount,
    int? controlPointCount,
    String? errorCode,
    String? errorMessage,
  }) {
    final payload = <String, Object?>{
      'eventName': eventName,
      'fromDistrict': fromDistrict,
      'toDistrict': toDistrict,
      'forceRefresh': forceRefresh,
  'requestId': requestId,
      if (durationMs != null) 'durationMs': durationMs,
      if (resultType != null) 'resultType': resultType,
      if (radarCount != null) 'radarCount': radarCount,
      if (speedTunnelCount != null) 'speedTunnelCount': speedTunnelCount,
      if (controlPointCount != null) 'controlPointCount': controlPointCount,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };

    debugPrint('[telemetry][mobile] $payload');
  }

  String _createRequestId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rnd = Random().nextInt(0x7fffffff).toRadixString(16);
    return 'm-$ts-$rnd';
  }

  Future<void> _onRefreshed(
    RadarRefreshed event,
    Emitter<RadarState> emit,
  ) {
    add(
      RadarRequested(
        fromDistrict: event.fromDistrict,
        toDistrict: event.toDistrict,
        forceRefresh: true,
      ),
    );
    return Future.value();
  }
}
