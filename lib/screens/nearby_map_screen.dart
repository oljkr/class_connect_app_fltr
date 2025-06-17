import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  late NLatLng _userPosition;
  List<NMarker> _markers = [];
  late NaverMapController _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initMap();
    });
  }

  Future<void> initMap() async {
    try {
      // 1. 현재 위치 감지
      final position = await _getCurrentPosition();
      final lat = position.latitude;
      final lng = position.longitude;
      _userPosition = NLatLng(lat, lng);

      // 2. Supabase에서 위치 목록 가져오기
      final locations = await _fetchAllLocations();

      // 3. 거리 필터링 (1km 이내)
      final nearby = locations.where((loc) {
        final dist = _calculateDistance(
          lat, lng, loc['lat'], loc['lng'],
        );
        return dist <= 1.0;
      }).toList();

      // 4. 마커 생성
      _markers = nearby.map((loc) {
        return NMarker(
          id: loc['id'].toString(),
          position: NLatLng(loc['lat'], loc['lng'])
        );
      }).toList();

      setState(() {});
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!serviceEnabled || permission == LocationPermission.deniedForever) {
      throw Exception("위치 권한 없음 또는 비활성화");
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<List<Map<String, dynamic>>> _fetchAllLocations() async {
    final res = await Supabase.instance.client
        .from('classes') // 👈 실제 테이블명으로 변경
        .select('*');
    return List<Map<String, dynamic>>.from(res);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // 지구 반지름 (km)
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 주변 위치")),
      body: _userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : NaverMap(
        onMapReady: (controller) {
          _mapController = controller;
        },
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
              target: _userPosition,
              zoom: 14,
              bearing: 0,
              tilt: 0
          ),
        )
      ),
    );
  }
}
