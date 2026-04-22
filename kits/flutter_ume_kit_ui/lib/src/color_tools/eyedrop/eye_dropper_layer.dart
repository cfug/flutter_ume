import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../color_utils.dart';
import 'eye_dropper_overlay.dart';

final _captureKey = GlobalKey();

class _EyeDropperModel {
  bool touchable = false;
  OverlayEntry? eyeOverlayEntry;
  img.Image? snapshot;
  Offset cursorPosition = Offset.zero;
  List<Color> hoverColors = const [];
  ValueChanged<Color>? onColorSelected;
  ValueChanged<Color>? onColorChanged;
}

class EyeDrop extends InheritedWidget {
  static final _EyeDropperModel _data = _EyeDropperModel();

  static Offset get cursorPosition => _data.cursorPosition;

  EyeDrop({required Widget child, super.key})
      : super(
          child: RepaintBoundary(
            key: _captureKey,
            child: Listener(
              onPointerMove: (details) => _handleHover(
                details.position,
                details.kind == PointerDeviceKind.touch,
              ),
              onPointerHover: (details) => _handleHover(
                details.position,
                details.kind == PointerDeviceKind.touch,
              ),
              onPointerUp: (details) => handlePointerUp(details.position),
              child: child,
            ),
          ),
        );

  static EyeDrop of(BuildContext context) {
    final eyeDrop = context.dependOnInheritedWidgetOfExactType<EyeDrop>();
    if (eyeDrop == null) {
      throw Exception(
        'No EyeDrop found. You must wrap your application within an EyeDrop widget.',
      );
    }
    return eyeDrop;
  }

  static void handlePointerMove(Offset position, bool touchable) {
    _data.cursorPosition = position;
    _data.touchable = touchable;

    if (_data.snapshot != null) {
      _data.hoverColors = getPixelColors(_data.snapshot!, position);
    }

    _data.eyeOverlayEntry?.markNeedsBuild();

    final onColorChanged = _data.onColorChanged;
    if (onColorChanged != null) {
      onColorChanged(_data.hoverColors.centerColor);
    }
  }

  static void handlePointerUp(Offset position) {
    handlePointerMove(position, _data.touchable);

    final onColorSelected = _data.onColorSelected;
    if (onColorSelected != null) {
      onColorSelected(_data.hoverColors.centerColor);
    }

    _clearCapture();
  }

  static void _handleHover(Offset position, bool touchable) {
    handlePointerMove(position, touchable);
  }

  static void _clearCapture() {
    try {
      _data.eyeOverlayEntry?.remove();
    } catch (err) {
      debugPrint('EyeDrop cleanup error: $err');
    }

    _data.eyeOverlayEntry = null;
    _data.snapshot = null;
    _data.hoverColors = const [];
    _data.onColorSelected = null;
    _data.onColorChanged = null;
    _data.touchable = false;
  }

  void capture(
    BuildContext context,
    ValueChanged<Color> onColorSelected,
    ValueChanged<Color>? onColorChanged,
  ) async {
    final renderer = _captureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (renderer == null) {
      debugPrint('EyeDrop: renderer is null');
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    _clearCapture();
    _data.onColorSelected = onColorSelected;
    _data.onColorChanged = onColorChanged;
    _data.snapshot = await repaintBoundaryToImage(renderer);

    if (_data.snapshot == null) {
      debugPrint('EyeDrop: snapshot failed');
      _clearCapture();
      return;
    }

    _data.eyeOverlayEntry = OverlayEntry(
      builder: (_) => EyeDropOverlay(
        touchable: _data.touchable,
        colors: _data.hoverColors,
        cursorPosition: _data.cursorPosition,
      ),
    );
    overlay.insert(_data.eyeOverlayEntry!);
  }

  @override
  bool updateShouldNotify(EyeDrop oldWidget) => true;
}
