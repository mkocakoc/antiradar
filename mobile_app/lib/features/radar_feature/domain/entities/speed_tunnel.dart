import 'package:equatable/equatable.dart';

import 'geo_point.dart';
import 'json_parsers.dart';

class SpeedTunnel extends Equatable {
  const SpeedTunnel({
    required this.id,
    required this.path,
    this.label,
    this.district,
    this.road,
  });

  final String id;
  final String? label;
  final String? district;
  final String? road;
  final List<GeoPoint> path;

  factory SpeedTunnel.fromJson(Map<String, dynamic> json) {
    final coordinates = readArray(json, const ['path', 'coordinates', 'Coordinates']);

    final parsedPath = coordinates
        .map((e) => asMap(e))
        .map((e) {
          try {
            return GeoPoint.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<GeoPoint>()
        .toList(growable: false);

    final parsedId =
        tryParseString(json['id'] ?? json['Id'] ?? json['ControlPointId']) ?? 'speed-tunnel-unknown';

    return SpeedTunnel(
      id: parsedId,
      label: tryParseString(json['label'] ?? json['name'] ?? json['Name']),
      district: tryParseString(json['district'] ?? json['District']),
      road: tryParseString(json['road'] ?? json['Road'] ?? json['roadName'] ?? json['RoadName']),
      path: parsedPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'district': district,
        'road': road,
        'path': path.map((e) => e.toJson()).toList(growable: false),
      };

  @override
  List<Object?> get props => [id, label, district, road, path];
}
