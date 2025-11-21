import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalDatabase {
  static const String _drawingsKey = 'drawings_list';
  static const String _sessionKeyPrefix = 'session_';

  // Сохранить рисунок
  static Future<int> saveDrawing({
    required String sessionId,
    required String filename,
    required List<int> originalImageBytes,
    required List<int> processedImageBytes,
    required String checkResult,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Создаем уникальный ID
      final drawingId = DateTime.now().millisecondsSinceEpoch;

      // Подготавливаем данные для сохранения
      final drawingData = {
        'id': drawingId,
        'session_id': sessionId,
        'filename': filename,
        'original_image_base64': base64.encode(originalImageBytes),
        'processed_image_base64': base64.encode(processedImageBytes),
        'status': 'checked',
        'check_result': checkResult,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Сохраняем в общей списке
      final drawingsList = prefs.getStringList(_drawingsKey) ?? [];
      drawingsList.add(json.encode(drawingData));
      await prefs.setStringList(_drawingsKey, drawingsList);

      // Также сохраняем для быстрого доступа по сессии
      final sessionKey = '$_sessionKeyPrefix$sessionId';
      final sessionDrawings = prefs.getStringList(sessionKey) ?? [];
      sessionDrawings.add(json.encode(drawingData));
      await prefs.setStringList(sessionKey, sessionDrawings);

      return drawingId;
    } catch (e) {
      rethrow;
    }
  }

  // Получить историю
  static Future<List<Map<String, dynamic>>> getHistory(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = '$_sessionKeyPrefix$sessionId';
      final sessionDrawings = prefs.getStringList(sessionKey) ?? [];

      // Преобразуем JSON строки обратно в Map
      final history = sessionDrawings.map((jsonString) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }).toList();

      // Сортируем по дате (новые сначала)
      history.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      return history;
    } catch (e) {

      rethrow;
    }
  }

  // Получить конкретный рисунок
  static Future<Map<String, dynamic>?> getDrawing(int drawingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsList = prefs.getStringList(_drawingsKey) ?? [];

      for (final jsonString in drawingsList) {
        final drawing = json.decode(jsonString) as Map<String, dynamic>;
        if (drawing['id'] == drawingId) {

          return drawing;
        }
      }

      return null;
    } catch (e) {

      rethrow;
    }
  }

  // Удалить рисунок
  static Future<void> deleteDrawing(int drawingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsList = prefs.getStringList(_drawingsKey) ?? [];

      // Удаляем из общего списка
      final updatedList = drawingsList.where((jsonString) {
        final drawing = json.decode(jsonString) as Map<String, dynamic>;
        return drawing['id'] != drawingId;
      }).toList();

      await prefs.setStringList(_drawingsKey, updatedList);

      // Также удаляем из всех сессий
      final keys = prefs.getKeys().where((key) => key.startsWith(_sessionKeyPrefix));
      for (final key in keys) {
        final sessionDrawings = prefs.getStringList(key) ?? [];
        final updatedSessionDrawings = sessionDrawings.where((jsonString) {
          final drawing = json.decode(jsonString) as Map<String, dynamic>;
          return drawing['id'] != drawingId;
        }).toList();
        await prefs.setStringList(key, updatedSessionDrawings);
      }

    } catch (e) {

      rethrow;
    }
  }

  // Очистить все данные (для тестирования)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Удаляем все ключи связанные с рисунками
      final keysToRemove = prefs.getKeys().where((key) =>
      key == _drawingsKey || key.startsWith(_sessionKeyPrefix));

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

    } catch (e) {
      rethrow;
    }
  }

  // Получить все рисунки (для отладки)
  static Future<List<Map<String, dynamic>>> getAllDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsList = prefs.getStringList(_drawingsKey) ?? [];

      return drawingsList.map((jsonString) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}