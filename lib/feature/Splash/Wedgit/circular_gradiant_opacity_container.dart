import 'package:flutter/material.dart';

class CircularGradientOpacityContainer extends StatelessWidget {
  const CircularGradientOpacityContainer({
    super.key,
    required this.size,
    required this.colorOne,
    required this.colorTwo,
    this.colorOneOpacity = 0.3,
    this.colorTwoOpacity = 0.0,
    this.radius = 0.5,
  });

  final double size;
  final Color colorOne;
  final Color colorTwo;
  final double colorOneOpacity;
  final double colorTwoOpacity;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colorOne.withOpacity(colorOneOpacity),
            colorTwo.withOpacity(colorTwoOpacity),
          ],
          center: Alignment.center,
          radius: radius,
        ),
      ),
    );
  }
}