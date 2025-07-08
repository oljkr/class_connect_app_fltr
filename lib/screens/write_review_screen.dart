import 'dart:convert';
import 'dart:io';

import 'package:class_connect_app_fltr/screens/reservations_webview.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:mime/mime.dart'; // to get content type from file extension
import 'package:image/image.dart' as img;

import 'home_screen.dart'; // 추가 필요

class WriteReviewScreen extends StatefulWidget {
  final int classNo;
  final int reservationNo;

  const WriteReviewScreen({
    super.key,
    required this.classNo,
    required this.reservationNo,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  int rating = 0;
  String content = '';
  List<String> uploadedUrls = [];
  bool uploading = false;

  Future<void> handleSubmit() async {
    if (rating == 0 || content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점과 내용을 입력해주세요.')),
      );
      return;
    }

    setState(() => uploading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // ⚠️ users 테이블에서 user_no, user_nickname 조회
    final userInfoRes = await supabase
        .from('users')
        .select('user_no, user_nickname')
        .eq('id', user.id)
        .single();

    if (userInfoRes == null || userInfoRes['user_no'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
      );
      return;
    }

    final insertResult = await supabase.from('class_reviews').insert({
      'class_no': widget.classNo,
      'reservation_no': widget.reservationNo,
      'user_no': userInfoRes['user_no'],
      'user_name': userInfoRes['user_nickname'],
      'rating': rating,
      'content': content,
    }).select('class_review_no').single();

    final classReviewNo = insertResult['class_review_no'];

    for (final url in uploadedUrls) {
      await supabase.from('class_review_images').insert({
        'class_review_no': classReviewNo,
        'image_url': url,
      });
    }

    setState(() => uploading = false);
    // if (mounted) Navigator.pop(context, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 등록되었습니다!')),
      );

      // 잠깐 보여준 후 이전 화면으로 돌아가기
      await Future.delayed(const Duration(seconds: 1));
      // Navigator.pop(context, true); // true는 등록 완료 상태를 의미
      // ✅ 이전 화면으로 pop하지 않고 예약 내역으로 이동
      // if (mounted) {
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (_) => const ReservationsWebView()),
      //         (route) => false, // 모든 이전 경로 제거
      //   );
      // }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(isFirstRun: false, initialIndex: 3),
        ),
            (Route<dynamic> route) => false, // 모든 이전 경로를 제거
      );
    }
  }

  Future<void> pickImages() async {
    final files = await _picker.pickMultiImage();
    final uploaded = <String>[];

    for (final file in files) {
      final uri = Uri.parse('https://www.sososi.com/api/upload');
      final request = http.MultipartRequest('POST', uri);

      // 🔽 원본 이미지 읽고 디코딩
      final fileBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) continue;

      // 🔽 리사이즈 + 압축 (너비 800, 품질 80)
      final resized = img.copyResize(originalImage, width: 800);
      final compressed = img.encodeJpg(resized, quality: 80);

      // 🔽 업로드 요청
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressed,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['url'] != null) {
          uploaded.add(data['url']);
        }
      } else {
        debugPrint('Upload failed: ${response.body}');
      }
    }

    setState(() {
      uploadedUrls.addAll(uploaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('리뷰 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('별점', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: List.generate(5, (i) =>
                    IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = i + 1),
                    )
                ),
              ),
              const SizedBox(height: 16),
              const Text('리뷰 내용', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                maxLines: 5,
                onChanged: (v) => content = v,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '어떤 점이 좋았나요? 개선할 점은 있었나요?',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: pickImages,
                    child: const Text('이미지 업로드'),
                  ),
                  const SizedBox(width: 8),
                  Text('${uploadedUrls.length}개 업로드됨'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uploadedUrls.map((url) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => uploadedUrls.remove(url)),
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: uploading ? null : handleSubmit,
                  child: Text(uploading ? '작성 중...' : '리뷰 등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
