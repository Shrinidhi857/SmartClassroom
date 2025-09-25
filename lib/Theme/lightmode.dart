import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: Color(0xFFFFFFFF),       // White cards/surfaces
    primary: Color(0xFFF5F5F5),       // Very light gray
    secondary: Color(0xFFE5E5E5),     // Slightly darker gray
    inversePrimary: Color(0xFF1A1A1A),// Opposite of dark inverse
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Color(0xFF1A1A1A),     // Dark text
    displayColor: Colors.black,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
  ),
);
