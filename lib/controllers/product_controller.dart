import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../../Core/server/email_server.dart';
import '../../../Core/services/guest_cart_service.dart';
import '../feature/Product/widget/order_details_bottom_sheet.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  final String productId;
  ProductController({required this.productId});

  final CollectionReference productsRef = FirebaseFirestore.instance.collection('products');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxInt selectedImageIndex = 0.obs;
  final RxBool isAddingToCart = false.obs;
  final RxBool isSubmittingReview = false.obs;
  final RxDouble userRating = 5.0.obs;

  bool _hasLoggedAnalytics = false;

  User? get currentUser => _auth.currentUser;

  Stream<ProductModel?> get productStream {
    return productsRef.doc(productId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final model = ProductModel.fromFirestore(snapshot.id, snapshot.data() as Map<String, dynamic>);

      if (!_hasLoggedAnalytics) {
        _hasLoggedAnalytics = true;
        AnalyticsService.logProductOpen(productId: model.id, productTitle: model.title);
      }
      return model;
    });
  }

  Stream<int> get cartCountStream {
    final user = currentUser;
    if (user != null) {
      return _db
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } else {
      return GuestCartService().cartCountStream;
    }
  }

  Stream<QuerySnapshot> get reviewsStream {
    return productsRef
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void setSelectedImage(int index) {
    selectedImageIndex.value = index;
  }

  Future<void> handleAddToCart(BuildContext context, ProductModel product) async {
    if (!product.isActive) {
      Get.snackbar("تنبيه".tr, "This product is currently unavailable.".tr,
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isAddingToCart.value = true;

    try {
      isAddingToCart.value = false;
      await showOrderDetailsBottomSheet(
        context: context,
        uid: currentUser?.uid,
        productId: product.id,
        productData: product.rawData,
        finalPrice: product.discountedPrice,
      );
    } catch (e) {
      isAddingToCart.value = false;
      Get.snackbar("خطأ".tr, "${"An error occurred during processing:".tr}$e");
    }
  }

  Future<void> submitReview({
    required String comment,
    required VoidCallback onShowLogin,
    required VoidCallback onSuccess,
  }) async {
    if (currentUser == null) {
      onShowLogin();
      return;
    }

    if (comment.trim().isEmpty) return;

    isSubmittingReview.value = true;

    try {
      final ref = productsRef.doc(productId).collection('reviews');
      await ref.add({
        'userName': currentUser!.displayName ?? 'client'.tr,
        'userUid': currentUser!.uid,
        'rating': userRating.value,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final docSnapshot = await productsRef.doc(productId).get();
      final data = docSnapshot.data() as Map<String, dynamic>?;
      final String productName = data?['title'] ?? '';

      await EmailServer().sendCommentNotificationToAdmins(
        customerName: currentUser!.displayName ?? 'client',
        productName: productName,
        commentText: comment.trim(),
      );

      onSuccess();
    } finally {
      isSubmittingReview.value = false;
    }
  }
}