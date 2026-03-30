import 'package:equatable/equatable.dart';

import 'json_parsers.dart';

class GeoPoint extends Equatable {
  const GeoPoint({
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final x = tryParseDouble(json['x'] ?? json['X'] ?? json['lng'] ?? json['longitude']);
    final y = tryParseDouble(json['y'] ?? json['Y'] ?? json['lat'] ?? json['latitude']);

    if (x == null || y == null) {
      throw const FormatException('Invalid coordinate payload for GeoPoint.');
    }

    return GeoPoint(lat: y, lng: x);
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };

  @override
  List<Object?> get props => [lat, lng];
}
