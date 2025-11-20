import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class DrawingService {
  static String baseUrl = '';
  static String? _sessionId;

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  static String getSessionId() {
    _sessionId ??= _generateUuid();
    print('🆔 [DrawingService] Current session ID: $_sessionId'); // ← ДОБАВЬТЕ
    return _sessionId!;
  }

  static String _generateUuid() {
    final random = Random();
    String generatePart(int length) {
      return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
    }

    return '${generatePart(8)}-${generatePart(4)}-${generatePart(4)}-${generatePart(4)}-${generatePart(12)}';
  }

  static Future<List<dynamic>> getHistory() async {
    try {
      final sessionId = getSessionId();
      final response = await http.get(Uri.parse('$baseUrl/history/$sessionId'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['drawings'] ?? [];
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getDrawingDetails(int drawingId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/drawing/$drawingId'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load drawing details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}