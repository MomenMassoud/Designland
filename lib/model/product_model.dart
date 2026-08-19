import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  String doc;
  double price;
  String title;
  String description;
  String categoryDoc;
  String SubCategoryDoc;
  double avgRate;
  List<String> images;
  final double discountPercentage; // نسبة الخصم مثلاً 15.0
  final DateTime? discountUntil;   // تاريخ ووقت انتهاء الخصم
  ProductModel({
    required this.doc,required this.title,required this.price,required this.avgRate,required this.categoryDoc,
    required this.description,required this.images,required this.SubCategoryDoc,
    this.discountPercentage = 0.0,
    this.discountUntil,
});
  bool get hasActiveDiscount {
    if (discountPercentage <= 0 || discountUntil == null) return false;
    return DateTime.now().isBefore(discountUntil!);
  }

  // حساب السعر النهائي بعد الخصم
  double get discountedPrice {
    if (!hasActiveDiscount) return price;
    return price - (price * (discountPercentage / 100));
  }
  factory ProductModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ProductModel(
      doc: id,
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      avgRate: (json['avgRate'] ?? 0).toDouble(),
      categoryDoc: json['categoryId'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      SubCategoryDoc: json['subcategoryId'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      discountUntil: json['discountUntil'] != null
          ? (json['discountUntil'] as Timestamp).toDate()
          : null,
    );
  }
}