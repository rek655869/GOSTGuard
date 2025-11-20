import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData basic = ThemeData(
    useMaterial3: true,

    // Цветовая схема на основе основного цвета приложения
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ),

    // Настройка AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBar,
      titleTextStyle: const TextStyle(
        color: AppColors.appBarText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),

    // Фон экранов
    scaffoldBackgroundColor: AppColors.background,

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBar,
      indicatorColor: AppColors.background,
    ),
  );
}
