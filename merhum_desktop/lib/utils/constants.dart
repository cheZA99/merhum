import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E20);
  static const secondary = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textLight = Color(0xFF757575);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  static const body = TextStyle(fontSize: 14, color: AppColors.textDark);
  static const caption = TextStyle(fontSize: 12, color: AppColors.textLight);
}
