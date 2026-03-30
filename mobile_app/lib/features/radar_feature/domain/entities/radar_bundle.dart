import 'package:equatable/equatable.dart';

import 'radar.dart';
import 'speed_tunnel.dart';
import 'json_parsers.dart';

class RadarBundle extends Equatable {
  const RadarBundle({
    required this.radars,
    required this.speedTunnels,
  });

  factory RadarBundle.empty() => const RadarBundle(radars: [], speedTunnels: []);

  final List<Radar> radars;
  final List<SpeedTunnel> speedTunnels;

  bool get isEmpty => radars.isEmpty && speedTunnels.isEmpty;

  factory RadarBundle.fromBackendJson(Map<String, dynamic> payload) {
    final root = asMap(payload['data']).isEmpty ? payload : asMap(payload['data']);

    final radarItems = readArray(root, const ['radars', 'Radars']);
    final tunnelItems = readArray(root, const ['speedTunnels', 'SpeedTunnels']);

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
    );
  }

  @override
  List<Object?> get props => [radars, speedTunnels];
}
