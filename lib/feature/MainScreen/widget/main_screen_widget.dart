import 'package:desginland/Core/Utils/app.images.dart';
import 'package:desginland/feature/About/view/about_view.dart';
import 'package:desginland/feature/Basket/view/basket_view.dart';
import 'package:desginland/feature/Home/view/home_view.dart';
import 'package:desginland/feature/Profile/view/profile_view.dart';
import 'package:flutter/material.dart';

class MainScreenWidget extends StatefulWidget {
  const MainScreenWidget({super.key});

  @override
  State<MainScreenWidget> createState() => _MainScreenWidgetState();
}

class _MainScreenWidgetState extends State<MainScreenWidget> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<Widget> _screens = [
    HomeView(),
    ProfileView(),
    AboutView(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: isDesktop ? 24 : 12,
        title: Row(
          children: [
            // اللوجو واسم الموقع
            CircleAvatar(
              backgroundImage: AssetImage(AppImages.appPLogo),
              radius: 30,
            ),
            const SizedBox(width: 12),

            // شريط البحث الذكي
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // أيقونة السلة مع العداد
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFF2D3436)),
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

          // القائمة العلوية تظهر فقط على الويب (Desktop Navigation)
          if (isDesktop) ...[
            const SizedBox(width: 8),
            _buildNavTextButton("Home", Icons.home_outlined, 0),
            _buildNavTextButton("Profile", Icons.person_outline, 1),
            _buildNavTextButton("About", Icons.info_outline, 2),
          ],
          const SizedBox(width: 12),
        ],
      ),

      // ==================== BODY ====================
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // ==================== MOBILE NAVIGATION BAR ====================
      // يظهر فقط على الهواتف والأجهزة الصغيرة
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  // Helper widget للأزرار العلوية الخاصة بشاشات الويب
  Widget _buildNavTextButton(String title, IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;
    return TextButton.icon(
      onPressed: () => setState(() => _selectedIndex = index),
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