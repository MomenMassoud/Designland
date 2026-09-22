import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/feature/Product/view/product_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Login/view/login_view.dart';

final FirebaseAuth _auth=FirebaseAuth.instance;
final FirebaseFirestore _firestore=FirebaseFirestore.instance;


class ProductListWidget extends StatefulWidget {
  final String categoryDoc;

  const ProductListWidget({super.key, required this.categoryDoc});

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');
  String lang = Get.locale?.languageCode ?? "ar";
  final CollectionReference _productsRef =
  FirebaseFirestore.instance.collection('products');
  final CollectionReference _categoriesRef =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _subcategoriesRef =
  FirebaseFirestore.instance.collection('subcategories');
  Timer? _searchDebounce;
  String? _selectedSubcategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userID': 'Gust',
        'gust': true
      });
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('search_history')
          .add({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('search_history').doc().set({
        'query': query.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userID': userId,
        'gust': false
      });
    } catch (e) {
      debugPrint("Error saving search history: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 1200
        ? 5
        : screenWidth >= 900
        ? 4
        : screenWidth >= 600
        ? 3
        : 2;

    final double childAspectRatio = screenWidth >= 1100
        ? 0.72
        : screenWidth >= 600
        ? 0.68
        : 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D3436), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _categoriesRef.doc(widget.categoryDoc).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                "Category Products".tr,
                style: const TextStyle(
                  color: Color(0xFF2D3436),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final String categoryTitle = lang == "en"
                ? (data['nameEn'] ?? data['name'] ?? "Category Products".tr)
                : (data['nameAr'] ?? "Category Products".tr);

            return Text(
              categoryTitle,
              style: const TextStyle(
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ==================== SEARCH & SUBCATEGORIES SECTION ====================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                        _searchNotifier.value = val.trim().toLowerCase();

                        if (_searchDebounce?.isActive ?? false) {
                          _searchDebounce!.cancel();
                        }

                        if (val.trim().length >= 2) {
                          _searchDebounce =
                              Timer(const Duration(milliseconds: 800), () {
                                _saveSearchHistory(val);
                              });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Search in this category...".tr,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6C5CE7),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 18, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // SUBCATEGORIES SLIDER
                StreamBuilder<QuerySnapshot>(
                  stream: _subcategoriesRef
                      .where('categoryId', isEqualTo: widget.categoryDoc)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final subdocs = snapshot.data!.docs;

                    if (subdocs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          child: Text(
                            "Subcategories".tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: subdocs.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final isSelected = _selectedSubcategoryId == null;
                                return _ModernSubcategoryChip(
                                  name: "All Items".tr,
                                  imageUrl: null,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedSubcategoryId = null;
                                    });
                                  },
                                );
                              }

                              final subdoc = subdocs[index - 1];
                              final subData = subdoc.data() as Map<String, dynamic>;
                              final isSelected = _selectedSubcategoryId == subdoc.id;
                              final String subName = lang == "en"
                                  ? (subData['nameEn'] ?? 'Subcategory'.tr)
                                  : (subData['nameAr'] ?? 'Subcategory'.tr);
                              final String? imageUrl = subData['imageUrl'] ?? subData['image'];

                              return _ModernSubcategoryChip(
                                name: subName,
                                imageUrl: imageUrl,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedSubcategoryId = subdoc.id;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ==================== PRODUCTS GRID ====================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedSubcategoryId != null
                  ? _productsRef
                  .where('categoryId', isEqualTo: widget.categoryDoc)
                  .where('subcategoryId', isEqualTo: _selectedSubcategoryId)
                  .snapshots()
                  : _productsRef
                  .where('categoryId', isEqualTo: widget.categoryDoc)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C5CE7),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Client-side search filtering
                final products = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String title =
                  (data['title'] ?? '').toString().toLowerCase();
                  final String desc =
                  (data['description'] ?? '').toString().toLowerCase();
                  return _searchQuery.isEmpty ||
                      title.contains(_searchQuery) ||
                      desc.contains(_searchQuery);
                }).toList();

                if (products.isEmpty) {
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
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final productData = products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;

                    return _InteractiveProductCard(
                      productData: productData,
                      productId: productId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Subcategory Chip Component
class _ModernSubcategoryChip extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernSubcategoryChip({
    required this.name,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
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
                  color: isSelected ? Colors.white : const Color(0xFF2D3436),
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

// 🛍️ Interactive Product Grid Card Component
class _InteractiveProductCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const _InteractiveProductCard({
    required this.productData,
    required this.productId,
  });

  @override
  State<_InteractiveProductCard> createState() => _InteractiveProductCardState();
}

class _InteractiveProductCardState extends State<_InteractiveProductCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.productData['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty ? images[0] : '';

    final num originalPrice = widget.productData['price'] ?? 0;
    final num discountPercentage = widget.productData['discountPercentage'] ?? 0;
    final bool hasDiscount = discountPercentage > 0;
    final num finalPrice = hasDiscount
        ? (originalPrice * (1 - (discountPercentage / 100))).round()
        : originalPrice;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductView(
                ProductDoc: widget.productId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered ? (Matrix4.identity()..translate(0, -5, 0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? const Color(0xFF6C5CE7).withOpacity(0.4) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? const Color(0xFF6C5CE7).withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isHovered ? 14 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Container
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: imageUrl.isNotEmpty
                          ? AnimatedScale(
                        scale: isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF6C5CE7).withOpacity(0.04),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                          : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Discount Badge
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "-$discountPercentage%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info & Details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productData['title'] ?? 'Product Title'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$finalPrice ${"EGP".tr}",
                                style: const TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              if (hasDiscount)
                                Text(
                                  "$originalPrice ${"EGP".tr}",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: ()async{
                            await _firestore.collection('products').doc(widget.productId).get().then((value){
                              final data=value.data() as Map<String, dynamic>;
                              final double originalPrice = double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;

                              final double discountPercentage = double.tryParse(
                                  (data['discount'] ?? data['discountPercentage'])?.toString() ?? '0'
                              ) ?? 0.0;
                              final double discountedPrice = discountPercentage > 0
                                  ? originalPrice - (originalPrice * (discountPercentage / 100))
                                  : originalPrice;
                              _handleAddToCart(data, discountedPrice);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(0xFF6C5CE7)
                                  : const Color(0xFF6C5CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: isHovered ? Colors.white : const Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(
      Map<String, dynamic> productData, double finalPrice) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showLoginDialog();
      return;
    }
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      String? phone = userData['phone'];
      List<dynamic> addresses = userData['addresses'] ?? [];
      if (!mounted) return;
      await _showOrderDetailsBottomSheet(
          user.uid, productData, finalPrice, addresses);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"An error occurred during processing:".tr}$e")),
      );
    }
  }
  Future<void> _showOrderDetailsBottomSheet(
      String uid,
      Map<String, dynamic> productData,
      double finalPrice,
      List<dynamic> addresses,
      ) async {
    final notesController = TextEditingController();
    int selectedAddressIndex = 0;

    // استخراج الحقول الديناميكية التي حددها الأدمن
    final List<dynamic> customFieldsRaw = productData['fields'] ?? productData['customFields'] ?? [];
    final List<Map<String, dynamic>> customFields = customFieldsRaw.map((e) => Map<String, dynamic>.from(e)).toList();

    // إنشاء Controllers لكل حقل قادم من الأدمن
    final Map<String, TextEditingController> customControllers = {
      for (var field in customFields)
        (field['name'] ?? 'field_${customFields.indexOf(field)}').toString(): TextEditingController()
    };

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order and Design Details".tr,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (customFields.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          "Required Product Specifications".tr,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                        ),
                        const SizedBox(height: 12),
                        ...customFields.map((field) {
                          final String fieldName = field['name'] ?? '';
                          final String fieldType = field['type'] ?? 'text';
                          final bool isRequired = field['isRequired'] ?? false;

                          final bool isDrive = fieldType == 'drive_link';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TextFormField(
                              controller: customControllers[fieldName],
                              keyboardType: isDrive ? TextInputType.url : TextInputType.text,
                              decoration: InputDecoration(
                                labelText: "$fieldName${isRequired ? ' *' : ''}",
                                hintText: isDrive ? "https://drive.google.com/..." : null,
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(isDrive ? Icons.add_link : Icons.edit_note),
                              ),
                              validator: (value) {
                                final textVal = value?.trim() ?? '';

                                // 1. التحقق من الإلزامية بناءً على isRequired
                                if (isRequired && textVal.isEmpty) {
                                  return "${"Please enter".tr} $fieldName";
                                }

                                // 2. التحقق من نوع drive_link لو كان مدخلاً
                                if (isDrive && textVal.isNotEmpty) {
                                  if (!textVal.startsWith('http://') && !textVal.startsWith('https://')) {
                                    return "Please enter a valid link (e.g. https://...)".tr;
                                  }
                                }

                                return null;
                              },
                            ),
                          );
                        }),
                        const Divider(height: 24),
                      ],
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "${"Additional notes on the request".tr} *",
                          hintText: "Write down any specific details or modifications you would like to be implemented...".tr,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter the required notes for the order.".tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            // التحقق من كافة الحقول وفق شروط الأدمن والملاحظات
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            // تجميع كافة الحقول الديناميكية المدخلة
                            final Map<String, String> collectedCustomFields = {};
                            customControllers.forEach((key, controller) {
                              collectedCustomFields[key] = controller.text.trim();
                            });

                            await _firestore.collection('users').doc(uid).collection('cart').add({
                              'productId': widget.productId,
                              'title': productData['title'] ?? '',
                              'price': finalPrice,
                              'originalPrice': (productData['price'] ?? 0.0).toDouble(),
                              'image': (productData['images'] as List?)?.firstOrNull ?? '',
                              'notes': notesController.text.trim(),
                              'customFieldsData': collectedCustomFields,
                              'selectedAddress': "",
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("The product has been successfully added to your cart! 🎉".tr),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          label: Text(
                            "Confirm addition to cart".tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login required".tr),
        content: Text("Please log in first to add products to the cart.".tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancellation".tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              Navigator.pushNamed(context, LoginView.id);
            },
            child: Text("Log in".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}