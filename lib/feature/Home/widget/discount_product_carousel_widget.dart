import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../Product/view/products_list_view.dart';
import '../../Product/widget/product_widget.dart';
import 'dynamic_countdown_widget.dart';


// ==================== DISCOUNT & ADMIN BANNERS CAROUSEL ====================
class DiscountProductsCarousel extends StatefulWidget {
  const DiscountProductsCarousel({super.key});

  @override
  State<DiscountProductsCarousel> createState() => _DiscountProductsCarouselState();
}

class _DiscountProductsCarouselState extends State<DiscountProductsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _activePage = 0;
  Timer? _autoSlideTimer;

  void _startAutoSlide(int itemCount) {
    _autoSlideTimer?.cancel();
    if (itemCount <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _activePage = (_activePage + 1) % itemCount;
        _pageController.animateToPage(
          _activePage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.decelerate,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // جلب منتجات التخفيضات
    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('discountPercentage', isGreaterThan: 0)
        .snapshots();

    // جلب بنارات الأدمن
    final bannersStream = FirebaseFirestore.instance
        .collection('banners')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: productsStream,
      builder: (context, productsSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: bannersStream,
          builder: (context, bannersSnapshot) {
            if ((!productsSnapshot.hasData || productsSnapshot.data!.docs.isEmpty) &&
                (!bannersSnapshot.hasData || bannersSnapshot.data!.docs.isEmpty)) {
              return const SizedBox.shrink();
            }

            final List<Map<String, dynamic>> combinedItems = [];
            final now = DateTime.now();

            // 1. تصفية وإضافة المنتجات التي عليها خصم
            if (productsSnapshot.hasData) {
              for (var doc in productsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final Timestamp? discountUntil = data['discountUntil'] as Timestamp?;

                if (discountUntil != null && discountUntil.toDate().isBefore(now)) {
                  doc.reference.update({
                    'discountPercentage': 0,
                    'discountUntil': FieldValue.delete(),
                  });
                  continue;
                }

                combinedItems.add({
                  'type': 'product',
                  'id': doc.id,
                  'data': data,
                  'docRef': doc.reference,
                });
              }
            }

            // 2. إضافة بنارات الأدمن
            if (bannersSnapshot.hasData) {
              for (var doc in bannersSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                combinedItems.add({
                  'type': 'banner',
                  'id': doc.id,
                  'data': data,
                });
              }
            }

            if (combinedItems.isEmpty) {
              return const SizedBox.shrink();
            }

            _startAutoSlide(combinedItems.length);

            return Column(
              children: [
                SizedBox(
                  height: 175,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: combinedItems.length,
                    onPageChanged: (int index) {
                      setState(() => _activePage = index);
                    },
                    itemBuilder: (context, index) {
                      final item = combinedItems[index];

                      // ---------------- عرض بنار الأدمن ----------------
                      if (item['type'] == 'banner') {
                        final data = item['data'] as Map<String, dynamic>;
                        final String imageUrl = data['image'] ?? '';
                        final bool canClick = data['onclick'] ?? false;
                        final String categoryId = data['category'] ?? '';

                        return GestureDetector(
                          onTap: () {
                            if (canClick && categoryId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductsListView(CategoryDoc: categoryId),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                                  : Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }

                      // ---------------- عرض منتج التخفيضات ----------------
                      final data = item['data'] as Map<String, dynamic>;
                      final docId = item['id'] as String;
                      final docRef = item['docRef'] as DocumentReference;

                      final String title = data['title'] ?? 'Special Offer'.tr;
                      final num originalPrice = data['price'] ?? 0;
                      final num discountPercentage = data['discountPercentage'] ?? 0;
                      final num finalPrice = (originalPrice * (1 - (discountPercentage / 100))).round();

                      final List images = data['images'] ?? [];
                      final String imageUrl = images.isNotEmpty ? images[0] : '';
                      final Timestamp? discountUntilTimestamp = data['discountUntil'] as Timestamp?;

                      return GestureDetector(
                        onTap: () {
                          AnalyticsService.logProductOpen(
                            productId: docId,
                            productTitle: title,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductWidget(productDoc: docId),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D3436), Color(0xFF111111)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: 200,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                                  child: Stack(
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFF2D3436), Colors.transparent],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF7675),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "${"discount".tr} $discountPercentage%",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: 170,
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "$finalPrice ${"EGP".tr}",
                                              style: const TextStyle(
                                                color: Color(0xFF55E6C1),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "$originalPrice ${"EGP".tr}",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    DynamicCountdownWidget(
                                      untilTimestamp: discountUntilTimestamp,
                                      onTimerExpired: () {
                                        docRef.update({
                                          'discountPercentage': 0,
                                          'discountUntil': FieldValue.delete(),
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    combinedItems.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 5,
                      width: _activePage == index ? 18 : 5,
                      decoration: BoxDecoration(
                        color: _activePage == index ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}