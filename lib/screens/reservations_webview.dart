import 'package:flutter/material.dart';
import '../widgets/authenticated_webview.dart';

class ReservationsWebView extends StatelessWidget {
  const ReservationsWebView({super.key});

  static const String _homeUrl = 'https://www.sososi.com/mypage/reservations';

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: AuthenticatedWebView(url: _homeUrl),
    );
  }
}
