import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../common/services/drawing_service.dart';
import '../../common/widgets/base_screen.dart';
import '../../common/widgets/alert.dart';
import '../../common/widgets/primary_button.dart';
import 'drawing_card.dart';
import 'empty_history_widget.dart';
import '../../app/theme/app_colors.dart';

import 'package:share_plus/share_plus.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _drawings = [];
  bool _isLoading = true;

  // Состояния для управления отображением
  Map<String, dynamic>? _selectedDrawingData;
  bool _showDetails = false; // false = список, true = детали

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      var history = await DrawingService.getHistory();
      if (!mounted) return;
      setState(() {
        _drawings = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _openDrawingDetails(String drawingId) async {
    try {
      final drawingDetails = await DrawingService.getDrawingDetails(int.parse(drawingId));
      final drawing = _drawings.firstWhere((d) => d['id'].toString() == drawingId);

      if (!mounted) return;
      setState(() {
        _selectedDrawingData = {
          'id': drawingId, // ДОБАВЛЕНО: ID для отчета
          'name': drawingDetails['filename'] ?? 'Чертеж',
          'date': drawing['created_at'].toString(),
          'status': drawingDetails['status'] ?? 'Проверен',
          'image_base64': drawingDetails['image_base64'],
          'check_result': drawingDetails['check_result'],
        };
        _showDetails = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чертежа: $e')),
      );
    }
  }

  void _closeDrawingDetails() {
    if (!mounted) return;
    setState(() {
      _showDetails = false;
      _selectedDrawingData = null;
    });
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Скачать отчет
  Future<void> _downloadReport() async {
    if (_selectedDrawingData == null) return;

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Генерация отчета...'),
            ],
          ),
        ),
      );

      // Генерируем отчет на сервере
      final reportResult = await DrawingService.generateReport( // ← ИСПРАВЛЕНО: reportResult
        drawingId: int.parse(_selectedDrawingData!['id']),
        filename: _selectedDrawingData!['name'] ?? 'Чертеж',
        checkResult: _selectedDrawingData!['check_result'] ?? '',
        imageBase64: _selectedDrawingData!['image_base64'] ?? '',
        createdAt: _selectedDrawingData!['date'] ?? DateTime.now().toIso8601String(),
      );

      // Декодируем и сохраняем .docx
      final docBytes = base64.decode(reportResult['doc_base64']); // ← ИСПРАВЛЕНО: reportResult
      final fileName = reportResult['filename'] ?? 'report_${_selectedDrawingData!['id']}.docx'; // ← ИСПРАВЛЕНО: _selectedDrawingData

      // Сохраняем файл
      await _saveFile(docBytes, fileName); // ← ИСПРАВЛЕНО: _saveFile

      // Закрываем индикатор
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Отчет $fileName успешно скачан')), // ← ИСПРАВЛЕНО: fileName
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Закрываем индикатор
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка генерации отчета: $e')),
      );
    }
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Сохранить файл
  Future<void> _saveFile(Uint8List bytes, String fileName) async {
    try {
      // Получаем директорию для сохранения
      final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final file = File('${directory?.path}/$fileName');

      // Сохраняем файл
      await file.writeAsBytes(bytes);

      // Открываем файл
      await OpenFile.open(file.path);

    } catch (e) {
      throw Exception('Не удалось сохранить файл: $e');
    }
  }

  void _openFullScreen(BuildContext context) {
    if (_selectedDrawingData == null || _selectedDrawingData!['image_base64'] == null) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 5,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.memory(base64.decode(_selectedDrawingData!['image_base64']!)),
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Простой способ - делиться через системный шеринг
  Future<void> _shareReportViaMessenger() async {
    if (_selectedDrawingData == null) return;

    try {
      // Показываем индикатор
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Подготовка отчета...'),
            ],
          ),
        ),
      );

      // Генерируем отчет
      final reportResult = await DrawingService.generateReport(
        drawingId: int.parse(_selectedDrawingData!['id']),
        filename: _selectedDrawingData!['name'] ?? 'Чертеж',
        checkResult: _selectedDrawingData!['check_result'] ?? '',
        imageBase64: _selectedDrawingData!['image_base64'] ?? '',
        createdAt: _selectedDrawingData!['date'] ?? DateTime.now().toIso8601String(),
      );

      final docBytes = base64.decode(reportResult['doc_base64']);
      final fileName = reportResult['filename'] ?? 'report_${_selectedDrawingData!['id']}.docx';

      // Сохраняем файл
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(docBytes);

      // Закрываем индикатор
      if (!mounted) return;
      Navigator.of(context).pop();

      // Делимся файлом через системный шеринг
      final files = [XFile(file.path)];
      await Share.shareXFiles(
        files,
        text: 'Отчет по проверке чертежа: ${_selectedDrawingData!['name']}',
        subject: 'Отчет по чертежу',
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_showDetails && _selectedDrawingData != null)
              _buildDetailView()
            else if (_drawings.isEmpty)
                EmptyHistoryWidget()
              else
                _buildListView()
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        for (var item in _drawings)
          DrawingCard(
            fileName: item['filename'],
            uploadDate: DateTime.parse(item['created_at']),
            onTap: () => _openDrawingDetails(item['id'].toString()),
          ),
      ],
    );
  }

  Widget _buildDetailView() {
    return Column(
      children: [
        // Кнопки навигации (без кнопки скачивания)
        Row(
          children: [
            PrimaryButton(
              icon: Icons.arrow_back,
              label: 'К истории',
              radius: 12,
              onPressed: _closeDrawingDetails,
            ),
            const SizedBox(width: 10),
            PrimaryButton(
              icon: Icons.help_outline,
              label: 'Справка',
              radius: 12,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => Alert(
                    title: 'Пояснение',
                    message: 'Цифрами на чертеже отмечены проблемные '
                        'места, ниже указаны конкретные ГОСТы, которым '
                        'они не соответствуют.',
                    onOk: () => Navigator.pop(context),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Карточка с деталями
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text('Название: ${_selectedDrawingData!['name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Дата: ${_selectedDrawingData!['date']}'),
                    const SizedBox(height: 10),
                    Text('Статус: ${_selectedDrawingData!['status']}'),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    const Text('Результат проверки:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildImageWithErrorNumber(),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Кнопки скачивания и отправки (рядом) - ОБЪЕДИНЯЕМ ОБА ВАРИАНТА
        const SizedBox(height: 20),
        Row(
          children: [
            // Существующая кнопка скачивания
            Expanded(
              child: PrimaryButton(
                icon: Icons.file_download,
                label: 'Скачать отчет',
                radius: 12,
                onPressed: _downloadReport,
              ),
            ),
            const SizedBox(width: 10),
            // НОВАЯ кнопка отправки
            Expanded(
              child: PrimaryButton(
                icon: Icons.share,
                label: 'Поделиться',
                radius: 12,
                onPressed: _shareReportViaMessenger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildImageWithErrorNumber() {
    if (_selectedDrawingData == null || _selectedDrawingData!['image_base64'] == null) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text('Изображение не найдено', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final Uint8List imageBytes = base64.decode(_selectedDrawingData!['image_base64']!);
    final screenWidth = MediaQuery.of(context).size.width;

    // Получаем текст результатов проверки
    final checkResult = _selectedDrawingData!['check_result'] ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _openFullScreen(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              width: screenWidth * 0.85,
              height: null,
              alignment: Alignment.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (checkResult.isNotEmpty) ...checkResult
                        .split('\n\n') // разделяем текст по переносам строк
                        .asMap()    // получаем индекс каждой строки
                        .entries
                        .map(
                          (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                (entry.key + 1).toString(), // порядковый номер
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ]
              )
          ),
        ),
      ],
    );
  }
}