import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Product/view/products_list_view.dart';
import 'animated_product_card_widget.dart';

class CategorySectionWidget extends StatelessWidget {
  final CollectionReference productsRef;
  final String categoryId;
  final String categoryTitle;
  final String? selectedSubcategoryId;
  final RangeValues priceRange;
  final ValueNotifier<String> searchQueryNotifier;

  const CategorySectionWidget({
    super.key,
    required this.productsRef,
    required this.categoryId,
    required this.categoryTitle,
    required this.selectedSubcategoryId,
    required this.priceRange,
    required this.searchQueryNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    Query query = productsRef.where('categoryId', isEqualTo: categoryId);

    if (selectedSubcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: selectedSubcategoryId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return ValueListenableBuilder<String>(
          valueListenable: searchQueryNotifier,
          builder: (context, searchQuery, child) {
            final products = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final double price = (data['price'] ?? 0.0).toDouble();
              final String title = (data['title'] ?? '').toString().toLowerCase();
              final String desc = (data['description'] ?? '').toString().toLowerCase();

              final bool matchesPrice = price >= priceRange.start && price <= priceRange.end;
              final bool matchesSearch = searchQuery.isEmpty ||
                  title.contains(searchQuery) ||
                  desc.contains(searchQuery);

              return matchesPrice && matchesSearch;
            }).toList();

            if (products.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              categoryTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductsListView(CategoryDoc: categoryId),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                "See All".tr,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal Product Carousel
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final productData = products[index].data() as Map<String, dynamic>;
                        final images = productData['images'] as List<dynamic>?;
                        final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

                        return AnimatedProductCard(
                          productData: productData,
                          imageUrl: imageUrl,
                          productId: products[index].id,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}