import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ImageResultCard extends StatelessWidget {
  final Uint8List responseImage;
  final int number;
  final String text;

  const ImageResultCard({
    super.key,
    required this.responseImage,
    required this.number,
    required this.text,
  });

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: InteractiveViewer(
            panEnabled: true, // включаем перетаскивание
            minScale: 1,
            maxScale: 5,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.memory(responseImage),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Изображение с ограничением размера и открытием на полный экран
        GestureDetector(
          onTap: () => _openFullScreen(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              responseImage,
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    number.toString(),
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
                    text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
