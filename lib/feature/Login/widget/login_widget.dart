import 'package:desginland/feature/MainScreen/view/main_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.images.dart';
import '../../ForgetPassword/view/forget_password_view.dart';
import '../../Signup/function/signup_function.dart';
import '../../Signup/view/sigup_view.dart';
import '../function/auth_function.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ValueNotifier<bool> _isPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  // Home Design Theme Palette
  static const Color primaryColor = Color(0xFF6C5CE7);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isPasswordObscure.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;
      bool isSuccess = await LoginFunction(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        _isLoading.value = false;
        if (isSuccess) {
          Navigator.pushReplacementNamed(context, MainScreenView.id);
        }
      }
    }
  }

  void _handleGoogleLogin() async {
    _isLoading.value = true;
    SignInWithGoogle(context);
    if (mounted) {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ألوان ديناميكية بحسب الثيم
    final scaffoldBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAF9FF);
    final cardBgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              clipBehavior: Clip.antiAlias,
              constraints: const BoxConstraints(maxWidth: 950),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : primaryColor.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: _BrandingSide()),
                        Expanded(child: _buildLoginForm(isDark)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const _MobileHeader(),
                      _buildLoginForm(isDark),
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

  Widget _buildLoginForm(bool isDark) {
    final mainTextColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final fieldBgColor = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFFAF9FF);
    final fieldBorderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sign In".tr,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: mainTextColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Sign in to access your orders and saved designs".tr,
              style: TextStyle(
                fontSize: 13,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 28),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: mainTextColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: "Email Address".tr,
                labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.email_outlined, color: primaryColor, size: 20),
                filled: true,
                fillColor: fieldBgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 1.8),
                ),
              ),
              validator: (val) => (val == null || !val.contains('@')) ? "Enter a valid email address".tr : null,
            ),
            const SizedBox(height: 18),

            // Password Field
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordObscure,
              builder: (context, isObscure, child) {
                return TextFormField(
                  controller: _passwordController,
                  obscureText: isObscure,
                  style: TextStyle(color: mainTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Password".tr,
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () => _isPasswordObscure.value = !_isPasswordObscure.value,
                    ),
                    filled: true,
                    fillColor: fieldBgColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: fieldBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: primaryColor, width: 1.8),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 6) ? "Password must be at least 6 characters".tr : null,
                );
              },
            ),
            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  ForgetPasswordView())),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  "Forgot Password?".tr,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          shadowColor: primaryColor.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          "Sign In".tr,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "OR".tr,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: fieldBorderColor),
                          backgroundColor: fieldBgColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(AppImages.google),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Sign in with Google".tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: mainTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?".tr,
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  SigupView())),
                  child: Text(
                    "Create Account".tr,
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _BrandingSide extends StatelessWidget {
  const _BrandingSide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8172F8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  AppImages.logo,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "Welcome Back!".tr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Explore customized gifts, order personalized items, and track your active orders effortlessly.".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8172F8),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(AppImages.logo, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "DesignLand Store",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}