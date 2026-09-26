import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class GuestCartService {
  static final GuestCartService _instance = GuestCartService._internal();
  factory GuestCartService() => _instance;
  GuestCartService._internal();

  final List<Map<String, dynamic>> guestCartItems = [];

  final StreamController<int> _cartCountController = StreamController<int>.broadcast();

  // 👈 تعديل هنا: إرسال القيمة الحالية فوراً + الاستماع للتحديثات القادمة
  Stream<int> get cartCountStream async* {
    yield guestCartItems.length; // يرسل عدد العناصر الحالي فوراً بمجرد الاستماع
    yield* _cartCountController.stream; // يكمل البث المباشر لأي تغييرات قادمة
  }

  List<Map<String, dynamic>> getItems() {
    return guestCartItems;
  }

  void _updateCartCount() {
    if (!_cartCountController.isClosed) {
      _cartCountController.add(guestCartItems.length);
    }
  }

  // باقي الدوال كما هي بدون تغيير...
  Future<void> addItem(Map<String, dynamic> item) async {
    guestCartItems.add(item);
    _updateCartCount();
  }

  void removeItem(int index) {
    if (index >= 0 && index < guestCartItems.length) {
      guestCartItems.removeAt(index);
      _updateCartCount();
    }
  }

  void clearCart() {
    guestCartItems.clear();
    _updateCartCount();
  }

  Future<void> syncGuestCartToUser(String uid) async {
    if (guestCartItems.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final userCartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');

    for (var item in guestCartItems) {
      final newDoc = userCartRef.doc();
      batch.set(newDoc, {
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    clearCart();
  }

  void dispose() {
    _cartCountController.close();
  }
}