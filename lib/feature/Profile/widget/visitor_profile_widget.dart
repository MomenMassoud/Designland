import 'package:desginland/feature/Login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VisitorProfileWidget extends StatefulWidget {
  const VisitorProfileWidget({super.key});

  @override
  State<VisitorProfileWidget> createState() => _VisitorProfileWidgetState();
}

class _VisitorProfileWidgetState extends State<VisitorProfileWidget> {

  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color primaryGradient = Color(0xFF8172F8);

  // اختيار اللغة عبر Dialog
  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "اختر اللغة / Select Language",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.scaffoldBackgroundColor
                      : const Color(0xFFFAF9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: const Text("🇪🇬", style: TextStyle(fontSize: 22)),
                    title: Text(
                      "العربية",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                      ),
                    ),
                    trailing: Get.locale?.languageCode == 'ar'
                        ? const Icon(Icons.check_circle, color: primaryColor)
                        : null,
                    onTap: () {
                      try {
                        Locale locale = const Locale("ar");
                        Intl.defaultLocale = locale.languageCode;
                        Get.updateLocale(locale);
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.scaffoldBackgroundColor
                      : const Color(0xFFFAF9FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: const Text("🇺🇸", style: TextStyle(fontSize: 22)),
                    title: Text(
                      "English",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                      ),
                    ),
                    trailing: Get.locale?.languageCode == 'en'
                        ? const Icon(Icons.check_circle, color: primaryColor)
                        : null,
                    onTap: () {
                      try {
                        Locale locale = const Locale("en");
                        Intl.defaultLocale = locale.languageCode;
                        Get.updateLocale(locale);
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFFAF9FF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 800;

                  if (isDesktop) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("General Settings".tr, isDarkMode),
                                const SizedBox(height: 10),
                                _buildSettingsCard(isDarkMode, theme),
                                const Spacer(),
                                const SizedBox(height: 20),
                                _buildLoginButton(isDarkMode),
                              ],
                            ),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(
                            width: 350,
                            child: _buildExpandedVisitorCard(),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildVisitorCard(),
                      const SizedBox(height: 20),
                      _buildSettingsCard(isDarkMode, theme),
                      const SizedBox(height: 24),
                      _buildLoginButton(isDarkMode),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
      ),
    );
  }

  // كارت الزائر الممتد للشاشات الكبيرة (Desktop)
  Widget _buildExpandedVisitorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                size: 50,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Welcome, Guest".tr,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Log in to access your orders, favorites, and saved addresses.".tr,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Get.to(() =>  LoginView());
            },
            child: Text(
              "Log In / Sign Up".tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // كارت الزائر للشاشات الصغيرة (Mobile)
  Widget _buildVisitorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Welcome, Guest".tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Log in to enjoy all features of the app".tr,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Get.to(() =>  LoginView());
            },
            child: Text(
              "Log In / Sign Up".tr,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // كارت إعدادات الزائر (اللغات والخدمات المتاحة)
  Widget _buildSettingsCard(bool isDarkMode, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: Icons.language_rounded,
            title: "Change Language".tr,
            isDarkMode: isDarkMode,
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }

  // زر تسجيل الدخول السفلي
  Widget _buildLoginButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          Get.to(() =>  LoginView());
        },
        icon: const Icon(Icons.login_rounded, size: 20),
        label: Text(
          "Log In".tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
          ),
        ),
      ),
    );
  }
}