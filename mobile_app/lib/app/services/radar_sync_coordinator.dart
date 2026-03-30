import 'dart:async';

import '../../features/radar_feature/infrastructure/sync/radar_request_queue.dart';
import '../../features/radar_feature/presentation/bloc/radar_bloc.dart';
import '../global/global_error_bus.dart';
import 'network_monitor_service.dart';

class RadarSyncCoordinator {
  RadarSyncCoordinator({
    required NetworkMonitorService networkMonitor,
    required RadarRequestQueue requestQueue,
    required RadarBloc radarBloc,
    required GlobalErrorBus errorBus,
  })  : _networkMonitor = networkMonitor,
        _requestQueue = requestQueue,
        _radarBloc = radarBloc,
        _errorBus = errorBus;

  final NetworkMonitorService _networkMonitor;
  final RadarRequestQueue _requestQueue;
  final RadarBloc _radarBloc;
  final GlobalErrorBus _errorBus;

  StreamSubscription<bool>? _subscription;

  Future<void> initialize() async {
    _subscription = _networkMonitor.connectivityStream.listen((isOnline) {
      if (isOnline) {
        unawaited(_replayQueue());
      }
    });

    if (_networkMonitor.isOnline) {
      await _replayQueue();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _replayQueue() async {
    final queued = await _requestQueue.readAll();
    if (queued.isEmpty) return;

    for (final request in queued) {
      _radarBloc.add(
        RadarRequested(
          fromDistrict: request.fromDistrict,
          toDistrict: request.toDistrict,
          forceRefresh: true,
        ),
      );
    }

    await _requestQueue.clear();
    _errorBus.info('${queued.length} bekleyen rota isteği tekrar gönderildi.');
  }
}
