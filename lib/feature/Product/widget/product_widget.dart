import 'package:cached_network_image/cached_network_image.dart';
import 'package:desginland/Core/widgets/full_screen_image_widget.dart';
import 'package:desginland/feature/Login/view/login_view.dart';
import 'package:desginland/feature/Product/widget/product_description_widget.dart';
import 'package:desginland/feature/Product/widget/product_reviews_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../model/product_model.dart';
import '../../Basket/view/basket_view.dart';
import 'package:seo/seo.dart';

class ProductWidget extends StatefulWidget {
  final String? productDoc;

  const ProductWidget({super.key, this.productDoc});

  @override
  State<ProductWidget> createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  late final ProductController controller;
  late final String effectiveProductId;

  @override
  void initState() {
    super.initState();

    // 🔍 الحصول على معرف المنتج: إما الممرر من الـ Widget أو المجلوب مباشرة من مسار الـ URL
    final urlParamId = Get.parameters['id'];
    effectiveProductId = (widget.productDoc != null && widget.productDoc!.isNotEmpty)
        ? widget.productDoc!
        : (urlParamId ?? '');

    if (effectiveProductId.isNotEmpty) {
      controller = Get.put(
        ProductController(productId: effectiveProductId),
        tag: effectiveProductId,
      );
    }
  }

  // 🔗 دالة مشاركة رابط المنتج
  void _shareProduct() {
    final String shareUrl = "https://designlandeg.com/product/$effectiveProductId";

    // نسخ الرابط لإلحاقه بالحافظة مع عرض إشعار للمستخدم
    Clipboard.setData(ClipboardData(text: shareUrl));
    Get.snackbar(
      "Link copied".tr,
      "The product link has been copied to your clipboard.".tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF6366F1),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
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
            onPressed: () => Navigator.pushNamed(context, LoginView.id),
            child: Text("Log in".tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (effectiveProductId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text("The product does not exist.".tr)),
      );
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? theme.cardColor : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.offAllNamed('/mainscreen');
            }
          },
        ),
        title: Text(
          "Product Details".tr,
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 📲 زر مشاركة رابط المنتج
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
            ),
            onPressed: _shareProduct,
          ),
          StreamBuilder<int>(
            stream: controller.cartCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3436),
                    ),
                    onPressed: () => Navigator.pushNamed(context, BasketView.id),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _BadgeCounter(count: count),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 950;

          return StreamBuilder<ProductModel?>(
            stream: controller.productStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text("The product does not exist.".tr));
              }

              final product = snapshot.data!;

              if (isDesktop) {
                return Seo.head(
                  tags: [
                    // 1. وسوم SEO العادية
                    MetaTag(
                      name: 'description',
                      content: product.description.length > 150
                          ? '${product.description.substring(0, 147)}...'
                          : product.description,
                    ),
                    MetaTag(
                      name: 'keywords',
                      content: '${product.title}, DesignLand',
                    ),
                    MetaTag(
                      name: 'title', // بتترجم تلقائياً لـ og:title
                      content: '${product.title} | DesignLand',
                    ),
                    MetaTag(
                      name: 'description', // بتترجم تلقائياً لـ og:description
                      content: product.description,
                    ),
                    MetaTag(
                      name: 'image', // بتترجم تلقائياً لـ og:image
                      content: product.images.isNotEmpty ? product.images.first : '',
                    ),
                    MetaTag(
                      name: 'url', // بتترجم تلقائياً لـ og:url
                      content: 'https://designlandeg.com/product/$effectiveProductId',
                    ),
                  ],
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.05,
                      vertical: 24,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
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
                                _buildImageGallery(product.images, isDarkMode),
                                const SizedBox(height: 20),
                                _buildMainProductHeader(product, isDarkMode),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildDetailsCard(product.description, isDarkMode, theme),
                              const SizedBox(height: 20),
                              ProductReviewsSection(
                                controller: controller,
                                showLoginDialog: _showLoginDialog,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Seo.head(
                tags: [
                  // 1. وسوم SEO العادية
                  MetaTag(
                    name: 'description',
                    content: product.description.length > 150
                        ? '${product.description.substring(0, 147)}...'
                        : product.description,
                  ),
                  MetaTag(
                    name: 'keywords',
                    content: '${product.title}, DesignLand',
                  ),
                  MetaTag(
                    name: 'title', // بتترجم تلقائياً لـ og:title
                    content: '${product.title} | DesignLand',
                  ),
                  MetaTag(
                    name: 'description', // بتترجم تلقائياً لـ og:description
                    content: product.description,
                  ),
                  MetaTag(
                    name: 'image', // بتترجم تلقائياً لـ og:image
                    content: product.images.isNotEmpty ? product.images.first : '',
                  ),
                  MetaTag(
                    name: 'url', // بتترجم تلقائياً لـ og:url
                    content: 'https://designlandeg.com/product/$effectiveProductId',
                  ),
                ],
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
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
                            _buildImageGallery(product.images, isDarkMode),
                            const SizedBox(height: 20),
                            _buildMainProductHeader(product, isDarkMode),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailsCard(product.description, isDarkMode, theme),
                      const SizedBox(height: 20),
                      ProductReviewsSection(
                        controller: controller,
                        showLoginDialog: _showLoginDialog,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, bool isDarkMode) {
    return Obx(() {
      final selectedIndex = controller.selectedImageIndex.value;
      final String currentImage = images.isNotEmpty ? images[selectedIndex] : '';

      return Column(
        children: [
          InkWell(
            onTap: () => Get.to(FullScreenImageViewer(images: images, initialIndex: selectedIndex)),
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                image: currentImage.isNotEmpty
                    ? DecorationImage(
                  image: CachedNetworkImageProvider(currentImage),
                  fit: BoxFit.contain,
                )
                    : null,
              ),
              child: currentImage.isEmpty
                  ? Icon(
                Icons.image_not_supported_outlined,
                size: 50,
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
              )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (images.length > 1)
            SizedBox(
              height: 65,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => controller.setSelectedImage(index),
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
                          image: CachedNetworkImageProvider(images[index]),
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
    });
  }

  Widget _buildMainProductHeader(ProductModel product, bool isDarkMode) {
    final bool hasDiscount = product.discountPercentage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                product.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: product.isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.isActive ? "In Stock".tr : "Out of stock".tr,
                style: TextStyle(
                  color: product.isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                    product.avgRate.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.amber.shade300 : const Color(0xFFB45309),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "${product.discountedPrice.toStringAsFixed(2)}${"EGP".tr}",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: hasDiscount ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 12),
              Text(
                "${product.originalPrice.toStringAsFixed(2)}${"EGP".tr}",
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "-${product.discountPercentage.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: product.isActive ? const Color(0xFF6366F1) : Colors.grey,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (controller.isAddingToCart.value || !product.isActive)
                ? null
                : () => controller.handleAddToCart(context, product),
            icon: controller.isAddingToCart.value
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Icon(product.isActive ? Icons.shopping_bag_outlined : Icons.block, size: 20),
            label: Text(
              product.isActive ? "Add to cart".tr : "This product is currently unavailable.".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(String description, bool isDarkMode, ThemeData theme) {
    return Container(
      width: double.infinity,
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
            "Detailed product information".tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Divider(height: 24, color: isDarkMode ? Colors.white12 : Colors.grey.shade200),
          ProductDescriptionWidget(description: description),
        ],
      ),
    );
  }
}

class _BadgeCounter extends StatelessWidget {
  final int count;
  const _BadgeCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7675),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$count",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}