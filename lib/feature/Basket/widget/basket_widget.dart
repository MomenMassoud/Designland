import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/server/confirm_email.dart';
import 'package:desginland/Core/server/email_notification_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BasketWidget extends StatefulWidget {
  const BasketWidget({super.key});

  @override
  State<BasketWidget> createState() => _BasketWidgetState();
}

class _BasketWidgetState extends State<BasketWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _promoController = TextEditingController();

  // متغيرات البرومو كود والخصم
  bool _isApplyingPromo = false;
  String? _appliedPromoCode;
  double _discountPercentage = 0.0;
  String? _promoErrorMsg;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

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
      SnackBar(
        content: Text("The product has been removed from the cart.".tr),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 3. التحقق من البرومو كود وتطبيقه
  Future<void> _applyPromoCode() async {
    final enteredCode = _promoController.text.trim();
    if (enteredCode.isEmpty) return;

    setState(() {
      _isApplyingPromo = true;
      _promoErrorMsg = null;
    });

    try {
      // تحويل الكود المكتوب إلى Capital للحصول على المطابقة بمرونة بدون إجبار العميل
      final uppercaseCode = enteredCode.toUpperCase();

      final query = await _db
          .collection('promo_codes')
          .where('code', isEqualTo: uppercaseCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() {
          _promoErrorMsg = "invalid Promo Code".tr;
          _isApplyingPromo = false;
        });
        return;
      }

      final promoData = query.docs.first.data();
      final bool isActive = promoData['isActive'] ?? false;
      final Timestamp? expiresAt = promoData['expiresAt'] as Timestamp?;
      final double percentage =
      (promoData['discountPercentage'] ?? 0).toDouble();

      // التحقق من صلاحية وتاريخ الكود
      final now = DateTime.now();
      if (!isActive || (expiresAt != null && expiresAt.toDate().isBefore(now))) {
        setState(() {
          _promoErrorMsg = "This promo code is expired or inactive.".tr;
          _isApplyingPromo = false;
        });
        return;
      }

      setState(() {
        _appliedPromoCode = uppercaseCode;
        _discountPercentage = percentage;
        _isApplyingPromo = false;
        _promoErrorMsg = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${"Promo code applied successfully! Discount:".tr} $percentage% 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _promoErrorMsg = "An error occurred while verifying the code.".tr;
        _isApplyingPromo = false;
      });
    }
  }

  // إزالة البرومو كود المطبق
  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountPercentage = 0.0;
      _promoController.clear();
      _promoErrorMsg = null;
    });
  }

  // 4. تأكيد الطلب وتحويله لحالة "تحت التنفيذ"
  Future<void> _confirmOrder(
      List<QueryDocumentSnapshot> items, double subtotal) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      String userEmail = "";
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        userEmail = userDoc.data()?['email'] ?? _auth.currentUser?.email ?? '';
      }

      // حساب الخصم والسعر النهائي
      final double discountAmount = subtotal * (_discountPercentage / 100);
      final double finalTotalPrice = subtotal - discountAmount;

      // تجهيز قائمة المنتجات بكل التفاصيل والداتا المدخلة
      final orderItems = items.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'cartItemId': doc.id,
          'productId': data['productId'] ?? '',
          'title': data['title'] ?? 'منتج',
          'price': data['price'] ?? 0,
          'originalPrice': data['originalPrice'] ?? data['price'] ?? 0,
          'quantity': data['quantity'] ?? 1,
          'image': data['image'] ?? '',
          'notes': data['notes'] ?? '',
          'customFieldsData': data['customFieldsData'] ?? {},
          'selectedAddress': data['selectedAddress'] ?? {},
        };
      }).toList();

      String orderID = "";

      // إضافة إشعار للمستخدم
      await _db
          .collection('user')
          .doc(uid)
          .collection('notifications')
          .doc()
          .set({
        'isRead': false,
        'title': "Order Created",
        'body': 'تم إرسال إيميل استقبال الفاتورة بنجاح!',
        'createdAt': FieldValue.serverTimestamp(),
        'targetUser': uid
      });

      // حفظ الطلب مع تفاصيل البرومو كود والخصم
      final orderRef = await _db.collection('users').doc(uid).collection('orders').add({
        'items': orderItems,
        'subtotal': subtotal,
        'discountPercentage': _discountPercentage,
        'discountAmount': discountAmount,
        'totalPrice': finalTotalPrice,
        'promoCode': _appliedPromoCode,
        'hasPromoCode': _appliedPromoCode != null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      orderID = orderRef.id;
      sendInvoiceEmail(customerEmail: _auth.currentUser!.email.toString(),
          orderId: orderID, total: finalTotalPrice);
      EmailNotificationService()
          .notifyAdmins(orderId: orderID, total: finalTotalPrice, customerEmail: _auth.currentUser!.email.toString());
      // تفريغ السلة بعد نجاح الطلب
      final batch = _db.batch();
      for (var doc in items) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (userEmail.isNotEmpty) {
        await sendInvoiceEmail(
            customerEmail: userEmail, orderId: orderID, total: finalTotalPrice);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: Text(
            "Your order has been successfully confirmed and is now being processed!".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Good".tr),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "${"An error occurred while confirming the order:".tr}$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Shopping Cart".tr)),
        body: Center(
          child: Text("Please log in to view the shopping cart.".tr),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Shopping Cart".tr,
          style: const TextStyle(
              color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "The cart is currently empty.".tr,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final cartDocs = snapshot.data!.docs;

          // حساب الإجمالي الضمني قبل الخصم
          double subtotal = 0;
          for (var doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] ?? 0).toDouble();
            final quantity = (data['quantity'] ?? 1) as int;
            subtotal += price * quantity;
          }

          // حساب الخصم والسعر الصافي
          final double discountAmount = subtotal * (_discountPercentage / 100);
          final double finalTotalPrice = subtotal - discountAmount;

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
                    final quantity = (item['quantity'] ?? 1) as int;
                    final image = item['image'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: image.isNotEmpty
                                    ? Image.network(image,
                                    width: 65, height: 65, fit: BoxFit.cover)
                                    : Container(
                                  width: 65,
                                  height: 65,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${price.toStringAsFixed(2)} ${"EGP".tr}",
                                      style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        color: Colors.grey),
                                    onPressed: () =>
                                        _updateQuantity(doc.id, quantity, -1),
                                  ),
                                  Text(
                                    "$quantity",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Color(0xFF6366F1)),
                                    onPressed: () =>
                                        _updateQuantity(doc.id, quantity, 1),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => _removeItem(doc.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // قسم البرومو كود والشريط السفلي
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================== 🎟️ PROMO CODE SECTION ====================
                    if (_appliedPromoCode == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: "Enter promo code".tr,
                                prefixIcon: const Icon(Icons.local_offer_outlined),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                errorText: _promoErrorMsg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isApplyingPromo ? null : _applyPromoCode,
                            child: _isApplyingPromo
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                                : Text("Apply".tr,
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${"Promo code applied:".tr} $_appliedPromoCode (-$_discountPercentage%)",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              onPressed: _removePromoCode,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ==================== 📊 SUMMARY & TOTALS ====================
                    if (_discountPercentage > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Subtotal:".tr,
                              style: const TextStyle(color: Colors.grey)),
                          Text("${subtotal.toStringAsFixed(2)} ${"EGP".tr}",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Discount:".tr,
                              style: const TextStyle(color: Colors.green)),
                          Text("-${discountAmount.toStringAsFixed(2)} ${"EGP".tr}",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total:".tr,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "${finalTotalPrice.toStringAsFixed(2)} ${"EGP".tr}",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1)),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmOrder(cartDocs, subtotal),
                        child: Text(
                          "Order Confirmation (In Progress)".tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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