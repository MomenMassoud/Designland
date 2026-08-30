import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/products_list_view.dart';
import 'package:desginland/feature/Product/widget/product_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../Core/server/analytics_service.dart';

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
  Timer? _searchDebounce;
  // Filter States
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  RangeValues _priceRange = const RangeValues(0, 50000);
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user') // 🎯 تعديل اسم الكولكشن إلى user
          .doc(userId)
          .collection('search_history')
          .add({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel(); // إلغاء الـ Timer عند إغلاق الشاشة
    super.dispose();
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
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });

                          // إلغاء أي تايمر سابق أثناء استمرار المستخدم في الكتابة
                          if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

                          // حفظ البحث بعد توقف المستخدم عن الكتابة لمدة 800 ميلي ثانية
                          if (val.trim().length >= 2) {
                            _searchDebounce = Timer(const Duration(milliseconds: 800), () {
                              _saveSearchHistory(val);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: "Search custom gifts, items...",
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
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

          // 2. بانر العروض والتخفيضات التفاعلي مع العداد التنازلي
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryTitle,
                    style: const TextStyle(
                      fontSize: 18,
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
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final productData = products[index].data() as Map<String, dynamic>;
                  final images = productData['images'] as List<dynamic>?;
                  final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

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

// ==================== DISCOUNT CAROUSEL BANNER ====================
class DiscountProductsCarousel extends StatefulWidget {
  const DiscountProductsCarousel({super.key});

  @override
  State<DiscountProductsCarousel> createState() => _DiscountProductsCarouselState();
}

class  _DiscountProductsCarouselState extends State<DiscountProductsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _activePage = 0;
  Timer? _autoSlideTimer;

  void _startAutoSlide(int itemCount) {
    if (_autoSlideTimer != null || itemCount <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _activePage = (_activePage + 1) % itemCount;
        _pageController.animateToPage(
          _activePage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.decelerate,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('discountPercentage', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final discountDocs = snapshot.data!.docs;
        _startAutoSlide(discountDocs.length);

        return Column(
          children: [
            SizedBox(
              height: 175,
              child: PageView.builder(
                controller: _pageController,
                itemCount: discountDocs.length,
                onPageChanged: (int index) {
                  setState(() => _activePage = index);
                },
                itemBuilder: (context, index) {
                  final doc = discountDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final String title = data['title'] ?? 'عرض خاص';
                  final num originalPrice = data['price'] ?? 0; // السعر الأصلي (مثلاً 300)
                  final num discountPercentage = data['discountPercentage'] ?? 0; // النسبة (مثلاً 10)

                  // 🎯 الحساب الصحيح: السعر بعد الخصم (300 * 0.9 = 270)
                  final num finalPrice = (originalPrice * (1 - (discountPercentage / 100))).round();

                  final List images = data['images'] ?? [];
                  final String imageUrl = images.isNotEmpty ? images[0] : '';

                  final Timestamp? discountUntilTimestamp = data['discountUntil'] as Timestamp?;

                  return GestureDetector(
                    onTap: () {
                      AnalyticsService.logProductOpen(
                        productId: doc.id,
                        productTitle: doc.get('title'),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductWidget(productDoc: doc.id),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D3436), Color(0xFF111111)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 200,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                              child: Stack(
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF2D3436), Colors.transparent],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7675),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "خصم $discountPercentage%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 170,
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // السعر النهائي بعد الخصم (270 ج.م)
                                        Text(
                                          "$finalPrice ج.م",
                                          style: const TextStyle(
                                            color: Color(0xFF55E6C1),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // السعر الأصلي المشطوب (300 ج.م)
                                        Text(
                                          "$originalPrice ج.م",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                DynamicCountdownWidget(untilTimestamp: discountUntilTimestamp),
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                discountDocs.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  width: _activePage == index ? 18 : 5,
                  decoration: BoxDecoration(
                    color: _activePage == index ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== DYNAMIC COUNTDOWN WIDGET ====================
class DynamicCountdownWidget extends StatefulWidget {
  final Timestamp? untilTimestamp;

  const DynamicCountdownWidget({super.key, required this.untilTimestamp});

  @override
  State<DynamicCountdownWidget> createState() => _DynamicCountdownWidgetState();
}

class _DynamicCountdownWidgetState extends State<DynamicCountdownWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
  }

  void _calculateTimeLeft() {
    if (widget.untilTimestamp == null) return;
    final targetDate = widget.untilTimestamp!.toDate();
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (mounted) {
      setState(() {
        _timeLeft = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          "انتهى العرض",
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Row(
      children: [
        if (days > 0) ...[
          _buildTimeBox(_twoDigits(days), "يوم"),
          const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
        _buildTimeBox(_twoDigits(hours), "ساعة"),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(minutes), "دقيقة"),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(seconds), "ثانية"),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STAGGERED ANIMATIONS & PRODUCT CARD ====================
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

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
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
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
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
    // 1. استخراج السعر الأصلي من داتا المنتج
    final num originalPrice = widget.productData['price'] ?? 0; // السعر الأصلي الأصلي (مثلاً 300)
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;
    final bool hasDiscount = discountPercentage > 0;

    // 2. 🎯 الحساب الصحيح للسعر النهائي بعد الخصم (مثلاً 300 * (1 - 0.10) = 270)
    final num finalPrice = hasDiscount
        ? (originalPrice * (1 - (discountPercentage / 100))).round()
        : originalPrice;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: () {
        AnalyticsService.logProductOpen(
          productId: widget.productId,
          productTitle: widget.productData['title'],
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductWidget(productDoc: widget.productId),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isHovered ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== صورة المنتج + شارة الخصم والمفضلة =====
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                      widget.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 130,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),

                  // 🏷️ شارة الخصم (Discount Badge)
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7675),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7675).withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "-$discountPercentage%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // ❤️ زر المفضلة
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                ],
              ),

              // ===== تفاصيل المنتج والأسعار =====
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
                        fontSize: 13,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // عرض السعر النهائي والسعر القديم المشطوب
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // السعر بعد الخصم (مثلاً 270 ج.م)
                            Text(
                              "$finalPrice ج.م",
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            // السعر الأصلي قبل الخصم (مثلاً 300 ج.م)
                            if (hasDiscount)
                              Text(
                                "$originalPrice ج.م",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),

                        // زر الإضافة للسلة
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
}