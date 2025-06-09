import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  // You must initialize the supabase instance before calling Supabase.instance
  //위와 같은 에러로 객체 만들지 않고 함수 내에서 직접 사용함
  // final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchnumberOfCardsData(String svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('svc_info') // 데이터를 가져올 테이블 이름을 지정합니다.
          .select('spread!inner(number_of_cards)') // 선택할 컬럼들을 지정합니다.
          .eq('svc_no', svcNo)
          .single();

      return response;
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchDrawMsgData(String svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('draw_msg') // 데이터를 가져올 테이블 이름을 지정합니다.
          .select('msg') // 선택할 컬럼들을 지정합니다.
          .eq('svc_no', svcNo)
          .order('order', ascending: true);

      return response;
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  // 현재 로그인된 사용자 정보 가져오기
  User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  // 사용자 로그인 상태 확인
  bool isUserLoggedIn() {
    print(
        'isUserLoggedIn: ${Supabase.instance.client.auth.currentUser != null}');
    return Supabase.instance.client.auth.currentUser != null;
  }

  // 사용자 ID 가져오기
  String? getUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  // 로그인 상태 변경 리스너 설정
  Stream<AuthState> authStateChanges() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<bool> isTokenValid(String accessToken, String refreshToken) async {
    try {
      final session =
      await Supabase.instance.client.auth.setSession(refreshToken);
      return session != null;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // **추가된 MBTI 관련 메서드**
  Future<List<dynamic>?> fetchMbtiData() async {
    try {
      final response = await Supabase.instance.client
          .from('mbti_data')
          .select('mbti_no, mbti_nm')
          .order('mbti_no', ascending: true);
      print('MBTI data fetched: $response');
      return response as List<dynamic>?;
    } catch (e) {
      print('Error fetching MBTI data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSvcType(int svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('svc_info')
          .select('svc_type')
          .eq('svc_no', svcNo)
          .maybeSingle();
      print('Service type fetched: $response');
      return response;
    } catch (e) {
      print('Error fetching service type: $e');
      return null;
    }
  }

  // **svc_info 데이터를 가져오는 함수**
  Future<Map<String, dynamic>?> fetchSvcDetail(int svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('svc_info')
          .select('svc_no, svc_nm, subtitle, tags, detail, preview, price')
          .eq('svc_no', svcNo)
          .single();

      return response;
    } catch (e) {
      print('Error fetching service detail: $e');
      return null;
    }
  }

  // **review 데이터를 가져오는 함수**
  Future<List<Map<String, dynamic>>?> fetchReviews(int svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('review')
          .select('type, comment, profiles!inner(username)')
          .eq('svc_no', svcNo)
          .eq('valid_yn', true)
          .order('order', ascending: true)
          .order('rating', ascending: false)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching reviews: $e');
      return null;
    }
  }

  // **svc_recommend_conn 데이터를 가져오는 함수**
  Future<List<Map<String, dynamic>>?> fetchSvcRecommendations(int svcNo) async {
    try {
      final response = await Supabase.instance.client
          .from('svc_recommend_conn')
          .select(
          'rec_svc_no, rec_comment, svc_info!svc_recommend_conn_rec_svc_no_fkey(svc_no, svc_nm, tags)')
          .eq('svc_no', svcNo)
          .eq('valid_yn', true)
          .order('order', ascending: true);

      return response;
    } catch (e) {
      print('Error fetching service recommendations: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchLikeServiceData(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('like_svc')
          .select('*, svc_info!inner(svc_no, svc_nm, svc_type, subtitle, tags)')
          .eq('cust_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      print('Error fetching like service data: $e');
      return [];
    }
  }
}
