import 'dart:convert';

import 'package:flutter_ume_plus/flutter_ume_plus.dart';

class DioConfig {
  final bool showCopyButton;
  final bool showFullUrl;
  final bool showResponseHeaders;
  final bool showRequestHeaders;
  final String urlKey;
  final String dataKey;
  final String responseKey;
  final String methodKey;
  final String statusKey;
  final String timestampKey;
  final String timeKey;

  // 1. 构造函数，包含默认值
  const DioConfig({
    this.showCopyButton = false,
    this.showFullUrl = false,
    this.showResponseHeaders = false,
    this.showRequestHeaders = true,
    this.urlKey = 'url',
    this.dataKey = '参数',
    this.responseKey = '返回',
    this.methodKey = '方法',
    this.statusKey = '状态码',
    this.timestampKey = '请求耗时',
    this.timeKey = '请求时间',
  });

  // 2. fromJson 函数
  factory DioConfig.fromJson(Map<String, dynamic> json) {
    return DioConfig(
      showCopyButton: json['showCopyButton'] as bool? ?? false,
      showFullUrl: json['showFullUrl'] as bool? ?? false,
      showResponseHeaders: json['showResponseHeaders'] as bool? ?? false,
      showRequestHeaders: json['showRequestHeaders'] as bool? ?? true,
      urlKey: json['urlKey'] as String? ?? 'url',
      dataKey: json['dataKey'] as String? ?? '参数',
      responseKey: json['responseKey'] as String? ?? '返回',
      methodKey: json['methodKey'] as String? ?? '方法',
      statusKey: json['statusKey'] as String? ?? '状态码',
      timestampKey: json['timestampKey'] as String? ?? '请求耗时',
      timeKey: json['timeKey'] as String? ?? '请求时间',
    );
  }

  // 3. toJson 函数
  Map<String, dynamic> toJson() {
    return {
      'showCopyButton': showCopyButton,
      'showFullUrl': showFullUrl,
      'showResponseHeaders': showResponseHeaders,
      'showRequestHeaders': showRequestHeaders,
      'urlKey': urlKey,
      'dataKey': dataKey,
      'responseKey': responseKey,
      'methodKey': methodKey,
      'statusKey': statusKey,
      'timestampKey': timestampKey,
      'timeKey': timeKey,
    };
  }

  // 4. copyWith 函数
  DioConfig copyWith({
    bool? showCopyButton,
    bool? showFullUrl,
    bool? showResponseHeaders,
    bool? showRequestHeaders,
    String? urlKey,
    String? dataKey,
    String? responseKey,
    String? methodKey,
    String? statusKey,
    String? timestampKey,
    String? timeKey,
  }) {
    return DioConfig(
      showCopyButton: showCopyButton ?? this.showCopyButton,
      showFullUrl: showFullUrl ?? this.showFullUrl,
      showResponseHeaders: showResponseHeaders ?? this.showResponseHeaders,
      showRequestHeaders: showRequestHeaders ?? this.showRequestHeaders,
      urlKey: urlKey ?? this.urlKey,
      dataKey: dataKey ?? this.dataKey,
      responseKey: responseKey ?? this.responseKey,
      methodKey: methodKey ?? this.methodKey,
      statusKey: statusKey ?? this.statusKey,
      timestampKey: timestampKey ?? this.timestampKey,
      timeKey: timeKey ?? this.timeKey,
    );
  }

  // 可选：实现对象对比 (freezed 默认有这个功能)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DioConfig &&
              runtimeType == other.runtimeType &&
              showCopyButton == other.showCopyButton &&
              showFullUrl == other.showFullUrl &&
              showResponseHeaders == other.showResponseHeaders &&
              showRequestHeaders == other.showRequestHeaders &&
              urlKey == other.urlKey &&
              dataKey == other.dataKey &&
              responseKey == other.responseKey &&
              methodKey == other.methodKey &&
              statusKey == other.statusKey &&
              timestampKey == other.timestampKey &&
              timeKey == other.timeKey;

  @override
  int get hashCode =>
      showCopyButton.hashCode ^
      showFullUrl.hashCode ^
      showResponseHeaders.hashCode ^
      showRequestHeaders.hashCode ^
      urlKey.hashCode ^
      dataKey.hashCode ^
      responseKey.hashCode ^
      methodKey.hashCode ^
      statusKey.hashCode ^
      timestampKey.hashCode ^
      timeKey.hashCode;
}

class DioConfigUtil with StoreMixin {
  final String _key = "_dio_config";

  ///加载配置
  Future<DioConfig> getConfig() async {
    final config = await fetchWithKey(_key);

    if (config is String) {
      try {
        return DioConfig.fromJson(jsonDecode(config));
      } catch (_) {}
    }
    return const DioConfig();
  }

  ///保存配置
  Future<void> saveConfig(DioConfig config) async {
    await storeWithKey(_key, jsonEncode(config));
  }
}
