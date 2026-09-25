import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // ☀️ الثيم الفاتح (Light Theme)
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF9FF), // خلفية ناعمة مائلة للبنفسجي الفاتح
    primaryColor: const Color(0xFF6C5CE7),
    cardColor: Colors.white,

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFF2D3436)),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C5CE7),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
      onSurface: Color(0xFF2D3436), // لون النصوص الرئيسية
      onSurfaceVariant: Color(0xFF636E72), // لون النصوص الفرعية
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.8),
      ),
    ),
  );

  // 🌙 الثيم الداكن (Dark Theme)
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0E17), // أسود ناعم متناسق مع البنفسجي
    primaryColor: const Color(0xFF7D6EFE), // درجة أفتح قليلاً لإضاءة مريحة للعين
    cardColor: const Color(0xFF1E1D2A), // خلفية الكروت والأسطح

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFFF1F2F6)),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7D6EFE),
      secondary: Color(0xFF10B981),
      surface: Color(0xFF1E1D2A),
      onSurface: Color(0xFFF1F2F6), // لون النصوص الرئيسية
      onSurfaceVariant: Color(0xFFA0A5B5), // لون النصوص الفرعية
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF181722),
      hintStyle: const TextStyle(color: Color(0xFF6C727F), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF7D6EFE), width: 1.8),
      ),
    ),
  );
}