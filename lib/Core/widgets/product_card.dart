import 'package:cached_network_image/cached_network_image.dart';
import 'package:desginland/feature/Product/view/product_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../feature/Product/widget/order_details_bottom_sheet.dart';

class InteractiveProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const InteractiveProductCard({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<InteractiveProductCard> createState() => _InteractiveProductCardState();
}

class _InteractiveProductCardState extends State<InteractiveProductCard> {
  bool isHovered = false;

  Future<void> _handleAddToCart(
      Map<String, dynamic> productData, double finalPrice) async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (!mounted) return;

      final bool isProductActive =
          productData['IsActive'] ?? productData['isActive'] ?? true;

      if (!isProductActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("This product is currently unavailable.".tr),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showOrderDetailsBottomSheet(
        context: context,
        uid: user?.uid,
        productId: widget.productId,
        productData: productData,
        finalPrice: finalPrice,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${"An error occurred during processing:".tr}$e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final images = widget.productData['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ??
        widget.productData['discount'] ??
        0;
    final bool hasDiscount = discountPercentage > 0;
    final num finalPrice = hasDiscount
        ? (originalPrice * (1 - (discountPercentage / 100))).round()
        : originalPrice;

    final bool isProductActive =
        widget.productData['IsActive'] ?? widget.productData['isActive'] ?? true;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductView(
                ProductDoc: widget.productId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered
              ? (Matrix4.identity()..translate(0, -5, 0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDarkMode ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF6C5CE7).withOpacity(0.4)
                  : isDarkMode
                  ? Colors.white10
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF6C5CE7).withOpacity(0.15)
                    : Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                blurRadius: isHovered ? 14 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductImageSection(
                  imageUrl: imageUrl,
                  isDarkMode: isDarkMode,
                  isHovered: isHovered,
                  hasDiscount: hasDiscount,
                  discountPercentage: discountPercentage,
                  isProductActive: isProductActive,
                ),
              ),
              _ProductInfoSection(
                title: widget.productData['title'] ?? 'Product Title'.tr,
                finalPrice: finalPrice,
                originalPrice: originalPrice,
                hasDiscount: hasDiscount,
                isProductActive: isProductActive,
                isDarkMode: isDarkMode,
                isHovered: isHovered,
                onAddToCart: () {
                  final double origPrice = double.tryParse(
                      widget.productData['price']?.toString() ?? '0') ??
                      0.0;
                  final double discPercent = double.tryParse(
                      (widget.productData['discount'] ??
                          widget.productData['discountPercentage'])
                          ?.toString() ??
                          '0') ??
                      0.0;
                  final double discountedPrice = discPercent > 0
                      ? origPrice - (origPrice * (discPercent / 100))
                      : origPrice;

                  _handleAddToCart(widget.productData, discountedPrice);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final String imageUrl;
  final bool isDarkMode;
  final bool isHovered;
  final bool hasDiscount;
  final num discountPercentage;
  final bool isProductActive;

  const _ProductImageSection({
    required this.imageUrl,
    required this.isDarkMode,
    required this.isHovered,
    required this.hasDiscount,
    required this.discountPercentage,
    required this.isProductActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          child: imageUrl.isNotEmpty
              ? AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDarkMode
                    ? Colors.grey.shade900
                    : const Color(0xFF6C5CE7).withOpacity(0.04),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                ),
              ),
            ),
          )
              : Container(
            color: isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
          ),
        ),
        if (hasDiscount)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "-$discountPercentage%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isProductActive
                  ? const Color(0xFF2ED573).withOpacity(0.9)
                  : Colors.red.shade600.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isProductActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isProductActive ? "In Stock".tr : "Out of stock".tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  final String title;
  final num finalPrice;
  final num originalPrice;
  final bool hasDiscount;
  final bool isProductActive;
  final bool isDarkMode;
  final bool isHovered;
  final VoidCallback onAddToCart;

  const _ProductInfoSection({
    required this.title,
    required this.finalPrice,
    required this.originalPrice,
    required this.hasDiscount,
    required this.isProductActive,
    required this.isDarkMode,
    required this.isHovered,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$finalPrice ${"EGP".tr}",
                      style: TextStyle(
                        color: isProductActive
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        "$originalPrice ${"EGP".tr}",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isProductActive
                        ? (isHovered
                        ? const Color(0xFF6C5CE7)
                        : const Color(0xFF6C5CE7).withOpacity(0.1))
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 16,
                    color: isProductActive
                        ? (isHovered ? Colors.white : const Color(0xFF6C5CE7))
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}