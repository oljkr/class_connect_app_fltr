import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class HomeWebView extends StatelessWidget {
  const HomeWebView({super.key});

  static const String _homeUrl = 'https://www.sososi.com';

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: AuthenticatedWebView(url: _homeUrl),
    );
  }
}
