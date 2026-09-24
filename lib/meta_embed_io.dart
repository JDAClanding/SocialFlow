import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import 'widgets.dart';

/// Windows desktop: embed with Edge WebView2.
bool get canEmbedWeb => Platform.isWindows;

Widget embeddedWeb(String url, {double height = 640}) =>
    SizedBox(height: height, child: _EmbeddedWebView(url: url));

class _EmbeddedWebView extends StatefulWidget {
  final String url;
  const _EmbeddedWebView({required this.url});

  @override
  State<_EmbeddedWebView> createState() => _EmbeddedWebViewState();
}

class _EmbeddedWebViewState extends State<_EmbeddedWebView> {
  final _c = WebviewController();
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _c.initialize();
      await _c.loadUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Embedded browser unavailable — install the Microsoft Edge WebView2 Runtime. ($e)');
      }
    }
  }

  @override
  void didUpdateWidget(covariant _EmbeddedWebView old) {
    super.didUpdateWidget(old);
    if (_ready && old.url != widget.url) _c.loadUrl(widget.url);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: ErrText(_error!));
    if (!_ready) return const Center(child: Thinking('Opening Meta Ad Library…'));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Webview(_c),
    );
  }
}
