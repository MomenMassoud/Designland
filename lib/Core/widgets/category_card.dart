import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../feature/Product/widget/product_list_widget.dart';

class CategoryCardWidget extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String categoryId;
  final bool isSelected;

  const CategoryCardWidget({
    super.key,
    required this.name,
    this.imageUrl,
    required this.categoryId,
    required this.isSelected,
  });

  @override
  State<CategoryCardWidget> createState() => _CategoryCardWidgetState();
}

class _CategoryCardWidgetState extends State<CategoryCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Get.to(() => ProductListWidget(categoryDoc: widget.categoryId)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform:
          isHovered ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? primaryColor : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? primaryColor.withOpacity(0.25)
                    : Colors.black.withOpacity(0.08),
                blurRadius: isHovered ? 15 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: primaryColor.withOpacity(0.05),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.category, color: primaryColor),
                    ),
                  )
                      : Container(
                    color: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.category, color: primaryColor),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(isHovered ? 0.8 : 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isSelected
                              ? primaryColor
                              : Colors.white.withOpacity(0.25),
                        ),
                        child: Icon(
                          widget.isSelected
                              ? Icons.check
                              : Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}