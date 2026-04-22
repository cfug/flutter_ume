import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ume_plus/flutter_ume_plus.dart';

import '../../flutter_ume_kit_dio_plus.dart';
import '../constants/extensions.dart';
import '../instances.dart';
import '../models/config.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
final _dioSettingCache = DioConfigUtil();

/// JSON 高亮工具类
class JsonHighlighter {
  static bool _initialized = false;
  static bool _initializing = false;

  static Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _initialized = true;
    _initializing = false;
  }

  static TextSpan? highlightCodeWithJson(String code) {
    try {
      // todo! 没有找到好的 json 高亮插件
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool get isReady => _initialized;
}

class DioPluggableState extends State<DioInspector> with StoreMixin {
  NavigatorState? get nav => widget.nav;

  final ScrollController scrollController = ScrollController();

  DioConfig _config = const DioConfig(); //配置

  bool _showSetting = false; //显示设置

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    InspectorInstance.httpContainer.addListener(_onResponseAdded);
    Future.microtask(() async {
      await JsonHighlighter.initialize();
      final value = await _dioSettingCache.getConfig();
      setState(() {
        _config = value;
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    InspectorInstance.httpContainer
      ..removeListener(_onResponseAdded)
      ..resetPaging();
    super.dispose();
  }

  void _onResponseAdded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listKey.currentState
          ?.insertItem(0, duration: const Duration(milliseconds: 300));
    });
  }

  void clearAll() {
    final httpContainer = InspectorInstance.httpContainer;
    httpContainer.removeListener(_onResponseAdded);

    final List<Response<dynamic>> requests = httpContainer.pagedRequests;
    final int initialLength = requests.length;

    for (int i = 0; i < initialLength; i++) {
      final Response<dynamic> response = requests[i];
      _listKey.currentState?.removeItem(
        0,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _ResponseCard(
            key: ValueKey<int>(response.startTimeMilliseconds),
            response: response,
            nav: nav,
            config: _config,
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );
    }

    httpContainer.clearRequests();
    httpContainer.addListener(_onResponseAdded);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget _itemList(BuildContext context) {
    final List<Response<dynamic>> requests =
        InspectorInstance.httpContainer.pagedRequests;
    if (requests.isNotEmpty) {
      return Scrollbar(
        controller: scrollController,
        child: AnimatedList(
          key: _listKey,
          controller: scrollController,
          initialItemCount: requests.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index, animation) {
            // 边界检查，防止 AnimatedList 内部状态与数据源不同步
            if (index < 0 || index >= requests.length) {
              return const SizedBox.shrink();
            }
            final Response<dynamic> r = requests[index];
            if (index == requests.length - 2) {
              InspectorInstance.httpContainer.loadNextPage();
            }
            return SizeTransition(
              sizeFactor: animation,
              child: _ResponseCard(
                key: ValueKey<int>(r.startTimeMilliseconds),
                response: r,
                nav: nav,
                config: _config,
              ),
            );
          },
        ),
      );
    }
    return const Center(
      child: Text(
        'Come back later...\n🧐',
        style: TextStyle(fontSize: 28),
        textAlign: TextAlign.center,
      ),
    );
  }

  ///
  @override
  Widget build(BuildContext context) {
    return FloatingWidget(
      toolbarActions: [
        UMEToolbarItem("设置", const Icon(Icons.settings), () {
          _dioSettingCache.getConfig().then((value) {
            setState(() {
              _config = value;
              _showSetting = !_showSetting;
            });
          });
        }),
        UMEToolbarItem("清空", Icon(Icons.delete), clearAll)
      ],
      contentWidget: Column(
        children: <Widget>[
          SettingWidget(
            show: _showSetting,
            config: _config,
            onChanged: (v) {
              setState(() {
                _config = v;
              });
            },
          ),
          Expanded(
            child: _itemList(context),
          ),
        ],
      ),
      onFullScreenChanged: (isFullScreen) {
        if (_showSetting) {
          _showSetting = false;
          setState(() {});
        }
      },
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required Key key,
    required this.response,
    this.nav,
    required this.config,
  }) : super(key: key);

  final Response<dynamic> response;
  final NavigatorState? nav;
  final DioConfig config;

  @override
  Widget build(BuildContext context) {
    final RequestOptions request = response.requestOptions;
    final DateTime startTime = response.startTime;
    final DateTime endTime = response.endTime;
    final Duration duration = endTime.difference(startTime);
    final int? statusCode = response.statusCode;

    final Color statusColor = _getStatusColor(statusCode);
    final String method = request.method;
    final String url =
        config.showFullUrl ? request.uri.toString() : request.uri.path;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTileTheme(
        dense: false,
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              side: BorderSide.none),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              side: BorderSide.none),
          title: _buildTitle(
            context,
            statusCode,
            statusColor,
            method,
            startTime,
            duration,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              url,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            _RequestDetails(
              response: response,
              config: config,
            ),
          ],
        ),
      ),
    );
  }

  /// 计算响应数据大小
  int _getResponseSize() {
    final data = response.data;
    if (data == null) return 0;

    if (data is String) {
      return utf8.encode(data).length;
    } else if (data is List<int>) {
      return data.length;
    } else if (data is Map || data is List) {
      return utf8.encode(jsonEncode(data)).length;
    }
    return utf8.encode(data.toString()).length;
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildTitle(
    BuildContext context,
    int? statusCode,
    Color statusColor,
    String method,
    DateTime startTime,
    Duration duration,
  ) {
    final responseSize = _getResponseSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusCode.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              method,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.visible,
            ),
            const SizedBox(width: 8),
            Text(
              startTime.hms(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            if (responseSize > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatBytes(responseSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            Text(
              '${duration.inMilliseconds}ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) {
      return Colors.grey;
    }
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green.shade600;
    }
    if (statusCode >= 300 && statusCode < 400) {
      return Colors.orange.shade600;
    }
    if (statusCode >= 400 && statusCode < 500) {
      return Colors.purple.shade600;
    }
    if (statusCode >= 500 && statusCode < 600) {
      return Colors.red.shade600;
    }
    return Colors.blueAccent.shade400;
  }
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails({
    required this.response,
    required this.config,
  });

  final Response<dynamic> response;
  final DioConfig config;

  RequestOptions get _request => response.requestOptions;

  /// The start time for the [_request].
  DateTime get _startTime => response.startTime;

  /// The end time for the [_response].
  DateTime get _endTime => response.endTime;

  /// The duration between the request and the response.
  Duration get _duration => _endTime.difference(_startTime);

  /// Status code for the [_response].
  int get _statusCode => response.statusCode ?? 0;

  /// The method that the [_request] used.
  String get _method => _request.method;

  /// The [Uri] that the [_request] requested.
  Uri get _requestUri {
    return _request.uri;
  }

  String get _requestUrl {
    return config.showFullUrl ? _requestUri.toString() : _requestUri.path;
  }

  dynamic tryParseMap(String? data) {
    if (data != null) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  ///form data 参数
  String? get _formData {
    if (_request.data is FormData) {
      var stringMap = <String, dynamic>{};
      final data = _request.data as FormData;
      for (var element in data.fields) {
        stringMap[element.key] = element.value;
      }
      for (var element in data.files) {
        final file = element.value;
        stringMap['(file)${element.value.filename}'] = <String, dynamic>{
          "filename": file.filename,
          "contentType": '${file.contentType}',
          "length": file.length,
          "headers": file.headers,
          "field": element.key
        };
      }

      return _encoder.convert(stringMap);
    }
    return null;
  }

  /// Data for the [_request].
  String? get _requestDataBuilder {
    if (_request.data is Map || _request.data is List) {
      return _encoder.convert(_request.data);
    }
    if (_request.data is FormData) {
      return null;
    }
    return _request.data?.toString();
  }

  /// Data for the [_response].
  String? get _responseDataBuilder {
    final data = response.data;
    if (data == null) {
      return null;
    }

    if (data is List<dynamic>) {
      return _encoder.convert(data);
    }

    if (response.data is Map) {
      return _encoder.convert(response.data);
    }
    final dataString = response.data.toString();

    try {
      return _encoder.convert(jsonDecode(dataString));
    } catch (_) {
      return dataString;
    }
  }

  String? get _requestQueryBuilder {
    final q = _requestUri.queryParameters;
    if (q.isNotEmpty) {
      return _encoder.convert(q);
    }
    return q.toString();
  }

  ///获取全部的数据
  String getAll() {
    return _encoder.convert({
      config.urlKey: _requestUrl,
      config.methodKey: _method,
      config.timestampKey: _duration.inMilliseconds,
      config.timeKey: (_startTime.toIso8601String()),
      config.dataKey: tryParseMap(
          _formData ?? (_requestDataBuilder ?? _requestQueryBuilder)),
      config.statusKey: _statusCode,
      config.responseKey: tryParseMap(_responseDataBuilder)
    });
  }

  @override
  Widget build(BuildContext context) {
    final uri = response.realUri.toString();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config.showCopyButton)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CopyActionsBar(
                uri: uri,
                allData: getAll(),
              ),
            ),
          if (config.showRequestHeaders)
            _buildDetailItem(
              context,
              'Request Headers',
              _getRequestHeaders(),
              isJson: true,
            ),
          if (_getRequestBody() != null)
            _buildDetailItem(
              context,
              'Request Body',
              _getRequestBody(),
              isJson: true,
            ),
          if (config.showResponseHeaders)
            _buildDetailItem(
              context,
              'Response Headers',
              _getResponseHeaders(),
              isJson: true,
            ),
          _buildDetailItem(
            context,
            'Response Body',
            _getResponseBody(),
            isJson: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String title,
    String? content, {
    bool isJson = false,
  }) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    return _DetailSection(
      title: title,
      content: content,
      isJson: isJson,
      showCopyButton: config.showCopyButton,
    );
  }

  String? _getRequestHeaders() {
    final headers = response.requestOptions.headers;
    if (headers.isEmpty) {
      return null;
    }
    return const JsonEncoder.withIndent('  ').convert(headers);
  }

  String? _getRequestBody() {
    final data = response.requestOptions.data;
    if (data == null) {
      return null;
    }
    if (data is FormData) {
      final fields =
          data.fields.map((e) => '"${e.key}": "${e.value}"').join(',\n');
      final files = data.files
          .map((e) => '"${e.key}": "File: ${e.value.filename}"')
          .join(',\n');
      return '{\n$fields,\n$files\n}';
    }
    if (data is Map || data is List) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return data.toString();
  }

  String? _getResponseHeaders() {
    final headers = response.headers.map;
    if (headers.isEmpty) {
      return null;
    }
    return const JsonEncoder.withIndent('  ').convert(
      headers.map((key, value) => MapEntry(key, value.join(', '))),
    );
  }

  String? _getResponseBody() {
    final data = response.data;
    if (data == null) {
      return null;
    }
    if (data is Map || data is List) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    try {
      return const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(data.toString()));
    } catch (_) {
      return data.toString();
    }
  }
}

extension _DateTimeExtension on DateTime {
  String hms([String separator = ':']) => '$hour$separator'
      '${'$minute'.padLeft(2, '0')}$separator'
      '${'$second'.padLeft(2, '0')}';
}

/// 简洁的复制操作栏
class _CopyActionsBar extends StatefulWidget {
  const _CopyActionsBar({
    required this.uri,
    required this.allData,
  });

  final String uri;
  final String allData;

  @override
  State<_CopyActionsBar> createState() => _CopyActionsBarState();
}

class _CopyActionsBarState extends State<_CopyActionsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主按钮行
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '复制',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 展开的选项
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionChip(
                      icon: Icons.link_rounded,
                      label: 'URI',
                      onTap: () => Clipboard.setData(
                        ClipboardData(text: widget.uri),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionChip(
                      icon: Icons.data_object_rounded,
                      label: '全部数据',
                      onTap: () => Clipboard.setData(
                        ClipboardData(text: widget.allData),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 可折叠的详情区块组件
class _DetailSection extends StatefulWidget {
  const _DetailSection({
    required this.title,
    required this.content,
    this.isJson = false,
    this.showCopyButton = true,
  });

  final String title;
  final String content;
  final bool isJson;
  final bool showCopyButton;

  @override
  State<_DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<_DetailSection> {
  bool _expanded = false;
  bool _showFullContent = false;
  bool _contentReady = false;
  TextSpan? _highlightedSpan;

  // 大数据阈值：超过此长度时截断显示
  static const int _truncateThreshold = 10000;

  // 预览长度
  static const int _previewLength = 2000;

  bool get _isLargeContent => widget.content.length > _truncateThreshold;

  String get _displayContent {
    if (_isLargeContent && !_showFullContent) {
      return '${widget.content.substring(0, _previewLength)}\n\n... [数据过大，已截断，点击下方按钮查看完整内容] ...';
    }
    return widget.content;
  }

  void _onExpand() {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    setState(() {
      _expanded = true;
      _contentReady = false;
    });

    // 延迟处理内容，避免展开动画卡顿
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !_expanded) return;
      _prepareContent();
    });
  }

  void _prepareContent() {
    final content = _displayContent;
    if (widget.isJson && JsonHighlighter.isReady && content.length < 5000) {
      _highlightedSpan = JsonHighlighter.highlightCodeWithJson(content);
    } else {
      _highlightedSpan = null;
    }
    if (mounted) {
      setState(() => _contentReady = true);
    }
  }

  void _toggleFullContent() {
    setState(() {
      _showFullContent = !_showFullContent;
      _contentReady = false;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _prepareContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          InkWell(
            onTap: _onExpand,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getTitleColor(widget.title, colorScheme),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_isLargeContent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(widget.content.length / 1024).toStringAsFixed(1)}KB',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  if (widget.showCopyButton && _expanded)
                    _MiniIconButton(
                      icon: Icons.copy_rounded,
                      onTap: () => Clipboard.setData(
                        ClipboardData(text: widget.content),
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 内容区域
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _contentReady
                        ? SingleChildScrollView(
                            child: _highlightedSpan != null
                                ? SelectableText.rich(
                                    _highlightedSpan!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  )
                                : SelectableText(
                                    _displayContent,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      fontFamily: 'monospace',
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                  ),
                  if (_isLargeContent && _contentReady)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _toggleFullContent,
                        icon: Icon(
                          _showFullContent
                              ? Icons.unfold_less
                              : Icons.unfold_more,
                          size: 16,
                        ),
                        label: Text(
                          _showFullContent ? '收起' : '显示完整内容',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Color _getTitleColor(String title, ColorScheme colorScheme) {
    if (title.contains('Request')) {
      return colorScheme.primary;
    } else if (title.contains('Response')) {
      return colorScheme.tertiary;
    }
    return colorScheme.secondary;
  }
}

/// 迷你图标按钮
class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
