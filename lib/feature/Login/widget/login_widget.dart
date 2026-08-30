import 'package:desginland/feature/MainScreen/view/main_screen_view.dart';
import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
import '../../../Core/Utils/app.images.dart';
import '../../ForgetPassword/view/forget_password_view.dart';
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

  // استخدام ValueNotifier للحد من إعادة رسم الشاشة بالكامل عند تغيير حالة بسيطة
  final ValueNotifier<bool> _isPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

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

  @override
  Widget build(BuildContext context) {
    // استخدام LayoutBuilder يمنع إعادة الرسم عند فتح وإغلاق الكيبورد
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 980),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 850;
                  if (isDesktop) {
                    return Row(
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
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sign In",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "Sign in to access your orders and saved designs",
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
              ),
              validator: (val) => (val == null || !val.contains('@')) ? "Enter a valid email address" : null,
            ),
            const SizedBox(height: 16),

            // إعادة رسم زري إخفاء/إظهار كلمة السر فقط دون بقية الشاشة
            ValueListenableBuilder<bool>(
              valueListenable: _isPasswordObscure,
              builder: (context, isObscure, child) {
                return TextFormField(
                  controller: _passwordController,
                  obscureText: isObscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => _isPasswordObscure.value = !_isPasswordObscure.value,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                  validator: (val) => (val == null || val.length < 6) ? "Password must be at least 6 characters" : null,
                );
              },
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgetPasswordView())),
                child: const Text("Forgot Password?", style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // إعادة رسم زر التحميل فقط أثناء عملية التسجيل
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: TextStyle(color: AppColors.textMuted)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SigupView())),
                  child: const Text("Create Account", style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// فصل الـ Branding Side إلى Widget مستقلة وثابتة
class _BrandingSide extends StatelessWidget {
  const _BrandingSide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppImages.appPLogo, width: 220, fit: BoxFit.contain),
          const SizedBox(height: 24),
          const Text(
            "Welcome Back!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            "Explore customized gifts, order personalized items, and track your active orders effortlessly.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// فصل Header الموبايل إلى Widget مستقلة وثابتة
class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Image.asset(AppImages.appPLogo, height: 90),
          const SizedBox(height: 12),
          const Text(
            "DesignLand Store",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}