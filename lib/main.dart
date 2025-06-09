import 'package:class_connect_app_fltr/screens/home_screen.dart';
import 'package:class_connect_app_fltr/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  await SupabaseService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // 웹뷰가 들어간 HomeScreen을 시작 화면으로 지정
    );
  }
}
