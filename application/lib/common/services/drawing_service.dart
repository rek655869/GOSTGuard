import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database.dart';

class DrawingService {
  static String baseUrl = '';
  static String? _deviceId;

  static Future<String> getDeviceId() async {
    if (_deviceId == null) {
      await _loadOrCreateDeviceId();
    }
    return _deviceId!;
  }

  static Future<void> _loadOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');

    if (_deviceId == null) {
      // Создаем постоянный ID устройства
      final random = Random();
      _deviceId = 'device_${random.nextInt(999999)}';
      await prefs.setString('device_id', _deviceId!);
    }
  }

  // История всегда из локальной БД
  static Future<List<dynamic>> getHistory() async {
    try {
      final deviceId = await getDeviceId();
      final history = await LocalDatabase.getHistory(deviceId);
      return history;
    } catch (e) {
      return [];
    }
  }

  // Сохраняем в локальную БД с deviceId
  static Future<int> saveDrawingResult({
    required String filename,
    required Uint8List originalImage,
    required Uint8List processedImage,
    required String checkResult,
  }) async {
    try {
      final deviceId = await getDeviceId();
      return await LocalDatabase.saveDrawing(
        sessionId: deviceId, // используем deviceId
        filename: filename,
        originalImageBytes: originalImage,
        processedImageBytes: processedImage,
        checkResult: checkResult,
      );
    } catch (e) {
      throw Exception('Failed to save to local database: $e');
    }
  }

  // YOLO обработка требует IP сервера
  static Future<Map<String, dynamic>> processImageWithYolo({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('Server IP is not configured. Please enter server IP.');
      }


      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Добавляем deviceId вместо session_id
      final deviceId = await getDeviceId();
      request.fields['device_id'] = deviceId;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = json.decode(body);

      if (data['success'] != true) {
        throw Exception('Processing failed: ${data['error']}');
      }

      return {
        'processed_image': base64.decode(data['image_base64']),
        'text': data['text'],
        'number': data['number'] ?? 1,
      };
    } catch (e) {
      throw Exception('Server connection error: $e');
    }
  }

  // Метод для получения деталей чертежа (должен быть в классе)
  static Future<Map<String, dynamic>> getDrawingDetails(int drawingId) async {
    try {
      final drawing = await LocalDatabase.getDrawing(drawingId);

      if (drawing == null) {
        throw Exception('Drawing not found in local database');
      }

      final imageBase64 = drawing['processed_image_base64'] as String?;

      if (imageBase64 == null || imageBase64.isEmpty) {
        throw Exception('Processed image not found in local database');
      }

      return {
        'filename': drawing['filename'] ?? 'Чертеж',
        'status': drawing['status'] ?? 'Проверен',
        'image_base64': imageBase64,
        'check_result': drawing['check_result'] ?? 'Результат проверки',
      };
    } catch (e) {
      throw Exception('Local database error: $e');
    }
  }

  // Метод для генерации отчета
  static Future<Map<String, dynamic>> generateReport({
    required int drawingId,
    required String filename,
    required String checkResult,
    required String imageBase64,
    required String createdAt,
  }) async {
    try {
      if (baseUrl.isEmpty) {
        throw Exception('Server URL is not configured');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/generate_report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'drawing_id': drawingId,
          'filename': filename,
          'check_result': checkResult,
          'image_base64': imageBase64,
          'created_at': createdAt,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Report generation failed: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['success'] != true) {
        throw Exception('Report generation failed: ${data['error']}');
      }
      return {
        'doc_base64': data['doc_base64'],
        'filename': data['filename'],
      };
    } catch (e) {
      throw Exception('Report generation error: $e');
    }
  }

  static void setBaseUrl(String url) {
    baseUrl = url;
  }
}