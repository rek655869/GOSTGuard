import 'dart:io';

import 'package:flutter/material.dart';

import '../../common/widgets/primary_button.dart';

class ImageSelectCard extends StatelessWidget {
  final File? image;
  final VoidCallback onPick;

  const ImageSelectCard({
    super.key,
    required this.image,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: screenHeight * 0.5,
      width: screenWidth * 0.85,
      child: Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrimaryButton(
                icon: Icons.image,
                label: 'Выбрать изображение',
                onPressed: onPick,
              ),
              const SizedBox(height: 20),
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image!,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
