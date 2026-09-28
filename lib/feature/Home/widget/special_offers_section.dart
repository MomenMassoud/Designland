import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/widgets/flash_sale_card.dart';
import 'discount_timer_widget.dart';

class SpecialOffersSection extends StatelessWidget {
  final CollectionReference productsRef;

  const SpecialOffersSection({super.key, required this.productsRef});

  Duration _getRemainingDiscountTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: productsRef.where('discountPercentage', isGreaterThan: 0).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final discountProducts = snapshot.data!.docs;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1300),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Special Offers ⚡".tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        DiscountTimerWidget(duration: _getRemainingDiscountTime()),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: discountProducts.length,
                    itemBuilder: (context, index) {
                      final productData =
                      discountProducts[index].data() as Map<String, dynamic>;
                      final String productId = discountProducts[index].id;

                      return FlashSaleCardWidget(
                        key: ValueKey(productId),
                        productData: productData,
                        productId: productId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}