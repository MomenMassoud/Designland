import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/Utils/app.images.dart';
import '../../MainScreen/view/main_screen_view.dart';
import '../function/signup_function.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ValueNotifier<bool> _isPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isConfirmPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  // Home Design Theme Palette
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color darkText = Color(0xFF2D3436);
  static const Color backgroundColor = Color(0xFFFAF9FF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isPasswordObscure.dispose();
    _isConfirmPasswordObscure.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;

      bool isSuccess = await RegisterFunction(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _confirmPasswordController.text.trim(),
        _nameController.text.trim(),
      );

      if (mounted) {
        _isLoading.value = false;
        if (isSuccess) {
          Navigator.pushReplacementNamed(context, MainScreenView.id);
        }
      }
    }
  }

  void _handleGoogleSignUp() async {
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
              clipBehavior: Clip.antiAlias, // قص الحواف الزائدة البنفسجية تلقائياً
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
                        const Expanded(child: _SignUpBrandingSide()),
                        Expanded(child: _buildSignUpForm()),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const _SignUpMobileHeader(),
                      _buildSignUpForm(),
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

  Widget _buildSignUpForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sign Up".tr,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: darkText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Please fill in your information to register".tr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Full Name Field
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: darkText, fontSize: 14),
              decoration: InputDecoration(
                labelText: "Full Name".tr,
                labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 20),
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
              validator: (val) => (val == null || val.trim().isEmpty) ? "Please enter your full name".tr : null,
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Confirm Password Field
            ValueListenableBuilder<bool>(
              valueListenable: _isConfirmPasswordObscure,
              builder: (context, isConfirmObscure, child) {
                return TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: isConfirmObscure,
                  style: const TextStyle(color: darkText, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "Confirm Password".tr,
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: () => _isConfirmPasswordObscure.value = !_isConfirmPasswordObscure.value,
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
                  validator: (val) {
                    if (val != _passwordController.text) return "Passwords do not match".tr;
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignUp,
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
                          "Create Account".tr,
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
                        onPressed: isLoading ? null : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.shade200),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(AppImages.google),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Sign up with Google".tr,
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
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?".tr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Sign In".tr,
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

class _SignUpBrandingSide extends StatelessWidget {
  const _SignUpBrandingSide();

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
            "Create Account".tr,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Join DesignLand today and start creating customized gifts & personalized orders easily.".tr,
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

class _SignUpMobileHeader extends StatelessWidget {
  const _SignUpMobileHeader();

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
            "Join DesignLand",
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