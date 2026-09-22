import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/server/email_server.dart';
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
        backgroundColor: const Color(0xFF6C5CE7), //[cite: 7]
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _promoErrorMsg = "An error occurred while verifying the code.".tr;
        _isApplyingPromo = false;
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountPercentage = 0.0;
      _promoController.clear();
      _promoErrorMsg = null;
    });
  }

  Future<void> _showAddAddressAndPhoneDialog(
      String uid, String? existingPhone, List<dynamic> existingAddresses) async {
    final phoneController = TextEditingController(text: existingPhone ?? '');
    final addressTitleController = TextEditingController();
    final addressDetailsController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Complete contact and address details".tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (existingPhone == null || existingPhone.isEmpty) ...[
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Contact phone number".tr,
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: addressTitleController,
                  decoration: InputDecoration(
                    labelText: "Address name (e.g., Home, Work)".tr,
                    prefixIcon: const Icon(Icons.label_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressDetailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Full address details".tr,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (phoneController.text.trim().isEmpty ||
                          addressTitleController.text.trim().isEmpty ||
                          addressDetailsController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill in all the details.".tr)),
                        );
                        return;
                      }

                      final newAddress = {
                        'title': addressTitleController.text.trim(),
                        'details': addressDetailsController.text.trim(),
                      };

                      await _db.collection('users').doc(uid).set({
                        'phone': phoneController.text.trim(),
                        'addresses': FieldValue.arrayUnion([newAddress]),
                      }, SetOptions(merge: true));

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Data saved successfully! Order now.".tr)),
                      );
                    },
                    child: Text("Save and track the order".tr, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. تأكيد الطلب وتحويله لحالة "تحت التنفيذ"
  Future<void> _confirmOrder(
      List<QueryDocumentSnapshot> items, double subtotal) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      int selectedAddressIndex = 0;
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      String? phone = userData['phone'];
      List<dynamic> addresses = userData['addresses'] ?? [];
      if (phone == null || phone.isEmpty || addresses.isEmpty) {
        if (!mounted) return;
        await _showAddAddressAndPhoneDialog(uid, phone, addresses);
        return;
      }


      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
          builder: (context){
            return StatefulBuilder(
                builder: (context, setBottomSheetState){
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      top: 20,
                      left: 20,
                      right: 20,
                    ),
                      child: SingleChildScrollView(
                        child: Form(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Select a delivery address:".tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: selectedAddressIndex,
                                items: List.generate(addresses.length, (index) {
                                  final addr = addresses[index];
                                  return DropdownMenuItem(
                                    value: index,
                                    child: Text("${addr['title']} - ${addr['details']}"),
                                  );
                                }),
                                onChanged: (val) {
                                  if (val != null) {
                                    setBottomSheetState(() => selectedAddressIndex = val);
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: (){Navigator.pop(context);},
                                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                                    label: Text("Order")),
                              )
                            ],
                          ),
                        ),
                      )
                  );
                }
            );
          }
      );

      String userEmail = "";
      if (userDoc.exists) {
        userEmail = userDoc.data()?['email'] ?? _auth.currentUser?.email ?? '';
      }

      final double discountAmount = subtotal * (_discountPercentage / 100);
      final double finalTotalPrice = subtotal - discountAmount;

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
          'selectedAddress': addresses[selectedAddressIndex]?? {},
        };
      }).toList();

      String orderID = "";

      await _db
          .collection('user')
          .doc(uid)
          .collection('notifications')
          .doc()
          .set({
        'isRead': false,
        'title': "Order Done",
        'body': '',
        'createdAt': FieldValue.serverTimestamp(),
        'targetUser': uid
      });

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

      EmailServer().sendInvoiceEmail(
          customerEmail: _auth.currentUser!.email.toString(),
          orderId: orderID,
          total: finalTotalPrice);

      EmailServer().notifyAdmins(
          orderId: orderID,
          total: finalTotalPrice,
          customerEmail: _auth.currentUser!.email.toString());

      final batch = _db.batch();
      for (var doc in items) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (userEmail.isNotEmpty && userEmail != _auth.currentUser?.email) {
        await EmailServer().sendInvoiceEmail(
            customerEmail: userEmail, orderId: orderID, total: finalTotalPrice);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 60),
          content: Text(
            "Your order has been successfully confirmed and is now being processed!".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436)), //[cite: 7]
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7), //[cite: 7]
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Good".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${"An error occurred while confirming the order:".tr} $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9FF), //[cite: 7]
        appBar: AppBar(
          title: Text("Shopping Cart".tr, style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold)), //[cite: 7]
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text("Please log in to view the shopping cart.".tr, style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF), //[cite: 7]
      appBar: AppBar(
        title: Text(
          "Shopping Cart".tr,
          style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.w800, fontSize: 20), //[cite: 7]
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').doc(uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))); //[cite: 7]
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.08), //[cite: 7]
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 70, color: Color(0xFF6C5CE7)), //[cite: 7]
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "The cart is currently empty.".tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)), //[cite: 7]
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Explore products and add your choices to the cart!".tr,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final cartDocs = snapshot.data!.docs;

          double subtotal = 0;
          for (var doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] ?? 0).toDouble();
            final quantity = (data['quantity'] ?? 1) as int;
            subtotal += price * quantity;
          }

          final double discountAmount = subtotal * (_discountPercentage / 100);
          final double finalTotalPrice = subtotal - discountAmount;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: isDesktop
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة منتجات السلة للويب (الجانب الأيسر/الأكبر)
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        return _buildCartItemCard(cartDocs[index]);
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  // بطاقة ملخص الحساب للويب (الجانب الأيمن)
                  Expanded(
                    flex: 2,
                    child: _buildSummaryCard(cartDocs, subtotal, discountAmount, finalTotalPrice),
                  ),
                ],
              )
                  : Column(
                children: [
                  // قائمة المنتجات للموبايل
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        return _buildCartItemCard(cartDocs[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // بطاقة الملخص للموبايل
                  _buildSummaryCard(cartDocs, subtotal, discountAmount, finalTotalPrice),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // كارت مفصل ومصمم لكل منتج داخل السلة
  Widget _buildCartItemCard(QueryDocumentSnapshot doc) {
    final item = doc.data() as Map<String, dynamic>;
    final title = item['title'] ?? 'منتج';
    final price = (item['price'] ?? 0).toDouble();
    final quantity = (item['quantity'] ?? 1) as int;
    final image = item['image'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.06), //[cite: 7]
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // صورة المنتج
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: image.isNotEmpty
                  ? Image.network(image, width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                width: 80,
                height: 80,
                color: const Color(0xFF6C5CE7).withOpacity(0.08), //[cite: 7]
                child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF6C5CE7)), //[cite: 7]
              ),
            ),
            const SizedBox(width: 16),
            // تفاصيل الاسم والسعر
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3436)), //[cite: 7]
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${price.toStringAsFixed(2)} ${"EGP".tr}",
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7), //[cite: 7]
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // أزرار التحكم بالكمية
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9FF), //[cite: 7]
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16, color: Color(0xFF2D3436)), //[cite: 7]
                        onPressed: () => _updateQuantity(doc.id, quantity, -1),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "$quantity",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3436)), //[cite: 7]
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF6C5CE7)), //[cite: 7]
                        onPressed: () => _updateQuantity(doc.id, quantity, 1),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4757), size: 22),
                  onPressed: () => _removeItem(doc.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الحساب والخصومات والأزرار الناتجة
  Widget _buildSummaryCard(List<QueryDocumentSnapshot> items, double subtotal, double discountAmount, double finalTotalPrice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.08), //[cite: 7]
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary".tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)), //[cite: 7]
          ),
          const SizedBox(height: 16),

          // قسم أدخال الكوبون
          if (_appliedPromoCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Enter promo code".tr,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFF6C5CE7), size: 18), //[cite: 7]
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFFAF9FF), //[cite: 7]
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _promoErrorMsg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7), //[cite: 7]
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  child: _isApplyingPromo
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text("Apply".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${"Promo code applied:".tr} $_appliedPromoCode (-$_discountPercentage%)",
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                    onPressed: _removePromoCode,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // التفاصيل المالية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal:".tr, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              Text("${subtotal.toStringAsFixed(2)} ${"EGP".tr}",
                  style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold, fontSize: 14)), //[cite: 7]
            ],
          ),
          if (_discountPercentage > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount:".tr, style: const TextStyle(color: Color(0xFF10B981), fontSize: 14)),
                Text("-${discountAmount.toStringAsFixed(2)} ${"EGP".tr}",
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total:".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))), //[cite: 7]
              Text(
                "${finalTotalPrice.toStringAsFixed(2)} ${"EGP".tr}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF6C5CE7)), //[cite: 7]
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7), //[cite: 7]
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: const Color(0xFF6C5CE7).withOpacity(0.3), //[cite: 7]
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _confirmOrder(items, subtotal),
              child: Text(
                "Confirm Order".tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}