import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textMedium = Color(0xFF555555);
  static const textLight = Color(0xFF888888);
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);
}

class AppTextStyles {
  static const heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const body = TextStyle(fontSize: 14, color: AppColors.textDark);
  static const bodyMedium = TextStyle(fontSize: 14, color: AppColors.textMedium);
  static const caption = TextStyle(fontSize: 12, color: AppColors.textLight);
  static const captionBold = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight);
}
