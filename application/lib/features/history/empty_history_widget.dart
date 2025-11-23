import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class EmptyHistoryWidget extends StatelessWidget {

  const EmptyHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 50, color: AppColors.primaryText),
          SizedBox(height: 10),
          Text(
            'История проверок пуста',
            style: TextStyle(fontSize: 16, color: AppColors.primaryText),
          ),
          Text(
            'Загрузите первый чертеж для проверки',
            style: TextStyle(fontSize: 14, color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}
