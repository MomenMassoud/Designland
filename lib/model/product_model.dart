import 'dart:convert';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double originalPrice;
  final double discountPercentage;
  final double discountedPrice;
  final double avgRate;
  final bool isActive;
  final List<String> images;
  final Map<String, dynamic> rawData;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.discountPercentage,
    required this.discountedPrice,
    required this.avgRate,
    required this.isActive,
    required this.images,
    required this.rawData,
  });

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    final double originalPrice = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;
    final double discountPercentage = double.tryParse(
        (data['discount'] ?? data['discountPercentage'])?.toString() ?? '0'
    ) ?? 0.0;

    final double discountedPrice = discountPercentage > 0
        ? originalPrice - (originalPrice * (discountPercentage / 100))
        : originalPrice;

    return ProductModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      originalPrice: originalPrice,
      discountPercentage: discountPercentage,
      discountedPrice: discountedPrice,
      avgRate: double.tryParse(data['avgRate']?.toString() ?? '0') ?? 0.0,
      isActive: data['IsActive'] ?? data['isActive'] ?? true,
      images: List<String>.from(data['images'] ?? []),
      rawData: data,
    );
  }
}