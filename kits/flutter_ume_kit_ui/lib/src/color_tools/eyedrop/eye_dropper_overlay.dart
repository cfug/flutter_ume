import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../color_utils.dart';
import 'eye_dropper_layer.dart';

const _cellSize = 10.0;
const _gridSize = 90.0;
const _gridCells = 9;

class EyeDropOverlay extends StatelessWidget {
  final Offset? cursorPosition;
  final bool touchable;
  final List<Color> colors;

  const EyeDropOverlay({
    required this.colors,
    this.cursorPosition,
    this.touchable = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (cursorPosition == null) {
      return const SizedBox.shrink();
    }

    final centerColor = colors.centerColor;
    final magnifierTop =
        cursorPosition!.dy - (_gridSize / 2) - (touchable ? _gridSize / 2 : 0);

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerMove: (details) => EyeDrop.handlePointerMove(
              details.position,
              details.kind == PointerDeviceKind.touch,
            ),
            onPointerUp: (details) => EyeDrop.handlePointerUp(details.position),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: cursorPosition!.dx - (_gridSize / 2),
          top: magnifierTop,
          child: IgnorePointer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildZoom(centerColor),
                const SizedBox(width: 8),
                _buildInfoTip(centerColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoom(Color centerColor) {
    return Container(
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 8, color: centerColor),
      ),
      width: _gridSize,
      height: _gridSize,
      child: ClipOval(
        child: CustomPaint(
          size: const Size.square(_gridSize),
          painter: _PixelGridPainter(colors),
        ),
      ),
    );
  }

  Widget _buildInfoTip(Color centerColor) {
    final hexColor = centerColor.hexRGB.toUpperCase();
    final red = (centerColor.r * 255).round();
    final green = (centerColor.g * 255).round();
    final blue = (centerColor.b * 255).round();
    final rgb = 'rgb($red, $green, $blue)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: centerColor,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.white54, width: 1),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    Clipboard.setData(ClipboardData(text: '#$hexColor')),
                child: Text(
                  '#$hexColor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: rgb)),
            child: Text(
              rgb,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'x: ${cursorPosition!.dx.toInt()}  y: ${cursorPosition!.dy.toInt()}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelGridPainter extends CustomPainter {
  final List<Color> colors;

  static const _eyeRadius = 35.0;

  static final Paint _blackStroke = Paint()
    ..color = Colors.black
    ..strokeWidth = 10
    ..style = PaintingStyle.stroke;

  _PixelGridPainter(this.colors);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final blackLine = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final selectedStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < colors.length; index++) {
      final rect = Rect.fromLTWH(
        (index % _gridCells) * _cellSize,
        ((index ~/ _gridCells) % _gridCells) * _cellSize,
        _cellSize,
        _cellSize,
      );
      canvas.drawRect(rect, Paint()..color = colors[index]);
      canvas.drawRect(
        rect,
        index == colors.length ~/ 2 ? selectedStroke : stroke,
      );

      if (index == colors.length ~/ 2) {
        canvas.drawRect(rect.deflate(1), blackLine);
      }
    }

    canvas.drawCircle(
      const Offset(_gridSize / 2, _gridSize / 2),
      _eyeRadius,
      _blackStroke,
    );
  }

  @override
  bool shouldRepaint(_PixelGridPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
