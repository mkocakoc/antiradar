import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_orchestrator.dart';

@pragma('vm:entry-point')
Future<void> radarBackgroundEntryPoint() async {
  final plugin = FlutterLocalNotificationsPlugin();
  final orchestrator = NotificationOrchestrator(plugin);
  await orchestrator.initialize();
}
