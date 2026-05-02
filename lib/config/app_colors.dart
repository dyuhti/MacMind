import 'package:flutter/material.dart';

/// Healthcare-themed color palette matching calculator app UI
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4A90E2); // Soft blue
  static const Color primaryDark = Color(0xFF2E5CB8);
  static const Color primaryLight = Color(0xFF6FA8F2);
  // Brand gradient colors (navy -> blue)
  static const Color gradientStart = Color(0xFF0D3B66);
  static const Color gradientEnd = Color(0xFF1E5F9A);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA); // App background (standardized light gray)
  static const Color cardBackground = Color(0xFFFFFFFF); // Card background white
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Text Colors
  static const Color textDark = Color(0xFF1F2937); // Dark gray
  static const Color textMedium = Color(0xFF6B7280); // Medium gray
  static const Color textLight = Color(0xFF9CA3AF); // Light gray
  static const Color textHint = Color(0xFFD1D5DB); // Hint text

  // State Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Semantic Colors
  static const Color disabled = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color shadow = Color(0x0A000000); // 10% black with transparency

  // Focus Colors
  static const Color focusBlue = Color(0xFF3B82F6);
  static const Color focusBorder = Color(0xFF2563EB);
}
