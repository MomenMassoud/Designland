import 'package:flutter/material.dart';
class CustomRainbowAppBarTitle extends StatefulWidget {
  const CustomRainbowAppBarTitle({super.key});

  @override
  State<CustomRainbowAppBarTitle> createState() => _CustomRainbowAppBarTitleState();
}

class _CustomRainbowAppBarTitleState extends State<CustomRainbowAppBarTitle> {
  final String _fullText = "Designland";
  int _displayedLetterCount = 0;

  // قائمة ألوان قزح لكل حرف بالترتيب
  final List<Color> _rainbowColors = const [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.blue,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
    Colors.pinkAccent,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _startTypewriterAnimation();
  }

  void _startTypewriterAnimation() async {
    for (int i = 0; i <= _fullText.length; i++) {
      // سرعة ظهور كل حرف (150 مللي ثانية)
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _displayedLetterCount = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: List.generate(_displayedLetterCount, (index) {
          return TextSpan(
            text: _fullText[index],
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontFamily: 'Pacifico',
              // اختيار اللون الخاص بالحرف
              color: _rainbowColors[index % _rainbowColors.length],
              shadows: const [
                Shadow(
                  blurRadius: 8.0,
                  color: Colors.black26,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}