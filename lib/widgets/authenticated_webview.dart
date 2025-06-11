import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Cookie, Platform;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class AuthenticatedWebView extends StatefulWidget {
  final String url;

  const AuthenticatedWebView({super.key, required this.url});

  @override
  State<AuthenticatedWebView> createState() => _AuthenticatedWebViewState();
}

class _AuthenticatedWebViewState extends State<AuthenticatedWebView> {
  late final WebViewController _controller;
  final cookieManager = WebviewCookieManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      debugPrint("❗ Supabase 세션이 존재하지 않습니다.");
      return;
    }

    final sessionJson = jsonEncode(session.toJson());

    // 👉 쿠키 설정
    // await cookieManager.setCookies([
    //   WebViewCookie(
    //     name: 'supabase-session',
    //     value: Uri.encodeComponent(sessionJson),
    //     domain: 'www.sososi.com',
    //     path: '/',
    //     // isHttpOnly: true, // JS에서 접근 못 하게 하려면 주석 해제
    //   ),
    // ]);

    // await cookieManager.setCookies([
    //   Cookie('supabase-session', Uri.encodeComponent(sessionJson))
    //     ..domain = 'www.sososi.com'
    //     ..expires = DateTime.now().add(Duration(days: 10))
    //     ..httpOnly = false
    // ]);

    await cookieManager.setCookies([
      Cookie('sb-access-token', session.accessToken)
        ..domain = 'www.sososi.com'
        ..expires = DateTime.now().add(Duration(days: 10))
        ..httpOnly = false,

      Cookie('sb-refresh-token', session.refreshToken ?? '')
        ..domain = 'www.sososi.com'
        ..expires = DateTime.now().add(Duration(days: 30))
        ..httpOnly = false,
    ]);


    // 플랫폼별 설정
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    );

    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setBackgroundColor(Colors.white);

    _controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (url) {
        log("✅ 페이지 로딩 완료: $url");
      },
    ));

    // Android 쿠키 허용
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      final AndroidWebViewCookieManager androidCookieManager =
      WebViewCookieManager().platform as AndroidWebViewCookieManager;
      await androidCookieManager.setAcceptThirdPartyCookies(androidController, true);
    }

    // 최종 페이지 바로 로딩
    await _controller.loadRequest(Uri.parse(widget.url));

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
