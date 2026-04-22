import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

import 'eye_dropper_layer.dart';

class EyedropperButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final ValueChanged<Color> onColor;
  final ValueChanged<Color>? onColorChanged;

  bool get eyedropEnabled => globalContext.has('flutterCanvasKit');

  const EyedropperButton({
    required this.onColor,
    this.onColorChanged,
    this.icon = Icons.colorize,
    this.iconColor = Colors.black54,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration:
            const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(icon),
          color: iconColor,
          onPressed:
              eyedropEnabled ? () => _onEyeDropperRequest(context) : null,
        ),
      );

  void _onEyeDropperRequest(BuildContext context) {
    try {
      EyeDrop.of(context).capture(context, onColor, onColorChanged);
    } catch (err) {
      throw Exception('EyeDrop capture error: $err');
    }
  }
}
