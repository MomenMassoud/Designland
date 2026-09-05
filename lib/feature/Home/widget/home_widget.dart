import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/products_list_view.dart';
import 'package:desginland/feature/Product/widget/product_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';

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
    // TODO: implement initState
    super.initState();
    lang=Get.locale?.languageCode ?? "ar";
  }
  // تم تغيير الاسم إلى _searchNotifier لمنع أي تضارب مع Getter قديم بنفس الاسم
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  // Filter States
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  RangeValues _priceRange = const RangeValues(0, 50000);

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user')
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

                    return _CategorySectionWidget(
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

// ==================== FAST CATEGORY & PRODUCTS SECTION ====================
class _CategorySectionWidget extends StatelessWidget {
  final CollectionReference productsRef;
  final String categoryId;
  final String categoryTitle;
  final String? selectedSubcategoryId;
  final RangeValues priceRange;
  final ValueNotifier<String> searchQueryNotifier;

  const _CategorySectionWidget({
    super.key,
    required this.productsRef,
    required this.categoryId,
    required this.categoryTitle,
    required this.selectedSubcategoryId,
    required this.priceRange,
    required this.searchQueryNotifier,
  });

  @override
  Widget build(BuildContext context) {
    Query query = productsRef.where('categoryId', isEqualTo: categoryId);

    if (selectedSubcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: selectedSubcategoryId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        return ValueListenableBuilder<String>(
          valueListenable: searchQueryNotifier,
          builder: (context, searchQuery, child) {
            final products = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final double price = (data['price'] ?? 0.0).toDouble();
              final String title = (data['title'] ?? '').toString().toLowerCase();
              final String desc = (data['description'] ?? '').toString().toLowerCase();

              final bool matchesPrice = price >= priceRange.start && price <= priceRange.end;
              final bool matchesSearch = searchQuery.isEmpty ||
                  title.contains(searchQuery) ||
                  desc.contains(searchQuery);

              return matchesPrice && matchesSearch;
            }).toList();

            if (products.isEmpty) return const SizedBox.shrink();

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
                            MaterialPageRoute(
                              builder: (context) => ProductsListView(CategoryDoc: categoryId),
                            ),
                          );
                        },
                        child:  Row(
                          children: [
                            Text("See All".tr, style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
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

                      return _AnimatedProductCard(
                        productData: productData,
                        imageUrl: imageUrl,
                        productId: products[index].id,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          },
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

class _DiscountProductsCarouselState extends State<DiscountProductsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _activePage = 0;
  Timer? _autoSlideTimer;

  void _startAutoSlide(int itemCount) {
    _autoSlideTimer?.cancel();
    if (itemCount <= 1) return;
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

        final now = DateTime.now();

        final validDiscountDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final Timestamp? discountUntil = data['discountUntil'] as Timestamp?;

          if (discountUntil != null) {
            final isExpired = discountUntil.toDate().isBefore(now);
            if (isExpired) {
              doc.reference.update({
                'discountPercentage': 0,
                'discountUntil': FieldValue.delete(),
              });
              return false;
            }
          }
          return true;
        }).toList();

        if (validDiscountDocs.isEmpty) {
          return const SizedBox.shrink();
        }

        _startAutoSlide(validDiscountDocs.length);

        return Column(
          children: [
            SizedBox(
              height: 175,
              child: PageView.builder(
                controller: _pageController,
                itemCount: validDiscountDocs.length,
                onPageChanged: (int index) {
                  setState(() => _activePage = index);
                },
                itemBuilder: (context, index) {
                  final doc = validDiscountDocs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final String title = data['title'] ?? 'Special Offer'.tr;
                  final num originalPrice = data['price'] ?? 0;
                  final num discountPercentage = data['discountPercentage'] ?? 0;
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
                                        "${"discount".tr} $discountPercentage%",
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
                                        Text(
                                          "$finalPrice ${"EGP".tr}",
                                          style: const TextStyle(
                                            color: Color(0xFF55E6C1),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "$originalPrice ${"EGP".tr}",
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
                                DynamicCountdownWidget(
                                  untilTimestamp: discountUntilTimestamp,
                                  onTimerExpired: () {
                                    doc.reference.update({
                                      'discountPercentage': 0,
                                      'discountUntil': FieldValue.delete(),
                                    });
                                  },
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                validDiscountDocs.length,
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
  final VoidCallback? onTimerExpired;

  const DynamicCountdownWidget({
    super.key,
    required this.untilTimestamp,
    this.onTimerExpired,
  });

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

    if (difference.isNegative || difference == Duration.zero) {
      _timer?.cancel();
      if (mounted) {
        setState(() => _timeLeft = Duration.zero);
      }
      widget.onTimerExpired?.call();
    } else {
      if (mounted) {
        setState(() => _timeLeft = difference);
      }
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
        child:  Text(
          "The offer has ended.".tr,
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
          _buildTimeBox(_twoDigits(days), "day".tr),
          const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
        _buildTimeBox(_twoDigits(hours), "hour".tr),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(minutes), "minute".tr),
        const Text(" : ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        _buildTimeBox(_twoDigits(seconds), "second".tr),
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

// ==================== PRODUCT CARD ====================
class _AnimatedProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String imageUrl;
  final String productId;

  const _AnimatedProductCard({
    super.key,
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
    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;

    final Timestamp? discountUntil = widget.productData['discountUntil'] as Timestamp?;
    final bool isExpired = discountUntil != null && discountUntil.toDate().isBefore(DateTime.now());
    final bool hasDiscount = discountPercentage > 0 && !isExpired;

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$finalPrice${"EGP".tr}",
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                "$originalPrice${"EGP".tr}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
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