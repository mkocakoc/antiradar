import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RadarIconFactory {
  const RadarIconFactory._();

  static Future<BitmapDescriptor> create({
    Color color = const Color(0xFFEF4444),
    int size = 120,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final pulsePaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final middlePulsePaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size * 0.45, pulsePaint);
    canvas.drawCircle(center, size * 0.32, middlePulsePaint);
    canvas.drawCircle(center, size * 0.16, corePaint);

    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.10),
      Offset(center.dx, center.dy + size * 0.10),
      crossPaint,
    );

    canvas.drawLine(
      Offset(center.dx - size * 0.10, center.dy),
      Offset(center.dx + size * 0.10, center.dy),
      crossPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }

    return BitmapDescriptor.bytes(Uint8List.view(bytes.buffer));
  }
}
