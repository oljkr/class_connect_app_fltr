import 'package:flutter/material.dart';
import 'class_applications_webview.dart';
import 'home_webview.dart';
import 'logout_screen.dart';
import 'mypage_webview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isFirstRun = false, this.initialIndex = 0});
  final bool isFirstRun;
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _buildBody() {
    if (_selectedIndex == 0) return const HomeWebView();
    if (_selectedIndex == 1) return const LogoutScreen();
    if (_selectedIndex == 2) return const ClassApplicationsWebView();
    if (_selectedIndex == 3) return const MyPageWebView();
    return const Center(child: Text('Unknown'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: '로그아웃'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '별조각'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}
