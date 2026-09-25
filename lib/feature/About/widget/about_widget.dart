import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutWidget extends StatefulWidget {
  const AboutWidget({super.key});

  @override
  State<AboutWidget> createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // Launch external links
  // ============================================================

  Future<void> _launchAction(String urlString) async {
    if (urlString.trim().isEmpty) {
      _showSnackBar("Unable to open the link.".tr);
      return;
    }

    final Uri uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar("Unable to open the link.".tr);
      }
    } catch (e) {
      _showSnackBar(
        "An error occurred while attempting to connect.".tr,
      );
    }
  }

  // ============================================================
  // Snackbar
  // ============================================================

  void _showSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // Policy Dialog / Bottom Sheet
  // ============================================================

  void _showPolicyDialogOrSheet(
      String title,
      String content,
      ) {
    final theme = Theme.of(context);
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 600,
              constraints: const BoxConstraints(
                maxHeight: 500,
              ),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24,
                    color: theme.dividerColor,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ??
                              theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ??
                            theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // ============================================================
  // Main Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isDesktop = constraints.maxWidth > 800;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 380,
                          child: Column(
                            children: [
                              _buildHeaderBanner(),
                              const SizedBox(height: 24),
                              _buildSectionTitle("Terms and Policies".tr),
                              const SizedBox(height: 12),
                              _buildLegalCard(
                                title: "terms of use".tr,
                                icon: Icons.gavel_rounded,
                                onTap: () => _showPolicyDialogOrSheet(
                                  "terms of use".tr,
                                  _termsOfUseText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildLegalCard(
                                title: "privacy policy".tr,
                                icon: Icons.security_rounded,
                                onTap: () => _showPolicyDialogOrSheet(
                                  "privacy policy".tr,
                                  _privacyPolicyText,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Version 1.0.0".tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("About Us".tr),
                              const SizedBox(height: 12),
                              _buildAboutUsStream(),
                              const SizedBox(height: 24),
                              _buildSectionTitle("Contact us".tr),
                              const SizedBox(height: 12),
                              _buildContactInfoStream(),
                              const SizedBox(height: 24),
                              _buildSectionTitle("Frequently Asked Questions".tr),
                              const SizedBox(height: 12),
                              _buildFaqStream(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // ==================================================
                  // Mobile
                  // ==================================================

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderBanner(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("About Us".tr),
                      const SizedBox(height: 12),
                      _buildAboutUsStream(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Contact us".tr),
                      const SizedBox(height: 12),
                      _buildContactInfoStream(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Frequently Asked Questions".tr),
                      const SizedBox(height: 12),
                      _buildFaqStream(),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Terms and Policies".tr),
                      const SizedBox(height: 12),
                      _buildLegalCard(
                        title: "terms of use".tr,
                        icon: Icons.gavel_rounded,
                        onTap: () => _showPolicyDialogOrSheet(
                          "terms of use".tr,
                          _termsOfUseText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLegalCard(
                        title: "privacy policy".tr,
                        icon: Icons.security_rounded,
                        onTap: () => _showPolicyDialogOrSheet(
                          "privacy policy".tr,
                          _privacyPolicyText,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          "Version 1.0.0".tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  // ============================================================
  // Header Banner
  // ============================================================

  Widget _buildHeaderBanner() {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Welcome to our platform.".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Specially designed to provide the best experience for custom designs and gifts.".tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Section Title
  // ============================================================

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }

  // ============================================================
  // About Us
  // ============================================================

  Widget _buildAboutUsStream() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('app_info').doc('about_us').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBox();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final String text = data?['description'] ??
            "We are pleased to provide the best services and custom designs of the highest quality.".tr;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : theme.primaryColor.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Contact Info
  // ============================================================

  Widget _buildContactInfoStream() {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('app_info').doc('contact').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBox();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final String email = data?['email'] ?? "support@domain.com";
        final String whatsapp = data?['whatsapp'] ?? "+201000000000";
        final String facebook = data?['facebook'] ?? "";
        final String insta = data?['instegram'] ?? "";

        return Column(
          children: [
            _buildContactItem(
              icon: Icons.wechat_outlined,
              title: "WhatsApp".tr,
              subtitle: whatsapp,
              iconBgColor: const Color(0xFF25D366).withOpacity(0.12),
              iconColor: const Color(0xFF25D366),
              onTap: () {
                final cleanPhone = whatsapp.replaceAll('+', '').replaceAll(' ', '');
                _launchAction("https://wa.me/$cleanPhone");
              },
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: Icons.alternate_email_rounded,
              title: "e-mail".tr,
              subtitle: email,
              iconBgColor: theme.primaryColor.withOpacity(0.12),
              iconColor: theme.primaryColor,
              onTap: () => _launchAction("mailto:$email"),
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: Icons.facebook,
              title: "FaceBook".tr,
              subtitle: "FaceBook Page",
              iconBgColor: const Color(0xFF1877F2).withOpacity(0.12),
              iconColor: const Color(0xFF1877F2),
              onTap: () => _launchAction(facebook),
            ),
            const SizedBox(height: 10),
            _buildContactItem(
              icon: Icons.camera_alt_outlined,
              title: "Instagram".tr,
              subtitle: "Instagram page",
              iconBgColor: const Color(0xFFE1306C).withOpacity(0.12),
              iconColor: const Color(0xFFE1306C),
              onTap: () => _launchAction(insta),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Contact Item
  // ============================================================

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : theme.primaryColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: theme.hintColor,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.hintColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Legal Card
  // ============================================================

  Widget _buildLegalCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : theme.primaryColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.hintColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FAQ
  // ============================================================

  Widget _buildFaqStream() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('faqs').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBox();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                "There are currently no frequently asked questions.".tr,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.hintColor,
                ),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final String question = data['question'] ?? '';
            final String answer = data['answer'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : theme.primaryColor.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: theme.copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    iconColor: theme.primaryColor,
                    collapsedIconColor: theme.hintColor,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      question,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            answer,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // Loading
  // ============================================================

  Widget _buildShimmerBox() {
    final theme = Theme.of(context);

    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Terms
  // ============================================================

  static const String _termsOfUseText =
      "أهلاً بك في تطبيقنا. باستخدامك لهذا التطبيق، فإنك توافق "
      "على الالتزام بالشروط والأحكام التالية:\n\n"
      "1. الاستخدام المقبول: يُمنع استخدام التطبيق لأي أغراض "
      "غير قانونية أو انتهاك حقوق الملكية الفكرية.\n"
      "2. الحسابات والطلبات: المستخدم مسؤول عن صحة البيانات "
      "المدخلة في طلبات التصاميم والهدايا.\n"
      "3. التعديلات: يحق للقيمين على التطبيق تعديل الخدمات "
      "أو الأسعار في أي وقت دون إشعار مسبق.";

  // ============================================================
  // Privacy Policy
  // ============================================================

  static const String _privacyPolicyText =
      "نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية:\n\n"
      "1. جمع البيانات: نجمع البيانات الأساسية مثل الاسم، "
      "رقم الهاتف، والبريد الإلكتروني لإتمام طلباتك بنجاح.\n"
      "2. حماية البيانات: نستخدم تقنيات تشفير عالية الجودة "
      "لضمان عدم تسريب أي من بياناتك أو مشاركتها مع أطراف ثالثة.\n"
      "3. التحكم بالبيانات: يمكنك طلب حذف بياناتك أو تعديلها "
      "في أي وقت من خلال التواصل معنا.";
}