// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regenerates the two source PNGs `flutter_launcher_icons` reads (see the
/// `flutter_launcher_icons:` block in `pubspec.yaml`).
///
/// Run with `flutter test tool/generate_app_icon.dart` — it uses the Flutter
/// test binding purely to get a working `dart:ui` image encoder, not to test
/// anything. The glyph is drawn as plain vector shapes rather than a
/// Material Icons glyph so this needs no font loading: a viewfinder — four
/// corner brackets around a scan line — the same "scanning" metaphor as the
/// in-app `Icons.qr_code_scanner`.
///
/// To change the icon: edit the constants or `_paintScanGlyph` below, run
/// this, then `dart run flutter_launcher_icons` to regenerate the platform
/// icon files from the new PNGs.
const int _canvasSize = 1024;
const Color _navy = Color(0xFF16243D); // AppColors.light.headerSurface
const Color _glyph = Color(0xFFFFFFFF);

void main() {
  testWidgets('generate app icon PNGs', (WidgetTester tester) async {
    // `Picture.toImage()` / `Image.toByteData()` are real asynchronous engine
    // operations — they never resolve inside `testWidgets`'s fake-async zone,
    // which drives time forward only on `pump()`. `runAsync` escapes that zone
    // so the actual rasterisation completes.
    await tester.runAsync(() async {
      final Uint8List flat = await _renderIcon(
        withBackground: true,
        glyphScale: 0.62,
      );
      final Uint8List foreground = await _renderIcon(
        withBackground: false,
        // Kept well inside Android's adaptive-icon safe zone (~66% of the
        // canvas), so a circle/squircle/rounded-square mask never clips it.
        glyphScale: 0.42,
      );

      final File flatFile = File('assets/icon/app_icon.png');
      final File foregroundFile = File('assets/icon/app_icon_foreground.png');
      await flatFile.create(recursive: true);
      await foregroundFile.create(recursive: true);
      await flatFile.writeAsBytes(flat);
      await foregroundFile.writeAsBytes(foreground);

      print('Wrote ${flatFile.path} (${flat.lengthInBytes} bytes)');
      print('Wrote ${foregroundFile.path} (${foreground.lengthInBytes} bytes)');
    });
  });
}

Future<Uint8List> _renderIcon({
  required bool withBackground,
  required double glyphScale,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final double size = _canvasSize.toDouble();
  final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  if (withBackground) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = _navy);
  }

  _paintScanGlyph(canvas, size: size, scale: glyphScale, color: _glyph);

  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(_canvasSize, _canvasSize);
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  return bytes!.buffer.asUint8List();
}

void _paintScanGlyph(
  Canvas canvas, {
  required double size,
  required double scale,
  required Color color,
}) {
  final double center = size / 2;
  final double half = size * scale / 2;
  final double armLength = half * 0.55;
  final double strokeWidth = size * 0.05;

  final Paint bracket = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

  void corner(Offset origin, Offset horizontalArm, Offset verticalArm) {
    canvas.drawLine(origin, origin + horizontalArm, bracket);
    canvas.drawLine(origin, origin + verticalArm, bracket);
  }

  corner(
    Offset(center - half, center - half),
    Offset(armLength, 0),
    Offset(0, armLength),
  );
  corner(
    Offset(center + half, center - half),
    Offset(-armLength, 0),
    Offset(0, armLength),
  );
  corner(
    Offset(center - half, center + half),
    Offset(armLength, 0),
    Offset(0, -armLength),
  );
  corner(
    Offset(center + half, center + half),
    Offset(-armLength, 0),
    Offset(0, -armLength),
  );

  final Paint scanLine = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth * 0.6
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    Offset(center - half * 0.7, center),
    Offset(center + half * 0.7, center),
    scanLine,
  );
}
