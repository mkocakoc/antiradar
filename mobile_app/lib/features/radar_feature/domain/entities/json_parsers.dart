double? tryParseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }
  return null;
}

String? tryParseString(dynamic value) {
  if (value == null) return null;
  final output = value.toString().trim();
  return output.isEmpty ? null : output;
}

List<dynamic> readArray(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }
  return const [];
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
