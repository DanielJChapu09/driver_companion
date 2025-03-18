import 'package:flutter/material.dart';

class AppTheme {
  static Color primaryGreen = const Color(0xFF58CC02);
  static Color secondaryYellow = const Color(0xFFFFD700);
  static Color lightBackground = const Color(0xFFFFFFFF);
  static Color darkBackground = const Color(0xFF1B1B1B);
  static Color buttonGreen = const Color(0xFF4CAF50);
  static Color cardBackground = Colors.white;
  static Color darkCardBackground = Colors.grey[900]!;

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: "HostGrotesk",
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
          fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFf8f8f8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: _border(Colors.grey.shade100),
      enabledBorder: _border(Colors.grey.shade100),
      focusedBorder: _border(Colors.grey.shade300),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red),
      hintStyle: const TextStyle(color: Color(0xFF596375)),
      prefixIconConstraints: BoxConstraints(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonGreen,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: "HostGrotesk",
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
          fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: _border(Colors.white70),
      enabledBorder: _border(Colors.grey.shade800),
      focusedBorder: _border(Colors.grey.shade600),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red),
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIconConstraints: BoxConstraints(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonGreen,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
  );
}
