import 'dart:io' show Platform;
import 'package:class_connect_app_fltr/services/push_notification_service.dart';
import 'package:class_connect_app_fltr/services/supabase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationManager {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final PushNotificationService _pushService = PushNotificationService();
  final SupabaseService _supabaseService = SupabaseService();
  final SharedPreferences _prefs;

  PushNotificationManager(this._prefs);

  String _getDeviceType() {
    if (Platform.isAndroid) {
      return '01';
    } else if (Platform.isIOS) {
      return '02';
    } else {
      return '01'; // 기본값
    }
  }

  Future<void> initializePushNotifications() async {
    // FCM 토큰 가져오기
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    String appCode = 'com.sososi.class_connect_app_fltr';

    print('FCM token: $fcmToken');

    if (fcmToken != null) {
      bool shouldRegister = await _shouldRegisterDevice(fcmToken);

      if (shouldRegister) {
        await _registerDevice(fcmToken, appCode);
      }

      // 토큰 갱신 리스너 등록
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("New FCM Token: $newToken");
        _registerDevice(fcmToken, appCode);
      });

      // 사용자가 로그인되어 있는지 확인하고, 로그인되어 있다면 사용자 ID와 연결
      await _associateUserIfLoggedIn(fcmToken);
    } else {
      print('Failed to get FCM token');
    }

    // 로그인 상태 변경 리스너 설정
    _supabaseService.authStateChanges().listen((AuthState state) async {
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.tokenRefreshed) {
        _associateUserIfLoggedIn(fcmToken!);
        // 만약 기본 알림 설정이 'y'로 되어있으면 회원 수신 알림을 추가 등록함
        Map<String, dynamic> consentInfo = await fetchNotiConsentInfo();
        if (consentInfo['defaultNotiConsent'] == 'y') {
          regUserDefaultNotification();
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _dissociateUserOnLogout(fcmToken!);
        // 만약 기본 알림 설정이 'y'로 되어있으면 회원 수신 알림을 삭제함
        Map<String, dynamic> consentInfo = await fetchNotiConsentInfo();
        if (consentInfo['defaultNotiConsent'] == 'y') {
          delUserDefaultNotification();
        }
      }
    });
  }

  Future<bool> _shouldRegisterDevice(String fcmToken) async {
    String? savedFcmToken = _prefs.getString('fcm_token');
    if (fcmToken != savedFcmToken) return true;

    int? lastCheckTimestamp = _prefs.getInt('last_device_check');
    if (lastCheckTimestamp == null) return true;

    DateTime lastCheckDate =
    DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
    if (DateTime.now().difference(lastCheckDate).inDays >= 7) return true;

    String? savedAppVersion = _prefs.getString('app_version');
    String currentVersion =
    await PackageInfo.fromPlatform().then((info) => info.version);
    if (savedAppVersion != currentVersion) return true;

    return false;
  }

  Future<void> _registerDevice(String fcmToken, String appCode) async {
    try {
      await _pushService.manageDevice('reg', _getDeviceType(), fcmToken);

      // 새 토큰을 로컬에 저장
      await _prefs.setString('fcm_token', fcmToken);
      await _prefs.setInt(
          'last_device_check', DateTime.now().millisecondsSinceEpoch);

      String currentVersion =
      await PackageInfo.fromPlatform().then((info) => info.version);
      await _prefs.setString('app_version', currentVersion);
    } catch (e) {
      print('Error registering device: $e');
    }
  }

  Future<void> regDefaultNotification() async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';

      print('FCM token: $fcmToken');

      if (fcmToken != null) {
        await _pushService.regDefaultNotification(fcmToken, appCode);
      }
    } catch (e) {
      print('Error regist default notifications: $e');
    }
  }

  Future<void> regUserDefaultNotification() async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';

      print('FCM token: $fcmToken');

      if (fcmToken != null) {
        await _pushService.regUserDefaultNotification(fcmToken, appCode);
      }
    } catch (e) {
      print('Error regist default notifications: $e');
    }
  }

  Future<void> delUserDefaultNotification() async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';

      print('FCM token: $fcmToken');

      if (fcmToken != null) {
        await _pushService.delUserDefaultNotification(fcmToken, appCode);
      }
    } catch (e) {
      print('Error regist default notifications: $e');
    }
  }

  Future<void> regMarketingNotification() async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';

      print('FCM token: $fcmToken');

      if (fcmToken != null) {
        await _pushService.regMarketingNotification(fcmToken, appCode);
      }
    } catch (e) {
      print('Error regist default markeing notifications: $e');
    }
  }

  Future<void> updateDefaultNotiConsentInfo({
    required String defaultNotiConsent,
  }) async {
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';
      String loginYn =
      _supabaseService.isUserLoggedIn() ? 'y' : 'n'; // 로그인 여부 확인

      if (fcmToken != null) {
        // 알림 수신 동의 정보를 서버에 업데이트하는 API 호출
        await _pushService.updateDefaultNotiConsentInfo(
          fcmToken: fcmToken,
          appCode: appCode,
          defaultNotiConsent: defaultNotiConsent,
          loginYn: loginYn, // 로그인 여부 전송
        );
        print('Notification consent info updated successfully');
      } else {
        print('FCM token is missing');
      }
    } catch (e) {
      print('Error updating notification consent info: $e');
    }
  }

  Future<void> updateMarketingNotiConsentInfo({
    required String marketingNotiConsent,
  }) async {
    try {
      String? fcmToken = _prefs.getString('fcm_token');
      String appCode = 'com.sososi.class_connect_app_fltr';
      String loginYn = _prefs.getBool('isLoggedIn') == true ? 'y' : 'n';

      if (fcmToken != null) {
        await _pushService.updateMarketingNotiConsentInfo(
          deviceId: fcmToken,
          appCode: appCode,
          marketingNotiConsent: marketingNotiConsent,
          loginYn: loginYn,
        );
      }
    } catch (e) {
      print('Error updating marketing notification consent: $e');
    }
  }

  Future<void> _associateUserIfLoggedIn(String fcmToken) async {
    print('Checking if user is logged in');
    if (_supabaseService.isUserLoggedIn()) {
      String? userId = _supabaseService.getUserId();
      if (userId != null) {
        await associateUserWithDevice(userId, fcmToken);
      }
    }
  }

  Future<void> associateUserWithDevice(String userId, String fcmToken) async {
    print('Associating user with device');
    try {
      await _pushService.associateUserWithDevice(fcmToken, userId);
    } catch (e) {
      print('Error associating user with device: $e');
    }
  }

  Future<void> _dissociateUserOnLogout(String fcmToken) async {
    print('User is logging out');
    try {
      await dissociateUserFromDevice(fcmToken);
    } catch (e) {
      print('Error dissociating user from device: $e');
    }
  }

  Future<void> dissociateUserFromDevice(String fcmToken) async {
    print('Dissociating device from user');
    try {
      // FCM 토큰을 이용해 기기와의 연관성을 해제
      await _pushService.dissociateUserFromDevice(fcmToken);
    } catch (e) {
      print('Error dissociating device: $e');
    }
  }

  Future<Map<String, dynamic>> fetchNotiConsentInfo() async {
    Map<String, dynamic> consentInfo = {}; // Map으로 초기화
    try {
      // FCM 토큰 가져오기
      String? fcmToken = _prefs.getString('fcm_token');

      print(
          '[PushNotificationManager::fetchNotiConsentInfo] FCM token: $fcmToken');

      if (fcmToken != null) {
        consentInfo =
        await _pushService.fetchNotiConsentInfo(fcmToken); // 메서드 이름 수정
        // print(consentInfo); // {"defaultNotiConsent": "n", "marketingNotiConsent": "n"}
        return consentInfo;
      }

      return consentInfo; // FCM 토큰이 없을 때도 빈 Map 반환
    } catch (e) {
      print(e);
      return {}; // 예외가 발생했을 때도 빈 Map 반환
    }
  }
}
