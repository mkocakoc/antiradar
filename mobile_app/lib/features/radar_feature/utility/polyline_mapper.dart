import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/entities/geo_point.dart';

class PolylineMapper {
  const PolylineMapper();

  List<LatLng> toLatLngList(List<GeoPoint> points) {
    if (points.isEmpty) return const [];

    return points
        .map((point) => LatLng(point.lat, point.lng))
        .toList(growable: false);
  }

  Polyline toPolyline({
    required String id,
    required List<GeoPoint> points,
    Color color = Colors.red,
    int width = 4,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: toLatLngList(points),
      color: color,
      width: width,
    );
  }

  Set<Polyline> toPolylineSet({
    required Iterable<List<GeoPoint>> paths,
    required String prefix,
    Color color = Colors.red,
  }) {
    var index = 0;
    return paths
        .where((path) => path.isNotEmpty)
        .map(
          (path) => toPolyline(
            id: '$prefix-$index',
            points: path,
            color: color,
          ),
        )
        .map((polyline) {
          index += 1;
          return polyline;
        })
        .toSet();
  }
}
