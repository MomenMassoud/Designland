import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Core/Utils/app.colors.dart'; //[cite: 5, 6]

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // حذف عنصر منفصل
  Future<void> _deleteSingleItem(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('search_history')
        .doc(docId)
        .delete();
  }

  // مسح السجل بالكامل
  Future<void> _clearAllSearchHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title:  Text(
          "Clear search history".tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textDark, //[cite: 5]
          ),
        ),
        content:  Text(
          "Do you want to clear all recorded searches?".tr,
          style: TextStyle(color: AppColors.textMuted, fontSize: 14), //[cite: 5]
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text("cancellation".tr, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C).withOpacity(0.9),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:  Text("Delete".tr, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await _db
          .collection('user')
          .doc(uid)
          .collection('search_history')
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // تجميع السجلات زمنياً
  Map<String, List<QueryDocumentSnapshot>> _groupDocsByDate(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> groups = {
      "اليوم": [],
      "أمس": [],
      "سابقاً": [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? timestamp = data['createdAt'] as Timestamp?;
      if (timestamp == null) {
        groups["سابقاً"]!.add(doc);
        continue;
      }

      final date = timestamp.toDate();
      final itemDate = DateTime(date.year, date.month, date.day);

      if (itemDate == today) {
        groups["اليوم"]!.add(doc);
      } else if (itemDate == yesterday) {
        groups["أمس"]!.add(doc);
      } else {
        groups["سابقاً"]!.add(doc);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bgLight, //[cite: 5]
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark, //[cite: 5]
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          "Search history".tr,
          style: TextStyle(
            color: AppColors.textDark, //[cite: 5]
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _clearAllSearchHistory,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primaryPurple.withOpacity(0.8), //[cite: 5]
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: uid == null
          ?  Center(child: Text("Please log in to view the history.".tr))
          : StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('user')
            .doc(uid)
            .collection('search_history')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple, //[cite: 5]
                strokeWidth: 2,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          final groupedDocs = _groupDocsByDate(docs);

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            children: groupedDocs.entries.map((entry) {
              return _buildAnimatedTimeGroup(entry.key, entry.value);
            }).toList(),
          );
        },
      ),
    );
  }

  // تجميع الـ Groups مع أنيميشن سلس
  Widget _buildAnimatedTimeGroup(
      String title, List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12, right: 4),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark, //[cite: 5]
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.08), //[cite: 5]
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${docs.length}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple, //[cite: 5]
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String query = data['query'] ?? '';

            return _AnimatedSearchTile(
              index: index,
              query: query,
              onDelete: () => _deleteSingleItem(doc.id),
              onTap: () {
                // تنفيذ عملية البحث بهذه الكلمة
              },
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.05), //[cite: 5]
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                size: 42,
                color: AppColors.primaryPurple.withOpacity(0.4), //[cite: 5]
              ),
            ),
            const SizedBox(height: 20),
             Text(
              "Search history is empty.".tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark, //[cite: 5]
              ),
            ),
            const SizedBox(height: 8),
             Text(
              "You haven't performed any searches recently.".tr,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted), //[cite: 5]
            ),
          ],
        ),
      ),
    );
  }
}

// ودجت تضمن انيميشن دخول وسحب للتفاعل مع العنصر
class _AnimatedSearchTile extends StatefulWidget {
  final int index;
  final String query;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AnimatedSearchTile({
    required this.index,
    required this.query,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_AnimatedSearchTile> createState() => _AnimatedSearchTileState();
}

class _AnimatedSearchTileState extends State<_AnimatedSearchTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.06), //[cite: 5]
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_toggle_off_rounded,
                      color: AppColors.primaryPurple, //[cite: 5]
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.query,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark, //[cite: 5]
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: widget.onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}