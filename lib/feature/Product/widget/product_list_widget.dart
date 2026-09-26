import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/product_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Login/view/login_view.dart';
import 'order_details_bottom_sheet.dart'; // استيراد الـ Bottom Sheet الموحد

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ProductListWidget extends StatefulWidget {
  final String categoryDoc;

  const ProductListWidget({super.key, required this.categoryDoc});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');
  String lang = Get.locale?.languageCode ?? "ar";
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');
  Timer? _searchDebounce;
  String? _selectedSubcategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userID': 'Gust',
        'gust': true
      });
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('search_history')
          .add({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userID': userId,
        'gust': false
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: isDarkMode
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _categoriesRef.doc(widget.categoryDoc).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                "Category Products".tr,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String categoryTitle = lang == "en"
                ? (data['nameEn'] ?? data['name'] ?? "Category Products".tr)
                : (data['nameAr'] ?? "Category Products".tr);

            return Text(
              categoryTitle,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ==================== SEARCH & SUBCATEGORIES SECTION ====================
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? theme.cardColor : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? Colors.white10
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                        _searchNotifier.value = val.trim().toLowerCase();

                        if (_searchDebounce?.isActive ?? false) {
                          _searchDebounce!.cancel();
                        }

                        if (val.trim().length >= 2) {
                          _searchDebounce =
                              Timer(const Duration(milliseconds: 800), () {
                                _saveSearchHistory(val);
                              });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search in this category...".tr,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // SUBCATEGORIES SLIDER
                StreamBuilder<QuerySnapshot>(
                  stream: _subcategoriesRef
                      .where('categoryId', isEqualTo: widget.categoryDoc)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final subdocs = snapshot.data!.docs;

                    if (subdocs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 2),
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
                                final isSelected =
                                    _selectedSubcategoryId == null;
                                return _ModernSubcategoryChip(
                                  name: "All Items".tr,
                                  imageUrl: null,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedSubcategoryId = null;
                                    });
                                  },
                                );
                              }

                              final subdoc = subdocs[index - 1];
                              final subData =
                              subdoc.data() as Map<String, dynamic>;
                              final isSelected =
                                  _selectedSubcategoryId == subdoc.id;
                              final String subName = lang == "en"
                                  ? (subData['nameEn'] ?? 'Subcategory'.tr)
                                  : (subData['nameAr'] ?? 'Subcategory'.tr);
                              final String? imageUrl =
                                  subData['imageUrl'] ?? subData['image'];

                              return _ModernSubcategoryChip(
                                name: subName,
                                imageUrl: imageUrl,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedSubcategoryId = subdoc.id;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ==================== PRODUCTS GRID ====================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedSubcategoryId != null
                  ? _productsRef
                  .where('categoryId', isEqualTo: widget.categoryDoc)
                  .where('subcategoryId',
                  isEqualTo: _selectedSubcategoryId)
                  .snapshots()
                  : _productsRef
                  .where('categoryId', isEqualTo: widget.categoryDoc)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C5CE7),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Client-side search filtering
                final products = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String title =
                  (data['title'] ?? '').toString().toLowerCase();
                  final String desc =
                  (data['description'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      title.contains(_searchQuery) ||
                      desc.contains(_searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 50,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "No products found in this category.".tr,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
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
                    final productData =
                    products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;

                    return _InteractiveProductCard(
                      productData: productData,
                      productId: productId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Subcategory Chip Component
class _ModernSubcategoryChip extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernSubcategoryChip({
    required this.name,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : isDarkMode
                ? theme.cardColor
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6C5CE7)
                  : isDarkMode
                  ? Colors.white24
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white
                      : const Color(0xFF2D3436),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🛍️ Interactive Product Grid Card Component
class _InteractiveProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const _InteractiveProductCard({
    required this.productData,
    required this.productId,
  });

  @override
  State<_InteractiveProductCard> createState() =>
      _InteractiveProductCardState();
}

class _InteractiveProductCardState extends State<_InteractiveProductCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final images = widget.productData['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ??
        widget.productData['discount'] ??
        0;
    final bool hasDiscount = discountPercentage > 0;
    final num finalPrice = hasDiscount
        ? (originalPrice * (1 - (discountPercentage / 100))).round()
        : originalPrice;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductView(
                ProductDoc: widget.productId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered
              ? (Matrix4.identity()..translate(0, -5, 0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDarkMode ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF6C5CE7).withOpacity(0.4)
                  : isDarkMode
                  ? Colors.white10
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF6C5CE7).withOpacity(0.15)
                    : Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
                blurRadius: isHovered ? 14 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Container
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                      child: imageUrl.isNotEmpty
                          ? AnimatedScale(
                        scale: isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDarkMode
                                ? Colors.grey.shade900
                                : const Color(0xFF6C5CE7)
                                .withOpacity(0.04),
                          ),
                          errorWidget: (context, url, error) =>
                              Container(
                                color: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey,
                                ),
                              ),
                        ),
                      )
                          : Container(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // Discount Badge
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "-$discountPercentage%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info & Details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['title'] ?? 'Product Title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$finalPrice ${"EGP".tr}",
                                style: const TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  "$originalPrice ${"EGP".tr}",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final double origPrice = double.tryParse(
                                widget.productData['price']?.toString() ??
                                    '0') ??
                                0.0;
                            final double discPercent = double.tryParse(
                                (widget.productData['discount'] ??
                                    widget.productData[
                                    'discountPercentage'])
                                    ?.toString() ??
                                    '0') ??
                                0.0;
                            final double discountedPrice = discPercent > 0
                                ? origPrice - (origPrice * (discPercent / 100))
                                : origPrice;

                            _handleAddToCart(
                                widget.productData, discountedPrice);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(0xFF6C5CE7)
                                  : const Color(0xFF6C5CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : const Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(
      Map<String, dynamic> productData, double finalPrice) async {
    final user = _auth.currentUser;

    try {
      if (!mounted) return;

      await showOrderDetailsBottomSheet(
        context: context,
        uid: user?.uid,
        productId: widget.productId,
        productData: productData,
        finalPrice: finalPrice,
      );
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"An error occurred during processing:".tr}$e")),
        );
      }
    }
  }