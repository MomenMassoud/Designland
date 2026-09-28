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
      body: Column(
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
      ),
    );
  }
}