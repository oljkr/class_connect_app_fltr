import 'dart:io';

import 'package:class_connect_app_fltr/screens/error_screen.dart';
import 'package:class_connect_app_fltr/screens/generic_webview.dart';
import 'package:class_connect_app_fltr/screens/home_screen.dart';
import 'package:class_connect_app_fltr/services/push_notification_manager.dart';
import 'package:class_connect_app_fltr/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> requestNotificationPermission(
    PushNotificationManager pushNotificationManager) async {
  if (Platform.isIOS) {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // iOS의 경우, 알림 권한을 요청
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // 권한이 허용되었으므로 푸쉬 알림 등록을 서버에 전송
      await pushNotificationManager.regDefaultNotification();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  } else if (Platform.isAndroid) {
    // Android 13 이상에서 알림 권한 요청
    if (await Permission.notification.isDenied) {
      var status = await Permission.notification.request();
      if (status.isGranted) {
        // 권한이 허용되었으므로 푸쉬 알림 등록을 서버에 전송
        await pushNotificationManager.regDefaultNotification();
      }
    }
  }
}


Future<void> main() async {

  Future<void> _onSelectNotification(
      NotificationResponse notificationResponse) async {
    print('_onSelectNotification called');
    String? payload = notificationResponse.payload;

  }

  // 플러터 프레임워크가 앱을 실행할 준비가 될때까지 기다림
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await SupabaseService().initialize();

  // 앱 최초 실행 여부 확인
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

  // PushNotificationManager 인스턴스를 생성하고 초기화합니다.
  PushNotificationManager pushNotificationManager =
  PushNotificationManager(prefs);
  await pushNotificationManager.initializePushNotifications();

  if (isFirstRun) {
    await requestNotificationPermission(pushNotificationManager);
    await prefs.setBool('isFirstRun', false);
  }

  // FlutterLocalNotificationsPlugin 인스턴스 생성
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 알림 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  // FlutterLocalNotificationsPlugin 초기화 시 `onSelectNotification` 설정
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: _onSelectNotification, // 변경된 부분
  );

  // 알림 채널 설정
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 앱이 포그라운드 상태에서 푸시 알림을 수신할 때 호출됩니다.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("foreground message received: ${message.notification?.body}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['targetPage'],
      );
    }

    // 백그라운드에서 메세지를 수신할 때 알림을 처리
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  });


  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey, // Add this line
    home: HomeScreen(isFirstRun: isFirstRun), // 웹뷰가 들어간 HomeScreen을 시작 화면으로 지정
  ));

  // 앱이 백그라운드 상태에서(그러니까 실행은 한 상태) 푸시 알림을 클릭해 열릴 때 호출됩니다.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('background Message clicked!');
    print('Message ${message}');
    print('Message data: ${message.data}');

    // 배지를 표시하는 메서드를 호출합니다.
    // homeScreenKey.currentState!.showBadge();

    // messageId를 String으로 변환
    String id = message.data['messageId']?.toString() ?? 'unknown';
    String url = 'https://www.sososi.com/messages/$id';

    // 푸시 알림이 클릭되었을 때의 처리
    if (message.data['targetPage'] != null) {
      // 원하는 페이지로 이동
      String targetPage = message.data['targetPage'];

      // 예시: Flutter의 Navigator를 이용하여 페이지 이동
      if (targetPage == "messages") {
        print('go to message page');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => GenericWebView(url: url),
          ),
        );
      } else {
        print('🚫 알 수 없는 targetPage: $targetPage');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ErrorScreen(
              message: '알 수 없는 페이지 요청입니다: $targetPage',
            ),
          ),
        );
      }
    }
  });

  // 앱을 아예 껐을 때 알림을 탭하면 내가 본 타로 결과로 이동함
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    print('after clicked, Initial message');
    if (message != null) {
      // 초기 메시지 데이터 처리
      print('Initial message: ${message.data}');
      // 푸시 알림이 클릭되었을 때의 처리
      if (message.data['targetPage'] != null) {
        // 원하는 페이지로 이동
        String targetPage = message.data['targetPage'];
      }
    }
  });


}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HomeScreen(isFirstRun: isFirstRun), // 웹뷰가 들어간 HomeScreen을 시작 화면으로 지정
//     );
//   }
// }
