import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/radar_feature/radar_feature.dart';
import '../features/radar_feature/presentation/radar_home_page.dart';
import 'app_bootstrap.dart';
import 'di/service_locator.dart';
import 'global/global_error_bus.dart';
import 'global/global_ui_wrapper.dart';
import 'services/network_monitor_service.dart';
import 'services/radar_sync_coordinator.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.bootstrap,
  });

  final AppBootstrapResult bootstrap;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    for (final warning in widget.bootstrap.startupWarnings) {
      serviceLocator<GlobalErrorBus>().warning(warning);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(serviceLocator<RadarSyncCoordinator>().dispose());
    unawaited(serviceLocator<NetworkMonitorService>().dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(serviceLocator<GeofencingService>().onAppResumed());
    }
    // Paused/background'da servisi durdurmuyoruz; Android foreground config ile takip sürer.
  }

  @override
  Widget build(BuildContext context) {
    final messengerKey = serviceLocator<GlobalKey<ScaffoldMessengerState>>();
    final errorBus = serviceLocator<GlobalErrorBus>();

    return GlobalUiWrapper(
      errorBus: errorBus,
      scaffoldMessengerKey: messengerKey,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RadarBloc>.value(value: serviceLocator<RadarBloc>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: messengerKey,
          theme: ThemeData.dark(useMaterial3: true),
          home: const RadarHomePage(),
        ),
      ),
    );
  }
}
