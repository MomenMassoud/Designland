import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Product/widget/product_list_widget.dart';

class BannersCarousel extends StatefulWidget {
  final CollectionReference bannersRef;

  const BannersCarousel({super.key, required this.bannersRef});

  @override
  State<BannersCarousel> createState() => _BannersCarouselState();
}

class _BannersCarouselState extends State<BannersCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _setupAutoScroll(int itemCount) {
    if (_timer != null || itemCount <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _nextPage(int totalCount) {
    if (_pageController.hasClients) {
      final nextPage = (_currentPage + 1) % totalCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage(int totalCount) {
    if (_pageController.hasClients) {
      final prevPage = (_currentPage - 1 + totalCount) % totalCount;
      _pageController.animateToPage(
        prevPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.bannersRef.orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final bannerDocs = snapshot.data!.docs;
        final totalBanners = bannerDocs.length;
        _setupAutoScroll(totalBanners);

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1300),
            height: isDesktop ? 280 : 180,
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. PageView الخاص بالبانرات
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: totalBanners,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = bannerDocs[index].data() as Map<String, dynamic>;
                    final String bannerUrl = data['image'] ?? data['imageUrl'] ?? '';
                    final bool onClickable = data['onclick'] ?? false;
                    final String? categoryId = data['category'];

                    if (bannerUrl.isEmpty) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () {
                        if (onClickable && categoryId != null && categoryId.isNotEmpty) {
                          Get.to(() => ProductListWidget(categoryDoc: categoryId));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.4)
                                  : Colors.black.withOpacity(0.08),
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
                            placeholder: (_, __) => Container(
                              color: primaryColor.withOpacity(0.05),
                            ),
                            errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 2. أسهم التنقل (ظهرت إذا كان هناك أكثر من بانر واحد)
                if (totalBanners > 1) ...[
                  // زر السابق (اليسار)
                  Positioned(
                    left: 32,
                    child: _buildArrowButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onPressed: () => _previousPage(totalBanners),
                      isDarkMode: isDarkMode,
                    ),
                  ),

                  // زر التالي (اليمين)
                  Positioned(
                    right: 32,
                    child: _buildArrowButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onPressed: () => _nextPage(totalBanners),
                      isDarkMode: isDarkMode,
                    ),
                  ),

                  // 3. مؤشرات الأرقام/النقاط في الأسفل (Indicators)
                  Positioned(
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalBanners, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 8,
                          width: isSelected ? 22 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ودجت زر السهم الأنيق مع تأثير Hover واستجابة سريعة
  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.75),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}