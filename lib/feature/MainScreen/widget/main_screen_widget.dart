import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/widgets/custom_title.dart';
import 'package:desginland/Core/widgets/staff_block_widget.dart';
import 'package:desginland/feature/About/view/about_view.dart';
import 'package:desginland/feature/Basket/view/basket_view.dart';
import 'package:desginland/feature/Home/view/home_view.dart';
import 'package:desginland/feature/Notification/view/notification_view.dart';
import 'package:desginland/feature/Profile/view/profile_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../Core/server/analytics_service.dart';
import '../../../Core/server/save_device_token.dart';
import '../../../Core/server/setup_notification.dart';
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

  StreamSubscription<QuerySnapshot>? _cartSubscription;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  static final List<Widget> _screens = [
    HomeView(),
    ProfileView(),
    AboutView(),
  ];

  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);
  final ValueNotifier<int> _notificationCount = ValueNotifier<int>(0);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.startSession();
    _fetchInitialUserData();
    _getToken();
  }

  Future<void> _getToken() async {
    try {
      if (!kIsWeb) {
        await setupAndroidNotifications();
      } else {
        await setupWeb();
      }
      await saveDeviceTokenToFirestore();
    } catch (e) {
      debugPrint("Error initializing notifications/tokens: $e");
    }
  }

  Future<void> _fetchInitialUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _listenToCartCount(user.uid);
      _listenToNotificationCount(user.uid);

      final userDoc = await _firestore.collection('user').doc(user.uid).get();
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
    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore
        .collection('user')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
        _notificationCount.value = snapshot.size;
      },
      onError: (e) {
        debugPrint("Error listening to notification count: $e");
      },
    );
  }

  void _listenToCartCount(String uid) {
    _cartSubscription?.cancel();
    _cartSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen(
          (snapshot) {
        _cartCount.value = snapshot.size;
      },
      onError: (e) {
        debugPrint("Error listening to cart count: $e");
      },
    );
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    _notificationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AnalyticsService.endSession();
    _cartCount.dispose();
    _notificationCount.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      final List<String> tabNames = ['Home'.tr, 'Profile'.tr, 'About'.tr];
      AnalyticsService.logTabVisit(tabNames[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isblocked) return const BlockListScreen();
    if (_isStaff) return StaffBlockScreen(userRole: _userRole);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconColor = theme.colorScheme.onSurface;

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;
            return AppBar(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
              ),
              backgroundColor: theme.cardColor,
              elevation: isDarkMode ? 0 : 0.5,
              titleSpacing: isDesktop ? 24 : 16,
              title: const CustomRainbowAppBarTitle(),
              actions: [
                // عداد الإشعارات
                ValueListenableBuilder<int>(
                  valueListenable: _notificationCount,
                  builder: (context, count, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: iconColor),
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
                // عداد السلة
                ValueListenableBuilder<int>(
                  valueListenable: _cartCount,
                  builder: (context, count, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
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
                // 🌙/☀️ زر التبديل بين الـ Light والـ Dark Theme
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                      key: ValueKey<bool>(isDarkMode),
                      color: isDarkMode ? const Color(0xFFFFD166) : iconColor,
                    ),
                  ),
                  onPressed: () {
                    Get.changeThemeMode(
                      isDarkMode ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                  tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  _buildNavTextButton("Home".tr, Icons.home_outlined, 0),
                  _buildNavTextButton("Profile".tr, Icons.person_outline, 1),
                  _buildNavTextButton("About".tr, Icons.info_outline, 2),
                ],
                const SizedBox(width: 8),
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
          return _buildLiquidGlassNavBar(context);
        },
      ),
    );
  }

  Widget _buildLiquidGlassNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
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
              color: isDarkMode
                  ? const Color(0xFF1E1D2A).withOpacity(0.85)
                  : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurfaceVariant;

    return TextButton.icon(
      onPressed: () => _onTabSelected(index),
      icon: Icon(
        icon,
        size: 18,
        color: isSelected ? primaryColor : textColor,
      ),
      label: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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