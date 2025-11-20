import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'drawing_service.dart';

class UploadResult {
  final String text;
  final int number;
  final Uint8List image;

  UploadResult({
    required this.text,
    required this.number,
    required this.image,
  });
}

class UploadService {
  static String serverUrl = '';

  static void setUrl(String url) {
    serverUrl = url;
  }

  Future<UploadResult> uploadImage({
    required File image,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${serverUrl}/upload'),
    );

    request.fields['session_id'] = DrawingService.getSessionId();
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final body = await response.stream.bytesToString();
    final data = json.decode(body);

    return UploadResult(
      text: data['text'],
      number: int.tryParse(data['number'].toString()) ?? 0,
      image: base64Decode(data['image_base64']),
    );
  }
}
