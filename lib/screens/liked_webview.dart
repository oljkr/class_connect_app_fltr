import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class LikedWebView extends StatelessWidget {
  const LikedWebView({super.key});

  static const String _homeUrl = 'https://www.sososi.com/liked';

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: AuthenticatedWebView(url: _homeUrl),
    );
  }
}
