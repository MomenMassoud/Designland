import 'package:flutter/material.dart';

class CustomRainbowAppBarTitle extends StatelessWidget {
  const CustomRainbowAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // كلمة Design باللون الداكن مع الخط المنحني الناعم
          const Text(
            "Design",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A), // كحلي/أسود داكن شيك
              letterSpacing: -0.5,
              fontFamily: "Lilitaone"
            ),
          ),

          // كلمة Land بأسلوب حروف ملونة ناعمة مطابقة للوجو
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'l',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF4880), // وردي القلعة
                      fontFamily: "Lilitaone"
                  ),
                ),
                TextSpan(
                  text: 'a',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFB800), // أصفر دافئ
                      fontFamily: "Lilitaone"
                  ),
                ),
                TextSpan(
                  text: 'n',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00C4CC), // تركواز
                      fontFamily: "Lilitaone"
                  ),
                ),
                TextSpan(
                  text: 'd',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9B51E0), // بنفسجي
                      fontFamily: "Lilitaone"
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // لمسة شرارة صغيرة/أيقونة سحرية تعكس روح القلعة
          const Text(
            "✨",
            style: TextStyle(fontSize: 16),
          ),
          const Text(
            "🎨",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}