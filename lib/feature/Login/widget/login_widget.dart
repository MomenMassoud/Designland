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
  static const Color darkText = Color(0xFF2D3436);
  static const Color backgroundColor = Color(0xFFFAF9FF);

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              clipBehavior: Clip.antiAlias, // حل مشكلة الحواف الحادة للـ Container البنفسجي
              constraints: const BoxConstraints(maxWidth: 950),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
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
                        Expanded(child: _buildLoginForm()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const _MobileHeader(),
                      _buildLoginForm(),
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

  Widget _buildLoginForm() {
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
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: darkText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Sign in to access your orders and saved designs".tr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 28),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: darkText, fontSize: 14),
              decoration: InputDecoration(
                labelText: "Email Address".tr,
                labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.email_outlined, color: primaryColor, size: 20),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
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
                  style: const TextStyle(color: darkText, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Password".tr,
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () => _isPasswordObscure.value = !_isPasswordObscure.value,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgetPasswordView())),
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
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            "OR".tr,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
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
                          side: BorderSide(color: Colors.grey.shade200),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, size: 30, color: Color(0xFFEA4335)),
                            const SizedBox(width: 8),
                            Text(
                              "Sign in with Google".tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: darkText,
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SigupView())),
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
          // تم قص اللوجو داخل دائرة ناعمة لحل مشكلة الحواف البيضاء المربعة
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