import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Core/Utils/app.colors.dart'; //[cite: 5, 6]

class AboutWidget extends StatefulWidget {
  const AboutWidget({super.key});

  @override
  State<AboutWidget> createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. تشغيل روابط التواصل المباشرة
  Future<void> _launchAction(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("تعذر فتح الرابط");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء محاولة الاتصال");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryPurple, //[cite: 5]
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 2. عرض السياسات والشروط في Modal Sheet أنيق
  void _showPolicyBottomSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark, //[cite: 5]
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textMuted, //[cite: 5]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight, //[cite: 5]
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "عن التطبيق",
          style: TextStyle(
            color: AppColors.textDark, //[cite: 5]
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------- Header Banner --------------------
            _buildHeaderBanner(),

            const SizedBox(height: 24),

            // -------------------- 1. من نحن (Firebase Dynamic) --------------------
            _buildSectionTitle("من نحن"),
            const SizedBox(height: 10),
            _buildAboutUsStream(),

            const SizedBox(height: 24),

            // -------------------- 2. بيانات التواصل (Firebase Dynamic Actions) --------------------
            _buildSectionTitle("تواصل معنا"),
            const SizedBox(height: 10),
            _buildContactInfoStream(),

            const SizedBox(height: 24),

            // -------------------- 3. الأسئلة الشائعة (Firebase Dynamic FAQs) --------------------
            _buildSectionTitle("الأسئلة الشائعة"),
            const SizedBox(height: 10),
            _buildFaqStream(),

            const SizedBox(height: 24),

            // -------------------- 4. السياسات والشروط (Static Local) --------------------
            _buildSectionTitle("الشروط والسياسات"),
            const SizedBox(height: 10),
            _buildLegalCard(
              title: "شروط الاستخدام",
              icon: Icons.gavel_rounded,
              onTap: () => _showPolicyBottomSheet("شروط الاستخدام", _termsOfUseText),
            ),
            const SizedBox(height: 8),
            _buildLegalCard(
              title: "سياسة الخصوصية",
              icon: Icons.security_rounded,
              onTap: () => _showPolicyBottomSheet("سياسة الخصوصية", _privacyPolicyText),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                "الإصدار 1.0.0",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Header Banner أنيق
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple,
            AppColors.primaryPurple.withOpacity(0.85),
          ], //[cite: 5, 6]
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.25), //[cite: 5]
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "مرحباً بك في منصتنا",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "صُممت خصيصاً لتوفير أفضل تجربة تصاميم وهدايا مخصصة",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // عنوان الأقسام
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark, //[cite: 5]
        letterSpacing: -0.3,
      ),
    );
  }

  // جلب نبذة "من نحن" من Firestore
  Widget _buildAboutUsStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('app_info').doc('about_us').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBox();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final String text = data?['description'] ?? "يسعدنا تقديم أفضل الخدمات والتصاميم المخصصة بأعلى جودة.";

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textMuted, //[cite: 5]
            ),
          ),
        );
      },
    );
  }

  // جلب بيانات التواصل من Firestore
  Widget _buildContactInfoStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('app_info').doc('contact').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerBox();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final String email = data?['email'] ?? "support@domain.com";
        final String phone = data?['phone'] ?? "+201000000000";
        final String whatsapp = data?['whatsapp'] ?? "+201000000000";

        return Column(
          children: [
            _buildContactItem(
              icon: Icons.wechat_outlined,
              title: "واتساب",
              subtitle: whatsapp,
              iconBgColor: const Color(0xFF25D366).withOpacity(0.1),
              iconColor: const Color(0xFF25D366),
              onTap: () {
                final cleanPhone = whatsapp.replaceAll('+', '').replaceAll(' ', '');
                _launchAction("https://wa.me/$cleanPhone");
              },
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.phone_in_talk_rounded,
              title: "رقم التواصل",
              subtitle: phone,
              iconBgColor: AppColors.primaryPurple.withOpacity(0.08), //[cite: 5]
              iconColor: AppColors.primaryPurple, //[cite: 5]
              onTap: () => _launchAction("tel:$phone"),
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              icon: Icons.alternate_email_rounded,
              title: "البريد الإلكتروني",
              subtitle: email,
              iconBgColor: const Color(0xFF0984E3).withOpacity(0.1),
              iconColor: const Color(0xFF0984E3),
              onTap: () => _launchAction("mailto:$email"),
            ),
          ],
        );
      },
    );
  }

  // ودجت عنصر التواصل
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark), //[cite: 5]
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted), //[cite: 5]
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  // جلب الأسئلة الشائعة FAQs من Firestore
  Widget _buildFaqStream() {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "لا توجد أسئلة شائعة حالياً",
                style: TextStyle(fontSize: 13, color: AppColors.textMuted), //[cite: 5]
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
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark, //[cite: 5]
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Text(
                        answer,
                        style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted), //[cite: 5]
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // كارت الشروط والسياسات الثابتة
  Widget _buildLegalCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.06), //[cite: 5]
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20), //[cite: 5]
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark), //[cite: 5]
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildShimmerBox() {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPurple), //[cite: 5]
        ),
      ),
    );
  }

  // نصوص ثابتة للشروط والسياسات
  static const String _termsOfUseText =
      "أهلاً بك في تطبيقنا. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بالشروط والأحكام التالية:\n\n"
      "1. الاستخدام المقبول: يُمنع استخدام التطبيق لأي أغراض غير قانونية أو انتهاك حقوق الملكية الفكرية.\n"
      "2. الحسابات والطلبات: المستخدم مسؤول عن صحة البيانات المدخلة في طلبات التصاميم والهدايا.\n"
      "3. التعديلات: يحق للقيمين على التطبيق تعديل الخدمات أو الأسعار في أي وقت دون إشعار مسبق.";

  static const String _privacyPolicyText =
      "نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية:\n\n"
      "1. جمع البيانات: نجمع البيانات الأساسية مثل الاسم، رقم الهاتف، والبريد الإلكتروني لإتمام طلباتك بنجاح.\n"
      "2. حماية البيانات: نستخدم تقنيات تشفير عالية الجودة لضمان عدم تسريب أي من بياناتك أو مشاركتها مع أطراف ثالثة.\n"
      "3. التحكم بالبيانات: يمكنك طلب حذف بياناتك أو تعديلها في أي وقت من خلال التواصل معنا.";
}