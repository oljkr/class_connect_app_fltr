import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_manager.dart';
import '../services/update_checker.dart';
import 'class_applications_webview.dart';
import 'home_webview.dart';
import 'liked_webview.dart';
import 'mypage_webview.dart';
import 'nearby_map_screen.dart';
import 'reservations_webview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isFirstRun = false, this.initialIndex = 0});
  final bool isFirstRun;
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late FirebaseMessaging messaging;
  bool _showMarketingConsent = false;
  bool _showNotificationReminder = false;
  bool _showCompletionMessage = false;
  bool _marketingConsentCompleted = false;
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
    UpdateChecker.checkAndHandleUpdate(context);
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    messaging = FirebaseMessaging.instance;

    if (widget.isFirstRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMarketingConsentDialog();
      });
    }

    // if (widget.isFirstRun) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     await Future.delayed(Duration(milliseconds: 100));
    //     if (mounted) {
    //       _showMarketingConsentDialog();
    //     }
    //   });
    // }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (_showNotificationReminder) {
        final settings = await messaging.getNotificationSettings();
        setState(() {
          _showNotificationReminder = false;
          if (_marketingConsentCompleted &&
              settings.authorizationStatus == AuthorizationStatus.authorized) {
            //기본 알림 수신을 등록함
            _regDefaultNotification();
            // 마케팅 알림 수신을 등록함
            _registerMarketingNotification();
            _showCompletionMessage = true;
            _hideCompletionMessageAfterDelay();
          }
        });
      }
    }
  }

  void _hideCompletionMessageAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCompletionMessage = false;
        });
      }
    });
  }

  void _showMarketingConsentDialog() {
    setState(() {
      _showMarketingConsent = true;
    });
  }

  void _showNotificationReminderDialog() {
    setState(() {
      _showNotificationReminder = true;
    });
  }

  Future<void> _openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  void _showCompletionMessageAndHideAfterDelay() {
    setState(() {
      _showCompletionMessage = true;
    });
    _hideCompletionMessageAfterDelay();
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
        return const ReservationsWebView();
      case 4:
        return const MyPageWebView();
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 메인 콘텐츠
          _buildBody(),

          // 마케팅 동의 다이얼로그
          if (_showMarketingConsent)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMarketingConsentDialog(),
            ),

          // 알림 설정 다이얼로그
          if (_showNotificationReminder)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildNotificationReminderDialog(),
            ),

          // 완료 메시지
          if (_showCompletionMessage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: _buildCompletionMessage(),
            ),
        ],
      ),
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


  Widget _buildMarketingConsentDialog() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '마케팅 정보 수신에 동의하시겠습니까?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setBool('marketingConsent', true);
                  setState(() {
                    _showMarketingConsent = false;
                    _marketingConsentCompleted = true;
                  });
                  // 기기 알림 상태 확인
                  final settings = await messaging.getNotificationSettings();
                  if (settings.authorizationStatus ==
                      AuthorizationStatus.authorized) {
                    // 알림이 이미 허용된 경우
                    _showCompletionMessageAndHideAfterDelay();
                    // 마케팅 알림 수신을 등록함
                    _registerMarketingNotification();
                  } else {
                    // 알림이 허용되지 않은 경우
                    setState(() {
                      _showNotificationReminder = true;
                    });
                  }
                },
                child: Text('동의'),
              ),
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setBool('marketingConsent', false);
                  setState(() {
                    _showMarketingConsent = false;
                  });
                },
                child: Text('거부'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationReminderDialog() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '마케팅 앱 푸쉬 수신 동의가 완료됐어요.\n기기 알림 켜시면 할인, 쿠폰 소식을 알려드릴게요.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showNotificationReminder = false;
                    _marketingConsentCompleted = false;
                  });
                },
                child: Text('취소'),
              ),
              ElevatedButton(
                onPressed: _openNotificationSettings,
                child: Text('기기 알림 켜기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage() {
    String formattedDate = DateFormat('yy-MM-dd').format(DateTime.now());
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: Colors.black.withOpacity(0.7),
      child: Text(
        '$formattedDate 마케팅 앱 푸쉬 수신 동의가 완료됐어요.',
        style: TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _registerMarketingNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await PushNotificationManager(prefs).regMarketingNotification();
  }

  Future<void> _regDefaultNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await PushNotificationManager(prefs).regDefaultNotification();
  }


}
