import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../Product/view/products_list_view.dart';
import '../../Product/widget/product_widget.dart';
import 'dynamic_countdown_widget.dart';

class DiscountProductsCarousel extends StatefulWidget {
  const DiscountProductsCarousel({super.key});

  @override
  State<DiscountProductsCarousel> createState() => _DiscountProductsCarouselState();
}

class _DiscountProductsCarouselState extends State<DiscountProductsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _activePage = 0;
  Timer? _autoSlideTimer;
  int _lastItemCount = 0;

  void _startAutoSlide(int itemCount) {
    if (_lastItemCount == itemCount && _autoSlideTimer != null && _autoSlideTimer!.isActive) {
      return;
    }
    _lastItemCount = itemCount;
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('discountPercentage', isGreaterThan: 0)
        .snapshots();

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

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startAutoSlide(combinedItems.length);
            });

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

                      if (item['type'] == 'banner') {
                        final data = item['data'] as Map<String, dynamic>;
                        final String imageUrl = data['image'] ?? data['imageUrl'] ?? '';
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
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: primaryColor.withOpacity(0.05),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              )
                                  : Container(
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }

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

                      // تخصيص الخلفية والتدرج حسب الـ Theme
                      final List<Color> cardGradientColors = isDarkMode
                          ? const [Color(0xFF1E232A), Color(0xFF121519)]
                          : [
                        primaryColor.withOpacity(0.08),
                        theme.cardColor,
                      ];

                      final Color cardBorderColor = isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : primaryColor.withOpacity(0.12);

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
                            gradient: LinearGradient(
                              colors: cardGradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: cardBorderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.3)
                                    : primaryColor.withOpacity(0.06),
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
                                width: 190,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                                  child: Stack(
                                    children: [
                                      if (imageUrl.isNotEmpty)
                                        CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          placeholder: (context, url) => Container(
                                            color: primaryColor.withOpacity(0.05),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image_outlined),
                                          ),
                                        ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              cardGradientColors.first,
                                              cardGradientColors.first.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
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
                                            color: const Color(0xFFFF4757),
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
                                          width: 160,
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "$finalPrice ${"EGP".tr}",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "$originalPrice",
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                                fontSize: 12,
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
                const SizedBox(height: 8),
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
                        color: _activePage == index
                            ? primaryColor
                            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
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