part of '../../flutter_ume_plus.dart';

const defaultLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

/// Wrap your App widget. If [enable] is false, the function will return [child].
class UMEWidget extends StatefulWidget {
  const UMEWidget({
    super.key,
    required this.child,
    this.enable = true,
    this.supportedLocales,
    this.localizationsDelegates = defaultLocalizationsDelegates,
    this.floatingButtonSize = const Size(65.0, 65.0),
    this.logoSize = 40.0,
  });

  final Widget child;
  final bool enable;
  final Iterable<Locale>? supportedLocales;
  final Iterable<LocalizationsDelegate> localizationsDelegates;
  final Size floatingButtonSize;
  final double logoSize;

  /// Close the activated plugin if any.
  ///
  /// The method does not have side-effects whether the [UMEWidget]
  /// is not enabled or no plugin has been activated.
  static void closeActivatedPlugin() {
    final _ContentPageState? state =
        _umeWidgetState?._contentPageKey.currentState;
    if (state?._currentSelected != null) {
      state?._closeActivatedPluggable();
    }
  }

  /// Get the currently activated plugin.
  ///
  /// Returns null if no plugin is currently activated.
  static Pluggable? getCurrentActivatedPlugin() {
    final _ContentPageState? state =
        _umeWidgetState?._contentPageKey.currentState;
    return state?._currentSelected;
  }

  /// Check if a specific plugin is currently activated.
  static bool isPluginActivated(String pluginName) {
    final currentPlugin = getCurrentActivatedPlugin();
    return currentPlugin?.name == pluginName;
  }

  @override
  _UMEWidgetState createState() => _UMEWidgetState();
}

/// Hold the [_UMEWidgetState] as a global variable.
_UMEWidgetState? _umeWidgetState;

class _UMEWidgetState extends State<UMEWidget> {
  _UMEWidgetState() {
    // Make sure only a single `UMEWidget` is being used.
    assert(
      _umeWidgetState == null,
      'Only one `UMEWidget` can be used at the same time.',
    );
    if (_umeWidgetState != null) {
      throw StateError('Only one `UMEWidget` can be used at the same time.');
    }
    _umeWidgetState = this;
  }

  final GlobalKey<_ContentPageState> _contentPageKey = GlobalKey();
  late Widget _child;
  VoidCallback? _onMetricsChanged;

  bool _overlayEntryInserted = false;
  OverlayEntry _overlayEntry = OverlayEntry(
    builder: (_) => const SizedBox.shrink(),
  );

  @override
  void initState() {
    super.initState();
    _replaceChild();
    _injectOverlay();

    _onMetricsChanged =
        bindingAmbiguate(WidgetsBinding.instance)!.window.onMetricsChanged;
    bindingAmbiguate(WidgetsBinding.instance)!.window.onMetricsChanged = () {
      if (_onMetricsChanged != null) {
        _onMetricsChanged!();
        _replaceChild();
        setState(() {});
      }
    };
  }

  @override
  void dispose() {
    if (_onMetricsChanged != null) {
      bindingAmbiguate(WidgetsBinding.instance)!.window.onMetricsChanged =
          _onMetricsChanged;
    }
    super.dispose();
    // Do the cleaning at last.
    _umeWidgetState = null;
  }

  @override
  void didUpdateWidget(UMEWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.enable
        ? PluggableMessageService().resetListener()
        : PluggableMessageService().clearListener();
    if (widget.enable != oldWidget.enable && widget.enable) {
      _injectOverlay();
    }
    if (widget.child != oldWidget.child) {
      _replaceChild();
    }
    if (!widget.enable) {
      _removeOverlay();
    }
  }

  void _replaceChild() {
    final nestedWidgets =
        PluginManager.instance.pluginsMap.values.where((value) {
      return value != null && value is PluggableWithNestedWidget;
    }).toList();
    Widget layoutChild = _buildLayout(
        widget.child, widget.supportedLocales, widget.localizationsDelegates);
    for (var item in nestedWidgets) {
      if (item!.name != PluginManager.instance.activatedPluggableName) {
        continue;
      }
      if (item is PluggableWithNestedWidget) {
        layoutChild = item.buildNestedWidget(layoutChild);
        break;
      }
    }
    _child =
        Directionality(textDirection: TextDirection.ltr, child: layoutChild);
  }

  Stack _buildLayout(Widget child, Iterable<Locale>? supportedLocales,
      Iterable<LocalizationsDelegate> delegates) {
    return Stack(
      children: <Widget>[
        RepaintBoundary(key: rootKey, child: child),
        MediaQuery(
          data: MediaQueryData.fromView(
              bindingAmbiguate(WidgetsBinding.instance)!.window),
          child: Localizations(
            locale: supportedLocales?.first ?? const Locale('en', 'US'),
            delegates: delegates.toList(),
            child: ScaffoldMessenger(child: Overlay(key: overlayKey)),
          ),
        ),
      ],
    );
  }

  void _removeOverlay() {
    // Call `remove` only when the entry has been inserted.
    if (_overlayEntryInserted) {
      _overlayEntry.remove();
      _overlayEntryInserted = false;
    }
  }

  void _injectOverlay() {
    bindingAmbiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) {
      if (_overlayEntryInserted) {
        return;
      }
      if (widget.enable) {
        _overlayEntry = OverlayEntry(
          builder: (_) => Material(
            type: MaterialType.transparency,
            child: _ContentPage(
              key: _contentPageKey,
              floatingButtonSize: widget.floatingButtonSize,
              logoSize: widget.logoSize,
              refreshChildLayout: () {
                _replaceChild();
                setState(() {});
              },
            ),
          ),
        );
        overlayKey.currentState?.insert(_overlayEntry);
        _overlayEntryInserted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) => _child;
}

class _ContentPage extends StatefulWidget {
  const _ContentPage(
      {super.key,
      this.refreshChildLayout,
      required this.floatingButtonSize,
      required this.logoSize});

  final VoidCallback? refreshChildLayout;
  final Size floatingButtonSize;
  final double logoSize;

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<_ContentPage> {
  final PluginStoreManager _storeManager = PluginStoreManager();
  Size _windowSize = windowSize;
  double _dx = 0;
  double _dy = 0;
  bool _showedMenu = false;
  Pluggable? _currentSelected;
  final Widget _empty = Container();
  Widget? _currentWidget;
  BuildContext? _context;
  bool _minimalContent = true;

  void dragEvent(DragUpdateDetails details) {
    _dx = details.globalPosition.dx - widget.floatingButtonSize.width / 2;
    _dy = details.globalPosition.dy - widget.floatingButtonSize.height / 2;
    setState(() {});
  }

  void dragEnd(DragEndDetails details) {
    if (_dx + widget.floatingButtonSize.width / 2 < _windowSize.width / 2) {
      _dx = margin;
    } else {
      _dx = _windowSize.width - widget.floatingButtonSize.width - margin;
    }
    if (_dy + widget.floatingButtonSize.height > _windowSize.height) {
      _dy = _windowSize.height - widget.floatingButtonSize.height - margin;
    } else if (_dy < 0) {
      _dy = margin;
    }

    _storeManager.storeFloatingDotPos(_dx, _dy);

    setState(() {});
  }

  void onTap() {
    if (_currentSelected != null) {
      _closeActivatedPluggable();
      return;
    }
    _showedMenu = !_showedMenu;
    _updatePanelWidget();
  }

  void _closeActivatedPluggable() {
    PluginManager.instance.deactivatePluggable(_currentSelected!);
    if (widget.refreshChildLayout != null) {
      widget.refreshChildLayout!();
    }
    _currentSelected = null;

    if (_minimalContent) {
      _showedMenu = true;
      _currentWidget = _buildToolbarWidget();
    } else {
      _showedMenu = false;
      _currentWidget = _empty;
    }
    setState(() {});
  }

  void _updatePanelWidget() {
    setState(() {
      _currentWidget = _showedMenu
          ? (_minimalContent ? _buildToolbarWidget() : _buildMenuPage())
          : _empty;
    });
  }

  Widget _buildToolbarWidget() {
    return ToolBarWidget(
      key: UniqueKey(),
      action: _itemTapAction,
      maximalAction: () {
        _minimalContent = false;
        _updatePanelWidget();
        PluginStoreManager().storeMinimalToolbarSwitch(false);
      },
      closeAction: () {
        _showedMenu = false;
        _updatePanelWidget();
      },
    );
  }

  Widget _buildMenuPage() {
    return MenuPage(
      key: UniqueKey(),
      action: _itemTapAction,
      minimalAction: () {
        _minimalContent = true;
        _updatePanelWidget();
        PluginStoreManager().storeMinimalToolbarSwitch(true);
      },
      closeAction: () {
        _showedMenu = false;
        _updatePanelWidget();
      },
    );
  }

  void _handleAction(BuildContext? context, Pluggable data) {
    _currentWidget = data.buildWidget(context);
    setState(() {
      _showedMenu = false;
    });
  }

  Widget _logoWidget() {
    Widget logo;
    Key key;

    if (_currentSelected != null) {
      key = ValueKey('plugin_${_currentSelected!.name}');
      logo = SizedBox(
        height: widget.logoSize,
        width: widget.logoSize,
        child: Image(image: _currentSelected!.iconImageProvider),
      );
    } else {
      key = ValueKey('flutter_logo_${_showedMenu ? 'active' : 'inactive'}');
      logo = FlutterLogo(
          size: widget.logoSize, colors: _showedMenu ? Colors.red : null);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: key,
        child: logo,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final ctx = context;
    _storeManager.fetchFloatingDotPos().then((value) {
      if (ctx.mounted) {
        final mq = MediaQuery.of(ctx);
        if (value == null || value.split(',').length != 2) {
          return;
        }
        final x = double.parse(value.split(',').first);
        final y = double.parse(value.split(',').last);
        if (mq.size.height - widget.floatingButtonSize.height < y ||
            mq.size.width - widget.floatingButtonSize.width < x) {
          return;
        }
        _dx = x;
        _dy = y;
        setState(() {});
      }
    });
    _storeManager.fetchMinimalToolbarSwitch().then((value) {
      setState(() {
        _minimalContent = value ?? true;
      });
    });
    _dx = _windowSize.width - widget.floatingButtonSize.width - margin * 4;
    _dy =
        _windowSize.height - widget.floatingButtonSize.height - bottomDistance;
    _currentWidget = _empty;
  }

  Future<void> _itemTapAction(dynamic pluginData) async {
    if (pluginData is PluggableWithAnywhereDoor) {
      dynamic result;
      if (pluginData.routeNameAndArgs != null) {
        result = await pluginData.navigator?.pushNamed(
            pluginData.routeNameAndArgs!.item1,
            arguments: pluginData.routeNameAndArgs!.item2);
      } else if (pluginData.route != null) {
        result = await pluginData.navigator?.push(pluginData.route!);
      }
      pluginData.popResultReceive(result);
    } else {
      _currentSelected = pluginData;
      if (_currentSelected != null) {
        PluginManager.instance.activatePluggable(_currentSelected!);
      }
      _handleAction(_context, pluginData!);
      if (widget.refreshChildLayout != null) {
        widget.refreshChildLayout!();
      }
      pluginData.onTrigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    if (_windowSize.isEmpty) {
      _dx = MediaQuery.of(context).size.width -
          widget.floatingButtonSize.width -
          margin * 4;
      _dy = MediaQuery.of(context).size.height -
          widget.floatingButtonSize.height -
          bottomDistance;
      _windowSize = MediaQuery.of(context).size;
    }
    return SizedBox(
      width: _windowSize.width,
      height: _windowSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _currentWidget ?? _empty,
          Positioned(
            left: _dx,
            top: _dy,
            child: Tooltip(
              message: 'Open ume panel',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (_) => onTap(),
                onPanUpdate: (details) {
                  _dx = details.globalPosition.dx -
                      widget.floatingButtonSize.width / 2;
                  _dy = details.globalPosition.dy -
                      widget.floatingButtonSize.height / 2;
                  setState(() {});
                },
                onPanEnd: (_) => dragEnd(DragEndDetails()),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0.0, 0.0),
                            blurRadius: 2.0,
                            spreadRadius: 1.0)
                      ]),
                  width: widget.floatingButtonSize.width,
                  height: widget.floatingButtonSize.height,
                  child: Stack(
                    children: [
                      Center(
                        child: _logoWidget(),
                      ),
                      Positioned(
                          right: 6,
                          top: 8,
                          child: RedDot(
                            pluginDatas: PluginManager
                                .instance.pluginsMap.values
                                .toList(),
                          ))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
