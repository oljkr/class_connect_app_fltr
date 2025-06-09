import 'package:flutter/material.dart';
import 'home_webview.dart';
import 'mypage_webview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isFirstRun = false});
  final bool isFirstRun;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeWebView(),
    Center(child: Text('별의 속삭임')),
    Center(child: Text('별조각')),
    MyPageWebView(), // ❗이제는 별도 페이지가 아닌 탭 내부로 편입
  ];

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 3) {
      setState(() => _selectedIndex = 0); // 마이페이지에서 홈으로 복귀
      return false; // 시스템 뒤로가기 동작 막음
    }
    return true; // 기본 동작 허용
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: '별의 속삭임'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '별조각'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
          ],
        ),
      ),
    );
  }
}
