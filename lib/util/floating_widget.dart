part of '../flutter_ume_plus.dart';

typedef ToolbarAction = void Function();
typedef UMEToolbarItem = Tuple3<String, Widget, ToolbarAction>;
typedef DragUpdateCallback = void Function(DragUpdateDetails details);
typedef DragEndCallback = void Function(DragEndDetails details);
typedef OnFullScreenChnagedCallback = void Function(bool isFullScreen);

class FloatingWidget extends StatefulWidget {
  const FloatingWidget(
      {super.key,
      this.contentWidget,
      this.closeAction,
      this.toolbarActions,
      this.minimalHeight = 260, //稍微增加一点高度给圆角留空间
      this.onFullScreenChanged});

  final Widget? contentWidget;
  final CloseAction? closeAction;
  final List<Tuple3<String, Widget, ToolbarAction>>? toolbarActions;
  final double minimalHeight;
  final OnFullScreenChnagedCallback? onFullScreenChanged;

  /// 获取浮动按钮的位置，用于关闭动画
  static Offset? getFloatingButtonPosition() {
    final state = _umeWidgetState?._contentPageKey.currentState;
    if (state != null) {
      return Offset(
          state._dx + dotSize.width / 2, state._dy + dotSize.height / 2);
    }
    return null;
  }

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

const double _kDragBarHeight = 32.0; // 稍微增高方便拖拽
const double _kToolBarHeight = 44.0; // 增加点击区域

class _FloatingWidgetState extends State<FloatingWidget>
    with TickerProviderStateMixin, StoreMixin {
  double _dy = 0;
  bool _fullScreen = false;
  bool _isDragging = false; // 新增：用于判断是否正在拖拽，避免动画冲突
  bool _isClosing = false; // 是否正在执行关闭动画

  // 新增：缩放控制器，用于入场动画
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // 关闭动画控制器
  late AnimationController _closeController;
  Offset? _closeTargetOffset; // 关闭动画目标位置（浮动按钮位置）
  Size _initialSize = Size.zero; // 动画开始时的面板尺寸

  double get _toolBarHeight =>
      (widget.toolbarActions?.isNotEmpty ?? false) ? _kToolBarHeight : 0;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();

    // 初始化缩放动画
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack, // 弹性效果
    );
    _scaleController.forward();

    // 初始化关闭动画
    _closeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _closeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 动画完成后执行真正的关闭
        final closeAction =
            widget.closeAction ?? UMEWidget.closeActivatedPlugin;
        closeAction();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosition() async {
    final savedPosition = await fetchWithKey('floating_widget');
    if (savedPosition != null && mounted) {
      setState(() {
        _dy = savedPosition;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dy == 0) {
      _dy = _calculateInitialPosition();
    }
  }

  double _calculateInitialPosition() {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        widget.minimalHeight -
        _kDragBarHeight -
        _toolBarHeight -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      final mediaQuery = MediaQuery.of(context);
      final maxDy =
          mediaQuery.size.height - _kDragBarHeight - mediaQuery.padding.top;

      _dy = (_dy + details.delta.dy).clamp(0.0, maxDy);
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    setState(() {
      _isDragging = false;
    });
    // 简单的吸附逻辑：如果拖动太高，自动全屏（可选）
    // if (_dy < 100) _toggleFullScreen();
    await storeWithKey('floating_widget', _dy);
  }

  void _toggleFullScreen() {
    _fullScreen = !_fullScreen;
    // 如果退出全屏，重置缩放动画带来一点视觉反馈
    if (!_fullScreen) {
      _scaleController.reset();
      _scaleController.forward();
    }
    widget.onFullScreenChanged?.call(_fullScreen);
    setState(() {});
  }

  /// 执行关闭动画
  void _animateClose() {
    if (_isClosing) return;
    _closeTargetOffset = FloatingWidget.getFloatingButtonPosition();
    // 记录当前面板尺寸
    final mediaQuery = MediaQuery.of(context);
    final visualHeight = _fullScreen
        ? mediaQuery.size.height
        : widget.minimalHeight +
            _kDragBarHeight +
            _toolBarHeight +
            mediaQuery.padding.bottom;
    final visualWidth = _fullScreen
        ? mediaQuery.size.width
        : mediaQuery.size.width - 32; // 减去左右 margin
    _initialSize = Size(visualWidth, visualHeight);

    setState(() {
      _isClosing = true;
    });
    _closeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // 计算当前 Top 位置
    double currentTop;
    if (_fullScreen) {
      currentTop = 0;
    } else {
      currentTop = _dy;
    }

    // 计算关闭动画的位移
    final targetOffset = _closeTargetOffset;
    final hasTarget = targetOffset != null && _isClosing;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _closeController,
          builder: (context, child) {
            final progress =
                Curves.easeInOutCubic.transform(_closeController.value);

            // 关闭动画：向浮动按钮位置收缩
            double translateX = 0;
            double translateY = 0;
            if (hasTarget && _initialSize != Size.zero) {
              // 目标尺寸
              const double targetSize = 56.0;
              // 当前动画中的高度
              final currentHeight = _initialSize.height +
                  (targetSize - _initialSize.height) * progress;

              // 面板当前中心点 X（始终在屏幕中央）
              final centerX = mediaQuery.size.width / 2;
              // 面板当前中心点 Y = top + 当前高度/2
              final centerY = currentTop + currentHeight / 2;

              // 目标位置是 logo 的中心
              translateX = (targetOffset.dx - centerX) * progress;
              translateY = (targetOffset.dy - centerY) * progress;
            }

            return AnimatedPositioned(
              duration: _isDragging || _isClosing
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              left: 0,
              right: 0,
              top: currentTop,
              height: mediaQuery.size.height,
              child: Transform.translate(
                offset: Offset(translateX, translateY),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _FloatingToolBarContent(
                    minimalHeight: widget.minimalHeight,
                    contentWidget: widget.contentWidget,
                    fullScreen: _fullScreen,
                    onDragUpdate: _handleDragUpdate,
                    onDragEnd: _handleDragEnd,
                    onToggleFullScreen: _toggleFullScreen,
                    onClose: _animateClose,
                    toolbarActions: widget.toolbarActions,
                    // 传递关闭动画参数
                    isClosing: _isClosing,
                    closeProgress: progress,
                    initialSize: _initialSize,
                  ),
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class _FloatingToolBarContent extends StatelessWidget {
  const _FloatingToolBarContent({
    required this.minimalHeight,
    required this.fullScreen,
    this.contentWidget,
    this.onDragUpdate,
    this.onDragEnd,
    this.onToggleFullScreen,
    this.onClose,
    this.toolbarActions,
    this.isClosing = false,
    this.closeProgress = 0.0,
    this.initialSize = Size.zero,
  });

  final Widget? contentWidget;
  final double minimalHeight;
  final bool fullScreen;
  final DragUpdateCallback? onDragUpdate;
  final DragEndCallback? onDragEnd;
  final VoidCallback? onToggleFullScreen;
  final CloseAction? onClose;
  final List<Tuple3<String, Widget, ToolbarAction>>? toolbarActions;

  // 关闭动画参数
  final bool isClosing;
  final double closeProgress;
  final Size initialSize;

  double get _toolBarHeight =>
      (toolbarActions?.isNotEmpty ?? false) ? _kToolBarHeight : 0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // 1. 计算视觉高度
    final double normalHeight = fullScreen
        ? mediaQuery.size.height
        : minimalHeight +
            _kDragBarHeight +
            _toolBarHeight +
            mediaQuery.padding.bottom;

    final double normalWidth =
        fullScreen ? mediaQuery.size.width : mediaQuery.size.width - 32;

    // 目标尺寸：浮动按钮大小
    const double targetSize = 56.0; // dotSize

    // 关闭动画：尺寸从当前大小变到圆形
    double visualHeight;
    double visualWidth;
    double borderRadius;

    if (isClosing && initialSize != Size.zero) {
      // 使用 easeInOutCubic 曲线让动画更平滑
      visualWidth =
          initialSize.width + (targetSize - initialSize.width) * closeProgress;
      visualHeight = initialSize.height +
          (targetSize - initialSize.height) * closeProgress;
      // 圆角从 24 变到完全圆形 (targetSize / 2)
      borderRadius = 24 + (targetSize / 2 - 24) * closeProgress;
    } else {
      visualHeight = normalHeight;
      visualWidth = normalWidth;
      borderRadius = 24;
    }

    // 关闭时的水平 margin 调整，让面板居中收缩
    final horizontalMargin = isClosing
        ? (mediaQuery.size.width - visualWidth) / 2
        : (fullScreen ? 0.0 : 16.0);

    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: AnimatedContainer(
        duration: isClosing ? Duration.zero : const Duration(milliseconds: 350),
        curve: Curves.fastOutSlowIn,
        height: visualHeight,
        width: isClosing ? visualWidth : null,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(
              isClosing ? borderRadius : (fullScreen ? 0 : 24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: isClosing
              ? const SizedBox.shrink() // 关闭动画时隐藏内容
              : Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: fullScreen ? mediaQuery.padding.top : 0,
                    ),
                    _buildDragBar(context),
                    _buildContent(),
                    if (toolbarActions?.isNotEmpty ?? false)
                      _buildToolbar(context),
                    if (fullScreen) SizedBox(height: mediaQuery.padding.bottom),
                  ],
                ),
        ),
      ),
    );
  }

// 1. 替换这个方法：构建顶部拖拽条
  Widget _buildDragBar(BuildContext context) {
    final activePluginName = PluginManager.instance.activatedPluggableName;
    return GestureDetector(
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 54, // 稍微增加高度，便于手指操作
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent, // 确保点击穿透
        child: Row(
          children: [
            _buildModernButton(
              onTap: onClose,
              icon: Icons.close_rounded,
              color: Colors.redAccent,
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              tooltip: 'Close',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    if (activePluginName != null && activePluginName.isNotEmpty)
                      Text(
                        activePluginName,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) {
                // 旋转 + 缩放动画
                return RotationTransition(
                  turns: child.key == const ValueKey('full')
                      ? Tween<double>(begin: 0.75, end: 1).animate(anim)
                      : Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: ScaleTransition(scale: anim, child: child),
                );
              },
              child: _buildModernButton(
                key: ValueKey(fullScreen ? 'normal' : 'full'), // 这一行很关键，触发动画
                onTap: onToggleFullScreen,
                // 根据状态切换图标
                icon: fullScreen
                    ? Icons.compress_rounded
                    : Icons.open_in_full_rounded,
                // 根据状态切换颜色
                color: fullScreen ? Colors.blueGrey : Colors.blueAccent,
                backgroundColor: fullScreen
                    ? Colors.grey.withValues(alpha: .15)
                    : Colors.blue.withValues(alpha: .1),
                tooltip: fullScreen ? 'Minimize' : 'Full Screen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. 替换/新增这个方法：通用的现代化按钮封装
  Widget _buildModernButton({
    Key? key,
    required VoidCallback? onTap,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    String? tooltip,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor, // 浅色背景
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: color, // 图标颜色
        ),
      ),
    );
  }

  // 更加简约的按钮封装

  Widget _buildContent() {
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: contentWidget ?? const SizedBox(),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: _kToolBarHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: toolbarActions!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _buildToolbarItem(toolbarActions![index]),
      ),
    );
  }

  Widget _buildToolbarItem(Tuple3<String, Widget, ToolbarAction> tuple) {
    return InkWell(
      onTap: tuple.item3,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 18, color: Colors.blueAccent.shade700),
              child: tuple.item2,
            ),
            const SizedBox(width: 6),
            Text(
              tuple.item1,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }
}
