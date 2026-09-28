import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Core/widgets/category_card.dart';

class CategoriesGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;

  const CategoriesGrid({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final String lang = Get.locale?.languageCode ?? "ar";

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1300),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Explore Categories ✨".tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Find personalized items crafted just for you".tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (selectedCategoryId != null)
                  TextButton.icon(
                    onPressed: () => onSelectCategory(null),
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text("Show All Categories"),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.8 : 1.4,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final categoryData =
                categories[index].data() as Map<String, dynamic>;
                final String categoryId = categories[index].id;
                final String name = lang == "en"
                    ? (categoryData['nameEn'] ?? '')
                    : (categoryData['nameAr'] ?? '');
                final String? imageUrl =
                    categoryData['imageUrl'] ?? categoryData['image'];

                final bool isSelected = selectedCategoryId == categoryId;

                return CategoryCardWidget(
                  key: ValueKey(categoryId),
                  name: name,
                  imageUrl: imageUrl,
                  categoryId: categoryId,
                  isSelected: isSelected,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}