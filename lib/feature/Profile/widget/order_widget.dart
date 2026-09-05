import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          title:  Text(
            "My Orders".tr,
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom:  TabBar(
            isScrollable: true,
            physics: BouncingScrollPhysics(),
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
        body:  TabBarView(
          physics: BouncingScrollPhysics(),
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
  const OrdersListWidget({super.key, this.statusFilter});

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

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title:  Text(
          "Cancel Order".tr,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
        ),
        content:  Text(
          "Are you sure you want to cancel this request?".tr,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text("to retreat".tr, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:  Text("Confirm Cancellation".tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('orders')
            .doc(orderId)
            .update({'status': 'cancelled'});

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text("The order has been successfully cancelled.".tr),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text("An error occurred while cancelling the order.".tr),
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
      return  Center(child: Text("Please log in to view orders.".tr));
    }

    return StreamBuilder<QuerySnapshot>(
      // تم إزالة orderBy من الاستعلام المباشر لتفادي مشكلة الـ Composite Index في الفايربيز
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

        // تصفية وترتيب الطلبات محلياً لمنع مشاكل Firestore Index
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
            final totalPrice = orderData['totalPrice'] ?? orderData['price'] ?? 0;
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
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
                          onPressed: () => _cancelOrder(context, doc.id),
                          child:  Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFE74C3C)),
                              SizedBox(width: 6),
                              Text(
                                "Cancel Order".tr,
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
            style: TextStyle(
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