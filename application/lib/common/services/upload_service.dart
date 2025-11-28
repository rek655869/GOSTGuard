import 'dart:typed_data';
import 'dart:io';
import 'drawing_service.dart';

class UploadResult {
  final String text;
  final Uint8List image;
  final int drawingId;

  UploadResult({
    required this.text,
    required this.image,
    required this.drawingId,
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
    try {
      // Читаем изображение, которое пользователь выбрал
      final imageBytes = await image.readAsBytes();

      // Генерируем имя файла
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'drawing_$timestamp.png';

      // Используем метод из DrawingService для обработки YOLO
      final yoloResult = await DrawingService.processImageWithYolo(
        imageBytes: imageBytes,
        filename: filename,
      );

      // Сохраняем результат в локальную БД
      final drawingId = await DrawingService.saveDrawingResult(
        filename: filename,
        originalImage: imageBytes,
        processedImage: yoloResult['processed_image'] as Uint8List,
        checkResult: yoloResult['text'] as String,
      );

      return UploadResult(
        text: yoloResult['text'] as String,
        image: yoloResult['processed_image'] as Uint8List,
        drawingId: drawingId,
      );
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}