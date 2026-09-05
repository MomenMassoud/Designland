import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/product_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductListWidget extends StatefulWidget {
  final String categoryDoc;

  const ProductListWidget({super.key, required this.categoryDoc});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  String lang = Get.locale?.languageCode ?? "ar";
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  String? _selectedSubcategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1100
        ? 5
        : screenWidth >= 800
        ? 4
        : screenWidth >= 600
        ? 3
        : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF2D3436), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _categoriesRef.doc(widget.categoryDoc).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return  Text(
                "Category Products".tr,
                style: TextStyle(color: Color(0xFF2D3436), fontSize: 18),
              );
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return Text(
             lang=="en"? data['nameEn'] ?? data['name'] ?? "Category Products".tr:data['nameAr'],
              style: const TextStyle(
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ==================== SEARCH & SUBCATEGORY FILTER BAR ====================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Input
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration:  InputDecoration(
                      hintText: "Search in this category...".tr,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon:
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Subcategories Horizontal Selector
                StreamBuilder<QuerySnapshot>(
                  stream: _subcategoriesRef
                      .where('categoryId', isEqualTo: widget.categoryDoc)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final subdocs = snapshot.data!.docs;

                    if (subdocs.isEmpty) return const SizedBox();

                    return SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subdocs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedSubcategoryId == null;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label:  Text("All".tr),
                                selected: isSelected,
                                selectedColor: const Color(0xFF6C5CE7),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2D3436),
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedSubcategoryId = null;
                                  });
                                },
                              ),
                            );
                          }

                          final subdoc = subdocs[index - 1];
                          final subData =
                          subdoc.data() as Map<String, dynamic>;
                          final isSelected =
                              _selectedSubcategoryId == subdoc.id;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(lang=="en"?subData['nameEn'] ?? 'Subcategory'.tr:subData['nameAr']),
                              selected: isSelected,
                              selectedColor: const Color(0xFF6C5CE7),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2D3436),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedSubcategoryId = subdoc.id;
                                });
                              },
                            ),
                          );
                        },
                      ),
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
                  .where('subcategoryId', isEqualTo: _selectedSubcategoryId)
                  .snapshots()
                  : _productsRef
                  .where('categoryId', isEqualTo: widget.categoryDoc)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  return  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 50, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "No products found in this category.".tr,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.62, // تعديل الارتفاع لاستيعاب عرض السعرين
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productData =
                    products[index].data() as Map<String, dynamic>;
                    final images = productData['images'] as List<dynamic>?;
                    final imageUrl =
                    images != null && images.isNotEmpty ? images[0] : '';

                    // 1. حسابات السعر والخصم
                    final num originalPrice = productData['price'] ?? 0;
                    final num discountPercentage = productData['discountPercentage'] ?? 0;
                    final bool hasDiscount = discountPercentage > 0;
                    final num finalPrice = hasDiscount
                        ? (originalPrice * (1 - (discountPercentage / 100))).round()
                        : originalPrice;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProductView(
                                ProductDoc: products[index].id,
                              )),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Container + Discount Badge
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                        : Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF7675),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "-$discountPercentage%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Product Info
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productData['title'] ?? 'Product Title'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // عرض السعر بعد وقبل الخصم
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$finalPrice${"EGP".tr}",
                                              style: const TextStyle(
                                                color: Color(0xFF6C5CE7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (hasDiscount)
                                              Text(
                                                "$originalPrice${"EGP".tr}",
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                  decoration:
                                                  TextDecoration.lineThrough,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          // TODO: Add product to cart action
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C5CE7)
                                                .withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 16,
                                            color: Color(0xFF6C5CE7),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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