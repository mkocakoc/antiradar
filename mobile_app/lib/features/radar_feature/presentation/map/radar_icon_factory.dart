import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RadarIconFactory {
  const RadarIconFactory._();

  static Future<BitmapDescriptor> createRadarIcon({
    Color color = const Color(0xFFEF4444),
    int size = 76,
  }) async {
    return _createCircularIcon(
      color: color,
      size: size,
      iconData: Icons.notification_important_rounded,
      withPulse: true,
      fallbackHue: BitmapDescriptor.hueRed,
    );
  }

  static Future<BitmapDescriptor> createControlPointIcon({
    Color color = const Color(0xFF22C55E),
    int size = 76,
  }) async {
    return _createCircularIcon(
      color: color,
      size: size,
      iconData: Icons.local_police_rounded,
      withPulse: false,
      fallbackHue: BitmapDescriptor.hueGreen,
    );
  }

  static Future<BitmapDescriptor> _createCircularIcon({
    required Color color,
    required int size,
    required IconData iconData,
    required bool withPulse,
    required double fallbackHue,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    if (withPulse) {
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill;

      final middlePulsePaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, size * 0.45, pulsePaint);
      canvas.drawCircle(center, size * 0.32, middlePulsePaint);
    }

    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size * 0.16, corePaint);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: size * 0.22,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
        ),
      ),
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }

    return BitmapDescriptor.bytes(Uint8List.view(bytes.buffer));
  }
}
