// lib/services/update_checker.dart

import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String currentReleaseVersion = "1.0.0";

  static Future<void> checkAndHandleUpdate(BuildContext context) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    print('[UpdateChecker] 현재 앱 버전: $currentVersion');

    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero, // 무조건 새로 fetch
    ));

    await remoteConfig.setDefaults({
      'min_version': '1.0.0',
      'target_version': '1.0.0',
      'update_required': false,
      'update_message': '',
      'store_url': 'https://play.google.com/store/apps/details?id=com.sososi.class_connect_app_fltr',
    });

    bool fetchSuccess = false;
    try {
      fetchSuccess = await remoteConfig.fetchAndActivate();
      print('[UpdateChecker] Remote Config fetch 성공 여부: $fetchSuccess');
    } catch (e) {
      print('[UpdateChecker] Remote Config fetch 실패: $e');
    }

    if (!fetchSuccess) {
      if (_compareVersions(currentVersion, currentReleaseVersion) < 0) {
        _showForceUpdateDialog(context,
            message: "최신 기능을 사용하려면 앱을 업데이트해 주세요.",
            storeUrl: remoteConfig.getString('store_url'));
      }
      return;
    }

    final minVersion = remoteConfig.getString('min_version');
    final targetVersion = remoteConfig.getString('target_version');
    final updateRequired = remoteConfig.getBool('update_required');
    final updateMessage = remoteConfig.getString('update_message');
    final storeUrl = remoteConfig.getString('store_url');

    print('[UpdateChecker] Remote Config 값');
    print('  🔸 min_version: $minVersion');
    print('  🔸 target_version: $targetVersion');
    print('  🔸 update_required: $updateRequired');
    print('  🔸 update_message: $updateMessage');
    print('  🔸 store_url: $storeUrl');

    if (_compareVersions(currentVersion, minVersion) < 0) {
      _showForceUpdateDialog(context,
          message: "이 버전은 더 이상 지원되지 않습니다. 업데이트가 필요해요.",
          storeUrl: storeUrl);
    } else if (updateRequired &&
        _compareVersions(currentVersion, targetVersion) < 0) {
      _showOptionalUpdateDialog(context,
          message: updateMessage.isNotEmpty
              ? updateMessage
              : "새로운 기능이 추가되었어요. 지금 업데이트해 보세요!",
          storeUrl: storeUrl);
    }
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal < bVal) return -1;
      if (aVal > bVal) return 1;
    }
    return 0;
  }

  static void _showForceUpdateDialog(BuildContext context,
      {required String message, required String storeUrl}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white, // ← 배경 흰색으로 설정
        title: const Text("업데이트 필요"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(storeUrl),
                mode: LaunchMode.externalApplication),
            child: const Text("업데이트 하기"),
          ),
        ],
      ),
    );
  }

  static void _showOptionalUpdateDialog(BuildContext context,
      {required String message, required String storeUrl}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white, // ← 배경 흰색으로 설정
        title: const Text("업데이트 안내"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("다음에 하기"),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(storeUrl),
                mode: LaunchMode.externalApplication),
            child: const Text("업데이트 하기"),
          ),
        ],
      ),
    );
  }
}
