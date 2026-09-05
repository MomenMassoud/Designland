import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/Utils/app.images.dart';
import 'package:desginland/Core/widgets/staff_block_widget.dart';
import 'package:desginland/feature/About/view/about_view.dart';
import 'package:desginland/feature/Basket/view/basket_view.dart';
import 'package:desginland/feature/Home/view/home_view.dart';
import 'package:desginland/feature/Notification/view/notification_view.dart';
import 'package:desginland/feature/Profile/view/profile_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../Core/server/analytics_service.dart';
import '../../../Core/widgets/black_list_widget.dart';
import '../../../Core/widgets/error_dailog_custom.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isblocked = false;
  String _userRole = "";
  bool _isStaff = false;

  // جعل القائمة const ومستقرة لتجنب إنشائها عند كل Rebuild
  static  List<Widget> _screens = [
    HomeView(),
    ProfileView(),
    AboutView(),
  ];

  // استخدام ValueNotifier لتقليل Rebuilds العدادات
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);
  final ValueNotifier<int> _notificationCount = ValueNotifier<int>(0);
  static  List<String> _tabNames = ['Home'.tr, 'Profile'.tr, 'About'.tr];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.startSession();
    _fetchInitialUserData();
  }

  // تجميع الطلبات في طلب واحد متوازي لتنفيذ الفحص بسرعة
  Future<void> _fetchInitialUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. طلب بيانات المستخدم الرئيسية مرة واحدة (Block status & Staff role)
      final userDocFuture = _firestore.collection('user').doc(user.uid).get();

      // 2. الاستماع التفاعلي اللحظي للعدادات عبر Streams لسرعة الاستجابة ودقة البيانات
      _listenToCartCount(user.uid);
      _listenToNotificationCount(user.uid);

      final userDoc = await userDocFuture;
      if (mounted && userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          final role = data['role'] ?? '';
          setState(() {
            _isblocked = data['isBlocked'] ?? false;
            _userRole = role;
            _isStaff = (role == "staff" || role == "admin");
          });
        }
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, "Error".tr, e.toString());
    }
  }

  void _listenToNotificationCount(String uid) {
    _firestore
        .collection('user')
        .doc(uid)
        .collection('notification')
        .where('isRead', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _notificationCount.value = snapshot.size;
    }, onError: (e) => showErrorDialog(context, "Error".tr, e.toString()));
  }

  void _listenToCartCount(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      _cartCount.value = snapshot.size;
    }, onError: (e) => showErrorDialog(context, "Error".tr, e.toString()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AnalyticsService.endSession();
    _cartCount.dispose();
    _notificationCount.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      AnalyticsService.logTabVisit(_tabNames[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isblocked) return const BlockListScreen();
    if (_isStaff) return StaffBlockScreen(userRole: _userRole);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
            return AppBar(
              systemOverlayStyle:  SystemUiOverlayStyle(
                statusBarColor: Colors.transparent, // أو Colors.white
                statusBarIconBrightness: Brightness.dark, // أيقونات سوداء/داكنة لكي تظهر فوق الخلفية البيضاء
                statusBarBrightness: Brightness.light, // مخصص لـ iOS
              ),
              backgroundColor: Colors.white,
              elevation: 0.5,
              titleSpacing: isDesktop ? 24 : 16,
              title: const Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(AppImages.appPLogo),
                    radius: 20,
                  ),
                  SizedBox(width: 10),
                 const Text(
                    "DesignLand",
                    style: TextStyle(
                      color: Color(0xFF2D3436),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                // تحديث عداد الإشعارات فقط
                ValueListenableBuilder<int>(
                  valueListenable: _notificationCount,
                  builder: (context, count, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Color(0xFF2D3436)),
                          onPressed: () => Get.to(() => NotificationView()),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _BadgeCounter(count: count),
                          ),
                      ],
                    );
                  },
                ),
                // تحديث عداد السلة فقط
                ValueListenableBuilder<int>(
                  valueListenable: _cartCount,
                  builder: (context, count, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2D3436)),
                          onPressed: () => Navigator.pushNamed(context, BasketView.id),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _BadgeCounter(count: count),
                          ),
                      ],
                    );
                  },
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  _buildNavTextButton("Home".tr, Icons.home_outlined, 0),
                  _buildNavTextButton("Profile".tr, Icons.person_outline, 1),
                  _buildNavTextButton("About".tr, Icons.info_outline, 2),
                ],
                const SizedBox(width: 12),
              ],
            );
          },
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 850) return const SizedBox.shrink();
          return _buildLiquidGlassNavBar();
        },
      ),
    );
  }

  Widget _buildLiquidGlassNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, "Home".tr, 0),
                _buildNavItem(Icons.person_outline, Icons.person, "Profile".tr, 1),
                _buildNavItem(Icons.info_outline, Icons.info, "About".tr, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavTextButton(String title, IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return TextButton.icon(
      onPressed: () => _onTabSelected(index),
      icon: Icon(
        icon,
        size: 18,
        color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade700,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// Widget مستقل وثابت لشارة العدادات لمنع إعادة إنشاء الـ Decoration
class _BadgeCounter extends StatelessWidget {
  final int count;
  const _BadgeCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFFF7675),
        shape: BoxShape.circle,
      ),
      child: Text(
        "$count",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}