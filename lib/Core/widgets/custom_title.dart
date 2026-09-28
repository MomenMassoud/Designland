import 'package:flutter/material.dart';
import 'dart:ui';

class CustomRainbowAppBarTitle extends StatelessWidget {
  final String fontFamilyName = "Waltograph";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // نمط الخط الأساسي بحجم أكبر ومعالجة الأحرف الصغيرة
    final TextStyle baseStyle = TextStyle(
      fontSize: 32, // تكبير الفونت ليصبح واضحاً وبارزاً
      fontWeight: FontWeight.normal,
      fontFamily: fontFamilyName,
      fontFeatures: const [
        FontFeature.enable('smcp'),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // كلمة Design (حرف D كابيتال وباقي الكلمة سمول)
          Text(
            "Design",
            style: baseStyle.copyWith(
              color: isDarkMode
                  ? const Color(0xFFF1F2F6)
                  : const Color(0xFF1E232A),
              letterSpacing: -0.5,
            ),
          ),

          // كلمة Land (حرف L كابيتال وباقي الكلمة سمول ملون)
          RichText(
            text: TextSpan(
              style: baseStyle,
              children: const [
                TextSpan(
                  text: 'L', // حرف L كابيتال
                  style: TextStyle(
                    color: Color(0xFFFF4880), // وردي
                  ),
                ),
                TextSpan(
                  text: 'a', // سمول
                  style: TextStyle(
                    color: Color(0xFFFFB800), // أصفر
                  ),
                ),
                TextSpan(
                  text: 'n', // سمول
                  style: TextStyle(
                    color: Color(0xFF00C4CC), // تركواز
                  ),
                ),
                TextSpan(
                  text: 'd', // سمول
                  style: TextStyle(
                    color: Color(0xFF9B51E0), // بنفسجي
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          //
          // // الأيقونات بحجم متناسق مع الفونت الجديد
          // const Text("✨", style: TextStyle(fontSize: 20)),
          const Text("🎨", style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}