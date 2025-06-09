import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthenticatedWebView extends StatefulWidget {
  final String url;

  const AuthenticatedWebView({super.key, required this.url});

  @override
  State<AuthenticatedWebView> createState() => _AuthenticatedWebViewState();
}

class _AuthenticatedWebViewState extends State<AuthenticatedWebView> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    // 안드로이드용 플랫폼 WebView 설정 (필요 시 주석 해제)
    // if (Platform.isAndroid) {
    //   WebView.platform = SurfaceAndroidWebView();
    // }

    _initWebView();
  }

  Future<void> _initWebView() async {
    final newController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          // Flutter → Web 메시지 전달 제거됨
        },
      ))
      ..loadRequest(Uri.parse(widget.url));

    setState(() {
      _controller = newController;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _controller!);
  }
}
