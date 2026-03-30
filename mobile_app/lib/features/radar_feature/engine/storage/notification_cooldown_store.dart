import 'package:shared_preferences/shared_preferences.dart';

abstract interface class NotificationCooldownStore {
  Future<bool> canNotify({
    required String radarId,
    required DateTime now,
    Duration cooldown = const Duration(hours: 1),
  });

  Future<void> markNotified({
    required String radarId,
    required DateTime now,
  });
}

class SharedPrefsNotificationCooldownStore implements NotificationCooldownStore {
  SharedPrefsNotificationCooldownStore({
    required SharedPreferences preferences,
  }) : _preferences = preferences;

  final SharedPreferences _preferences;

  static const _keyPrefix = 'radar_notification_ts_';

  @override
  Future<bool> canNotify({
    required String radarId,
    required DateTime now,
    Duration cooldown = const Duration(hours: 1),
  }) async {
    final key = '$_keyPrefix$radarId';
    final millis = _preferences.getInt(key);
    if (millis == null) return true;

    final lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(millis);
    return now.difference(lastNotifiedAt) >= cooldown;
  }

  @override
  Future<void> markNotified({
    required String radarId,
    required DateTime now,
  }) async {
    final key = '$_keyPrefix$radarId';
    await _preferences.setInt(key, now.millisecondsSinceEpoch);
  }
}

class InMemoryNotificationCooldownStore implements NotificationCooldownStore {
  final Map<String, DateTime> _lastNotifiedByRadar = {};

  @override
  Future<bool> canNotify({
    required String radarId,
    required DateTime now,
    Duration cooldown = const Duration(hours: 1),
  }) async {
    final last = _lastNotifiedByRadar[radarId];
    if (last == null) return true;
    return now.difference(last) >= cooldown;
  }

  @override
  Future<void> markNotified({
    required String radarId,
    required DateTime now,
  }) async {
    _lastNotifiedByRadar[radarId] = now;
  }
}
