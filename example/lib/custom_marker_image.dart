import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Paints a simple ringed circle to PNG bytes for [MKAnnotationIcon.image],
/// keeping the example self-contained (no bundled image assets). The bytes
/// feed the custom-image annotation variant so the demo also exercises the
/// reuse/update paths the 0.2.2 fix repairs for `MKAnnotationView.image`.
Future<Uint8List> renderCircleMarkerPng(Color color, {int size = 96}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final d = size.toDouble();
  final center = Offset(d / 2, d / 2);
  const white = Color(0xFFFFFFFF);

  canvas.drawCircle(center, d / 2, Paint()..color = color);
  canvas.drawCircle(
    center,
    d / 2 - d * 0.06,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = d * 0.08
      ..color = white,
  );
  canvas.drawCircle(center, d * 0.18, Paint()..color = white);

  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
