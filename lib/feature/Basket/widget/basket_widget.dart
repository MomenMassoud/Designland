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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
          backgroundColor: Theme.of(context).colorScheme.secondary,
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

  // دالة إضافة عنوان ورقم هاتف في حال عدم وجودهما
  Future<void> _showAddAddressAndPhoneDialog(
      String uid, String? existingPhone, List<dynamic> existingAddresses) async {
    final phoneController = TextEditingController(text: existingPhone ?? '');
    final fullNameController = TextEditingController();
    final governorateController = TextEditingController();
    final cityController = TextEditingController();
    final streetController = TextEditingController();
    final buildingController = TextEditingController();
    final floorController = TextEditingController();
    final apartmentController = TextEditingController();
    final landmarkController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complete contact and address details".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (existingPhone == null || existingPhone.isEmpty) ...[
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                      decoration: InputDecoration(
                        labelText: "Contact phone number".tr,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: fullNameController,
                    validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                    decoration: InputDecoration(
                      labelText: "Full Name".tr,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: governorateController,
                          validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                          decoration: InputDecoration(
                            labelText: "Governorate".tr,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                          decoration: InputDecoration(
                            labelText: "City / Area".tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: streetController,
                    validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                    decoration: InputDecoration(
                      labelText: "Street Name".tr,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: buildingController,
                          validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                          decoration: InputDecoration(
                            labelText: "Building".tr,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: floorController,
                          validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                          decoration: InputDecoration(
                            labelText: "Floor".tr,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextFormField(
                          controller: apartmentController,
                          validator: (v) => v == null || v.isEmpty ? "Required".tr : null,
                          decoration: InputDecoration(
                            labelText: "Apt No.".tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: landmarkController,
                    decoration: InputDecoration(
                      labelText: "Nearest Landmark (optional)".tr,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final newAddress = {
                          'fullName': fullNameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'governorate': governorateController.text.trim(),
                          'city': cityController.text.trim(),
                          'street': streetController.text.trim(),
                          'building': buildingController.text.trim(),
                          'floor': floorController.text.trim(),
                          'apartment': apartmentController.text.trim(),
                          'landmark': landmarkController.text.trim(),
                          'createdAt': DateTime.now().toIso8601String(),
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
                      child: Text("Save Address".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 4. تأكيد الطلب وتوليد رقم الطلب وسحب العنوان المختار
  Future<void> _confirmOrder(
      List<QueryDocumentSnapshot> items, double subtotal) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      String? phone = userData['phone'];
      List<dynamic> addresses = userData['addresses'] ?? [];
      if (phone == null || phone.isEmpty || addresses.isEmpty) {
        if (!mounted) return;
        await _showAddAddressAndPhoneDialog(uid, phone, addresses);
        return;
      }

      int selectedAddressIndex = 0;
      bool isAddressSelected = false;

      // اختيار العنوان المفضل للتوصيل
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setBottomSheetState) {
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
                        "Select a delivery address:".tr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedAddressIndex,
                        dropdownColor: Theme.of(context).cardColor,
                        isExpanded: true,
                        items: List.generate(addresses.length, (index) {
                          final addr = addresses[index];
                          final label = addr['street'] != null
                              ? "${addr['fullName'] ?? ''} - ${addr['street']}, Bldg ${addr['building']}, ${addr['city']}"
                              : "${addr['title'] ?? 'Address'} - ${addr['details'] ?? ''}";
                          return DropdownMenuItem(
                            value: index,
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setBottomSheetState(() => selectedAddressIndex = val);
                          }
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            isAddressSelected = true;
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                          label: Text("Confirm & Checkout".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (!isAddressSelected) return;

      final selectedAddress = addresses[selectedAddressIndex];

      int newOrderNumber = 1;
      final constDocRef = _db.collection('app_info').doc('const');

      await _db.runTransaction((transaction) async {
        final constSnapshot = await transaction.get(constDocRef);
        if (constSnapshot.exists && constSnapshot.data()!.containsKey('order_number')) {
          final currentNum = constSnapshot.data()?['order_number'];
          if (currentNum is int) {
            newOrderNumber = currentNum;
          } else if (currentNum is num) {
            newOrderNumber = currentNum.toInt();
          }
        }
        transaction.set(constDocRef, {'order_number': newOrderNumber + 1}, SetOptions(merge: true));
      });

      String clientName = userData['name'] ?? '';
      if (clientName.isEmpty) {
        final mainUserDoc = await _db.collection('user').doc(uid).get();
        if (mainUserDoc.exists) {
          clientName = mainUserDoc.data()?['name'] ?? '';
        }
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
        };
      }).toList();

      final orderRef = await _db.collection('users').doc(uid).collection('orders').add({
        'orderNumber': newOrderNumber,
        'items': orderItems,
        'selectedAddress': selectedAddress,
        'subtotal': subtotal,
        'discountPercentage': _discountPercentage,
        'discountAmount': discountAmount,
        'totalPrice': finalTotalPrice,
        'promoCode': _appliedPromoCode,
        'hasPromoCode': _appliedPromoCode != null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final String orderID = orderRef.id;

      await _db.collection('user').doc(uid).collection('notifications').add({
        'isRead': false,
        'title': "Order Received!",
        'body': 'Thank you for choosing DesignLand',
        'createdAt': FieldValue.serverTimestamp(),
        'targetUser': uid,
      });

      final userEmail = _auth.currentUser?.email ?? '';
      EmailServer().sendInvoiceEmail(
        customerEmail: userEmail,
        orderId: orderID,
        total: finalTotalPrice,
        customerName: clientName,
        items: orderItems,
        orderNumber: newOrderNumber,
      );

      EmailServer().notifyAdmins(
        orderId: orderID,
        total: finalTotalPrice,
        customerEmail: userEmail,
        orderNumber: newOrderNumber,
        items: orderItems,
        customerName: clientName,
        selectedAddress: selectedAddress,
        customerPhone: selectedAddress['phone'] ?? phone,
      );

      final batch = _db.batch();
      for (var doc in items) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Order #$newOrderNumber Placed Successfully!".tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your order has been confirmed and is now being processed.".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Done".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
    final colorScheme = Theme.of(context).colorScheme;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Shopping Cart".tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Text("Please log in to view the shopping cart.".tr, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shopping Cart".tr,
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').doc(uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 70, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "The cart is currently empty.".tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Explore products and add your choices to the cart!".tr,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isDesktop
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        return _buildCartItemCard(cartDocs[index], screenWidth);
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _buildSummaryCard(cartDocs, subtotal, discountAmount, finalTotalPrice),
                  ),
                ],
              )
                  : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartDocs.length,
                      itemBuilder: (context, index) {
                        return _buildCartItemCard(cartDocs[index], screenWidth);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(cartDocs, subtotal, discountAmount, finalTotalPrice),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // كارت المنتجات متجاوب الحجم وديناميكي مع الثيم
  Widget _buildCartItemCard(QueryDocumentSnapshot doc, double screenWidth) {
    final item = doc.data() as Map<String, dynamic>;
    final title = item['title'] ?? 'منتج';
    final price = (item['price'] ?? 0).toDouble();
    final quantity = (item['quantity'] ?? 1) as int;
    final image = item['image'] ?? '';

    final colorScheme = Theme.of(context).colorScheme;
    final double imgSize = screenWidth < 400 ? 60.0 : 75.0;
    final double titleFontSize = screenWidth < 400 ? 13.0 : 14.0;
    final double priceFontSize = screenWidth < 400 ? 13.0 : 14.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image.isNotEmpty
                  ? Image.network(image, width: imgSize, height: imgSize, fit: BoxFit.cover)
                  : Container(
                width: imgSize,
                height: imgSize,
                color: colorScheme.primary.withOpacity(0.12),
                child: Icon(Icons.image_not_supported_outlined, color: colorScheme.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleFontSize, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${price.toStringAsFixed(2)} ${"EGP".tr}",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: priceFontSize,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.onSurfaceVariant.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 14, color: colorScheme.onSurface),
                        onPressed: () => _updateQuantity(doc.id, quantity, -1),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "$quantity",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onSurface),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 14, color: colorScheme.primary),
                        onPressed: () => _updateQuantity(doc.id, quantity, 1),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4757), size: 20),
                  onPressed: () => _removeItem(doc.id),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الحساب والخصومات للألوان الديناميكية
  Widget _buildSummaryCard(List<QueryDocumentSnapshot> items, double subtotal, double discountAmount, double finalTotalPrice) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary".tr,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),

          if (_appliedPromoCode == null) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Enter promo code".tr,
                      prefixIcon: Icon(Icons.local_offer_outlined, color: colorScheme.primary, size: 16),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      errorText: _promoErrorMsg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  child: _isApplyingPromo
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text("Apply".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: colorScheme.secondary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${"Promo code applied:".tr} $_appliedPromoCode (-$_discountPercentage%)",
                      style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                    onPressed: _removePromoCode,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal:".tr, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
              Text("${subtotal.toStringAsFixed(2)} ${"EGP".tr}",
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (_discountPercentage > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount:".tr, style: TextStyle(color: colorScheme.secondary, fontSize: 13)),
                Text("-${discountAmount.toStringAsFixed(2)} ${"EGP".tr}",
                    style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total:".tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              Text(
                "${finalTotalPrice.toStringAsFixed(2)} ${"EGP".tr}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _confirmOrder(items, subtotal),
              child: Text(
                "Confirm Order".tr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}