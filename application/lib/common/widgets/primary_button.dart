import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String? label;
  final IconData icon;
  final VoidCallback onPressed;
  final double? radius;

  const PrimaryButton({
    super.key,
    this.label,
    required this.icon,
    required this.onPressed,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? 100),
    );

    // Если есть текст — FilledButton.icon
    if (label != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label!,
          style: const TextStyle(color: Colors.white),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: shape,
        ),
      );
    }

    // Если текста нет — FilledButton с иконкой
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: shape,
        padding: EdgeInsets.zero,
        minimumSize: const Size(40, 40),
      ),
      child: Icon(
          icon,
          color: Colors.white,
          size: 24
      ),
    );
  }
}