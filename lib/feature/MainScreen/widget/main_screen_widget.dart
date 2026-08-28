import 'package:desginland/Core/Utils/app.images.dart';
import 'package:desginland/feature/About/view/about_view.dart';
import 'package:desginland/feature/Basket/view/basket_view.dart';
import 'package:desginland/feature/Home/view/home_view.dart';
import 'package:desginland/feature/Profile/view/profile_view.dart';
import 'package:flutter/material.dart';

import '../../../Core/server/analytics_service.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Widget> _screens =  [
    HomeView(),
    ProfileView(),
    AboutView(),
  ];

  final List<String> _tabNames = ['Home', 'Profile', 'About'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🚀 بدء الجلسة والـ Heartbeat عند فتح الصفحة
    AnalyticsService.startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // إيقاف مؤقت الـ Heartbeat بشكل آمن عند تدمير الـ Widget
    AnalyticsService.endSession();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      // 📊 تسجيل زيارة التبويب
      AnalyticsService.logTabVisit(_tabNames[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: isDesktop ? 24 : 16,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage(AppImages.appPLogo),
              radius: 20,
            ),
            const SizedBox(width: 10),
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2D3436)),
                onPressed: () {
                  Navigator.pushNamed(context, BasketView.id);
                },
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7675),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "3",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            _buildNavTextButton("Home", Icons.home_outlined, 0),
            _buildNavTextButton("Profile", Icons.person_outline, 1),
            _buildNavTextButton("About", Icons.info_outline, 2),
          ],
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: "About",
          ),
        ],
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