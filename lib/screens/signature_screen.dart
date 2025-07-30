import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:signature/signature.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // 클립보드 기능을 사용하기 위해 추가

class SignatureScreen extends StatefulWidget {
  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 5,
    exportBackgroundColor: Colors.transparent,
  );

  // 이미지 URL을 화면에 표시할 텍스트 컨트롤러
  TextEditingController _urlController = TextEditingController();

  // API 응답에서 URL 추출
  Future<void> uploadSignatureToApi(Uint8List signatureImage) async {
    final url = Uri.parse('https://www.sososi.com/api/upload-image');

    final mimeType = lookupMimeType('signature.png') ?? 'image/png';
    final request = http.MultipartRequest('POST', url)
      ..headers['Content-Type'] = 'multipart/form-data'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          signatureImage,
          filename: 'signature.png',
          contentType: MediaType('image', 'png'),
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      print('서명 이미지 업로드 성공');

      // 응답 처리
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      final imageUrl = jsonResponse['url']; // 'url' 값 추출

      print('이미지 URL: $imageUrl');

      // 이미지 URL을 화면에 표시
      setState(() {
        _urlController.text = imageUrl; // URL을 TextField에 표시
      });
    } else {
      print('서명 이미지 업로드 실패: ${response.statusCode}');
    }
  }

  // 서명 저장하기
  void _saveSignature() async {
    if (_controller.isNotEmpty) {
      final signature = await _controller.toPngBytes(); // 서명을 이미지로 변환
      await uploadSignatureToApi(signature as Uint8List); // API에 업로드
    }
  }

  // 클립보드에 텍스트 복사
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _urlController.text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL이 클립보드에 복사되었습니다!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('전자서명')),
      body: Column(
        children: [
          Signature(
            controller: _controller,
            width: 300,
            height: 200,
            backgroundColor: Colors.grey[200]!,
          ),
          ElevatedButton(
            onPressed: _saveSignature,
            child: Text('서명 저장'),
          ),
          SizedBox(height: 20),
          // 이미지 URL을 표시하는 텍스트 필드
          TextField(
            controller: _urlController,
            readOnly: true, // 수정 불가능하게 설정
            decoration: InputDecoration(
              labelText: '이미지 URL',
              hintText: '서명 후 이미지 URL이 표시됩니다.',
            ),
          ),
          SizedBox(height: 10),
          // 복사 버튼
          ElevatedButton(
            onPressed: _copyToClipboard,
            child: Text('복사하기'),
          ),
        ],
      ),
    );
  }
}
