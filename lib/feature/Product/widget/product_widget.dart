import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/server/email_server.dart';
import 'package:desginland/Core/widgets/full_screen_image_widget.dart';
import 'package:desginland/feature/Login/view/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../../Core/services/guest_cart_service.dart';
import '../../Basket/view/basket_view.dart';
import 'order_details_bottom_sheet.dart';

class ProductWidget extends StatefulWidget {
  final String productDoc;

  const ProductWidget({super.key, required this.productDoc});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;
  bool _hasLoggedAnalytics = false;

  // 👈 Stream مخصص للسلة حسب حالة المستخدم
  Stream<int> _getCartCountStream() {
    final user = _auth.currentUser;
    if (user != null) {
      // للمستخدم المسجل: Stream من Firestore
      return _db
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } else {
      // للزائر: Stream الخاص بـ GuestCartService
      return GuestCartService().cartCountStream;
    }
  }

  Future<void> _handleAddToCart(
      Map<String, dynamic> productData, double finalPrice) async {
    final user = _auth.currentUser;

    setState(() => _isAddingToCart = true);

    try {
      if (!mounted) return;
      setState(() => _isAddingToCart = false);

      await showOrderDetailsBottomSheet(
        context: context,
        uid: user?.uid,
        productId: widget.productDoc,
        productData: productData,
        finalPrice: finalPrice,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${"An error occurred during processing:".tr}$e")),
        );
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login required".tr),
        content: Text("Please log in first to add products to the cart.".tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancellation".tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              Navigator.pushNamed(context, LoginView.id);
            },
            child: Text("Log in".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details".tr,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 👈 استخدام StreamBuilder لاستهلاك الـ Stream الجديد مباشرة
          StreamBuilder<int>(
            stream: _getCartCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                    ),
                    onPressed: () => Navigator.pushNamed(context, BasketView.id),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _BadgeCounter(count: count),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;

          return StreamBuilder<DocumentSnapshot>(
            stream: _productsRef.doc(widget.productDoc).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("The product does not exist.".tr));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List<String> images = List<String>.from(data['images'] ?? []);

              final double originalPrice = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;

              final double discountPercentage = double.tryParse(
                  (data['discount'] ?? data['discountPercentage'])?.toString() ?? '0'
              ) ?? 0.0;

              final double discountedPrice = discountPercentage > 0
                  ? originalPrice - (originalPrice * (discountPercentage / 100))
                  : originalPrice;

              final double avgRate = double.tryParse(data['avgRate']?.toString() ?? '0') ?? 0.0;
              final String title = data['title'] ?? '';
              final String description = data['description'] ?? '';

              if (!_hasLoggedAnalytics) {
                _hasLoggedAnalytics = true;
                AnalyticsService.logProductOpen(
                  productId: widget.productDoc,
                  productTitle: title,
                );
              }

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? constraints.maxWidth * 0.08 : 16,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? theme.cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: isDesktop
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildImageGallery(images, isDarkMode),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 6,
                            child: _buildMainProductHeader(
                                title,
                                avgRate,
                                originalPrice,
                                discountedPrice,
                                discountPercentage,
                                description,
                                data,
                                isDarkMode),
                          ),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageGallery(images, isDarkMode),
                          const SizedBox(height: 20),
                          _buildMainProductHeader(
                              title,
                              avgRate,
                              originalPrice,
                              discountedPrice,
                              discountPercentage,
                              description,
                              data,
                              isDarkMode),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    isDesktop
                        ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildDetailsCard(description, data, isDarkMode, theme),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 7,
                          child: _buildReviewsCard(avgRate, isDarkMode, theme),
                        ),
                      ],
                    )
                        : Column(
                      children: [
                        _buildDetailsCard(description, data, isDarkMode, theme),
                        const SizedBox(height: 20),
                        _buildReviewsCard(avgRate, isDarkMode, theme),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, bool isDarkMode) {
    final String currentImage = images.isNotEmpty ? images[_selectedImageIndex] : '';

    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.to(FullScreenImageViewer(images: images, initialIndex: _selectedImageIndex));
          },
          child: Container(
            height: 340,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              image: currentImage.isNotEmpty
                  ? DecorationImage(
                image: CachedNetworkImageProvider(currentImage),
                fit: BoxFit.contain,
              )
                  : null,
            ),
            child: currentImage.isEmpty
                ? Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (images.length > 1)
          SizedBox(
            height: 65,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMainProductHeader(
      String title,
      double avgRate,
      double originalPrice,
      double discountedPrice,
      double discountPercentage,
      String description,
      Map<String, dynamic> data,
      bool isDarkMode) {
    final bool hasDiscount = discountPercentage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    avgRate.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.amber.shade300 : const Color(0xFFB45309),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "${discountedPrice.toStringAsFixed(2)}${"EGP".tr}",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: hasDiscount ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 12),
              Text(
                "${originalPrice.toStringAsFixed(2)}${"EGP".tr}",
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "-${discountPercentage.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
            height: 1.5,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isAddingToCart ? null : () => _handleAddToCart(data, discountedPrice),
          icon: _isAddingToCart
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Icon(Icons.shopping_bag_outlined, size: 20),
          label: Text(
            "Add to cart".tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(String description, Map<String, dynamic> data, bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Detailed product information".tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Divider(height: 24, color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
          Text(
            description.isNotEmpty
                ? description
                : "There is no additional description for the product.".tr,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade300 : const Color(0xFF475569),
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsCard(double avgRate, bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Ratings and Reviews".tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          AddReviewSection(
            key: const PageStorageKey('add_review_section_key'),
            productDoc: widget.productDoc,
            productsRef: _productsRef,
            showLoginDialog: _showLoginDialog,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _productsRef
                .doc(widget.productDoc)
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!.docs;

              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "There are currently no ratings. Be the first to rate this product!".tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 20, color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final rev = reviews[index].data() as Map<String, dynamic>;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                        child: Text(
                          (rev['userName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rev['userName'] ?? 'client'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: starIdx < (rev['rating'] ?? 0)
                                          ? Colors.amber
                                          : isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                    );
                                  }),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rev['comment'] ?? '',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddReviewSection extends StatefulWidget {
  final String productDoc;
  final CollectionReference productsRef;
  final VoidCallback showLoginDialog;

  const AddReviewSection({
    super.key,
    required this.productDoc,
    required this.productsRef,
    required this.showLoginDialog,
  });

  @override
  State<AddReviewSection> createState() => _AddReviewSectionState();
}

class _AddReviewSectionState extends State<AddReviewSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  double _userRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add your rating".tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              DropdownButton<double>(
                value: _userRating,
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                underline: const SizedBox(),
                items: [1.0, 2.0, 3.0, 4.0, 5.0].map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(
                      "$r ★",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _userRating = val);
                },
              ),
            ],
          ),
          TapRegion(
            onTapOutside: (_) {},
            child: TextField(
              key: const PageStorageKey('review_input_field'),
              controller: _commentController,
              focusNode: _focusNode,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Write your opinion about the product here...".tr,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                if (currentUser == null) {
                  widget.showLoginDialog();
                  return;
                }

                if (_commentController.text.trim().isEmpty) return;
                setState(() => _isSubmitting = true);

                final ref = widget.productsRef.doc(widget.productDoc).collection('reviews');
                await ref.add({
                  'userName': currentUser.displayName ?? 'client'.tr,
                  'userUid': currentUser.uid,
                  'rating': _userRating,
                  'comment': _commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                final docSnapshot = await widget.productsRef.doc(widget.productDoc).get();
                final data = docSnapshot.data() as Map<String, dynamic>?;
                final String productName = data?['title'] ?? '';

                await EmailServer().sendCommentNotificationToAdmins(
                  customerName: currentUser.displayName ?? 'client',
                  productName: productName,
                  commentText: _commentController.text.trim(),
                );

                _commentController.clear();
                if (mounted) {
                  setState(() => _isSubmitting = false);
                  _focusNode.unfocus();
                }
              },
              child: _isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("Publish the review".tr),
            ),
          )
        ],
      ),
    );
  }
}

class _BadgeCounter extends StatelessWidget {
  final int count;
  const _BadgeCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7675),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$count",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}