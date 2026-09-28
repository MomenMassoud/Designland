import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ModernSubcategoryChip extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const ModernSubcategoryChip({
    super.key,
    required this.name,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : isDarkMode
                ? theme.cardColor
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6C5CE7)
                  : isDarkMode
                  ? Colors.white24
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white
                      : const Color(0xFF2D3436),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}