import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

extension ColorHexTools on Color {
  String get hexRGB {
    final red = (r * 255).round().toRadixString(16).padLeft(2, '0');
    final green = (g * 255).round().toRadixString(16).padLeft(2, '0');
    final blue = (b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$red$green$blue';
  }
}

extension CenterColor on List<Color> {
  Color get centerColor => isEmpty ? Colors.black : this[length ~/ 2];
}

const _samplingGridSize = 9;

List<Color> getPixelColors(
  img.Image image,
  Offset offset, {
  int size = _samplingGridSize,
}) =>
    List.generate(
      size * size,
      (index) => getPixelColor(
        image,
        offset + _offsetFromIndex(index, size),
      ),
    );

Color getPixelColor(img.Image image, Offset offset) {
  if (offset.dx < 0 ||
      offset.dy < 0 ||
      offset.dx >= image.width ||
      offset.dy >= image.height) {
    return const Color(0x00000000);
  }

  final pixel = image.getPixel(offset.dx.toInt(), offset.dy.toInt());
  return Color.fromARGB(
    (pixel.a.toInt() >> 8).clamp(0, 255),
    (pixel.r.toInt() >> 8).clamp(0, 255),
    (pixel.g.toInt() >> 8).clamp(0, 255),
    (pixel.b.toInt() >> 8).clamp(0, 255),
  );
}

Future<img.Image?> repaintBoundaryToImage(
  RenderRepaintBoundary renderer,
) async {
  try {
    final rawImage = await renderer.toImage(pixelRatio: 1);
    final byteData = await rawImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final pngBytes = byteData.buffer.asUint8List();
    rawImage.dispose();
    return img.decodeImage(pngBytes);
  } catch (err) {
    debugPrint('repaintBoundaryToImage error: $err');
    return null;
  }
}

ui.Offset _offsetFromIndex(int index, int numColumns) {
  final half = numColumns ~/ 2;
  return Offset(
    (index % numColumns).toDouble() - half,
    ((index ~/ numColumns) % numColumns).toDouble() - half,
  );
}
