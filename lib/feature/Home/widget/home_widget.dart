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
                        const Text(
                          "Filter Products",
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
                          child: const Text(
                            "Reset All",
                            style: TextStyle(color: Color(0xFF6C5CE7)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Category Selector
                    const Text("Category",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _categoriesRef.snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final docs = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          hint: const Text("All Categories"),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "\$${_priceRange.start.round()} - \$${_priceRange.end.round()}",
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      activeColor: const Color(0xFF6C5CE7),
                      inactiveColor: const Color(0xFF6C5CE7).withOpacity(0.15),
                      divisions: 20,
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
                        child: const Text("Apply Filters",
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
          // Header مع Search & Filter
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C5CE7).withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
                          hintText: "Search custom gifts, items...",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openFilterBottomSheet,
                      child: Container(
                        height: 50,
                        width: 50,
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

          // Stream categories مع Staggered Entrance
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
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text("No categories found.", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final categoryDoc = categoryDocs[index];
                    final categoryData = categoryDoc.data() as Map<String, dynamic>;
                    final categoryTitle = categoryData['nameEn'] ?? 'Category';

                    // تحريك ظهور القسم بحسب الـ index الخاص به
                    return _StaggeredCategoryWrapper(
                      index: index,
                      child: _buildCategorySection(
                        categoryId: categoryDoc.id,
                        categoryTitle: categoryTitle,
                      ),
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

        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final double price = (data['price'] ?? 0.0).toDouble();
          final String title = (data['title'] ?? '').toString().toLowerCase();
          final String desc = (data['description'] ?? '').toString().toLowerCase();

          final bool matchesPrice = price >= _priceRange.start && price <= _priceRange.end;
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductsListView(CategoryDoc: categoryId)),
                      );
                    },
                    child: const Row(
                      children: [
                        Text("See All", style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6C5CE7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData = products[index].data() as Map<String, dynamic>;
                  final images = productData['images'] as List<dynamic>?;
                  final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

                  // ظهور منتجات كل قسم بالترتيب أفوقياً (Staggered horizontal animation)
                  return _StaggeredProductWrapper(
                    index: index,
                    child: _AnimatedProductCard(
                      productData: productData,
                      imageUrl: imageUrl,
                      productId: products[index].id,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

// 1. أنيميشن ظهور القسم بالترتيب (Category Vertical Entrance)
class _StaggeredCategoryWrapper extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredCategoryWrapper({required this.index, required this.child});

  @override
  State<_StaggeredCategoryWrapper> createState() => _StaggeredCategoryWrapperState();
}

class _StaggeredCategoryWrapperState extends State<_StaggeredCategoryWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // تأخير الظهور بناءً على index القسم
    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// 2. أنيميشن ظهور الكروت بالترتيب داخل الأفقي (Product Horizontal Entrance)
class _StaggeredProductWrapper extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredProductWrapper({required this.index, required this.child});

  @override
  State<_StaggeredProductWrapper> createState() => _StaggeredProductWrapperState();
}

class _StaggeredProductWrapperState extends State<_StaggeredProductWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // تأخير ظهور الكروت أفُقياً بالترتيب
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// 3. كارت المنتج التفاعلي عند اللمس (Hover Scale Effect)
class _AnimatedProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String imageUrl;
  final String productId;

  const _AnimatedProductCard({
    required this.productData,
    required this.imageUrl,
    required this.productId,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductWidget(productDoc: widget.productId)),
        );
      },
      child: AnimatedScale(
        scale: _isHovered ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 165,
          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                      widget.imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 140,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        );
                      },
                    )
                        : Container(
                      height: 140,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF6C5CE7)),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['title'] ?? '',
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "\$${widget.productData['price'] ?? 0}",
                          style: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xFF6C5CE7),
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
      ),
    );
  }
}