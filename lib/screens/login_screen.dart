import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';
import 'dart:ui'; // ImageFilter를 사용하기 위해 추가
import 'package:flutter_svg/flutter_svg.dart'; // flutter_svg 패키지 임포트

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late final StreamSubscription<AuthState> _authStateSubscription;
  Session? session;
  bool _handledLoginRedirect = false;

  @override
  void initState() {
    super.initState();

    session = Supabase.instance.client.auth.currentSession;
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedIn && !_handledLoginRedirect) {
        _handledLoginRedirect = true;
        print('User is signed in');

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(isFirstRun: false, initialIndex: 2),
          ),
              (Route<dynamic> route) => false, // 모든 이전 경로를 제거
        );

      }
    });
  }



  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final AuthResponse response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        // 로그인 성공 시
        // Navigator.pushReplacementNamed(context, '/mypage');
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb ? null : 'tarotapp://login-callback/',
      );

      if (res == false) {
        setState(() {
          _errorMessage = 'Social login failed. Please try again later.';
        });
      }
      // 여기서 Navigator.pushReplacementNamed를 호출하지 않습니다.
      // 대신 AuthState 리스너가 로그인 성공을 감지하고 처리할 것입니다.
    } catch (e) {
      setState(() {
        _errorMessage = 'Social login failed. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    try {
      String? webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign-in was cancelled.');
        return; // 사용자가 로그인 과정을 취소한 경우
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        print('Failed to retrieve Access Token or ID Token.');
        return;
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null) {
        print('Supabase sign-in successful.');
        // Navigator.pushReplacementNamed(context, '/mypage');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(isFirstRun: false, initialIndex: 2),
          ),
              (Route<dynamic> route) => false, // 모든 이전 경로를 제거
        );
      } else {
        print('Supabase sign-in failed.');
        setState(() {
          _errorMessage = 'Supabase sign-in failed.';
        });
      }
    } catch (e) {
      print('An error occurred during Google sign-in: $e');
      if (e is PlatformException) {
        print(
            'Error details: ${e.message}, code: ${e.code}, details: ${e.details}');
      }
      setState(() {
        _errorMessage = 'An error occurred during Google sign-in: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.transparent,
                floating: true,
                snap: true,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 50.0,
                iconTheme: IconThemeData(
                  color: Colors.white,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(50, 100, 50, 0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 0, 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter:
                              ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFfefcfc).withOpacity(1.0),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.1,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 10),
                                child: GestureDetector(
                                  onTap: _nativeGoogleSignIn,
                                  child: Row(
                                    children: [
                                      SvgPicture.network(
                                        'https://vismpynytzpoaspqrcvn.supabase.co/storage/v1/object/public/sososi/googleSocialLoginLogo1.svg',
                                        height: 50,
                                        width: 50,
                                        placeholderBuilder: (BuildContext context) => CircularProgressIndicator(),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '구글로 로그인',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 5), // 간격 추가
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 0, 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: BackdropFilter(
                              filter:
                              ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFfee500).withOpacity(1.0),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.1,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 13, horizontal: 20),
                                child: GestureDetector(
                                  onTap: () => _socialLogin('kakao'),
                                  child: Row(
                                    children: [
                                      Image.network(
                                        'https://vismpynytzpoaspqrcvn.supabase.co/storage/v1/object/public/sososi/kakaoLoginLogo.png',
                                        height: 26,
                                        width: 26,
                                        fit: BoxFit.contain, // 필요시 추가
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return SizedBox(
                                            height: 26,
                                            width: 26,
                                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.error, size: 26);
                                        },
                                      ),
                                      SizedBox(width: 23),
                                      Expanded(
                                        child: Text(
                                          '카카오로 로그인',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
