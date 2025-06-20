import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Cookie, Platform;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

import '../screens/class_detail_webview.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';

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
    print('_checkLoginStatus:: session: $session');
    final accessToken = session?.accessToken;
    final refreshToken = session?.refreshToken;

    print('🟢 accessToken: $accessToken');
    print('🟢 refreshToken: $refreshToken');

    if (session != null) {
      // 세션이 있을 경우에만 쿠키 설정
      await cookieManager.setCookies([
        Cookie('supabase.auth.token', Uri.encodeComponent(jsonEncode({
          'access_token': accessToken,
          'refresh_token': refreshToken,
        })))
          ..domain = 'www.sososi.com'
          ..path = '/'
          ..expires = DateTime.now().add(Duration(days: 10))
          ..httpOnly = false,
      ]);
    } else {
      debugPrint("⚠️ Supabase 세션이 없음 → 쿠키 설정 생략");
    }

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
      onNavigationRequest: (request) async {
        final url = request.url;

        if (url == 'sososi://go-to-native-settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
          return NavigationDecision.prevent; // 웹뷰에선 열지 않도록
        }

        if (url == 'sososi://login') {
          debugPrint("📲 딥링크 로그인 감지됨 → 로그인 페이지로 이동");

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
          return NavigationDecision.prevent;
        }

        if (url == 'sososi://logout') {
          debugPrint("📲 딥링크 로그아웃 감지됨 → Supabase 로그아웃 실행");

          await Supabase.instance.client.auth.signOut();

          if (!mounted) return NavigationDecision.prevent;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(isFirstRun: false, initialIndex: 0),
            ),
                (Route<dynamic> route) => false, // 모든 이전 경로를 제거
          );
          return NavigationDecision.prevent;
        }

        if (url.startsWith('sososi://class-detail/')) {
          final classNo = int.tryParse(url.split('/').last); // ex: 14
          if (classNo != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClassDetailWebView(classNo: classNo)),
            );
          }
          return NavigationDecision.prevent;
        }

        if (url == 'sososi://goBack') {
          Navigator.of(context).maybePop(); // 혹은 원하는 페이지로 이동
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
        onPageFinished: (url) async {
          log("✅ 페이지 로딩 완료: $url");

          await Future.delayed(Duration(milliseconds: 300));
          await _controller.runJavaScript("""
    (function() {
      const event = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window
      });
      document.body.dispatchEvent(event);
      window.scrollTo(0, 1);
      window.scrollTo(0, 0);
      document.body.focus();
      window.dispatchEvent(new Event('resize'));
    })();
  """);
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