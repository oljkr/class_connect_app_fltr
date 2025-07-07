import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class GenericWebView extends StatelessWidget {
  final String url;

  const GenericWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AuthenticatedWebView(url: url),
    );
  }
}
