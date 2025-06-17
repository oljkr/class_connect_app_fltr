import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  LatLng? _userPosition;
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  LatLng? _currentMapCenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initMap();
    });
  }

  Future<void> initMap() async {
    try {
      final position = await _getCurrentPosition();
      final lat = position.latitude;
      final lng = position.longitude;
      _userPosition = LatLng(lat, lng);

      await _loadMarkers(center: _userPosition!);
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  Future<void> _loadMarkers({required LatLng center}) async {
    try {
      final lat = center.latitude;
      final lng = center.longitude;

      final rawLocations = await _fetchAllLocations();
      final filteredLocations = rawLocations.where((loc) {
        final latVal = loc['lat'];
        final lngVal = loc['lng'];
        return latVal != null && lngVal != null && latVal != 0 && lngVal != 0;
      }).toList();

      final nearby = filteredLocations.where((loc) {
        final locLat = (loc['lat'] as num).toDouble();
        final locLng = (loc['lng'] as num).toDouble();
        final dist = _calculateDistance(lat, lng, locLat, locLng);
        print('거리: ${loc['title']} → ${dist.toStringAsFixed(2)} km');
        return dist <= 2.0;
      }).toList();

      setState(() {
        _markers.clear();
        for (var loc in nearby) {
          final id = loc['class_no'].toString();
          final locLat = (loc['lat'] as num).toDouble();
          final locLng = (loc['lng'] as num).toDouble();

          // 마커 ID 중복 체크 (로딩 중)
          if (_markers.any((m) => m.markerId.value == id)) {
            print('⚠️ 중복 마커 ID 감지: $id');
            continue;
          }

          _markers.add(
            Marker(
              markerId: MarkerId(id),
              position: LatLng(locLat, locLng),
              infoWindow: InfoWindow(title: loc['title'] ?? '장소'),
            ),
          );
        }

        print('✅ 마커 로드 완료: ${_markers.length}개');
      });
    } catch (e) {
      print('마커 로딩 중 에러: $e');
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
        .from('classes')
        .select('*');
    return List<Map<String, dynamic>>.from(res);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
  }

  Future<void> _onCameraIdle() async {
    if (_currentMapCenter == null) return;
    print('📌 카메라 이동 완료. 새로운 중심 좌표: $_currentMapCenter');
    await _loadMarkers(center: _currentMapCenter!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 주변 위치")),
      body: _userPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: _onMapCreated,
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
        initialCameraPosition: CameraPosition(
          target: _userPosition!,
          zoom: 16,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
