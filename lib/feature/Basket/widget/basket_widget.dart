import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/services/guest_cart_service.dart';
import 'package:desginland/feature/Login/view/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'order_summry.dart';

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

  // زيادة / تقليل كمية المنتج للزائر أو المستخدم المسجل
  Future<void> _updateQuantity(String? docId, int index, int currentQty, int delta) async {
    final uid = _auth.currentUser?.uid;
    int newQty = currentQty + delta;

    if (uid == null) {
      // تعديل سلة الزائر Local
      setState(() {
        if (newQty <= 0) {
          GuestCartService().guestCartItems.removeAt(index);
        } else {
          GuestCartService().guestCartItems[index]['quantity'] = newQty;
        }
      });
      return;
    }

    if (docId != null) {
      if (newQty <= 0) {
        await _removeItem(docId, index);
      } else {
        await _db
            .collection('users')
            .doc(uid)
            .collection('cart')
            .doc(docId)
            .update({'quantity': newQty});
      }
    }
  }

  // حذف عنصر من السلة
  Future<void> _removeItem(String? docId, int index) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        GuestCartService().guestCartItems.removeAt(index);
      });
    } else if (docId != null) {
      await _db.collection('users').doc(uid).collection('cart').doc(docId).delete();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("The product has been removed from the cart.".tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // التحقق من البرومو كود وتطبيقه
  Future<void> _applyPromoCode() async {
    final enteredCode = _promoController.text.trim();
    if (enteredCode.isEmpty) return;

    setState(() {
      _isApplyingPromo = true;
      _promoErrorMsg = null;
    });

    try {
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
      final double percentage = (promoData['discountPercentage'] ?? 0).toDouble();

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
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    } catch (e) {
      setState(() {
        _promoErrorMsg = "An error occurred while verifying the code.".tr;
        _isApplyingPromo = false;
      });
    }
  }

  // إلغاء كود الخصم
  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountPercentage = 0.0;
      _promoController.clear();
      _promoErrorMsg = null;
    });
  }

  // الانتقال للتأكيد أو تسجيل الدخول
  void _proceedToCheckout(List<Map<String, dynamic>> items, double subtotal) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      // توجيه الزائر للتسجيل مع الحفاظ على السلة
      Get.toNamed(LoginView.id)?.then((_) async {
        final newUid = _auth.currentUser?.uid;
        if (newUid != null) {
          await GuestCartService().syncGuestCartToUser(newUid);
          setState(() {});
        }
      });
      return;
    }

    // الانتقال إلى صفحة Order Summary مع إرسال تفاصيل الخصم والبرومو كود
    Get.to(() => OrderSummry(
      cartItems: items,
      subtotal: subtotal,
      discountPercentage: _discountPercentage,
      appliedPromoCode: _appliedPromoCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;
    final colorScheme = Theme.of(context).colorScheme;

    // إذا كان زائر نعرض سلة الزائر Local
    if (uid == null) {
      final guestItems = GuestCartService().guestCartItems;
      return _buildCartUI(guestItems, isDesktop, screenWidth, colorScheme, isGuest: true);
    }

    // إذا كان مسجل نعرض البيانات من Firebase
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(uid).collection('cart').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<Map<String, dynamic>> cartItems = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'docId': doc.id,
            ...data,
          };
        }).toList();

        return _buildCartUI(cartItems, isDesktop, screenWidth, colorScheme, isGuest: false);
      },
    );
  }

  Widget _buildCartUI(List<Map<String, dynamic>> cartItems, bool isDesktop, double screenWidth, ColorScheme colorScheme, {required bool isGuest}) {
    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Shopping Cart".tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 70, color: colorScheme.primary),
              const SizedBox(height: 20),
              Text("The cart is currently empty.".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    double subtotal = 0;
    for (var item in cartItems) {
      final price = (item['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 1) as int;
      subtotal += price * quantity;
    }

    final double discountAmount = subtotal * (_discountPercentage / 100);
    final double finalTotalPrice = subtotal - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text("Shopping Cart".tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isDesktop
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) => _buildCartItemCard(cartItems[index], index, screenWidth),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildSummaryCard(cartItems, subtotal, discountAmount, finalTotalPrice, isGuest),
              ),
            ],
          )
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) => _buildCartItemCard(cartItems[index], index, screenWidth),
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(cartItems, subtotal, discountAmount, finalTotalPrice, isGuest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item, int index, double screenWidth) {
    final title = item['title'] ?? 'منتج';
    final price = (item['price'] ?? 0).toDouble();
    final quantity = (item['quantity'] ?? 1) as int;
    final image = item['image'] ?? '';
    final docId = item['docId'];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.isNotEmpty
                ? Image.network(image, width: 70, height: 70, fit: BoxFit.cover)
                : Container(width: 70, height: 70, color: Colors.grey.shade300),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${price.toStringAsFixed(2)} EGP", style: TextStyle(color: colorScheme.primary)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _updateQuantity(docId, index, quantity, -1),
              ),
              Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _updateQuantity(docId, index, quantity, 1),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(docId, index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // كارت ملخص الطلب + إدخال البرومو كود
  Widget _buildSummaryCard(List<Map<String, dynamic>> items, double subtotal, double discountAmount, double finalTotalPrice, bool isGuest) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Summary".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // --- قسم إدخال البرومو كود ---
          if (_appliedPromoCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: "Enter promo code".tr,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: _promoErrorMsg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  child: _isApplyingPromo
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Apply".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            // إظهار الكود المطبق مع زر الإزالة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.secondary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, color: colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text("Code: $_appliedPromoCode ($_discountPercentage%)", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: _removePromoCode,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),

          // --- التفاصيل المالية ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal:".tr),
              Text("${subtotal.toStringAsFixed(2)} EGP"),
            ],
          ),

          if (_discountPercentage > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount ($_discountPercentage%):".tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text("-${discountAmount.toStringAsFixed(2)} EGP", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ],

          const SizedBox(height: 8),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total:".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${finalTotalPrice.toStringAsFixed(2)} EGP", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => _proceedToCheckout(items, subtotal),
              child: Text(
                isGuest ? "Log in to Complete Order".tr : "Proceed to Checkout".tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}