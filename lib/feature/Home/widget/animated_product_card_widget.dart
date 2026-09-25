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
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
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
                        ? CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 130,
                        color: primaryColor.withOpacity(0.05),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 130,
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    )
                        : Container(
                      height: 130,
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
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
                          color: const Color(0xFFFF4757),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4757).withOpacity(0.4),
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
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.5)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          size: 16,
                          color: _isFavorite ? Colors.red : primaryColor,
                        ),
                        onPressed: _toggleFavorite,
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
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
                              "$finalPrice ${"EGP".tr}",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                "$originalPrice ${"EGP".tr}",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: primaryColor,
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