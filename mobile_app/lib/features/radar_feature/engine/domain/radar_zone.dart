import 'package:equatable/equatable.dart';

import '../../domain/entities/geo_point.dart';

class RadarZone extends Equatable {
  const RadarZone({
    required this.id,
    required this.startPoint,
    required this.endPoint,
    required this.path,
    this.label,
  });

  final String id;
  final String? label;
  final GeoPoint startPoint;
  final GeoPoint endPoint;
  final List<GeoPoint> path;

  factory RadarZone.fromPath({
    required String id,
    required List<GeoPoint> path,
    String? label,
  }) {
    if (path.length < 2) {
      throw const FormatException('RadarZone path should contain at least 2 points.');
    }

    return RadarZone(
      id: id,
      label: label,
      startPoint: path.first,
      endPoint: path.last,
      path: List.unmodifiable(path),
    );
  }

  @override
  List<Object?> get props => [id, label, startPoint, endPoint, path];
}
