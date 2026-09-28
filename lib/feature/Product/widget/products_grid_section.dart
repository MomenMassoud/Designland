import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../Core/widgets/product_card.dart';
import '../view/empty_products_view.dart';

class ProductsGridSection extends StatelessWidget {
  final CollectionReference productsRef;
  final String categoryDoc;
  final String? selectedSubcategoryId;
  final String searchQuery;
  final bool isDarkMode;

  const ProductsGridSection({
    super.key,
    required this.productsRef,
    required this.categoryDoc,
    required this.selectedSubcategoryId,
    required this.searchQuery,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth >= 1200
        ? 5
        : screenWidth >= 900
        ? 4
        : screenWidth >= 600
        ? 3
        : 2;

    final double childAspectRatio = screenWidth >= 1100
        ? 0.72
        : screenWidth >= 600
        ? 0.68
        : 0.62;

    final stream = selectedSubcategoryId != null
        ? productsRef
        .where('categoryId', isEqualTo: categoryDoc)
        .where('subcategoryId', isEqualTo: selectedSubcategoryId)
        .snapshots()
        : productsRef.where('categoryId', isEqualTo: categoryDoc).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final products = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String title = (data['title'] ?? '').toString().toLowerCase();
          final String desc =
          (data['description'] ?? '').toString().toLowerCase();

          return searchQuery.isEmpty ||
              title.contains(searchQuery) ||
              desc.contains(searchQuery);
        }).toList();

        if (products.isEmpty) {
          return EmptyProductsView(isDarkMode: isDarkMode);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final productData = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;

            return InteractiveProductCard(
              key: ValueKey(productId), // لتحسين سرعة إعادة الرسم عند التعديل
              productData: productData,
              productId: productId,
            );
          },
        );
      },
    );
  }
}