import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/authenticated_webview.dart';
import 'login_screen.dart';

class MyPageWebView extends StatefulWidget {
  const MyPageWebView({super.key});

  @override
  State<MyPageWebView> createState() => _MyPageWebViewState();
}

class _MyPageWebViewState extends State<MyPageWebView> {
  @override
  void initState() {
    super.initState();

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
    }
  }

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
