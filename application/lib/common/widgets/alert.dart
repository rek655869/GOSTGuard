import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class Alert extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOk;

  const Alert({
    super.key,
    required this.title,
    required this.message,
    this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Text(message),
      actionsAlignment: MainAxisAlignment.start,
      actions: [
        TextButton(
          onPressed: onOk ?? () => Navigator.pop(context),
          child: const Text('ОК'),
        ),
      ],
    );
  }
}
