import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../features/radar_feature/radar_feature.dart';
import 'config/app_environment.dart';
import 'di/service_locator.dart';
import 'global/global_error_bus.dart';
import 'services/network_monitor_service.dart';
import 'services/radar_sync_coordinator.dart';

class AppBootstrapResult {
  const AppBootstrapResult({
    required this.startupWarnings,
  });

  final List<String> startupWarnings;
}

class AppBootstrap {
  const AppBootstrap._();

  static Future<AppBootstrapResult> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await setupServiceLocator();

    final warnings = <String>[];
    final errorBus = serviceLocator<GlobalErrorBus>();
  final appConfig = serviceLocator<AppConfig>();

  warnings.add('Aktif profil: ${appConfig.environment.name}');

    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      warnings.add('Konum servisi kapalı. Radar takibi sınırlı çalışabilir.');
      errorBus.warning('Konum servisi kapalı. Lütfen cihaz ayarlarından açın.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      warnings.add('Konum izni verilmedi.');
      errorBus.warning('Konum izni olmadan yaklaşım uyarıları çalışmaz.');
    }

    await serviceLocator<NetworkMonitorService>().initialize();
  await serviceLocator<RadarSyncCoordinator>().initialize();

    final geofencingService = serviceLocator<GeofencingService>();
    try {
      await geofencingService.initialize();
    } catch (_) {
      warnings.add('Geofencing servisi başlatılamadı.');
      errorBus.error('Geofencing servisi başlatılamadı. İzinleri kontrol edin.');
    }

    return AppBootstrapResult(startupWarnings: warnings);
  }
}
