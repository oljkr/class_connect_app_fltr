import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'class_applications_webview.dart';
import 'home_webview.dart';
import 'liked_webview.dart';
import 'mypage_webview.dart';
import 'nearby_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isFirstRun = false, this.initialIndex = 0});
  final bool isFirstRun;
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _tappedIndex = -1; // 탭 효과용 임시 인덱스

  final List<String> _filledIcons = [
    'assets/tabbar/home_filled.svg',
    'assets/tabbar/location_filled.svg',
    'assets/tabbar/heart_filled.svg',
    'assets/tabbar/calendar_filled.svg',
    'assets/tabbar/my_filled.svg',
  ];

  final List<String> _outlinedIcons = [
    'assets/tabbar/home_outline.svg',
    'assets/tabbar/location_outline.svg',
    'assets/tabbar/heart_outlined.svg',
    'assets/tabbar/calendar_outlined.svg',
    'assets/tabbar/my_outline.svg',
  ];

  final List<String> _labels = ['홈', '내근처', '찜', '예약', '마이'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeWebView();
      case 1:
        return const NearbyMapScreen();
      case 2:
        return const LikedWebView();
      case 3:
        return const Center(child: Text('예약'));
      case 4:
        return const MyPageWebView();
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFe8e8e8),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,       // ✅ Ripple 효과 제거
            highlightColor: Colors.transparent,          // ✅ 반짝임 제거
            splashColor: Colors.transparent,             // ✅ 물결 효과 제거
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _tappedIndex = index;
              });

              Future.delayed(const Duration(milliseconds: 100), () {
                setState(() {
                  _selectedIndex = index;
                  _tappedIndex = -1;
                });
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            items: List.generate(5, (index) {
              return BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(
                    top: index == 1 ? 1 : index == 2 ? 2 : 0,
                  ),
                  child: SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: _tappedIndex == index ? 0.85 : 1.0, // ✅ 작아졌다가 원상복구
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child: SvgPicture.asset(
                          _selectedIndex == index ? _filledIcons[index] : _outlinedIcons[index],
                          width: () {
                            if (index == 1) return _selectedIndex == index ? 26.0 : 24.0;
                            if (index == 2) return 20.0;
                            if (index == 4) return _selectedIndex == index ? 26.0 : 24.0;
                            return 24.0;
                          }(),
                          height: () {
                            if (index == 1) return _selectedIndex == index ? 26.0 : 24.0;
                            if (index == 2) return 20.0;
                            if (index == 4) return _selectedIndex == index ? 26.0 : 24.0;
                            return 24.0;
                          }(),
                        ),
                      ),
                    ),
                  ),
                ),
                label: _labels[index],
              );
            }),
          ),
        ),
      ),
    );
  }



}
