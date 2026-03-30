import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RadarRequest {
  const RadarRequest({
    required this.fromDistrict,
    required this.toDistrict,
    required this.createdAt,
  });

  final String fromDistrict;
  final String toDistrict;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'fromDistrict': fromDistrict,
        'toDistrict': toDistrict,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RadarRequest.fromJson(Map<String, dynamic> json) {
    return RadarRequest(
      fromDistrict: (json['fromDistrict'] ?? '').toString(),
      toDistrict: (json['toDistrict'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class RadarRequestQueue {
  RadarRequestQueue({required SharedPreferences preferences}) : _preferences = preferences;

  final SharedPreferences _preferences;

  static const _key = 'radar_request_queue_v1';

  Future<void> enqueue({
    required String fromDistrict,
    required String toDistrict,
  }) async {
    final queue = await readAll();

    final exists = queue.any(
      (item) =>
          item.fromDistrict.toLowerCase().trim() == fromDistrict.toLowerCase().trim() &&
          item.toDistrict.toLowerCase().trim() == toDistrict.toLowerCase().trim(),
    );

    if (exists) {
      return;
    }

    final next = [
      ...queue,
      RadarRequest(
        fromDistrict: fromDistrict,
        toDistrict: toDistrict,
        createdAt: DateTime.now(),
      ),
    ];

    await _write(next);
  }

  Future<List<RadarRequest>> readAll() async {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
          .map(RadarRequest.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> clear() => _preferences.remove(_key);

  Future<void> _write(List<RadarRequest> queue) async {
    final encoded = jsonEncode(queue.map((e) => e.toJson()).toList(growable: false));
    await _preferences.setString(_key, encoded);
  }
}
