import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color primary = Color(0xFF3366FF);
  static const Color primaryVariant = Color(0xFF2952CC);
  static const Color secondary = Color(0xFF00C853);
  static const Color secondaryVariant = Color(0xFF009624);
  static const Color accent = Color(0xFFFF6D00);
  static const Color error = Color(0xFFD32F2F);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color primaryLight = Color(0xFF4D7AFF);
  static const Color primaryVariantLight = Color(0xFF3366FF);
  static const Color secondaryLight = Color(0xFF00E676);
  static const Color secondaryVariantLight = Color(0xFF00C853);
  static const Color accentLight = Color(0xFFFF9E40);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color dividerDark = Color(0xFF424242);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF3366FF),
    Color(0xFF00C6FF),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF00C853),
    Color(0xFF69F0AE),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFFF6D00),
    Color(0xFFFFAB40),
  ];

  // Map-specific colors
  static const Color mapRoute = Color(0xFF3366FF);
  static const Color mapMarker = Color(0xFFFF6D00);
  static const Color mapTraffic = Color(0xFFFF5252);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF3366FF),
    Color(0xFF00C853),
    Color(0xFFFF6D00),
    Color(0xFFFFD600),
    Color(0xFF2979FF),
    Color(0xFF00E676),
    Color(0xFFFF9100),
    Color(0xFFFFEA00),
  ];
}
