import 'package:desginland/feature/Login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthNotLoginWidget extends StatelessWidget {
  const AuthNotLoginWidget({super.key});

  // Modern Indigo Theme Palette
  final Color primaryColor = const Color(0xFF6366F1);
  final Color darkText = const Color(0xFF1E293B);
  final Color backgroundColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Premium Visual Illustration Container
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.06),
                    ),
                  ),
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.12),
                    ),
                  ),
                  Icon(
                    Icons.lock_person_outlined,
                    size: 54,
                    color: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // 2. Headline
              Text(
                "Login required".tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 3. Subtext
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Please log in to access all features, track your orders, and easily manage your personal account.".tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // 4. Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(
                          () => LoginView(),
                      routeName: LoginView.id,
                      transition: Transition.cupertino,
                      duration: const Duration(milliseconds: 400),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: Text(
                    "Log in now".tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}