part of '../../flutter_ume_plus.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({
    super.key,
    this.action,
    this.minimalAction,
    this.closeAction,
  });

  final MenuAction? action;
  final MinimalAction? minimalAction;
  final CloseAction? closeAction;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  final _storeManager = PluginStoreManager();
  List<Pluggable?> _dataList = [];
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadPlugins();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

    _savePlugins(result);
    setState(() => _dataList = result);
  }

  void _savePlugins(List<Pluggable?> data) {
    final names = data.map((p) => p!.name).toList();
    if (names.isEmpty) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      _storeManager.storePlugins(names);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildActionButton(
                color: const Color(0xFFFF5F57),
                icon: Icons.close,
                onTap: widget.closeAction,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                color: const Color(0xFFFFBD2E),
                icon: Icons.remove,
                onTap: widget.minimalAction,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'UME',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_dataList.isEmpty) {
      return const Center(
        child: Text(
          'No plugins',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
      ),
      itemCount: _dataList.length,
      itemBuilder: (_, index) {
        final plugin = _dataList[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.action?.call(plugin);
            PluggableMessageService().resetCounter(plugin!);
          },
          child: _MenuCell(pluginData: plugin),
        );
      },
    );
  }
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({this.pluginData});

  final Pluggable? pluginData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconCache.icon(pluggableInfo: pluginData!),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    pluginData!.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: RedDot(pluginDatas: [pluginData], size: 18),
          ),
        ],
      ),
    );
  }
}
