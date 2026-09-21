import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'category_section_widget.dart';
import 'discount_product_carousel_widget.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef = FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef = FirebaseFirestore.instance.collection('subcategories');

  String lang = "";
  Timer? _searchDebounce;

  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    lang=Get.locale?.languageCode ?? "ar";
  }


  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  // Filter States
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  RangeValues _priceRange = const RangeValues(0, 50000);

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await FirebaseFirestore.instance.collection('search_history').doc().set({
      'query':query.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'userID':'Gust',
      'gust':true
    });
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('search_history')
          .add({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }).then((value)async{
        await FirebaseFirestore.instance.collection('search_history').doc().set({
          'query':query.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'userID':userId,
          'gust':false
        });
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchNotifier.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _priceRange = const RangeValues(0, 50000);
      _searchController.clear();
      _searchNotifier.value = '';
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          "Filter Products".tr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(ctx);
                          },
                          child:  Text(
                            "Reset All".tr,
                            style: TextStyle(color: Color(0xFF6C5CE7)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text("Category".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _categoriesRef.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          hint:  Text("All Categories".tr),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(lang=="en"?data['nameEn'] ?? 'Category'.tr :data['nameAr']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              _selectedCategoryId = val;
                              _selectedSubcategoryId = null;
                            });
                            setState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_selectedCategoryId != null) ...[
                      Text("Subcategory".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: _subcategoriesRef
                            .where('categoryId', isEqualTo: _selectedCategoryId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final docs = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: _selectedSubcategoryId,
                            hint:  Text("All Subcategories".tr),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(lang=="en"? data['nameEn'] ?? 'Subcategory'.tr :data['nameAr'] ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() => _selectedSubcategoryId = val);
                              setState(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Price Range".tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "\$${_priceRange.start.round()} - \$${_priceRange.end.round()}",
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 50000,
                      activeColor: const Color(0xFF6C5CE7),
                      inactiveColor: const Color(0xFF6C5CE7).withOpacity(0.15),
                      divisions: 50,
                      onChanged: (values) {
                        setModalState(() => _priceRange = values);
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child:  Text("Apply Filters".tr,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. شريط البحث والفلترة
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          _searchNotifier.value = val.trim().toLowerCase();

                          if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

                          if (val.trim().length >= 2) {
                            _searchDebounce = Timer(const Duration(milliseconds: 800), () {
                              _saveSearchHistory(val);
                            });
                          }
                        },
                        decoration:  InputDecoration(
                          hintText: "Search custom gifts, items...".tr,
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openFilterBottomSheet,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. بانر العروض والتخفيضات التفاعلي
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: DiscountProductsCarousel(),
            ),
          ),

          // 3. الأقسام والمنتجات
          StreamBuilder<QuerySnapshot>(
            stream: _selectedCategoryId != null
                ? _categoriesRef
                .where(FieldPath.documentId, isEqualTo: _selectedCategoryId)
                .snapshots()
                : _categoriesRef.snapshots(),
            builder: (context, catSnapshot) {
              if (catSnapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                    ),
                  ),
                );
              }

              final categoryDocs = catSnapshot.data?.docs ?? [];

              if (categoryDocs.isEmpty) {
                return  SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No categories found.".tr, style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final categoryDoc = categoryDocs[index];
                    final categoryData = categoryDoc.data() as Map<String, dynamic>;
                    String categoryTitle =Get.locale?.languageCode=="en"? categoryData['nameEn']:categoryData['nameAr'];

                    return CategorySectionWidget(
                      productsRef: _productsRef,
                      categoryId: categoryDoc.id,
                      categoryTitle: categoryTitle,
                      selectedSubcategoryId: _selectedSubcategoryId,
                      priceRange: _priceRange,
                      searchQueryNotifier: _searchNotifier, // تم التمرير كـ ValueNotifier صريح
                    );
                  },
                  childCount: categoryDocs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
