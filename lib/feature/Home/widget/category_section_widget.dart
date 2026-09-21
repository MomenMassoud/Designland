import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Product/view/products_list_view.dart';
import 'animated_product_card_widget.dart';



// ==================== FAST CATEGORY & PRODUCTS SECTION ====================
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Color(0xFF2D3436),
                        ),
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
                        child:  Row(
                          children: [
                            Text("See All".tr, style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6C5CE7)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}
