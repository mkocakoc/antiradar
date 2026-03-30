import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../global/global_error_bus.dart';

class NetworkMonitorService {
  NetworkMonitorService({
    required Connectivity connectivity,
    required GlobalErrorBus errorBus,
  })  : _connectivity = connectivity,
        _errorBus = errorBus;

  final Connectivity _connectivity;
  final GlobalErrorBus _errorBus;

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<dynamic>? _subscription;
  bool _lastOnlineState = true;

  bool get isOnline => _lastOnlineState;
  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<void> initialize() async {
    final initial = await _connectivity.checkConnectivity();
    _handleConnectivity(initial);

    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivity);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _connectivityController.close();
  }

  void _handleConnectivity(dynamic event) {
    final isOnline = _isConnected(event);

    if (isOnline == _lastOnlineState) {
      return;
    }

    _lastOnlineState = isOnline;
    if (!_connectivityController.isClosed) {
      _connectivityController.add(isOnline);
    }

    if (!isOnline) {
      _errorBus.error('İnternet bağlantısı kesildi.');
    } else {
      _errorBus.info('İnternet bağlantısı geri geldi.');
    }
  }

  bool _isConnected(dynamic event) {
    if (event is ConnectivityResult) {
      return event != ConnectivityResult.none;
    }

    if (event is List<ConnectivityResult>) {
      return event.any((result) => result != ConnectivityResult.none);
    }

    return true;
  }
}
