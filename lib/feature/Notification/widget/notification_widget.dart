import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final Color primaryColor = const Color(0xFF6366F1);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // تحديث حالة الإشعار إلى "تمت القراءة"
  Future<void> _markAsRead(String notificationId) async {
    try {
      if (_auth.currentUser == null) return;
      await FirebaseFirestore.instance
          .collection('user')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _auth.currentUser?.uid;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // إعداد الألوان الديناميكية بحسب حالة الثيم
    final scaffoldBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final appBarBgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final titleTextColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final emptyStateTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: appBarBgColor,
        elevation: 0.5,
        title: Text(
          "Notifications".tr,
          style: TextStyle(
            color: titleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: titleTextColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUserId == null
          ? Center(
        child: Text(
          "Please log in to view notifications.".tr,
          style: TextStyle(color: titleTextColor),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        // جلب الإشعارات الخاصة بالعميل الحالي أو الإشعارات العامة لكل المستخدمين
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(currentUserId)
            .collection('notifications')
            .where('targetUser', whereIn: [currentUserId, 'all'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "There are currently no notifications.".tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: emptyStateTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'New notification'.tr;
              final String body = data['body'] ?? data['message'] ?? '';
              final bool isRead = data['isRead'] ?? false;
              final Timestamp? createdAt = data['createdAt'] as Timestamp?;

              // ألوان العنصر الديناميكية بحسب (مقروء/غير مقروء + ثيم داكن/فاتح)
              final cardBgColor = isRead
                  ? (isDark ? const Color(0xFF1E1E2C) : Colors.white)
                  : (isDark ? primaryColor.withOpacity(0.18) : primaryColor.withOpacity(0.05));

              final cardBorderColor = isRead
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                  : primaryColor.withOpacity(0.4);

              final iconBgColor = isRead
                  ? (isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade100)
                  : primaryColor.withOpacity(0.15);

              final iconColor = isRead
                  ? (isDark ? Colors.grey.shade400 : Colors.grey)
                  : primaryColor;

              final itemTitleColor = isDark ? Colors.white : const Color(0xFF1E293B);
              final itemBodyColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
              final timeTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    _markAsRead(doc.id);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cardBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أيقونة الإشعار
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // تفاصيل الإشعار
                      Expanded(
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
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      color: itemTitleColor,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 13,
                                color: itemBodyColor,
                                height: 1.4,
                              ),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: timeTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // دالة لتنسيق الوقت بصيغة مبسطة
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final Duration diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "now".tr;
    if (diff.inMinutes < 60) return "${"since".tr} ${diff.inMinutes} ${"minute".tr}";
    if (diff.inHours < 24) return "${"since".tr} ${diff.inHours} ${"hour".tr}";
    return "${date.day}/${date.month}/${date.year}";
  }
}