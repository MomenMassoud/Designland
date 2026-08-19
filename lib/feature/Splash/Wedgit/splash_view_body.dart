import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/Utils/app.images.dart';
import '../../Login/view/login_view.dart';
import '../../MainScreen/view/main_screen_view.dart';
import 'circular_gradiant_opacity_container.dart';
import 'gradient_container.dart';

class SplashViewBody extends StatefulWidget {
  const SplashViewBody({super.key});

  @override
  State<SplashViewBody> createState() => _SplashViewBodyState();
}

class _SplashViewBodyState extends State<SplashViewBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }
  void _navigateToNextScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, MainScreenView.id);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    return Scaffold(
      body: GradientContainer(
        // خلفية بنفسجية فخمة مستوحاة من الشنطة
        colorOne: AppColors.primaryPurple,
        colorTwo: AppColors.secondaryPurple,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // هالة ضوئية ناعمة خلف اللوجو
            CircularGradientOpacityContainer(
              size: isWeb ? 450 : size.width * 0.85,
              colorOne: AppColors.lightPurpleGlow,
              colorTwo: Colors.transparent,
              colorOneOpacity: 0.35,
            ),

            // المحتوى الرئيسي: اللوجو
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(
                            AppImages.appPLogo
                          ),
                          radius: 90,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Customized Gifts & Memories",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // يوزر إنستغرام في أسفل الشاشة زي الشنطة
            Positioned(
              bottom: 30,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white60,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "@Designland.eg",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}