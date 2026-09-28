import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/product_controller.dart';

class ProductReviewsSection extends StatelessWidget {
  final ProductController controller;
  final VoidCallback showLoginDialog;

  const ProductReviewsSection({
    super.key,
    required this.controller,
    required this.showLoginDialog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Ratings and Reviews".tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _AddReviewForm(controller: controller, showLoginDialog: showLoginDialog),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: controller.reviewsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final reviews = snapshot.data!.docs;
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "There are currently no ratings. Be the first to rate this product!".tr,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 20, color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final rev = reviews[index].data() as Map<String, dynamic>;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                        child: Text(
                          (rev['userName'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rev['userName'] ?? 'client'.tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: starIdx < (rev['rating'] ?? 0)
                                          ? Colors.amber
                                          : isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                    );
                                  }),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rev['comment'] ?? '',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddReviewForm extends StatefulWidget {
  final ProductController controller;
  final VoidCallback showLoginDialog;

  const _AddReviewForm({required this.controller, required this.showLoginDialog});

  @override
  State<_AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<_AddReviewForm> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add your rating".tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Obx(() => DropdownButton<double>(
                value: widget.controller.userRating.value,
                dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                underline: const SizedBox(),
                items: [1.0, 2.0, 3.0, 4.0, 5.0]
                    .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text("$r ★",
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.controller.userRating.value = val;
                },
              )),
            ],
          ),
          TextField(
            controller: _commentController,
            focusNode: _focusNode,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Write your opinion about the product here...".tr,
              hintStyle: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade500 : Colors.grey),
              border: InputBorder.none,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Obx(() => TextButton(
              onPressed: widget.controller.isSubmittingReview.value
                  ? null
                  : () => widget.controller.submitReview(
                comment: _commentController.text,
                onShowLogin: widget.showLoginDialog,
                onSuccess: () {
                  _commentController.clear();
                  _focusNode.unfocus();
                },
              ),
              child: widget.controller.isSubmittingReview.value
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("Publish the review".tr),
            )),
          )
        ],
      ),
    );
  }
}