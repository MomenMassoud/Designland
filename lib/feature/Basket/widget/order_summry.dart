import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/server/email_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrderSummry extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double discountPercentage;
  final String? appliedPromoCode;

  const OrderSummry({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.discountPercentage,
    this.appliedPromoCode,
  });

  @override
  State<OrderSummry> createState() => _OrderSummryState();
}

class _OrderSummryState extends State<OrderSummry> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // الدولة والمحافظة ورسوم الشحن
  String? _selectedCountryId;
  String? _selectedCountryName;
  String? _selectedSubCountryId;
  String? _selectedSubCountryName;
  double _shippingFee = 0.0;

  // طريقة الدفع (افتراضياً: الدفع عند الاستلام)
  String _paymentMethod = 'cod'; // 'cod' or 'card'

  bool _isSubmitting = false;

  // اختيار العنوان من العناوين المسجلة أو إضافة عنوان جديد
  int? _selectedAddressIndex;
  bool _isAddingNewAddress = false;

  // حقول إضافة عنوان جديد
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _instructionsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(List<dynamic> existingAddresses) async {
    if (_selectedCountryId == null || _selectedSubCountryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select Country and Governorate".tr)),
      );
      return;
    }

    Map<String, dynamic> selectedAddress = {};

    if (_isAddingNewAddress || existingAddresses.isEmpty) {
      if (!_formKey.currentState!.validate()) return;
      selectedAddress = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _selectedCountryName,
        'governorate': _selectedSubCountryName,
        'street': _streetController.text.trim(),
        'building': _buildingController.text.trim(),
        'floor': _floorController.text.trim(),
        'apartment': _apartmentController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };
    } else {
      if (_selectedAddressIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a delivery address".tr)),
        );
        return;
      }
      final addr = Map<String, dynamic>.from(existingAddresses[_selectedAddressIndex!]);
      addr['country'] = _selectedCountryName;
      addr['governorate'] = _selectedSubCountryName;
      selectedAddress = addr;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      // إرفاق وتحديث العنوان في بيانات المستخدم إذا تم إدخال عنوان جديد
      if (_isAddingNewAddress || existingAddresses.isEmpty) {
        await _db.collection('users').doc(uid).set({
          'phone': _phoneController.text.trim(),
          'addresses': FieldValue.arrayUnion([selectedAddress]),
        }, SetOptions(merge: true));
      }

      final double discountAmount = widget.subtotal * (widget.discountPercentage / 100);
      final double finalTotal = (widget.subtotal - discountAmount) + _shippingFee;

      // توليد رقم الطلب
      int newOrderNumber = 1;
      final constDocRef = _db.collection('app_info').doc('const');

      await _db.runTransaction((transaction) async {
        final constSnapshot = await transaction.get(constDocRef);
        if (constSnapshot.exists && constSnapshot.data()!.containsKey('order_number')) {
          final currentNum = constSnapshot.data()?['order_number'];
          newOrderNumber = (currentNum is num) ? currentNum.toInt() : 1;
        }
        transaction.set(constDocRef, {'order_number': newOrderNumber + 1}, SetOptions(merge: true));
      });

      // تحضير العناصر الشاملة للطلب
      final List<Map<String, dynamic>> finalOrderItems = widget.cartItems.map((item) {
        return {
          'productId': item['productId'] ?? '',
          'title': item['title'] ?? 'منتج',
          'price': item['price'] ?? 0,
          'quantity': item['quantity'] ?? 1,
          'image': item['image'] ?? '',
          'notes': item['notes'] ?? '',
          'customFieldsData': item['customFieldsData'] ?? {},
        };
      }).toList();

      // إضافة الشحن كبند مستقل في الفاتورة
      finalOrderItems.add({
        'productId': 'shipping_fee',
        'title': 'رسوم الشحن - ${_selectedSubCountryName ?? ''}',
        'price': _shippingFee,
        'quantity': 1,
        'image': '',
        'notes': 'Shipping fee based on selected region',
        'customFieldsData': {},
      });

      // حفظ بيانات الطلب
      final orderRef = await _db.collection('users').doc(uid).collection('orders').add({
        'orderNumber': newOrderNumber,
        'items': finalOrderItems,
        'selectedAddress': selectedAddress,
        'subtotal': widget.subtotal,
        'shippingFee': _shippingFee,
        'discountPercentage': widget.discountPercentage,
        'discountAmount': discountAmount,
        'totalPrice': finalTotal,
        'promoCode': widget.appliedPromoCode,
        'hasPromoCode': widget.appliedPromoCode != null,
        'paymentMethod': _paymentMethod,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // الإشعارات والبريد الإلكتروني
      final userEmail = _auth.currentUser?.email ?? '';
      final userDoc = await _db.collection('users').doc(uid).get();
      final clientName = userDoc.data()?['name'] ?? selectedAddress['fullName'] ?? '';

      EmailServer().sendInvoiceEmail(
        customerEmail: userEmail,
        orderId: orderRef.id,
        total: finalTotal,
        customerName: clientName,
        items: finalOrderItems,
        orderNumber: newOrderNumber,
      );

      EmailServer().notifyAdmins(
        orderId: orderRef.id,
        total: finalTotal,
        customerEmail: userEmail,
        orderNumber: newOrderNumber,
        items: finalOrderItems,
        customerName: clientName,
        selectedAddress: selectedAddress,
        customerPhone: selectedAddress['phone'] ?? '',
      );
      await _db.collection('user').doc(uid).collection('notifications').add({
        'isRead': false,
        'title': "Order Received!",
        'body': 'Thank you for choosing DesignLand',
        'createdAt': FieldValue.serverTimestamp(),
        'targetUser': uid,
      });


      // تفريغ السلة بعد نجاح الطلب
      final cartSnap = await _db.collection('users').doc(uid).collection('cart').get();
      final batch = _db.batch();
      for (var doc in cartSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
          content: Text(
            "${"Order #".tr}$newOrderNumber ${"Placed Successfully!".tr}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text("Done".tr),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error placing order: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Order Summary".tr, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
        body: uid == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: colorScheme.primary));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final addresses = List<dynamic>.from(userData['addresses'] ?? []);

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: isDesktop
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCartItemsSummary(isDarkMode),
                            const SizedBox(height: 20),
                            _buildLocationAndAddressSection(addresses, isDarkMode),
                            const SizedBox(height: 20),
                            _buildPaymentMethodSection(isDarkMode),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildPaymentBreakdownCard(addresses),
                    ),
                  ],
                )
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCartItemsSummary(isDarkMode),
                      const SizedBox(height: 16),
                      _buildLocationAndAddressSection(addresses, isDarkMode),
                      const SizedBox(height: 16),
                      _buildPaymentMethodSection(isDarkMode),
                      const SizedBox(height: 16),
                      _buildPaymentBreakdownCard(addresses),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ملخص المنتجات (مع الملاحظات والحقول المخصصة)
  Widget _buildCartItemsSummary(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Items".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              final title = item['title'] ?? 'منتج';
              final price = (item['price'] ?? 0).toDouble();
              final quantity = (item['quantity'] ?? 1) as int;
              final image = item['image'] ?? '';
              final notes = item['notes'] as String? ?? '';
              final customFields = item['customFieldsData'] as Map<String, dynamic>? ?? {};

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: image.isNotEmpty
                        ? Image.network(image, width: 55, height: 55, fit: BoxFit.cover)
                        : Container(width: 55, height: 55, color: Colors.grey.shade300),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Qty: $quantity".tr, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text("Note: $notes".tr, style: const TextStyle(fontSize: 11, color: Colors.orange)),
                        ],
                        if (customFields.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            customFields.entries.map((e) => "${e.key}: ${e.value}").join(", "),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    "${(price * quantity).toStringAsFixed(2)} EGP",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // قسم اختيار الموقع والعنوان
  Widget _buildLocationAndAddressSection(List<dynamic> addresses, bool isDarkMode) {
    final lang = Get.locale?.languageCode ?? "ar";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Shipping & Delivery".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // 1. اختيار الدولة
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('countries').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final countryDocs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: _selectedCountryId,
                  hint: Text("Select Country".tr),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: countryDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = lang == 'en' ? (data['nameEn'] ?? '') : (data['nameAr'] ?? '');
                    return DropdownMenuItem(value: doc.id, child: Text(name));
                  }).toList(),
                  onChanged: (val) {
                    final selectedDoc = countryDocs.firstWhere((d) => d.id == val);
                    final data = selectedDoc.data() as Map<String, dynamic>;
                    setState(() {
                      _selectedCountryId = val;
                      _selectedCountryName = lang == 'en' ? data['nameEn'] : data['nameAr'];
                      _selectedSubCountryId = null;
                      _selectedSubCountryName = null;
                      _shippingFee = 0.0;
                    });
                  },
                  validator: (v) => v == null ? "Required".tr : null,
                );
              },
            ),
            const SizedBox(height: 12),

            // 2. اختيار المحافظة
            if (_selectedCountryId != null)
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('countries').doc(_selectedCountryId).collection('sub_countries').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final subDocs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedSubCountryId,
                    hint: Text("Select Governorate / Sub-Region".tr),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: subDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = lang == 'en' ? (data['nameEn'] ?? '') : (data['nameAr'] ?? '');
                      final fee = (data['shippingFee'] ?? 0).toDouble();
                      return DropdownMenuItem(value: doc.id, child: Text("$name (+$fee EGP)"));
                    }).toList(),
                    onChanged: (val) {
                      final selectedDoc = subDocs.firstWhere((d) => d.id == val);
                      final data = selectedDoc.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedSubCountryId = val;
                        _selectedSubCountryName = lang == 'en' ? data['nameEn'] : data['nameAr'];
                        _shippingFee = (data['shippingFee'] ?? 0).toDouble();
                      });
                    },
                    validator: (v) => v == null ? "Required".tr : null,
                  );
                },
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // 3. التحقق من وجود عناوين محفوظة أم إدخال عنوان جديد
            if (addresses.isNotEmpty && !_isAddingNewAddress) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Saved Address".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () => setState(() => _isAddingNewAddress = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text("Add New".tr),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(addresses.length, (index) {
                  final addr = addresses[index];
                  final titleText = "${addr['fullName'] ?? ''} - ${addr['phone'] ?? ''}";
                  final fullAddressText = addr['street'] != null
                      ? "${addr['street']}, Bldg ${addr['building']}, Floor ${addr['floor']}, Apt ${addr['apartment']}"
                      : (addr['details'] ?? '');

                  return Card(
                    elevation: 0,
                    color: _selectedAddressIndex == index
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                        : (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedAddressIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedAddressIndex,
                      onChanged: (val) => setState(() => _selectedAddressIndex = val),
                      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(fullAddressText, style: const TextStyle(fontSize: 12)),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }),
              ),
            ] else ...[
              // حقول نموذج العنوان الجديد
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Enter Address Details".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (addresses.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _isAddingNewAddress = false),
                      child: Text("Use Saved Address".tr),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAddressTextField(
                      controller: _fullNameController,
                      label: "Full Name".tr,
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Required".tr : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAddressTextField(
                      controller: _phoneController,
                      label: "Mobile Number".tr,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? "Required".tr : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAddressTextField(
                controller: _streetController,
                label: "Street Name".tr,
                icon: Icons.add_road_outlined,
                validator: (v) => v!.isEmpty ? "Required".tr : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildAddressTextField(
                      controller: _buildingController,
                      label: "Building".tr,
                      icon: Icons.domain_outlined,
                      validator: (v) => v!.isEmpty ? "Required".tr : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAddressTextField(
                      controller: _floorController,
                      label: "Floor".tr,
                      icon: Icons.stairs_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildAddressTextField(
                      controller: _apartmentController,
                      label: "Apt No.".tr,
                      icon: Icons.door_front_door_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildAddressTextField(
                controller: _landmarkController,
                label: "Landmark (Optional)".tr,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 8),
              _buildAddressTextField(
                controller: _instructionsController,
                label: "Delivery Instructions (Optional)".tr,
                icon: Icons.note_alt_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // قسم اختيار طريقة الدفع
  Widget _buildPaymentMethodSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment Method".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _paymentMethod,
            onChanged: (val) => setState(() => _paymentMethod = val!),
            title: Text("Cash on Delivery".tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            secondary: const Icon(Icons.payments_outlined),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          RadioListTile<String>(
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (val) => setState(() => _paymentMethod = val!),
            title: Text("Credit / Debit Card".tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            secondary: const Icon(Icons.credit_card_outlined),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // بطاقة الحساب الإجمالي والتاكيد النهائي
  Widget _buildPaymentBreakdownCard(List<dynamic> addresses) {
    final colorScheme = Theme.of(context).colorScheme;
    final double discountAmount = widget.subtotal * (widget.discountPercentage / 100);
    final double grandTotal = (widget.subtotal - discountAmount) + _shippingFee;

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
          Text("Payment Summary".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal:".tr),
              Text("${widget.subtotal.toStringAsFixed(2)} EGP"),
            ],
          ),
          if (widget.discountPercentage > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Discount:".tr, style: const TextStyle(color: Colors.green)),
                Text("-${discountAmount.toStringAsFixed(2)} EGP", style: const TextStyle(color: Colors.green)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Shipping Fee:".tr),
              Text("+${_shippingFee.toStringAsFixed(2)} EGP", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Grand Total:".tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                "${grandTotal.toStringAsFixed(2)} EGP",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSubmitting ? null : () => _submitOrder(addresses),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("Confirm Order".tr, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFFAF9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}