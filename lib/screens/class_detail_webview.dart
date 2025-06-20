import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class ClassDetailWebView extends StatelessWidget {
  final int classNo;
  const ClassDetailWebView({super.key, required this.classNo});

  @override
  Widget build(BuildContext context) {
    final url = 'https://www.sososi.com/classes/$classNo';
    return SafeArea(
      child: AuthenticatedWebView(url: url),
    );
  }
}
