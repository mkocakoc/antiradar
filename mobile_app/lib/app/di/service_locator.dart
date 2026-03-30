import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/radar_feature/domain/repositories/radar_repository.dart';
import '../../features/radar_feature/engine/services/adaptive_location_service.dart';
import '../../features/radar_feature/engine/services/geofencing_service.dart';
import '../../features/radar_feature/engine/services/location_notification_engine.dart';
import '../../features/radar_feature/engine/services/notification_orchestrator.dart';
import '../../features/radar_feature/engine/services/proximity_evaluator.dart';
import '../../features/radar_feature/engine/storage/notification_cooldown_store.dart';
import '../../features/radar_feature/infrastructure/datasources/radar_remote_data_source.dart';
import '../../features/radar_feature/infrastructure/repositories/radar_repository_impl.dart';
import '../../features/radar_feature/infrastructure/sync/radar_request_queue.dart';
import '../../features/radar_feature/presentation/bloc/radar_bloc.dart';
import '../config/app_environment.dart';
import '../global/global_error_bus.dart';
import '../services/network_monitor_service.dart';
import '../services/radar_sync_coordinator.dart';
import '../services/route_history_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  if (serviceLocator.isRegistered<RadarRepository>()) {
    return;
  }

  serviceLocator.registerSingleton<GlobalKey<ScaffoldMessengerState>>(
    GlobalKey<ScaffoldMessengerState>(),
  );

  serviceLocator.registerLazySingleton<GlobalErrorBus>(GlobalErrorBus.new);

  final preferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(preferences);
  serviceLocator.registerSingleton<AppConfig>(AppConfig.fromDartDefines());

  serviceLocator.registerLazySingleton<Connectivity>(Connectivity.new);
  serviceLocator.registerLazySingleton<NetworkMonitorService>(
    () => NetworkMonitorService(
      connectivity: serviceLocator<Connectivity>(),
      errorBus: serviceLocator<GlobalErrorBus>(),
    ),
  );

  final baseUrl = serviceLocator<AppConfig>().bffBaseUrl;

  serviceLocator.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 7),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    ),
  );

  serviceLocator.registerLazySingleton<RadarRemoteDataSource>(
    () => RadarRemoteDataSourceDio(serviceLocator<Dio>()),
  );

  serviceLocator.registerLazySingleton<RadarRepository>(
    () => RadarRepositoryImpl(
      remoteDataSource: serviceLocator<RadarRemoteDataSource>(),
      requestQueue: serviceLocator<RadarRequestQueue>(),
    ),
  );

  serviceLocator.registerLazySingleton<RadarBloc>(
    () => RadarBloc(repository: serviceLocator<RadarRepository>()),
  );

  serviceLocator.registerLazySingleton<NotificationOrchestrator>(
    () => NotificationOrchestrator(FlutterLocalNotificationsPlugin()),
  );

  serviceLocator.registerLazySingleton<NotificationCooldownStore>(
    () => SharedPrefsNotificationCooldownStore(
      preferences: serviceLocator<SharedPreferences>(),
    ),
  );

  serviceLocator.registerLazySingleton<AdaptiveLocationService>(AdaptiveLocationService.new);
  serviceLocator.registerLazySingleton<ProximityEvaluator>(ProximityEvaluator.new);
  serviceLocator.registerLazySingleton<RouteHistoryService>(
    () => RouteHistoryService(preferences: serviceLocator<SharedPreferences>()),
  );
  serviceLocator.registerLazySingleton<RadarRequestQueue>(
    () => RadarRequestQueue(preferences: serviceLocator<SharedPreferences>()),
  );

  serviceLocator.registerLazySingleton<LocationNotificationEngine>(
    () => LocationNotificationEngine(
      locationService: serviceLocator<AdaptiveLocationService>(),
      proximityEvaluator: serviceLocator<ProximityEvaluator>(),
      orchestrator: serviceLocator<NotificationOrchestrator>(),
      cooldownStore: serviceLocator<NotificationCooldownStore>(),
    ),
  );

  serviceLocator.registerLazySingleton<GeofencingService>(
    () => GeofencingService(engine: serviceLocator<LocationNotificationEngine>()),
  );

  serviceLocator.registerLazySingleton<RadarSyncCoordinator>(
    () => RadarSyncCoordinator(
      networkMonitor: serviceLocator<NetworkMonitorService>(),
      requestQueue: serviceLocator<RadarRequestQueue>(),
      radarBloc: serviceLocator<RadarBloc>(),
      errorBus: serviceLocator<GlobalErrorBus>(),
    ),
  );
}
