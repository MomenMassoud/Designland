import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/product_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Product/widget/product_list_widget.dart';
import 'category_section_widget.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  late final CollectionReference _categoriesRef;
  late final CollectionReference _productsRef;
  late final CollectionReference _bannersRef;

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  RangeValues _priceRange = const RangeValues(0, 10000);

  final PageController _bannerPageController = PageController();
  Timer? _bannerTimer;
  int _currentBannerPage = 0;
  int _lastBannerCount = 0;
  Timer? _searchDebounceTimer;

  void _startBannerAutoScroll(int totalBanners) {
    if (_lastBannerCount == totalBanners && _bannerTimer != null && _bannerTimer!.isActive) {
      return;
    }
    _lastBannerCount = totalBanners;
    _bannerTimer?.cancel();
    if (totalBanners <= 1) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController.hasClients) {
        _currentBannerPage = (_currentBannerPage + 1) % totalBanners;
        _bannerPageController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Duration _getRemainingDiscountTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now);
  }

  Future<void> _saveSearchToFirebase(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return;

    if (_auth.currentUser == null) {
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': cleanQuery,
        'createdAt': FieldValue.serverTimestamp(),
        'userID': 'Gust',
        'gust': true
      });
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(_auth.currentUser!.uid)
          .collection('search_history')
          .add({
        'query': cleanQuery,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': cleanQuery,
        'createdAt': FieldValue.serverTimestamp(),
        'userID': _auth.currentUser!.uid,
        'gust': false
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _categoriesRef = _firestore.collection('categories');
    _productsRef = _firestore.collection('products');
    _bannersRef = _firestore.collection('banners');

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      _searchNotifier.value = query;

      if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();

      if (query.isNotEmpty && query.length >= 2) {
        _searchDebounceTimer = Timer(const Duration(seconds: 1), () {
          _saveSearchToFirebase(query);
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: isDesktop ? 450 : 250,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (value) {
                                _saveSearchToFirebase(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search custom gifts, bags, items...'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C5CE7)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _bannersRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final bannerDocs = snapshot.data!.docs;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _startBannerAutoScroll(bannerDocs.length);
                  });

                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      height: isDesktop ? 280 : 180,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      child: PageView.builder(
                        controller: _bannerPageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: bannerDocs.length,
                        onPageChanged: (index) {
                          _currentBannerPage = index;
                        },
                        itemBuilder: (context, index) {
                          final bannerData = bannerDocs[index].data() as Map<String, dynamic>;

                          final String bannerUrl = bannerData['image'] ?? bannerData['imageUrl'] ?? '';
                          final bool onClickable = bannerData['onclick'] ?? false;
                          final String? categoryId = bannerData['category'];

                          if (bannerUrl.isEmpty) return const SizedBox.shrink();

                          return GestureDetector(
                            onTap: () {
                              if (onClickable && categoryId != null && categoryId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductListWidget(
                                      categoryDoc: categoryId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CachedNetworkImage(
                                  imageUrl: bannerUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFF6C5CE7).withOpacity(0.05),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productsRef.where('discountPercentage', isGreaterThan: 0).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final discountProducts = snapshot.data!.docs;

                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Special Offers ⚡".tr,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _DiscountTimerWidget(
                                    duration: _getRemainingDiscountTime(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: discountProducts.length,
                              itemBuilder: (context, index) {
                                final productData = discountProducts[index].data() as Map<String, dynamic>;
                                final String productId = discountProducts[index].id;

                                return _FlashSaleCardWidget(
                                  productData: productData,
                                  productId: productId,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: _categoriesRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final categories = snapshot.data!.docs;

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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Find personalized items crafted just for you".tr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedCategoryId != null)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategoryId = null;
                                    });
                                  },
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
                              final categoryData = categories[index].data() as Map<String, dynamic>;
                              final String categoryId = categories[index].id;
                              final String name = Get.locale?.languageCode == "en"
                                  ? (categoryData['nameEn'] ?? '')
                                  : (categoryData['nameAr'] ?? '');
                              final String? imageUrl = categoryData['imageUrl'] ?? categoryData['image'];

                              final bool isSelected = _selectedCategoryId == categoryId;

                              return _CategoryCardWidget(
                                name: name,
                                imageUrl: imageUrl,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = isSelected ? null : categoryId;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _categoriesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                var categoryDocs = snapshot.data!.docs;

                if (_selectedCategoryId != null) {
                  categoryDocs = categoryDocs.where((doc) => doc.id == _selectedCategoryId).toList();
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final categoryDoc = categoryDocs[index];
                      final categoryData = categoryDoc.data() as Map<String, dynamic>;
                      final String categoryTitle = Get.locale?.languageCode == "en"
                          ? (categoryData['nameEn'] ?? '')
                          : (categoryData['nameAr'] ?? '');

                      return Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1300),
                          child: CategorySectionWidget(
                            productsRef: _productsRef,
                            categoryId: categoryDoc.id,
                            categoryTitle: categoryTitle,
                            selectedSubcategoryId: _selectedSubcategoryId,
                            priceRange: _priceRange,
                            searchQueryNotifier: _searchNotifier,
                          ),
                        ),
                      );
                    },
                    childCount: categoryDocs.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountTimerWidget extends StatefulWidget {
  final Duration duration;
  const _DiscountTimerWidget({required this.duration});

  @override
  State<_DiscountTimerWidget> createState() => _DiscountTimerWidgetState();
}

class _DiscountTimerWidgetState extends State<_DiscountTimerWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        if (mounted) {
          setState(() => _remaining -= const Duration(seconds: 1));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String hours = _remaining.inHours.remainder(24).toString().padLeft(2, '0');
    String minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4757).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFFF4757)),
          const SizedBox(width: 4),
          Text(
            "$hours:$minutes:$seconds",
            style: const TextStyle(
              color: Color(0xFFFF4757),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashSaleCardWidget extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const _FlashSaleCardWidget({
    required this.productData,
    required this.productId,
  });

  @override
  State<_FlashSaleCardWidget> createState() => _FlashSaleCardWidgetState();
}

class _FlashSaleCardWidgetState extends State<_FlashSaleCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.productData['images'] as List<dynamic>?;
    final String imageUrl = (images != null && images.isNotEmpty) ? images[0] : '';
    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;
    final num finalPrice = (originalPrice * (1 - (discountPercentage / 100))).round();

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductView(ProductDoc: widget.productId),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered ? const Color(0xFF6C5CE7) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF6C5CE7).withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isHovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : Container(color: Colors.grey.shade100),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757),
                          borderRadius: BorderRadius.circular(6),
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
              Padding(
                padding: const EdgeInsets.all(10.0),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "$finalPrice ${"EGP".tr}",
                          style: const TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$originalPrice",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
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

class _CategoryCardWidget extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCardWidget({
    required this.name,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryCardWidget> createState() => _CategoryCardWidgetState();
}

class _CategoryCardWidgetState extends State<_CategoryCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF6C5CE7).withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isHovered ? 15 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      child: const Icon(Icons.category, color: Color(0xFF6C5CE7)),
                    ),
                  )
                      : Container(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    child: const Icon(Icons.category, color: Color(0xFF6C5CE7)),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(isHovered ? 0.75 : 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isSelected
                              ? const Color(0xFF6C5CE7)
                              : Colors.white.withOpacity(0.25),
                        ),
                        child: Icon(
                          widget.isSelected ? Icons.check : Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}