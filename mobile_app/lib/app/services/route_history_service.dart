import 'package:shared_preferences/shared_preferences.dart';

class RouteSelection {
  const RouteSelection({
    required this.fromDistrict,
    required this.toDistrict,
  });

  final String fromDistrict;
  final String toDistrict;

  String get key => '${fromDistrict.trim()}|${toDistrict.trim()}';

  factory RouteSelection.fromKey(String value) {
    final parts = value.split('|');
    if (parts.length != 2) {
      return const RouteSelection(fromDistrict: 'Ankara', toDistrict: 'Eskisehir');
    }

    return RouteSelection(
      fromDistrict: parts[0].trim(),
      toDistrict: parts[1].trim(),
    );
  }
}

class RouteHistoryService {
  RouteHistoryService({
    required SharedPreferences preferences,
    this.maxSize = 6,
  }) : _preferences = preferences;

  final SharedPreferences _preferences;
  final int maxSize;

  static const _key = 'recent_route_pairs';

  Future<List<RouteSelection>> getRecentRoutes() async {
    final values = _preferences.getStringList(_key) ?? const [];
    return values.map(RouteSelection.fromKey).toList(growable: false);
  }

  Future<void> saveRoute(RouteSelection route) async {
    final current = _preferences.getStringList(_key) ?? <String>[];
    final normalized = route.key;

    final next = <String>[normalized, ...current.where((item) => item != normalized)]
        .take(maxSize)
        .toList(growable: false);

    await _preferences.setStringList(_key, next);
  }

  Future<void> clearRoutes() async {
    await _preferences.remove(_key);
  }
}
