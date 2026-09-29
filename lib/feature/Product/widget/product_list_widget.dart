import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/widget/products_grid_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/services/search_history_service.dart';
import '../../../Core/widgets/category_app_bar.dart';
import '../../../Core/widgets/search_bar_widget.dart';
import '../../../Core/widgets/subcategories_list.dart';

class ProductListWidget extends StatefulWidget {
  final String categoryDoc;

  const ProductListWidget({super.key, required this.categoryDoc});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  Timer? _searchDebounce;
  String? _selectedSubcategoryId;
  String _searchQuery = '';
  final String _lang = Get.locale?.languageCode ?? "ar";

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    final formattedQuery = val.trim().toLowerCase();
    setState(() {
      _searchQuery = formattedQuery;
    });
    _searchNotifier.value = formattedQuery;

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    if (formattedQuery.length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 800), () {
        SearchHistoryService.saveSearchHistory(val);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FD),
      appBar: CategoryAppBar(
        categoryDoc: widget.categoryDoc,
        categoriesRef: _categoriesRef,
        lang: _lang,
        isDarkMode: isDarkMode,
        theme: theme,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 850;

          if (isDesktop) {
            // 🌐 تصميم الويب والسطح مكتبي (Sidebar للفئات الفرعية + Grid)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. القائمة الجانبية للفئات الفرعية (Side Filter Toolbar)
                Container(
                  width: 270,
                  decoration: BoxDecoration(
                    color: isDarkMode ? theme.cardColor : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // شريط البحث الجانبي
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SearchBarWidget(
                          controller: _searchController,
                          isDarkMode: isDarkMode,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          "Subcategories".tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // قائمة التصنيفات الفرعية بشكل رأسي
                      Expanded(
                        child: _WebVerticalSubcategoriesList(
                          subcategoriesRef: _subcategoriesRef,
                          categoryDoc: widget.categoryDoc,
                          selectedSubcategoryId: _selectedSubcategoryId,
                          lang: _lang,
                          onSubcategorySelected: (subId) {
                            setState(() => _selectedSubcategoryId = subId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. شبكة المنتجات (Products Grid)
                Expanded(
                  child: ProductsGridSection(
                    productsRef: _productsRef,
                    categoryDoc: widget.categoryDoc,
                    selectedSubcategoryId: _selectedSubcategoryId,
                    searchQuery: _searchQuery,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            );
          }

          // 📱 تصميم الموبايل (الشريط الأفقي المعتاد)
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.cardColor : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SearchBarWidget(
                        controller: _searchController,
                        isDarkMode: isDarkMode,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SubcategoriesList(
                      subcategoriesRef: _subcategoriesRef,
                      categoryDoc: widget.categoryDoc,
                      selectedSubcategoryId: _selectedSubcategoryId,
                      lang: _lang,
                      onSubcategorySelected: (subId) {
                        setState(() => _selectedSubcategoryId = subId);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ProductsGridSection(
                  productsRef: _productsRef,
                  categoryDoc: widget.categoryDoc,
                  selectedSubcategoryId: _selectedSubcategoryId,
                  searchQuery: _searchQuery,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ودجت القائمة الرأسية للتصنيفات الفرعية الخاصة بالويب (مع صور مصغرة راقية)
class _WebVerticalSubcategoriesList extends StatelessWidget {
  final CollectionReference subcategoriesRef;
  final String categoryDoc;
  final String? selectedSubcategoryId;
  final String lang;
  final Function(String?) onSubcategorySelected;

  const _WebVerticalSubcategoriesList({
    required this.subcategoriesRef,
    required this.categoryDoc,
    required this.selectedSubcategoryId,
    required this.lang,
    required this.onSubcategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return StreamBuilder<QuerySnapshot>(
      stream: subcategoriesRef
          .where('categoryId', isEqualTo: categoryDoc)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          children: [
            // بطاقة خيار "الكل" All
            _buildCategoryCard(
              context: context,
              title: "All".tr,
              imageUrl: null,
              isSelected: selectedSubcategoryId == null,
              onTap: () => onSubcategorySelected(null),
              primaryColor: primaryColor,
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String title = lang == "en"
                  ? (data['nameEn'] ?? data['name'] ?? '')
                  : (data['nameAr'] ?? data['name'] ?? '');
              final String? imageUrl = data['imageUrl'] ?? data['image'];
              final bool isSelected = selectedSubcategoryId == doc.id;

              return _buildCategoryCard(
                context: context,
                title: title,
                imageUrl: imageUrl,
                isSelected: isSelected,
                onTap: () => onSubcategorySelected(doc.id),
                primaryColor: primaryColor,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.12) : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // صورة التصنيف مصغرة شيك جداً وواضحة
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 38,
                      height: 38,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.category, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: isSelected ? primaryColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // اسم التصنيف
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryColor : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              // أيقونة الصح للتحديد
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}