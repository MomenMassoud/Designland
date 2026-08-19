import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductWidget extends StatefulWidget {
  final String productDoc;

  const ProductWidget({super.key, required this.productDoc});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');

  int _selectedImageIndex = 0;
  final TextEditingController _commentController = TextEditingController();
  double _userRating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "تفاصيل المنتج",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _productsRef.doc(widget.productDoc).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("المنتج غير موجود."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> images = List<String>.from(data['images'] ?? []);
          final double price = (data['price'] ?? 0.0).toDouble();
          final double avgRate = (data['avgRate'] ?? 0.0).toDouble();
          final String title = data['title'] ?? '';
          final String description = data['description'] ?? '';

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? screenWidth * 0.08 : 16,
              vertical: 24,
            ),
            child: Column(
              children: [
                // ==================== TOP SECTION: GALLERY + MAIN INFO ====================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Gallery Section (Left Side)
                            Expanded(
                              flex: 5,
                              child: _buildImageGallery(images),
                            ),
                            const SizedBox(width: 32),

                            // 2. Main Product Info & Cart Action (Right Side)
                            Expanded(
                              flex: 6,
                              child: _buildMainProductHeader(title, avgRate, price, description),
                            ),
                          ],
                        );
                      } else {
                        // Mobile Layout Vertical Fallback
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageGallery(images),
                            const SizedBox(height: 20),
                            _buildMainProductHeader(title, avgRate, price, description),
                          ],
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ==================== BOTTOM SECTION: DETAILS (RIGHT) & REVIEWS (LEFT) ====================
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Product Details Card (Right Panel in RTL)
                          Expanded(
                            flex: 5,
                            child: _buildDetailsCard(description, data),
                          ),
                          const SizedBox(width: 24),

                          // 2. Reviews Section Card (Left Panel in RTL)
                          Expanded(
                            flex: 7,
                            child: _buildReviewsCard(avgRate),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDetailsCard(description, data),
                          const SizedBox(height: 20),
                          _buildReviewsCard(avgRate),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Image Gallery Builder ---
  Widget _buildImageGallery(List<String> images) {
    final String currentImage = images.isNotEmpty ? images[_selectedImageIndex] : '';

    return Column(
      children: [
        // Main Display Box
        Container(
          height: 340,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            image: currentImage.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(currentImage),
              fit: BoxFit.contain,
            )
                : null,
          ),
          child: currentImage.isEmpty
              ? const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 12),

        // Thumbnails List Below Main Image
        if (images.length > 1)
          SizedBox(
            height: 65,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- Main Product Header (Title, Price, Compact Cart Button) ---
  Widget _buildMainProductHeader(String title, double avgRate, double price, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        // Rating Badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    avgRate.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price Label
        Text(
          "\$${price.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 24),

        // Compact Add to Cart Button (Does NOT take full width)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // TODO: Cart Handler
          },
          icon: const Icon(Icons.shopping_bag_outlined, size: 20),
          label: const Text(
            "إضافة إلى السلة",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  // --- Product Full Specification Card ---
  Widget _buildDetailsCard(String description, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "بيانات المنتج التفصيلية",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const Divider(height: 24),
          Text(
            description.isNotEmpty ? description : "لا يوجد وصف إضافي للمنتج.",
            style: const TextStyle(color: Color(0xFF475569), height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- Product Reviews & Rating Card ---
  Widget _buildReviewsCard(double avgRate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "تقييمات العملاء والمراجعات",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Stream Reviews
          StreamBuilder<QuerySnapshot>(
            stream: _productsRef
                .doc(widget.productDoc)
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!.docs;

              return Column(
                children: [
                  // Submit Review Box
                  _buildAddReviewInput(reviews),
                  const SizedBox(height: 16),

                  if (reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "لا توجد تقييمات حالية. كن أول من يقيّم هذا المنتج!",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final rev = reviews[index].data() as Map<String, dynamic>;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                              child: Text(
                                (rev['userName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
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
                                        rev['userName'] ?? 'عميل',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: starIdx < (rev['rating'] ?? 0)
                                                ? Colors.amber
                                                : Colors.grey.shade300,
                                          );
                                        }),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rev['comment'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Input Box for Adding Review ---
  Widget _buildAddReviewInput(List<QueryDocumentSnapshot> existingReviews) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("أضف تقييمك", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              DropdownButton<double>(
                value: _userRating,
                underline: const SizedBox(),
                items: [1.0, 2.0, 3.0, 4.0, 5.0].map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text("$r ★", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _userRating = val);
                },
              ),
            ],
          ),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: "اكتب رأيك عن المنتج هنا...",
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                if (_commentController.text.trim().isEmpty) return;
                setState(() => _isSubmitting = true);

                final ref = _productsRef.doc(widget.productDoc).collection('reviews');
                await ref.add({
                  'userName': 'Momen Massoud',
                  'rating': _userRating,
                  'comment': _commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                _commentController.clear();
                setState(() => _isSubmitting = false);
              },
              child: _isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("نشر التقييم"),
            ),
          )
        ],
      ),
    );
  }
}