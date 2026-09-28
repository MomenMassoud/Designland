import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyProductsView extends StatelessWidget {
  final bool isDarkMode;

  const EmptyProductsView({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 50,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No products found in this category.".tr,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}