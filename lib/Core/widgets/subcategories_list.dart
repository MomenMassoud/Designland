import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'subcategory_chip.dart';

class SubcategoriesList extends StatelessWidget {
  final CollectionReference subcategoriesRef;
  final String categoryDoc;
  final String? selectedSubcategoryId;
  final String lang;
  final ValueChanged<String?> onSubcategorySelected;

  const SubcategoriesList({
    super.key,
    required this.subcategoriesRef,
    required this.categoryDoc,
    required this.selectedSubcategoryId,
    required this.lang,
    required this.onSubcategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: subcategoriesRef
          .where('categoryId', isEqualTo: categoryDoc)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final subdocs = snapshot.data!.docs;
        if (subdocs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Text(
                "Subcategories".tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subdocs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ModernSubcategoryChip(
                      name: "All Items".tr,
                      imageUrl: null,
                      isSelected: selectedSubcategoryId == null,
                      onTap: () => onSubcategorySelected(null),
                    );
                  }

                  final subdoc = subdocs[index - 1];
                  final subData = subdoc.data() as Map<String, dynamic>;
                  final String subName = lang == "en"
                      ? (subData['nameEn'] ?? 'Subcategory'.tr)
                      : (subData['nameAr'] ?? 'Subcategory'.tr);
                  final String? imageUrl =
                      subData['imageUrl'] ?? subData['image'];

                  return ModernSubcategoryChip(
                    name: subName,
                    imageUrl: imageUrl,
                    isSelected: selectedSubcategoryId == subdoc.id,
                    onTap: () => onSubcategorySelected(subdoc.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}