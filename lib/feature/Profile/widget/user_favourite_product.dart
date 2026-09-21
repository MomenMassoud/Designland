import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserFavouriteProduct extends StatefulWidget {
  final String UserId;
  const UserFavouriteProduct({Key? key, required this.UserId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _UserFavouriteProduct();
  }
}

class _UserFavouriteProduct extends State<UserFavouriteProduct> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب كافة بيانات المنتجات المفضلة بناءً على الـ Sub-collection "fav"
  Future<List<Map<String, dynamic>>> _getFavouriteProducts() async {
    // 1. قراءة كل الـ Documents داخل fav
    final favSnapshot = await _firestore
        .collection('user')
        .doc(widget.UserId)
        .collection('fav')
        .get();

    if (favSnapshot.docs.isEmpty) {
      return [];
    }

    // 2. استخراج الـ Product IDs
    List<String> productIds = favSnapshot.docs
        .map((doc) => doc.data()['product'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    if (productIds.isEmpty) return [];

    // 3. جلب بيانات كل منتج من كوليكشن products بالتوازي
    List<Future<DocumentSnapshot>> productFutures = productIds
        .map((productId) => _firestore.collection('products').doc(productId).get())
        .toList();

    List<DocumentSnapshot> productDocs = await Future.wait(productFutures);

    // 4. تجميع البيانات المرجعة للمنتجات الموجودة فقط
    List<Map<String, dynamic>> products = [];
    for (var doc in productDocs) {
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        products.add(data);
      }
    }

    return products;
  }

  // حذف منتج من المفضلة
  Future<void> _removeFromFav(String productId) async {
    try {
      final favDocs = await _firestore
          .collection('user')
          .doc(widget.UserId)
          .collection('fav')
          .where('product', isEqualTo: productId)
          .get();

      for (var doc in favDocs.docs) {
        await doc.reference.delete();
      }

      setState(() {}); // إعادة بناء الواجهة بعد الحذف
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إزالة المنتج من المفضلة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'المنتجات المفضلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFavouriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ أثناء تحميل المفضلة: ${snapshot.error}'),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد منتجات مفضلة لهذا العميل',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              final String title = product['title'] ?? 'بدون عنوان';
              final String description = product['description'] ?? '';
              final double price = (product['price'] ?? 0).toDouble();
              final int discount = (product['discountPercentage'] ?? 0).toInt();
              final List<dynamic> images = product['images'] ?? [];
              final String imageUrl = images.isNotEmpty ? images[0] : '';

              // حساب السعر بعد الخصم إن وجد
              final double finalPrice = discount > 0
                  ? price - (price * (discount / 100))
                  : price;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // صورة المنتج
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                          errorListener: (error) =>
                              Container(
                                width: 85,
                                height: 85,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                        )
                            : Container(
                          width: 85,
                          height: 85,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // تفاصيل المنتج
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // عرض الأسعار والخصم
                            Row(
                              children: [
                                Text(
                                  '${finalPrice.toStringAsFixed(0)} ج.م',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 15,
                                  ),
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${price.toStringAsFixed(0)} ج.م',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '%$discount-',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // زر إزالة المنتج من المفضلة
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _removeFromFav(product['id']),
                        tooltip: 'حذف من المفضلة',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}