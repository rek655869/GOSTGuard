import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class Prompt extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String labelText;
  final String confirmText;

  /// Callback вызывается, когда пользователь нажал кнопку ОК
  /// и поле не пустое. Возвращает введённую строку.
  final void Function(String value)? onConfirm;

  const Prompt({
    super.key,
    required this.controller,
    required this.title,
    required this.labelText,
    this.confirmText = 'OK',
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),

      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              onConfirm?.call(text);
            }
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
