import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/products_list_view.dart';
import 'package:desginland/feature/Product/widget/product_widget.dart';
import 'package:flutter/material.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');

  // Filter States
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _priceRange = const RangeValues(0, 1000);
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Products",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(ctx);
                          },
                          child: const Text("Reset All"),
                        )
                      ],
                    ),
                    const Divider(),

                    // Category Selector
                    const Text("Category",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _categoriesRef.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          hint: const Text("All Categories"),
                          items: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['nameEn'] ?? 'Category'),
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

                    // Subcategory Selector
                    if (_selectedCategoryId != null) ...[
                      const Text("Subcategory",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                            hint: const Text("All Subcategories"),
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(data['nameEn'] ?? 'Subcategory'),
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

                    // Price Range Filter
                    const Text("Price Range (\$)"),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      labels: RangeLabels(
                        "\$${_priceRange.start.round()}",
                        "\$${_priceRange.end.round()}",
                      ),
                      onChanged: (values) {
                        setModalState(() => _priceRange = values);
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Apply Filters",
                            style: TextStyle(color: Colors.white)),
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
        slivers: [
          // Search & Filter Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "Search by title or description...",
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _openFilterBottomSheet,
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Sections Loop
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
                    padding: EdgeInsets.all(32),
                    child: Center(

                        child: CircularProgressIndicator()),
                  ),
                );
              }

              final categoryDocs = catSnapshot.data?.docs ?? [];

              if (categoryDocs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No categories found."),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final categoryDoc = categoryDocs[index];
                    final categoryData =
                    categoryDoc.data() as Map<String, dynamic>;
                    final categoryTitle =
                        categoryData['nameEn'] ?? 'Category';

                    return _buildCategorySection(
                      categoryId: categoryDoc.id,
                      categoryTitle: categoryTitle,
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

  // Section Builder per Category
  Widget _buildCategorySection({
    required String categoryId,
    required String categoryTitle,
  }) {
    Query query = _productsRef.where('categoryId', isEqualTo: categoryId);

    if (_selectedSubcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: _selectedSubcategoryId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        // Client-side filtering for search & price range
        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final double price = (data['price'] ?? 0.0).toDouble();
          final String title = (data['title'] ?? '').toString().toLowerCase();
          final String desc =
          (data['description'] ?? '').toString().toLowerCase();

          final bool matchesPrice =
              price >= _priceRange.start && price <= _priceRange.end;
          final bool matchesSearch = _searchQuery.isEmpty ||
              title.contains(_searchQuery) ||
              desc.contains(_searchQuery);

          return matchesPrice && matchesSearch;
        }).toList();

        if (products.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  ProductsListView(CategoryDoc: categoryId)),
                      );
                    },
                    child:  Text("See All"),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData =
                  products[index].data() as Map<String, dynamic>;
                  final images = productData['images'] as List<dynamic>?;
                  final imageUrl =
                  images != null && images.isNotEmpty ? images[0] : '';
                  return InkWell(
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  ProductWidget(productDoc: products[index].id,)),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                              imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 130,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image,
                                  color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productData['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "\$${productData['price'] ?? 0}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}