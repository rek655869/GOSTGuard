import 'package:flutter/material.dart';
import '../../common/widgets/custom_app_bar.dart';
import '../../app/theme/app_colors.dart';

class BaseScreen extends StatelessWidget {
  final Widget child;

  const BaseScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          // Прямоугольник на фоне
          Positioned(
            bottom: -10,
            left: 0,
            child: Container(
              width: screenWidth,
              height: screenHeight / 5 * 3,
              decoration: BoxDecoration(
                color: AppColors.background2,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Основной контент
          Center(
            child: child,
          )
        ],
      ),
    );
  }
}
