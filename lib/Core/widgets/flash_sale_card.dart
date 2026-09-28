import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../feature/Product/view/product_view.dart';

class FlashSaleCardWidget extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const FlashSaleCardWidget({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  State<FlashSaleCardWidget> createState() => _FlashSaleCardWidgetState();
}

class _FlashSaleCardWidgetState extends State<FlashSaleCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.productData['images'] as List<dynamic>?;
    final String imageUrl = (images != null && images.isNotEmpty) ? images[0] : '';
    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;
    final num finalPrice = (originalPrice * (1 - (discountPercentage / 100))).round();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Get.to(() => ProductView(ProductDoc: widget.productId)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered
                  ? primaryColor
                  : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? primaryColor.withOpacity(0.18)
                    : (isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04)),
                blurRadius: isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17)),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "-$discountPercentage%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "$finalPrice ${"EGP".tr}",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$originalPrice",
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}