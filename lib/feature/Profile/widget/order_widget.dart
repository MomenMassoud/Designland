import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../Core/Utils/app.colors.dart';



class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "My Orders".tr,
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: TabBar(
            isScrollable: true,
            physics: const BouncingScrollPhysics(),
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryPurple,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "all".tr),
              Tab(text: "Pending".tr),
              Tab(text: "Delivery in progress".tr),
              Tab(text: "The Completed".tr),
              Tab(text: "Cancelled".tr),
            ],
          ),
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            OrdersListWidget(statusFilter: null),
            OrdersListWidget(statusFilter: 'pending'.tr),
            OrdersListWidget(statusFilter: 'shipping'.tr),
            OrdersListWidget(statusFilter: 'completed'.tr),
            OrdersListWidget(statusFilter: 'cancelled'.tr),
          ],
        ),
      ),
    );
  }
}

class OrdersListWidget extends StatelessWidget {
  final String? statusFilter;
  OrdersListWidget({super.key, this.statusFilter});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF2ECC71);
      case 'shipping':
        return const Color(0xFFE67E22);
      case 'pending':
        return AppColors.primaryPurple;
      case 'cancelled':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return "completed".tr;
      case 'shipping':
        return "shipping".tr;
      case 'pending':
        return "pending".tr;
      case 'cancelled':
        return "ملغي";
      default:
        return status;
    }
  }

  // دالة إرسال إيميل إلغاء الطلب عبر سيرفر Vercel
  Future<void> _sendCancelInvoiceEmail({
    required String customerEmail,
    required String orderId,
    required double total,
  }) async {
    const String apiUrl = 'https://designland-backend.vercel.app/api/cancel-email';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customerEmail': customerEmail,
          'orderId': orderId,
          'total': total,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('🎉 تم إرسال إيميل إلغاء الفاتورة بنجاح!');
      } else {
        debugPrint('فشل إرسال إيميل الإلغاء: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending cancel email: $e');
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId, double totalPrice) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final currentUser = auth.currentUser;
    if (currentUser == null) return;
    
    

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Cancel Order".tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
        ),
        content: Text(
          "Are you sure you want to cancel this request?".tr,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("to retreat".tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirm Cancellation".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firestore.collection('user').doc(auth.currentUser!.uid).collection('notifications').doc().set({
          'isRead':false,
          'title':"Order Cancel",
          'body':'تم إرسال إيميل إلغاء الفاتورة بنجاح!',
          'createdAt':FieldValue.serverTimestamp(),
          'targetUser':auth.currentUser!.uid
        });
        // 1. تحديث حالة الطلب في الفايربيز إلى ملغي
        await firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('orders')
            .doc(orderId)
            .update({'status': 'cancelled'});

        // 2. جلب إيميل المستخدم الحالي
        String userEmail = currentUser.email ?? '';
        if (userEmail.isEmpty) {
          final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            userEmail = userDoc.data()?['email'] ?? '';
          }
        }

        // 3. إرسال إيميل الإلغاء أوتوماتيكياً
        if (userEmail.isNotEmpty) {
          _sendCancelInvoiceEmail(
            customerEmail: userEmail,
            orderId: orderId.length > 6 ? orderId.substring(0, 6) : orderId,
            total: totalPrice,
          );
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("The order has been successfully cancelled.".tr),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred while cancelling the order.".tr),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text("Please log in to view orders.".tr));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryPurple, strokeWidth: 2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        List<QueryDocumentSnapshot> orders = snapshot.data!.docs;
        if (statusFilter != null) {
          orders = orders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == statusFilter;
          }).toList();
        }

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final doc = orders[index];
            final orderData = doc.data() as Map<String, dynamic>;
            final status = orderData['status'] ?? 'pending';
            final num priceRaw = orderData['totalPrice'] ?? orderData['price'] ?? 0;
            final double totalPrice = priceRaw.toDouble();
            final items = List<dynamic>.from(orderData['items'] ?? []);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${"Order no".tr} #${doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.8),
                    if (items.isNotEmpty)
                      ...items.map(
                            (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item['title']} (x${item['quantity'] ?? 1})",
                                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              ),
                              Text(
                                "${item['price']}${"EGP".tr}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        orderData['title'] ?? 'طلب منتجات مخصصة',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    const Divider(height: 24, thickness: 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:".tr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                        Text(
                          "$totalPrice${"EGP".tr}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'pending') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE74C3C),
                            side: BorderSide(color: const Color(0xFFE74C3C).withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _cancelOrder(context, doc.id, totalPrice),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFE74C3C)),
                              SizedBox(width: 6),
                              Text(
                                "Cancel Order",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AppColors.primaryPurple.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "There are no requests available at the moment.".tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}