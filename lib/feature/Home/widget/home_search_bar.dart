import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueNotifier<String> searchNotifier;
  final Function(String) onSubmitted;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.searchNotifier,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1300),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: ValueListenableBuilder<String>(
          valueListenable: searchNotifier,
          builder: (context, query, _) {
            final bool isSearching = query.isNotEmpty;

            return Container(
              width: isDesktop ? 450 : double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.12)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : primaryColor.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: textColor, fontSize: 14),
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  hintText: 'Search custom gifts, bags, items...'.tr,
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                  suffixIcon: isSearching
                      ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                      size: 18,
                    ),
                    onPressed: () => controller.clear(),
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}