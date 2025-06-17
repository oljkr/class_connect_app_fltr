import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
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

      final Set<Marker> newMarkers = {};

      for (var loc in nearby) {
        final id = loc['class_no'].toString();
        final locLat = (loc['lat'] as num).toDouble();
        final locLng = (loc['lng'] as num).toDouble();
        final title = loc['title']?.toString() ?? '클래스';

        // final icon = await createCustomMarkerBitmap(title);
        final icon = await createBalloonMarkerBitmap(title);

        newMarkers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(locLat, locLng),
            icon: icon,
          ),
        );
      }

      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });

      print('✅ 마커 로드 완료: ${_markers.length}개');
    } catch (e) {
      print('마커 로딩 중 에러: $e');
    }
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap(String text) async {
    const int width = 300;
    const int height = 100;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = const Color(0xFF2196F3);
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 30,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: width.toDouble(),
      maxWidth: width.toDouble(),
    );
    textPainter.paint(canvas, Offset(0, (height - textPainter.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> createBalloonMarkerBitmap(String text) async {
    // 👇 padding 값 추가
    const double paddingX = 5;
    const double paddingY = 5;

    // 1. 텍스트 자르기
    const maxLength = 25;
    if (text.length > maxLength) {
      text = text.substring(0, maxLength) + '...';
    }

    // 2. 마커 크기 설정
    const int width = 400;
    const int height = 140;
    const int balloonHeight = 110;
    const int tailHeight = 30;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 3. 그림자 페인트
    final shadowPaint = Paint()
      ..color = Colors.deepOrange.withOpacity(1.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // 4. 배경 박스 그림자
    const double shadowOffsetX = 10;
    const double shadowOffsetY = 10;

// 그림자 및 박스 그릴 때 좌표 보정 적용
    final boxRect = Rect.fromLTWH(
      shadowOffsetX,
      shadowOffsetY,
      width.toDouble() - shadowOffsetX * 2,
      balloonHeight.toDouble(),
    );

    final boxRRect = RRect.fromRectAndRadius(boxRect.shift(const Offset(0, 0)), const Radius.circular(24));
    canvas.drawRRect(boxRRect, shadowPaint);

    // 5. 꼬리 그림자
    final shadowTailPath = Path()
      ..moveTo(width / 2 - 25 + 2, balloonHeight + 4)
      ..lineTo(width / 2 + 2, (balloonHeight + tailHeight + 4))
      ..lineTo(width / 2 + 25 + 2, balloonHeight + 4)
      ..close();
    canvas.drawPath(shadowTailPath, shadowPaint);

    // 6. 흰 배경 본체
    final fillPaint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(boxRect, const Radius.circular(24)), fillPaint);

    final tailPath = Path()
      ..moveTo(width / 2 - 25, balloonHeight.toDouble())
      ..lineTo(width / 2, (balloonHeight + tailHeight).toDouble())
      ..lineTo(width / 2 + 25, balloonHeight.toDouble())
      ..close();
    canvas.drawPath(tailPath, fillPaint);

    // 7. 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 36,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: boxRect.width - paddingX * 2, // 좌우 여백 고려
    );
    textPainter.paint(canvas, Offset(
      boxRect.left + paddingX,
      boxRect.top + (boxRect.height - textPainter.height) / 2 - paddingY / 2,
    ),);

    // 8. 이미지 생성
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
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
