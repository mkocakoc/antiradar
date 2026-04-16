import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class AdaptiveLocationService {
  AdaptiveLocationService({
    LocationSettings? baseSettings,
  }) : _baseSettings = baseSettings;

  final LocationSettings? _baseSettings;

  final StreamController<Position> _controller = StreamController.broadcast();

  StreamSubscription<Position>? _subscription;
  int? _activeDistanceFilter;

  Stream<Position> get stream => _controller.stream;

  Future<void> start() async {
    final hasPermission = await _ensurePermissions();
    if (!hasPermission) {
      throw Exception('Location permission is not granted.');
    }

    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _controller.add(initial);
    } catch (_) {
      // Ignore here; stream updates can still provide position.
    }

    _startInternal(distanceFilter: 50);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _activeDistanceFilter = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<bool> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  void _startInternal({required int distanceFilter}) {
    _activeDistanceFilter = distanceFilter;

    final settings = _buildLocationSettings(distanceFilter);

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        _controller.add(position);

        final nextFilter = _distanceFilterBySpeed(position.speed);
        if (_activeDistanceFilter != nextFilter) {
          _restartWithFilter(nextFilter);
        }
      },
      onError: _controller.addError,
    );
  }

  void _restartWithFilter(int nextFilter) {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _startInternal(distanceFilter: nextFilter);
  }

  LocationSettings _buildLocationSettings(int distanceFilter) {
    if (_baseSettings != null) {
      return _baseSettings;
    }

    if (kIsWeb) {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        intervalDuration: const Duration(seconds: 8),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'AntiRadar aktif',
          notificationText: 'Radar yaklaşım takibi arka planda sürüyor.',
          enableWakeLock: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: true,
        activityType: ActivityType.automotiveNavigation,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );
  }

  int _distanceFilterBySpeed(double speedMeterPerSecond) {
    if (speedMeterPerSecond < 3) return 20; // walking / slow traffic
    if (speedMeterPerSecond < 10) return 50; // city driving
    if (speedMeterPerSecond < 20) return 100; // intercity moderate
    if (speedMeterPerSecond < 30) return 180; // highway
    return 300; // very high speed
  }
}
