import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/services/drawing_service.dart';
import '../../common/widgets/base_screen.dart';
import 'drawing_details.dart';
import 'drawing_card.dart';
import 'empty_history_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _drawings = [];
  bool _isLoading = true;
  String? selectedDrawing;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      var history = await DrawingService.getHistory();
      setState(() {
        _drawings = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> buildDrawingData(String drawingId) async {
    try {
      final drawingDetails = await DrawingService.getDrawingDetails(int.parse(drawingId));
      final drawing = _drawings.firstWhere((d) => d['id'].toString() == drawingId);
      return {
        'name': drawingDetails['filename'] ?? 'Чертеж',
        'date': drawing['created_at'].toString(),
        'status': drawingDetails['status'] ?? 'Проверен',
        'image_base64': drawingDetails['image_base64'],
        'check_result': drawingDetails['check_result'],
      };
    } catch (e) {
      print('Error loading drawing details: $e');
      return {};
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

              else
                if (_drawings.isEmpty)
                  EmptyHistoryWidget()

                else
                  Column(
                    children: [
                      for (var item in _drawings)
                        DrawingCard(
                            fileName: item['filename'],
                            uploadDate: DateTime.parse(item['created_at']),
                            onTap: () async {
                              final data = await buildDrawingData(item['id'].toString());
                              if (data.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DrawingDetails(
                                      drawingId: item['filename'],
                                      drawingData: data,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ошибка загрузки чертежа')),
                                );
                              }
                            }

                        ),
                    ],
                  )
            ],
          ),
        )
    );
  }
}