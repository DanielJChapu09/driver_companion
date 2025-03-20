import 'package:flutter/material.dart';

import '../typography/typography.dart';

class Palette {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFFdc721b),
    hintColor: Colors.blue.shade300,
    disabledColor: Colors.grey.shade400,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    textTheme: CustomTypography.dinRoundTextTheme
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
      primaryColor: Color(0xFFdc721b),
      hintColor: Colors.blue,
    appBarTheme: const AppBarTheme(
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: CustomTypography.dinRoundTextTheme
  );
}