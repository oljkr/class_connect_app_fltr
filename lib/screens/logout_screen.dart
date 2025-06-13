import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // HomeScreen import 위치에 맞게 수정하세요

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(isFirstRun: false, initialIndex: 3),
      ),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그아웃")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signOut(context),
          child: const Text("로그아웃"),
        ),
      ),
    );
  }
}
