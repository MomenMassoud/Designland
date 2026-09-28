import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryDoc;
  final CollectionReference categoriesRef;
  final String lang;
  final bool isDarkMode;
  final ThemeData theme;

  const CategoryAppBar({
    super.key,
    required this.categoryDoc,
    required this.categoriesRef,
    required this.lang,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: StreamBuilder<DocumentSnapshot>(
        stream: categoriesRef.doc(categoryDoc).snapshots(),
        builder: (context, snapshot) {
          final defaultTitle = "Category Products".tr;
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildTitleText(defaultTitle);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String categoryTitle = lang == "en"
              ? (data['nameEn'] ?? data['name'] ?? defaultTitle)
              : (data['nameAr'] ?? defaultTitle);

          return _buildTitleText(categoryTitle);
        },
      ),
    );
  }

  Widget _buildTitleText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    );
  }
}