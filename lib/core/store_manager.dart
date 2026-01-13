part of '../flutter_ume_plus.dart';

class PluginStoreManager {
  static final PluginStoreManager _instance = PluginStoreManager._();
  factory PluginStoreManager() => _instance;
  PluginStoreManager._();

  static const _kPlugins = 'PluginStoreKey';
  static const _kMinimalToolbar = 'MinimalToolbarSwitch';
  static const _kFloatingPos = 'FloatingDotPos';

  SharedPreferences? _prefs;
  Timer? _posDebounceTimer;

  Future<SharedPreferences> get _sp async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<String>?> fetchStorePlugins() async {
    return (await _sp).getStringList(_kPlugins);
  }

  Future<void> storePlugins(List<String> plugins) async {
    if (plugins.isEmpty) return;
    await (await _sp).setStringList(_kPlugins, plugins);
  }

  Future<bool?> fetchMinimalToolbarSwitch() async {
    return (await _sp).getBool(_kMinimalToolbar);
  }

  Future<void> storeMinimalToolbarSwitch(bool value) async {
    await (await _sp).setBool(_kMinimalToolbar, value);
  }

  Future<String?> fetchFloatingDotPos() async {
    return (await _sp).getString(_kFloatingPos);
  }

  /// 防抖存储位置，避免拖拽时频繁写入
  void storeFloatingDotPos(double x, double y) {
    _posDebounceTimer?.cancel();
    _posDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await (await _sp).setString(_kFloatingPos, '$x,$y');
    });
  }
}
