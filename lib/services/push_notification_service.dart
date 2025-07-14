import 'dart:convert';

import 'package:http/http.dart' as http;

import '../consts/api_consts.dart';

class PushNotificationService {
  final String baseUrl = BASEURL;

  Future<String> manageDevice(String mode, String deviceType, String deviceId,
      {String? custId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/device/manage'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'mode': mode,
        'deviceType': deviceType,
        'deviceId': deviceId,
        if (custId != null) 'custId': custId,
      },
    );

    if (response.statusCode == 200) {
      print('FCM 토큰이 서버에 성공적으로 전송되었습니다.');
      return response.body;
    } else {
      print('FCM 토큰 전송 실패: ${response.statusCode}');
      throw Exception('Failed to manage device');
    }
  }

  Future<String> managePushNotification(String mode, String appCode,
      String notiCode, String deviceType, String deviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/manage'),
      body: {
        'mode': mode,
        'appCode': appCode,
        'notiCode': notiCode,
        'deviceType': deviceType,
        'deviceId': deviceId,
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to manage push notification');
    }
  }

  Future<List<dynamic>> getPushHistory(String deviceType, String deviceId,
      {String? appCode, String? receiveSuccesYn, String? qryStartDt}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/notifications/history?deviceType=$deviceType&deviceId=$deviceId${appCode != null ? '&appCode=$appCode' : ''}${receiveSuccesYn != null ? '&receiveSuccesYn=$receiveSuccesYn' : ''}${qryStartDt != null ? '&qryStartDt=$qryStartDt' : ''}'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get push history');
    }
  }

  Future<String> regDefaultNotification(String fcmToken, String appCode) async {
    print('Regist default notifications');
    // API를 호출하여 FCM 토큰과 사용자 ID를 연결하는 로직 구현
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/reg-default'),
      body: {'deviceId': fcmToken, 'appCode': appCode},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to regist default notifications');
    }
  }

  Future<String> regUserDefaultNotification(String fcmToken, String appCode) async {
    print('Regist user default notifications');
    // API를 호출하여 FCM 토큰과 사용자 ID를 연결하는 로직 구현
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/reg-user-default'),
      body: {'deviceId': fcmToken, 'appCode': appCode},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to regist user default notifications');
    }
  }

  Future<String> delUserDefaultNotification(String fcmToken, String appCode) async {
    print('Delete user default notifications');
    // API를 호출하여 FCM 토큰과 사용자 ID를 연결하는 로직 구현
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/del-user-default'),
      body: {'deviceId': fcmToken, 'appCode': appCode},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to delete user default notifications');
    }
  }

  Future<String> regMarketingNotification(
      String fcmToken, String appCode) async {
    print('Regist default marketing notifications');
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/reg-marketing'),
      body: {'deviceId': fcmToken, 'appCode': appCode},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to regist default markeing notifications');
    }
  }

  Future<void> updateDefaultNotiConsentInfo({
    required String fcmToken,
    required String appCode,
    required String defaultNotiConsent,
    required String loginYn,  // 로그인 여부 추가
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/update-default'),
      body: {
        'deviceId': fcmToken,
        'appCode': appCode,
        'defaultNotiConsent': defaultNotiConsent,
        'loginYn': loginYn,  // 로그인 여부 전송
      },
    );

    if (response.statusCode == 200) {
      print('Notification consent info updated successfully');
    } else {
      throw Exception('Failed to update notification consent info');
    }
  }

  Future<void> updateMarketingNotiConsentInfo({
    required String deviceId,
    required String appCode,
    required String marketingNotiConsent,
    required String loginYn,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/update-marketing'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'deviceId': deviceId,
        'appCode': appCode,
        'marketingNotiConsent': marketingNotiConsent,
        'loginYn': loginYn,
      },
    );

    if (response.statusCode == 200) {
      print('Successfully updated marketing notification consent.');
    } else {
      print('Failed to update marketing notification consent: ${response.statusCode}');
      throw Exception('Failed to update marketing notification consent');
    }
  }

  Future<String> associateUserWithDevice(String fcmToken, String userId) async {
    print('Associating user with device');
    // API를 호출하여 FCM 토큰과 사용자 ID를 연결하는 로직 구현
    final response = await http.post(
      Uri.parse('$baseUrl/device/update-custid'),
      body: {'deviceId': fcmToken, 'custId': userId},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to associating user with device');
    }
  }

  Future<String> dissociateUserFromDevice(String fcmToken) async {
    print('Dissociating user with device');
    // API를 호출하여 FCM 토큰에 해당하는 사용자 ID를 해제하는 로직 구현
    final response = await http.post(
      Uri.parse('$baseUrl/device/delete-custid'),
      body: {'deviceId': fcmToken},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to dissociating user with device');
    }
  }

  Future<Map<String, dynamic>> fetchNotiConsentInfo(String fcmToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/noti-consent-info?deviceId=$fcmToken'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get notification consent info');
    }
  }


}
