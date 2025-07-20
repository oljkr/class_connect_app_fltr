import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  List<Map<String, dynamic>> _nearbyLocations = [];
  List<Map<String, dynamic>> _originalLocations = [];
  bool _isFiltered = false; // 🔑 필터 상태 여부
  final DraggableScrollableController _draggableController = DraggableScrollableController();
  final ScrollController _scrollController = ScrollController(); // ✅ 추가

  double _lastScrollSize = 0.2; // 사용자가 마지막으로 내려둔 비율
  double _savedScrollOffset = 0.0; // ✅ 추가

  @override
  void initState() {
    super.initState();

    _draggableController.addListener(() {
      _lastScrollSize = _draggableController.size;
      print('📌 저장된 스크롤 비율: $_lastScrollSize');
    });

    _scrollController.addListener(() {
      _savedScrollOffset = _scrollController.offset;
      // print('📌 저장된 offset: $_savedScrollOffset');
    });

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

      // final nearby = filteredLocations.where((loc) {
      //   final locLat = (loc['lat'] as num).toDouble();
      //   final locLng = (loc['lng'] as num).toDouble();
      //   final dist = _calculateDistance(lat, lng, locLat, locLng);
      //   print('거리: ${loc['title']} → ${dist.toStringAsFixed(2)} km');
      //   return dist <= 2.0;
      // }).toList();

      final nearby = filteredLocations.map((loc) {
        final locLat = (loc['lat'] as num).toDouble();
        final locLng = (loc['lng'] as num).toDouble();
        final dist = _calculateDistance(lat, lng, locLat, locLng);

        return {
          ...loc,
          'distance': dist,
        };
      }).where((loc) => loc['distance'] <= 2.0).toList();


      final Set<Marker> newMarkers = {};

      for (var loc in nearby) {
        final id = loc['class_no'].toString();
        final locLat = (loc['lat'] as num).toDouble();
        final locLng = (loc['lng'] as num).toDouble();
        final title = loc['title']?.toString() ?? '클래스';

        // final icon = await createCustomMarkerBitmap(title);
        // final icon = await createCleanBalloonMarker(title);
        final icon = await createPillBalloonMarker(title);

        newMarkers.add(
          Marker(
            markerId: MarkerId(id),
            position: LatLng(locLat, locLng),
            icon: icon,
          ),
        );
      }

      setState(() {
        _originalLocations = nearby;

        // ✅ 필터 상태가 아닐 때만 전체 목록 덮어쓰기
        if (!_isFiltered) {
          _nearbyLocations = nearby;
        }

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
    const double paddingX = 5;
    const double paddingY = 5;
    const int maxLength = 25;

    if (text.length > maxLength) {
      text = text.substring(0, maxLength) + '...';
    }

    const int width = 400;
    const int height = 140;
    const int balloonHeight = 110;
    const int tailHeight = 30;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const double offsetX = 10;
    const double offsetY = 10;

    final boxRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      width.toDouble() - offsetX * 2,
      balloonHeight.toDouble(),
    );

    final boxRRect = RRect.fromRectAndRadius(boxRect, const Radius.circular(24));

    // 1. 흰 배경용 페인트
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 2. 외곽선 페인트
    final borderPaint = Paint()
      ..color = const Color(0xFFfc17d2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // 3. 풍선 + 꼬리 결합 Path
    final balloonPath = Path()
      ..addRRect(boxRRect)
      ..moveTo(width / 2 - 25, balloonHeight.toDouble())
      ..lineTo(width / 2, (balloonHeight + tailHeight).toDouble())
      ..lineTo(width / 2 + 25, balloonHeight.toDouble())
      ..close();

    // 4. 배경 채우기 → 외곽선 그리기
    canvas.drawPath(balloonPath, fillPaint);
    canvas.drawPath(balloonPath, borderPaint);

    // 5. 텍스트
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
      maxWidth: boxRect.width - paddingX * 2,
    );

    textPainter.paint(
      canvas,
      Offset(
        boxRect.left + paddingX,
        boxRect.top + (boxRect.height - textPainter.height) / 2 - paddingY / 2,
      ),
    );

    // 6. 이미지 생성
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> createCleanBalloonMarker(String text) async {
    const int width = 320;
    const int height = 130;
    const int tailHeight = 15;
    const double radius = 24;

    // 텍스트 길이 자르기
    if (text.length > 20) {
      text = text.substring(0, 20) + '...';
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFFfc17d2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();

    // 공통적으로 사용될 좌표들 double로 변환
    final double widthD = width.toDouble();
    final double heightD = height.toDouble();
    final double tailTop = (height - tailHeight).toDouble();
    final double centerX = widthD / 2;

    // ✅ 말풍선 본체 + 꼬리를 하나의 Path로 연결
    path.moveTo(radius, 0);
    path.lineTo(widthD - radius, 0);
    path.quadraticBezierTo(widthD, 0, widthD, radius);
    path.lineTo(widthD, tailTop - radius);
    path.quadraticBezierTo(widthD, tailTop, widthD - radius, tailTop);
    path.lineTo(centerX + 12, tailTop);
    path.lineTo(centerX, heightD); // 꼬리 아래 꼭짓점
    path.lineTo(centerX - 12, tailTop);
    path.lineTo(radius, tailTop);
    path.quadraticBezierTo(0, tailTop, 0, tailTop - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();

    // 풍선 배경과 테두리 그리기
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // 텍스트 중앙 정렬
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: widthD - 40);
    textPainter.paint(
      canvas,
      Offset(
        (widthD - textPainter.width) / 2,
        (tailTop - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> createOvalBalloonMarker(String text) async {
    const int width = 320;
    const int height = 130;
    const int tailHeight = 15;
    const double radiusX = 160; // 타원의 반지름 x
    const double radiusY = 50;  // 타원의 반지름 y

    if (text.length > 20) {
      text = text.substring(0, 20) + '...';
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(0.5, 0.5); // 반픽셀 보정

    final fillPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFFfc17d2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    final double centerX = width / 2;
    final double centerY = radiusY + 10;

    // ✅ 타원 윗부분부터 시계방향으로 시작
    path.moveTo(centerX - radiusX, centerY); // 좌측 시작점

    // 타원 윗쪽 호
    path.arcToPoint(
      Offset(centerX + radiusX, centerY),
      radius: const Radius.elliptical(radiusX, radiusY),
      clockwise: true,
    );

    // 타원 아랫부분에서 꼬리로 이어지는 곡선
    path.arcToPoint(
      Offset(centerX + 12, centerY + radiusY),
      radius: const Radius.elliptical(radiusX, radiusY),
      clockwise: true,
    );

    // 꼬리 삼각형
    path.lineTo(centerX, height.toDouble());
    path.lineTo(centerX - 12, centerY + radiusY);

    // 타원 아래쪽 나머지 곡선
    path.arcToPoint(
      Offset(centerX - radiusX, centerY),
      radius: const Radius.elliptical(radiusX, radiusY),
      clockwise: true,
    );

    path.close();

    // ✅ 그리기
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // ✅ 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: width - 40);
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, centerY - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> createPillBalloonMarker(String text) async {
    const int originalWidth = 420;
    const int originalHeight = 130;
    const int tailHeight = 15;
    const int extraMargin = 10; // ← 캔버스 여백
    const int canvasWidth = originalWidth + extraMargin * 2;
    const int canvasHeight = originalHeight + extraMargin;

    if (text.length > 25) {
      text = text.substring(0, 25) + '...';
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(0.5, 0.5); // 픽셀 보정

    final fillPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFFDDD6F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final double widthD = originalWidth.toDouble();
    final double heightD = originalHeight.toDouble();
    final double centerX = canvasWidth / 2;
    final double topY = extraMargin.toDouble();
    final double pillHeight = heightD - tailHeight;
    final double radius = pillHeight / 2;

    final path = Path();
    final left = extraMargin.toDouble();
    final right = left + widthD;

    // ✅ path 시작점부터 pill + 꼬리까지
    path.moveTo(left + radius, topY);
    path.lineTo(right - radius, topY);
    path.arcToPoint(Offset(right, topY + radius), radius: Radius.circular(radius));
    path.lineTo(right, topY + pillHeight - radius);
    path.arcToPoint(Offset(right - radius, topY + pillHeight), radius: Radius.circular(radius));
    path.lineTo(centerX + 10, topY + pillHeight);
    path.lineTo(centerX, topY + pillHeight + tailHeight); // 꼬리
    path.lineTo(centerX - 10, topY + pillHeight);
    path.lineTo(left + radius, topY + pillHeight);
    path.arcToPoint(Offset(left, topY + pillHeight - radius), radius: Radius.circular(radius));
    path.lineTo(left, topY + radius);
    path.arcToPoint(Offset(left + radius, topY), radius: Radius.circular(radius));
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // 텍스트 중앙 정렬
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 34,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: widthD - 40);
    textPainter.paint(
      canvas,
      Offset(
        left + (widthD - textPainter.width) / 2,
        topY + (pillHeight - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth, canvasHeight);
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
    // final res = await Supabase.instance.client
    //     .from('classes')
    //     .select('*');
    // return List<Map<String, dynamic>>.from(res);
    final res = await Supabase.instance.client
        .from('classes')
        .select('*, class_images(*)')
        .order('class_no'); // 정렬은 메인 테이블 기준

    return (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();

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
    return WillPopScope(
      onWillPop: () async {
        if (_isFiltered) {
          setState(() {
            _isFiltered = false;
            _nearbyLocations = List.from(_originalLocations);
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("내 주변 위치")),
        body: _userPosition == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            // ⬇️ 구글 지도
            GoogleMap(
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

            // ✅ 필터 상태에 따라 다른 위젯 표시
            if (_isFiltered)
            // 단일 클래스 카드 (고정 위치)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: _buildSingleClassCard(_nearbyLocations.first),
              )
            else
            // 전체 목록 (DraggableScrollableSheet)
              DraggableScrollableSheet(
                controller: _draggableController,
                initialChildSize: _lastScrollSize,
                minChildSize: 0.1,
                maxChildSize: 1.0,
                builder: (context, scrollController) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_savedScrollOffset); // ✅ 저장된 위치로 점프
                    }
                  });

                  // // 이 시점에서 jumpTo로 복원
                  // WidgetsBinding.instance.addPostFrameCallback((_) {
                  //   if (_draggableController.size != _lastScrollSize) {
                  //     _draggableController.jumpTo(_lastScrollSize);
                  //   }
                  // });
                  // _draggableController!.addListener(() {
                  //   _lastScrollSize = _draggableController!.size;
                  //   print('📌 저장된 스크롤 비율: $_lastScrollSize');
                  // });

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: _buildListContent(scrollController),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

// ✅ 단일 클래스 카드 위젯
  Widget _buildSingleClassCard(Map<String, dynamic> item) {
    final images = item['class_images'] as List<dynamic>?;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (images != null && images.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, imgIndex) {
                    final imgUrl = images[imgIndex]['image_url'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imgUrl,
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text(
              item['title'] ?? '클래스 제목 없음',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '거리: ${item['distance']?.toStringAsFixed(2)}km',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

// ✅ 필터된 상태의 컨텐츠 (단일 카드)
  Widget _buildFilteredContent() {
    final item = _nearbyLocations.first;
    final images = item['class_images'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (images != null && images.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, imgIndex) {
                  final imgUrl = images[imgIndex]['image_url'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imgUrl,
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Text(
            item['title'] ?? '클래스 제목 없음',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('거리: ${item['distance']?.toStringAsFixed(2)}km'),
        ],
      ),
    );
  }

// ✅ 전체 리스트 컨텐츠
  Widget _buildListContent(ScrollController scrollController) {
    return ListView.builder(
      controller: _scrollController, // ✅ 여기에 우리가 관리하는 컨트롤러 적용
      itemCount: _nearbyLocations.length,
      itemBuilder: (context, index) {
        final item = _nearbyLocations[index];
        final images = item['class_images'] as List<dynamic>?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images != null && images.isNotEmpty)
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, imgIndex) {
                    final imgUrl = images[imgIndex]['image_url'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imgUrl,
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ListTile(
              title: Text(item['title'] ?? '클래스 제목 없음'),
              subtitle: Text('거리: ${item['distance']?.toStringAsFixed(2)}km'),
              onTap: () {
                final lat = (item['lat'] as num).toDouble();
                final lng = (item['lng'] as num).toDouble();

                _mapController.animateCamera(
                  CameraUpdate.newLatLng(LatLng(lat, lng)),
                );

                setState(() {
                  _isFiltered = true;
                  _nearbyLocations = [item];
                });
              },
            ),
            const Divider(),
          ],
        );
      },
    );
  }

}
