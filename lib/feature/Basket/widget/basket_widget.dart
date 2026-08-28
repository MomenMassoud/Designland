import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BasketWidget extends StatefulWidget {
  const BasketWidget({super.key});

  @override
  State<BasketWidget> createState() => _BasketWidgetState();
}

class _BasketWidgetState extends State<BasketWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. زيادة أو تقليل كمية المنتج في السلة
  Future<void> _updateQuantity(String docId, int currentQty, int delta) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    int newQty = currentQty + delta;
    if (newQty <= 0) {
      _removeItem(docId);
    } else {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(docId)
          .update({'quantity': newQty});
    }
  }

  // 2. حذف عنصر من السلة
  Future<void> _removeItem(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(docId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم إزالة المنتج من السلة"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 3. تأكيد الطلب وتحويله لحالة "تحت التنفيذ"
  Future<void> _confirmOrder(
      List<QueryDocumentSnapshot> items, double totalPrice) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      // تجهيز قائمة المنتجات للطلب
      final orderItems = items.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'productId': doc.id,
          'title': data['title'] ?? 'منتج',
          'price': data['price'] ?? 0,
          'quantity': data['quantity'] ?? 1,
          'image': data['image'] ?? '',
        };
      }).toList();

      // إنشاء وثيقة طلب جديد بحالة pending
      await _db.collection('users').doc(uid).collection('orders').add({
        'items': orderItems,
        'totalPrice': totalPrice,
        'status': 'pending', // حالة الطلب: تحت التنفيذ
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تفريغ السلة بعد نجاح الطلب
      final batch = _db.batch();
      for (var doc in items) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: const Text(
            "تم تأكيد طلبك بنجاح وهو الآن تحت التنفيذ!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("حسناً"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء تأكيد الطلب: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("سلة التسوق")),
        body: const Center(
          child: Text("برجاء تسجيل الدخول لعرض سلة التسوق"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "سلة التسوق",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').doc(uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "السلة فارغة حالياً",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final cartDocs = snapshot.data!.docs;

          // حساب الإجمالي
          double totalPrice = 0;
          for (var doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] ?? 0).toDouble();
            final quantity = (data['quantity'] ?? 1) as int;
            totalPrice += price * quantity;
          }

          return Column(
            children: [
              // قائمة العناصر في السلة
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartDocs.length,
                  itemBuilder: (context, index) {
                    final doc = cartDocs[index];
                    final item = doc.data() as Map<String, dynamic>;

                    final title = item['title'] ?? 'منتج';
                    final price = (item['price'] ?? 0).toDouble();
                    final quantity = item['quantity'] ?? 1;
                    final image = item['image'] ?? '';

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // صورة المنتج
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image.isNotEmpty
                                  ? Image.network(image, width: 60, height: 60, fit: BoxFit.cover)
                                  : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // تفاصيل الاسم والسعر
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$price ج.م",
                                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // تحكم الكمية والحذف
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                  onPressed: () => _updateQuantity(doc.id, quantity, -1),
                                ),
                                Text(
                                  "$quantity",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1)),
                                  onPressed: () => _updateQuantity(doc.id, quantity, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeItem(doc.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // شريط الفاتورة السفلي وتأكيد الطلب
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("الإجمالي:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "${totalPrice.toStringAsFixed(2)} ج.م",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmOrder(cartDocs, totalPrice),
                        child: const Text(
                          "تأكيد الطلب (تحت التنفيذ)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}