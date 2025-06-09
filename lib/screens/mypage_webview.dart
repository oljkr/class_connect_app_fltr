import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class MyPageWebView extends StatelessWidget {
  const MyPageWebView({super.key});

  static const String _mypageUrl = 'https://www.sososi.com/mypage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: AuthenticatedWebView(url: _mypageUrl),
      ),
    );
  }
}
