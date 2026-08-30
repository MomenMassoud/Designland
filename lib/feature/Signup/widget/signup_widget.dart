import 'package:flutter/material.dart';
import '../../../Core/Utils/app.colors.dart';
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

  // استخدام ValueNotifier لمنع Rebuilds الشاشة كاملة
  final ValueNotifier<bool> _isPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isConfirmPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

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

  @override
  Widget build(BuildContext context) {
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
          children: [
            const Text(
              "Sign Up",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              "Please fill in your information to register",
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? "Please enter your full name" : null,
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            ValueListenableBuilder<bool>(
              valueListenable: _isConfirmPasswordObscure,
              builder: (context, isConfirmObscure, child) {
                return TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: isConfirmObscure,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(isConfirmObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => _isConfirmPasswordObscure.value = !_isConfirmPasswordObscure.value,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) return "Passwords do not match";
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Create Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?", style: TextStyle(color: AppColors.textMuted)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Sign In", style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
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
            "Create Account",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            "Join DesignLand today and start creating customized gifts & personalized orders easily.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
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
            "Join DesignLand",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}