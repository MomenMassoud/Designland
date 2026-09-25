import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Core/Utils/app.colors.dart';

class ForgetPasswordWidget extends StatefulWidget {
  const ForgetPasswordWidget({super.key});

  @override
  State<ForgetPasswordWidget> createState() => _ForgetPasswordWidgetState();
}

class _ForgetPasswordWidgetState extends State<ForgetPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      _showSnackBar(
        "Password reset link sent to your email!".tr,
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        e.message ?? "An error occurred while sending reset link".tr,
        isError: true,
      );
    } catch (e) {
      _showSnackBar("An unexpected error occurred".tr, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // إعداد الألوان الديناميكية
    final cardBgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final scaffoldBgColor = isDark ? const Color(0xFF121212) : AppColors.bgLight;
    final titleTextColor = isDark ? Colors.white : AppColors.textDark;
    final mutedTextColor = isDark ? Colors.grey.shade400 : AppColors.textMuted;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _emailSent
                ? _buildSuccessState(titleTextColor, mutedTextColor)
                : _buildResetForm(isDark, titleTextColor, mutedTextColor),
          ),
        ),
      ),
    );
  }

  // واجهة إدخال البريد الإلكتروني
  Widget _buildResetForm(bool isDark, Color titleTextColor, Color mutedTextColor) {
    final fieldFillColor = isDark ? const Color(0xFF2A2A3D) : Colors.white;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 24),

          // Title & Description
          Text(
            "Forgot Password?".tr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: titleTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No worries, enter your registered email and we'll send you a link to reset your password.".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: mutedTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Email Input Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: titleTextColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: "Email Address".tr,
              labelStyle: TextStyle(color: mutedTextColor, fontSize: 13),
              hintText: "example@domain.com",
              hintStyle: TextStyle(color: mutedTextColor.withOpacity(0.6)),
              filled: true,
              fillColor: fieldFillColor,
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.primaryPurple,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryPurple,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your email".tr;
              }
              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegExp.hasMatch(value.trim())) {
                return "Enter a valid email address".tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Send Reset Link Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                "Send Reset Link".tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to Login Button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: mutedTextColor,
            ),
            label: Text(
              "Back to Login".tr,
              style: TextStyle(
                color: mutedTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // واجهة تأكيد إرسال البريد النجاح
  Widget _buildSuccessState(Color titleTextColor, Color mutedTextColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Check Your Email".tr,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: titleTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${"We sent a password reset link to:".tr}\n${_emailController.text.trim()}",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: mutedTextColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "Return to Login".tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            "Didn't receive the email? Try again".tr,
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}