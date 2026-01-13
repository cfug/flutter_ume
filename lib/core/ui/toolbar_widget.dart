part of '../../flutter_ume_plus.dart';

const double _kHandleHeight = 32;
const double _kContentHeight = 88;

class ToolBarWidget extends StatefulWidget {
  const ToolBarWidget({
    super.key,
    this.action,
    this.maximalAction,
    this.closeAction,
  });

  final MenuAction? action;
  final CloseAction? closeAction;
  final MaximalAction? maximalAction;

  @override
  State<ToolBarWidget> createState() => _ToolBarWidgetState();
}

class _ToolBarWidgetState extends State<ToolBarWidget>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0; // 拖拽偏移量，0 表示底部，负值表示向上
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails details) {
    setState(() {
      // 限制拖拽范围：最多向上拖到屏幕顶部附近
      final maxUp =
          -(windowSize.height - _kContentHeight - _kHandleHeight - 100);
      _dragOffset = (_dragOffset + details.delta.dy).clamp(maxUp, 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: _slideAnim,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: _ToolBarBody(
            action: widget.action,
            onDrag: _onDrag,
            onClose: widget.closeAction,
            onMaximize: widget.maximalAction,
          ),
        ),
      ),
    );
  }
}

class _ToolBarBody extends StatefulWidget {
  const _ToolBarBody({
    this.action,
    this.onDrag,
    this.onClose,
    this.onMaximize,
  });

  final MenuAction? action;
  final Function(DragUpdateDetails)? onDrag;
  final CloseAction? onClose;
  final MaximalAction? onMaximize;

  @override
  State<_ToolBarBody> createState() => _ToolBarBodyState();
}

class _ToolBarBodyState extends State<_ToolBarBody> {
  final _storeManager = PluginStoreManager();
  List<Pluggable?> _plugins = [];

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    final stored = await _storeManager.fetchStorePlugins();
    final allPlugins = PluginManager.instance.pluginsMap;

    List<Pluggable?> result;
    if (stored == null || stored.isEmpty) {
      result = allPlugins.values.toList();
    } else {
      result = [
        ...stored.where(allPlugins.containsKey).map((k) => allPlugins[k]),
        ...allPlugins.keys
            .where((k) => !stored.contains(k))
            .map((k) => allPlugins[k]),
      ];
    }

    if (result.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _storeManager.storePlugins(result.map((p) => p!.name).toList());
      });
    }

    setState(() => _plugins = result);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildPluginList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 确保整个区域都能响应手势
      onVerticalDragUpdate: widget.onDrag,
      child: Container(
        height: _kHandleHeight,
        color: Colors.transparent, // 需要有颜色才能响应手势
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F57),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onMaximize,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF28C840),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginList() {
    return SizedBox(
      height: _kContentHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _plugins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, index) => _PluginItem(
          plugin: _plugins[index],
          onTap: widget.action,
        ),
      ),
    );
  }
}

class _PluginItem extends StatelessWidget {
  const _PluginItem({this.plugin, this.onTap});

  final Pluggable? plugin;
  final MenuAction? onTap;

  @override
  Widget build(BuildContext context) {
    if (plugin == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        PluggableMessageService().resetCounter(plugin!);
        onTap?.call(plugin);
      },
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconCache.icon(pluggableInfo: plugin!),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plugin!.name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 6,
              top: 0,
              child: RedDot(pluginDatas: [plugin]),
            ),
          ],
        ),
      ),
    );
  }
}
