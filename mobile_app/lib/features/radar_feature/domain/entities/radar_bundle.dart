import 'package:equatable/equatable.dart';

import 'control_point.dart';
import 'radar.dart';
import 'speed_tunnel.dart';
import 'json_parsers.dart';

class RadarBundle extends Equatable {
  const RadarBundle({
    required this.radars,
    required this.speedTunnels,
    required this.controlPoints,
    this.radarCount,
    this.speedTunnelCount,
    this.controlPointCount,
  });

  factory RadarBundle.empty() =>
      const RadarBundle(radars: [], speedTunnels: [], controlPoints: [], radarCount: 0, speedTunnelCount: 0, controlPointCount: 0);

  final List<Radar> radars;
  final List<SpeedTunnel> speedTunnels;
  final List<ControlPoint> controlPoints;
  final int? radarCount;
  final int? speedTunnelCount;
  final int? controlPointCount;

  int get effectiveRadarCount => _normalizeCount(radarCount) ?? radars.length;
  int get effectiveSpeedTunnelCount => _normalizeCount(speedTunnelCount) ?? speedTunnels.length;
  int get effectiveControlPointCount => _normalizeCount(controlPointCount) ?? controlPoints.length;

  bool get isEmpty =>
      effectiveRadarCount == 0 && effectiveSpeedTunnelCount == 0 && effectiveControlPointCount == 0;

  factory RadarBundle.fromBackendJson(Map<String, dynamic> payload) {
    final root = asMap(payload['data']).isEmpty ? payload : asMap(payload['data']);
  final summary = asMap(root['summary']);

    final radarItems = readArray(root, const ['radars', 'Radars']);
    final tunnelItems = readArray(root, const ['speedTunnels', 'SpeedTunnels']);
    final controlPointItems = readArray(root, const ['controlPoints', 'ControlPoints']);

    return RadarBundle(
      radars: radarItems
          .map((e) => asMap(e))
          .map(Radar.fromJson)
          .where((e) => e.path.isNotEmpty)
          .toList(growable: false),
      speedTunnels: tunnelItems
          .map((e) => asMap(e))
          .map(SpeedTunnel.fromJson)
          .where((e) => e.path.isNotEmpty)
          .toList(growable: false),
      controlPoints: controlPointItems
          .map((e) => asMap(e))
          .map(ControlPoint.fromJson)
          .where((e) => e.path.isNotEmpty)
          .toList(growable: false),
      radarCount: _normalizeCount(
        summary['radarCount'] ?? root['RadarCount'] ?? root['radarCount'],
      ),
      speedTunnelCount: _normalizeCount(
        summary['speedTunnelCount'] ??
            root['CorridorCount'] ??
            root['corridorCount'] ??
            root['SpeedTunnelCount'] ??
            root['speedTunnelCount'],
      ),
      controlPointCount: _normalizeCount(
        summary['controlPointCount'] ?? root['ControlPointCount'] ?? root['controlPointCount'],
      ),
    );
  }

  static int? _normalizeCount(dynamic value) {
    if (value is num) {
      final n = value.toInt();
      return n >= 0 ? n : null;
    }

    if (value is String) {
      final n = int.tryParse(value.trim());
      if (n == null || n < 0) return null;
      return n;
    }

    return null;
  }

  @override
  List<Object?> get props => [
        radars,
        speedTunnels,
        controlPoints,
        radarCount,
        speedTunnelCount,
        controlPointCount,
      ];
}
