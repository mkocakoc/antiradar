enum RadarFailureType {
  network,
  server,
  emptyData,
  parsing,
  unknown,
}

class RadarFailure {
  const RadarFailure({
    required this.type,
    required this.message,
    this.code,
  });

  final RadarFailureType type;
  final String message;
  final String? code;
}
