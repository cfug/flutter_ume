part of '../../flutter_ume_kit_ui_plus.dart';

class ColorPicker extends StatefulWidget implements PluggableWithNestedWidget {
  const ColorPicker({super.key});

  @override
  _ColorPickerState createState() => _ColorPickerState();

  @override
  Widget buildWidget(BuildContext? context) => this;

  @override
  String get name => 'ColorPicker';

  @override
  String get displayName => 'TouchIndicator';

  @override
  void onTrigger() {}

  @override
  ImageProvider<Object> get iconImageProvider =>
      MemoryImage(iconBytesWithColorPicker);

  @override
  Widget buildNestedWidget(Widget child) {
    return EyeDrop(child: child);
  }
}

class _ColorPickerState extends State<ColorPicker> {
  static const _colorTextStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20);

  Color? _color;
  bool _panelAtBottom = true;

  void _onColorSelected(Color color) {
    setState(() => _color = color);
  }

  void _onColorChanged(Color color) {
    // 取色过程中更新颜色和面板位置
    final cursorY = EyeDrop.cursorPosition.dy;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final shouldBeAtBottom = cursorY < screenHeight * 0.5;

    setState(() {
      _color = color;
      if (_panelAtBottom != shouldBeAtBottom) {
        _panelAtBottom = shouldBeAtBottom;
      }
    });
  }

  void _copyHexToClipboard() {
    if (_color != null) {
      Clipboard.setData(
          ClipboardData(text: '#${_color!.hexRGB.toUpperCase()}'));
    }
  }

  void _copyRgbToClipboard() {
    if (_color != null) {
      final r = (_color!.r * 255).round();
      final g = (_color!.g * 255).round();
      final b = (_color!.b * 255).round();
      Clipboard.setData(ClipboardData(text: 'rgb($r, $g, $b)'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Stack(
        children: [
          // 透明层用于检测手指位置，但不阻止事件传递
          Positioned.fill(
            child: IgnorePointer(
              child: Builder(
                builder: (context) {
                  // 使用 EyeDrop 的 hover 回调来更新面板位置
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // 面板
          Positioned(
            left: 0,
            right: 0,
            top: _panelAtBottom ? null : 48,
            bottom: _panelAtBottom ? 48 : null,
            child: Center(child: _buildPanel()),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色预览 + 取色按钮
          CircleAvatar(
            radius: 32,
            backgroundColor: _color ?? Colors.grey.shade200,
            child: EyedropperButton(
              onColor: _onColorSelected,
              onColorChanged: _onColorChanged,
            ),
          ),
          const SizedBox(width: 12),
          // 颜色值显示
          _color == null
              ? Text(
                  '👈 点击取色',
                  style: _colorTextStyle.copyWith(
                      color: Colors.grey, fontSize: 16),
                )
              : _buildColorInfo(),
        ],
      ),
    );
  }

  Widget _buildColorInfo() {
    final hex = _color!.hexRGB.toUpperCase();
    final r = (_color!.r * 255).round();
    final g = (_color!.g * 255).round();
    final b = (_color!.b * 255).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEX（点击复制）
        GestureDetector(
          onTap: _copyHexToClipboard,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#',
                style:
                    _colorTextStyle.copyWith(color: Colors.grey, fontSize: 18),
              ),
              Text(
                hex.substring(0, 2),
                style:
                    _colorTextStyle.copyWith(color: Colors.red, fontSize: 18),
              ),
              Text(
                hex.substring(2, 4),
                style:
                    _colorTextStyle.copyWith(color: Colors.green, fontSize: 18),
              ),
              Text(
                hex.substring(4, 6),
                style:
                    _colorTextStyle.copyWith(color: Colors.blue, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // RGB（点击复制）
        GestureDetector(
          onTap: _copyRgbToClipboard,
          child: Text(
            'rgb($r, $g, $b)',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
