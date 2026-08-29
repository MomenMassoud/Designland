import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("طلباتي", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF6366F1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6366F1),
            tabs: [
              Tab(text: "الكل"),
              Tab(text: "تحت الانتظار"),
              Tab(text: "جاري التوصيل"),
              Tab(text: "المكتملة"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OrdersListWidget(statusFilter: null),
            OrdersListWidget(statusFilter: 'pending'),
            OrdersListWidget(statusFilter: 'shipping'),
            OrdersListWidget(statusFilter: 'completed'),
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
      case 'completed': return Colors.green;
      case 'shipping': return Colors.orange;
      case 'pending': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed': return "مكتمل";
      case 'shipping': return "جاري التوصيل / الشحن";
      case 'pending': return "تحت الانتظار / التجهيز";
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("لا توجد طلبات متوفرة."));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final status = orderData['status'] ?? 'pending';
            final totalPrice = orderData['totalPrice'] ?? orderData['price'] ?? 0;
            final items = List<dynamic>.from(orderData['items'] ?? []);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("طلب #${orders[index].id.substring(0, 6)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (items.isNotEmpty)
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item['title']} (x${item['quantity'] ?? 1})"),
                            Text("${item['price']} ج.م"),
                          ],
                        ),
                      ))
                    else
                      Text(orderData['title'] ?? 'طلب منتجات'),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("الإجمالي:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$totalPrice ج.م", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}