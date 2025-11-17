import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF323232),
        surface: const Color(0xFFFFFFFF),
        onPrimary: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF323232),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    );
  }
}
