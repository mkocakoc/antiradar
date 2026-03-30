import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationOrchestrator {
  NotificationOrchestrator(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _androidChannelId = 'radar_high_importance';
  static const _androidChannelName = 'Radar Alerts';
  static const _androidChannelDescription =
      'Critical radar proximity alerts with high importance';

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);
  }

  Future<void> showRadarAlert({
    required String radarId,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ticker: 'Radar Alert',
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.critical,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: _stableId(radarId),
      title: title,
      body: body,
      notificationDetails: details,
      payload: radarId,
    );
  }

  int _stableId(String radarId) => radarId.hashCode & 0x7fffffff;
}
