import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../Product/widget/product_widget.dart';

class AnimatedProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String imageUrl;
  final String productId;

  const AnimatedProductCard({
    super.key,
    required this.productData,
    required this.imageUrl,
    required this.productId,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard> {
  bool _isHovered = false;
  bool _isFavorite = false;
  StreamSubscription<QuerySnapshot>? _favSubscription;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _listenToFavoriteStatus();
  }

  // الاستماع لحالة المفضلة لهذا المنتج بشكل منفصل ومُدار
  void _listenToFavoriteStatus() {
    final user = _auth.currentUser;
    if (user == null) return;

    _favSubscription = _firestore
        .collection('user')
        .doc(user.uid)
        .collection('fav')
        .where('product', isEqualTo: widget.productId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _isFavorite = snapshot.docs.isNotEmpty;
        });
      }
    }, onError: (e) => debugPrint("Error listening to favorite status: $e"));
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final favCollection = _firestore
        .collection('user')
        .doc(user.uid)
        .collection('fav');

    try {
      if (_isFavorite) {
        final querySnapshot = await favCollection
            .where('product', isEqualTo: widget.productId)
            .get();
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      } else {
        await favCollection.add({'product': widget.productId});
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    final num originalPrice = widget.productData['price'] ?? 0; //[cite: 7]
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0; //[cite: 7]
    final Timestamp? discountUntil = widget.productData['discountUntil'] as Timestamp?; //[cite: 7]
    final bool isExpired = discountUntil != null && discountUntil.toDate().isBefore(DateTime.now()); //[cite: 7]
    final bool hasDiscount = discountPercentage > 0 && !isExpired; //[cite: 7]

    final num finalPrice = hasDiscount //[cite: 7]
        ? (originalPrice * (1 - (discountPercentage / 100))).round() //[cite: 7]
        : originalPrice; //[cite: 7]

    // فحص حالة التفعيل الخاصة بالمنتج
    final bool isProductActive =
        widget.productData['IsActive'] ?? widget.productData['isActive'] ?? true;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true), //[cite: 7]
      onTapUp: (_) => setState(() => _isHovered = false), //[cite: 7]
      onTapCancel: () => setState(() => _isHovered = false), //[cite: 7]
      onTap: () {
        AnalyticsService.logProductOpen( //[cite: 7]
          productId: widget.productId, //[cite: 7]
          productTitle: widget.productData['title'], //[cite: 7]
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductWidget(productDoc: widget.productId),
            settings: RouteSettings(name: '/product/${widget.productId}'), // 👈 يغير الـ URL في الـ Web
          ),
        );
      },
      child: AnimatedScale(
        scale: _isHovered ? 0.95 : 1.0, //[cite: 7]
        duration: const Duration(milliseconds: 160), //[cite: 7]
        curve: Curves.easeOutCubic, //[cite: 7]
        child: Container(
          width: 160, //[cite: 7]
          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4), //[cite: 7]
          decoration: BoxDecoration(
            color: theme.cardColor, //[cite: 7]
            borderRadius: BorderRadius.circular(20), //[cite: 7]
            border: Border.all(
              color: isDarkMode //[cite: 7]
                  ? Colors.white.withOpacity(0.1) //[cite: 7]
                  : Colors.grey.shade200, //[cite: 7]
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode //[cite: 7]
                    ? Colors.black.withOpacity(0.3) //[cite: 7]
                    : Colors.black.withOpacity(_isHovered ? 0.08 : 0.04), //[cite: 7]
                blurRadius: _isHovered ? 14 : 8, //[cite: 7]
                offset: const Offset(0, 5), //[cite: 7]
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, //[cite: 7]
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), //[cite: 7]
                    child: widget.imageUrl.isNotEmpty //[cite: 7]
                        ? CachedNetworkImage( //[cite: 7]
                      imageUrl: widget.imageUrl, //[cite: 7]
                      height: 130, //[cite: 7]
                      width: double.infinity, //[cite: 7]
                      fit: BoxFit.cover, //[cite: 7]
                      placeholder: (context, url) => Container( //[cite: 7]
                        height: 130, //[cite: 7]
                        color: primaryColor.withOpacity(0.05), //[cite: 7]
                      ),
                      errorWidget: (context, url, error) => Container( //[cite: 7]
                        height: 130, //[cite: 7]
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100, //[cite: 7]
                        child: const Icon(Icons.broken_image_outlined), //[cite: 7]
                      ),
                    )
                        : Container( //[cite: 7]
                      height: 130, //[cite: 7]
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100, //[cite: 7]
                      child: const Icon(Icons.image, color: Colors.grey), //[cite: 7]
                    ),
                  ),

                  // شارة حالة التفعيل (Active / Inactive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isProductActive
                            ? const Color(0xFF2ED573).withOpacity(0.9)
                            : Colors.red.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProductActive
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isProductActive ? "In Stock".tr : "Out of stock".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // شارة الخصم (تظهر بأسفل شارة التفعيل إذا كان الخصم متوفراً)
                  if (hasDiscount) //[cite: 7]
                    Positioned(
                      top: 32,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), //[cite: 7]
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757), //[cite: 7]
                          borderRadius: BorderRadius.circular(8), //[cite: 7]
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4757).withOpacity(0.4), //[cite: 7]
                              blurRadius: 4, //[cite: 7]
                              offset: const Offset(0, 2), //[cite: 7]
                            ),
                          ],
                        ),
                        child: Text(
                          "-$discountPercentage%", //[cite: 7]
                          style: const TextStyle(
                            color: Colors.white, //[cite: 7]
                            fontSize: 10, //[cite: 7]
                            fontWeight: FontWeight.w900, //[cite: 7]
                          ),
                        ),
                      ),
                    ),

                  // زر المفضلة
                  Positioned(
                    top: 8, //[cite: 7]
                    right: 8, //[cite: 7]
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode //[cite: 7]
                            ? Colors.black.withOpacity(0.5) //[cite: 7]
                            : Colors.white.withOpacity(0.9), //[cite: 7]
                        shape: BoxShape.circle, //[cite: 7]
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(), //[cite: 7]
                        padding: const EdgeInsets.all(6), //[cite: 7]
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border_rounded, //[cite: 7]
                          size: 16, //[cite: 7]
                          color: _isFavorite ? Colors.red : primaryColor, //[cite: 7]
                        ),
                        onPressed: _toggleFavorite, //[cite: 7]
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0), //[cite: 7]
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //[cite: 7]
                  children: [
                    Text(
                      widget.productData['title'] ?? '', //[cite: 7]
                      maxLines: 1, //[cite: 7]
                      overflow: TextOverflow.ellipsis, //[cite: 7]
                      style: TextStyle(
                        fontWeight: FontWeight.bold, //[cite: 7]
                        fontSize: 13, //[cite: 7]
                        color: textColor, //[cite: 7]
                      ),
                    ),
                    const SizedBox(height: 6), //[cite: 7]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 7]
                      crossAxisAlignment: CrossAxisAlignment.end, //[cite: 7]
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start, //[cite: 7]
                          children: [
                            Text(
                              "$finalPrice ${"EGP".tr}", //[cite: 7]
                              style: TextStyle(
                                color: isProductActive ? primaryColor : Colors.grey,
                                fontWeight: FontWeight.w800, //[cite: 7]
                                fontSize: 14, //[cite: 7]
                              ),
                            ),
                            if (hasDiscount) //[cite: 7]
                              Text(
                                "$originalPrice ${"EGP".tr}", //[cite: 7]
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400, //[cite: 7]
                                  fontSize: 11, //[cite: 7]
                                  decoration: TextDecoration.lineThrough, //[cite: 7]
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4), //[cite: 7]
                          decoration: BoxDecoration(
                            color: isProductActive
                                ? primaryColor.withOpacity(0.12)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8), //[cite: 7]
                          ),
                          child: Icon(
                            Icons.add_rounded, //[cite: 7]
                            size: 16, //[cite: 7]
                            color: isProductActive
                                ? primaryColor
                                : Colors.grey.shade600,
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