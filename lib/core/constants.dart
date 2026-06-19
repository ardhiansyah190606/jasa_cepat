import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0066FF); // Biru Khas JasaCepat
  static const Color secondary = Color(0xFFFF9900); // Amber untuk Rating/Urgent
  static const Color background = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
}

class AppStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
}