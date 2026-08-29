import 'package:desginland/feature/Login/function/auth_function.dart';
import 'package:flutter/material.dart';

class BlockListScreen extends StatelessWidget {
  final String? blockReason;

  const BlockListScreen({
    super.key,
    this.blockReason,
  });

  // Modern Indigo Theme Palette
  final Color primaryColor = const Color(0xFF6366F1);
  final Color errorColor = const Color(0xFFEF4444);
  final Color darkText = const Color(0xFF1E293B);
  final Color backgroundColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // منع المستخدم من الرجوع للخلف
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500), // مناسب للويب والموبايل
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. أيقونة الحظر المتحركة/البصرية
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: errorColor.withOpacity(0.08),
                          ),
                        ),
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: errorColor.withOpacity(0.15),
                          ),
                        ),
                        Icon(
                          Icons.block_rounded,
                          size: 56,
                          color: errorColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 2. عنوان الشاشة
                    Text(
                      "تم تعليق الحساب",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 3. رسالة التوضيح والسبب
                    Text(
                      "تم إيقاف حسابك مؤقتاً أو إدراجه في قائمة الحظر لتجاوز شروط الاستخدام والأحكام الخاصة بالموقع.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // عرض سبب الحظر إن وجد
                    if (blockReason != null && blockReason!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 18, color: errorColor),
                                const SizedBox(width: 8),
                                Text(
                                  "سبب الحظر:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: errorColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              blockReason!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),

                    // 4. زر التواصل مع الدعم الفني
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // يمكنك فتح رابط WhatsApp أو فتح Dialog للتواصل مع الدعم
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("يرجى التواصل مع الدعم عبر البريد: support@designland.com"),
                            ),
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
                        icon: const Icon(Icons.support_agent_rounded, size: 20),
                        label: const Text(
                          "التواصل مع الدعم الفني",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. زر تسجيل الخروج
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => LogoutMethod(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: darkText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          "تسجيل الخروج",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}