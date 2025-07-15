import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/push_notification_manager.dart';
import '../services/supabase_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isGeneralNotificationEnabled = false; // 기본 알림 여부
  bool _isMarketingConsentEnabled = false; // 마케팅 수신 동의 여부
  final SupabaseService _supabaseService = SupabaseService();
  Session? session;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 저장된 설정 불러오기
  }

  @override
  void dispose() {
    super.dispose();
  }

  // api로 알림 수신 데이터를 가져오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> consentInfo =
    await PushNotificationManager(prefs).fetchNotiConsentInfo();
    // API로부터 받아온 값을 사용하여 상태 설정
    setState(() {
      _isGeneralNotificationEnabled =
          consentInfo['defaultNotiConsent']?.toLowerCase() ==
              'y'; // 'y'면 true, 그 외는 false
      _isMarketingConsentEnabled =
          consentInfo['marketingNotiConsent']?.toLowerCase() ==
              'y'; // 'y'면 true, 그 외는 false
    });
    // 확인용 디버깅 로그
    print('기본 알림 설정: $_isGeneralNotificationEnabled');
    print('마케팅 수신 동의: $_isMarketingConsentEnabled');
  }

  Future<void> _saveDefualtSettings(bool _isGeneralNotificationEnabled) async {
    print('기본 알림 설정 저장: $_isGeneralNotificationEnabled');
    final prefs = await SharedPreferences.getInstance();
    String loginYn = _supabaseService.isUserLoggedIn() ? 'y' : 'n'; // 로그인 여부 설정

    await PushNotificationManager(prefs).updateDefaultNotiConsentInfo(
      defaultNotiConsent:
      _isGeneralNotificationEnabled ? 'y' : 'n', // 'y' 또는 'n' 설정
    );

    // 로컬에 저장
    prefs.setBool('generalNotification', _isGeneralNotificationEnabled);
  }

  Future<void> _saveMarketingSettings(bool _isMarketingConsentEnabled) async {
    print('마케팅 알림 설정 저장: $_isMarketingConsentEnabled');
    final prefs = await SharedPreferences.getInstance();
    String loginYn = _supabaseService.isUserLoggedIn() ? 'y' : 'n'; // 로그인 여부 설정

    await PushNotificationManager(prefs).updateMarketingNotiConsentInfo(
      marketingNotiConsent:
      _isMarketingConsentEnabled ? 'y' : 'n', // 'y' 또는 'n' 설정
    );

    // 로컬에 저장
    prefs.setBool('marketingConsent', _isMarketingConsentEnabled);
  }

  // 설정을 SharedPreferences에 저장
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('generalNotification', _isGeneralNotificationEnabled);
    prefs.setBool('marketingConsent', _isMarketingConsentEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('알림 설정',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '앱 알림 설정을 관리하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: Text('기본 알림 받기',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            value: _isGeneralNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                _isGeneralNotificationEnabled = value;
              });
              _saveDefualtSettings(
                  _isGeneralNotificationEnabled); // 상태가 변경될 때마다 저장
            },
          ),
          Divider(color: Color(0xFFEAECEF), // 선 색상 설정
            thickness: 1, // 선의 두께 설정
            height: 1, // 간격 조절
          ),
          SwitchListTile(
            title: Text('마케팅 수신 동의',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            value: _isMarketingConsentEnabled,
            onChanged: (bool value) {
              setState(() {
                _isMarketingConsentEnabled = value;
              });
              _saveMarketingSettings(
                  _isMarketingConsentEnabled); // 상태가 변경될 때마다 저장
            },
          ),
        ],
      ),
    );
  }
}
