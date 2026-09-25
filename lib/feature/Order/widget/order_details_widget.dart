import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderDetailsWidget extends StatefulWidget {
  final String _orderID;

  const OrderDetailsWidget({Key? key, required String orderID})
      : _orderID = orderID,
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _OrderDetailsWidgetState();
  }
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب تفاصيل الطلب من Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getOrderDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(widget._orderID)
        .get();
  }

  // تحديد لون حالة الطلب
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6C5CE7);

    final cardBgColor = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3436);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFFAF9FF),
      appBar: AppBar(
        title: Text(
          'Order Details'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        elevation: 0,
        backgroundColor: cardBgColor,
        foregroundColor: textColor,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: _getOrderDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Failed to load order details'.tr,
                style: TextStyle(color: subTextColor, fontSize: 16),
              ),
            );
          }

          final orderData = snapshot.data!.data()!;

          final Timestamp? createdAt = orderData['createdAt'] as Timestamp?;
          final String formattedDate = createdAt != null
              ? DateFormat('yyyy-MM-dd - hh:mm a').format(createdAt.toDate())
              : '';

          final int orderNumber = orderData['orderNumber'] ?? 0;
          final String status = orderData['status'] ?? 'Pending';
          final num subtotal = orderData['subtotal'] ?? 0;
          final num totalPrice = orderData['totalPrice'] ?? 0;
          final num discountAmount = orderData['discountAmount'] ?? 0;

          final List<dynamic> items = orderData['items'] ?? [];
          final Map<String, dynamic> selectedAddress =
          Map<String, dynamic>.from(orderData['selectedAddress'] ?? {});

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 750;

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // جانب المنتجات
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildHeaderCard(
                                    orderNumber: orderNumber,
                                    formattedDate: formattedDate,
                                    status: status,
                                    isDarkMode: isDarkMode,
                                    cardBgColor: cardBgColor,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildItemsCard(
                                    items: items,
                                    isDarkMode: isDarkMode,
                                    cardBgColor: cardBgColor,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    primaryColor: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // جانب معلومات الشحن والملخص المالي
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildAddressCard(
                                    address: selectedAddress,
                                    isDarkMode: isDarkMode,
                                    cardBgColor: cardBgColor,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    primaryColor: primaryColor,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSummaryCard(
                                    subtotal: subtotal,
                                    discountAmount: discountAmount,
                                    totalPrice: totalPrice,
                                    isDarkMode: isDarkMode,
                                    cardBgColor: cardBgColor,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    primaryColor: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      // العرض المخصص للموبايل
                      return Column(
                        children: [
                          _buildHeaderCard(
                            orderNumber: orderNumber,
                            formattedDate: formattedDate,
                            status: status,
                            isDarkMode: isDarkMode,
                            cardBgColor: cardBgColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                          ),
                          const SizedBox(height: 16),
                          _buildItemsCard(
                            items: items,
                            isDarkMode: isDarkMode,
                            cardBgColor: cardBgColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          _buildAddressCard(
                            address: selectedAddress,
                            isDarkMode: isDarkMode,
                            cardBgColor: cardBgColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryCard(
                            subtotal: subtotal,
                            discountAmount: discountAmount,
                            totalPrice: totalPrice,
                            isDarkMode: isDarkMode,
                            cardBgColor: cardBgColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryColor: primaryColor,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 1. كارت رأس الطلب (رقم الطلب والحالة والتاريخ)
  Widget _buildHeaderCard({
    required int orderNumber,
    required String formattedDate,
    required String status,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$orderNumber',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              if (formattedDate.isNotEmpty)
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              status.toUpperCase().tr,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. كارت منتجات الطلب
  Widget _buildItemsCard({
    required List<dynamic> items,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${items.length})'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(items[index]);
              final String title = item['title'] ?? 'Product';
              final String image = item['image'] ?? '';
              final num price = item['price'] ?? 0;
              final int quantity = item['quantity'] ?? 1;

              final Map<String, dynamic> customFields =
              Map<String, dynamic>.from(item['customFieldsData'] ?? {});
              final String? size = customFields['size'];
              final String? notes = customFields['notes'];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: image.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: image,
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 75,
                        height: 75,
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                        : Container(
                      width: 75,
                      height: 75,
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (size != null && size.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Size: $size'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              'Qty: $quantity'.tr,
                              style: TextStyle(fontSize: 12, color: subTextColor),
                            ),
                          ],
                        ),
                        if (notes != null && notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Notes: "$notes"'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(price * quantity).toStringAsFixed(0)} EGP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. كارت عنوان التوصيل والمعلومات الشخصية
  Widget _buildAddressCard({
    required Map<String, dynamic> address,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    if (address.isEmpty) return const SizedBox.shrink();

    final String fullName = address['fullName'] ?? '';
    final String phone = address['phone'] ?? '';
    final String street = address['street'] ?? '';
    final String building = address['building'] ?? '';
    final String apartment = address['apartment'] ?? '';
    final String floor = address['floor'] ?? '';
    final String city = address['city'] ?? '';
    final String governorate = address['governorate'] ?? '';
    final String landmark = address['landmark'] ?? '';

    final String fullAddressText =
        '$street, Building: $building, Floor: $floor, Apt: $apartment${landmark.isNotEmpty ? ' (Near $landmark)' : ''}, $city, $governorate';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Shipping Address'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fullName.isNotEmpty)
            Text(
              fullName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(fontSize: 13, color: subTextColor),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            fullAddressText,
            style: TextStyle(
              fontSize: 13,
              color: subTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 4. كارت ملخص الدفع (Subtotal, Discount, Total)
  Widget _buildSummaryCard({
    required num subtotal,
    required num discountAmount,
    required num totalPrice,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            label: 'Subtotal'.tr,
            value: '${subtotal.toStringAsFixed(0)} EGP',
            textColor: subTextColor,
          ),
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              label: 'Discount'.tr,
              value: '-${discountAmount.toStringAsFixed(0)} EGP',
              textColor: Colors.green,
            ),
          ],
          Divider(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            height: 24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)} EGP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: textColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}