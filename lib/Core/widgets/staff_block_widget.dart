import 'package:desginland/feature/Login/function/auth_function.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // في حال كانت لوحة التحكم على رابط مختلف/خارجي للويب

class StaffBlockScreen extends StatelessWidget {
  final String userRole; // 'admin' أو 'staff'
  final String dashboardUrl="https://desginland-5ca7a.web.app/"; // رابط لوحة التحكم (اختياري للويب)

  const StaffBlockScreen({
    super.key,
    required this.userRole,
  });

  // Dynamic Theme Colors
  final Color primaryColor = const Color(0xFF6366F1);
  final Color warningColor = const Color(0xFFF59E0B);
  final Color darkText = const Color(0xFF1E293B);
  final Color backgroundColor = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = userRole.toLowerCase() == 'admin';
    final String roleTitle = isAdmin ? "مدير النظام (Admin)" : "موظف (Staff)";

    return PopScope(
      canPop: false, // منع الرجوع لصفحات المتجر
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. أيقونة الإدارة والوظائف
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: warningColor.withOpacity(0.08),
                          ),
                        ),
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: warningColor.withOpacity(0.15),
                          ),
                        ),
                        Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.badge_rounded,
                          size: 56,
                          color: warningColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 2. العنوان الرئيسي
                    Text(
                      "${"Welcome,".tr}$roleTitle",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 3. النص التوضيحي
                    Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "${"This interface is for store customers only. Since your account is registered as (".tr}$roleTitle${"), please proceed to the product and order management dashboard.".tr}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // 4. زر الانتقال للوحة التحكم
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (dashboardUrl != null && dashboardUrl!.isNotEmpty) {
                            final Uri uri = Uri.parse(dashboardUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } else {
                            // إذا كانت لوحة التحكم شاشة داخلية بالمشروع نفسه:
                            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));

                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text("Redirecting to the dashboard...".tr)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.dashboard_customize_rounded, size: 20),
                        label:  Text(
                          "Go to the control panel".tr,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        label:  Text(
                          "Log out".tr,
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