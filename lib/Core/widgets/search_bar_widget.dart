import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search in this category...".tr,
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6C5CE7),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear_rounded,
              size: 18,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
            ),
            onPressed: onClear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}