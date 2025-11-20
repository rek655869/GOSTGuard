import 'dart:convert';
import 'package:flutter/material.dart';

import '../../common/widgets/alert.dart';
import '../../common/widgets/base_screen.dart';
import '../../common/widgets/primary_button.dart';

class DrawingDetails extends StatelessWidget {
  final String drawingId;
  final Map<String, dynamic> drawingData;

  const DrawingDetails({
    super.key,
    required this.drawingId,
    required this.drawingData,
  });

  void _openFullScreen(BuildContext context) {
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
                child: Image.memory(base64.decode(drawingData['image_base64']!)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                PrimaryButton(
                  icon: Icons.arrow_back,
                  label: 'К истории',
                  radius: 12,
                  onPressed: () => Navigator.pop(context),
                ),

                SizedBox(width: 10),

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

            SizedBox(height: 20),

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
                        SizedBox(height: 10),
                        Text('Название: ${drawingData['name']}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('Дата: ${drawingData['date']}'),
                        SizedBox(height: 10),
                        Text('Статус: ${drawingData['status']}'),
                      ],
                    ),

                    SizedBox(height: 20),

                    Column(
                      children: [
                        Text('Результат проверки:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Container(
                          height: screenHeight * 0.3, // 30% от высоты экрана
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: drawingData['image_base64'] != null
                              ? GestureDetector(
                            onTap: () => _openFullScreen(context),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64.decode(drawingData['image_base64']!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text('Изображение не найдено',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),

                    SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
   // TODO: при проверке чертежа будет приходить список с номером ошибки и описанием, пример в checking_screen
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                drawingData['check_result'] ?? 'Результат проверки не найден',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      )
    );
  }
}