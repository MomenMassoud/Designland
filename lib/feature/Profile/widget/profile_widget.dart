import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/widgets/auth_not_found.dart';
import 'package:desginland/feature/Profile/widget/search_history_widget.dart';
import 'package:desginland/feature/Profile/widget/user_favourite_product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../Login/function/auth_function.dart';
import 'order_widget.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Palette & Theme Constants
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color primaryGradient = Color(0xFF8172F8);
  static const Color darkText = Color(0xFF2D3436);
  static const Color backgroundColor = Color(0xFFFAF9FF);

  // 1. تعديل بيانات الحساب
  Future<void> _showEditProfileDialog(String currentName, String currentPhone) async {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit personal information".tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "full name".tr,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: primaryColor),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 1.8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "phone number".tr,
                  prefixIcon: const Icon(Icons.phone_outlined, color: primaryColor),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 1.8)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final uid = _auth.currentUser!.uid;
                    await _db.collection('users').doc(uid).set({
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                    }, SetOptions(merge: true));

                    await _auth.currentUser?.updateDisplayName(nameController.text.trim());

                    if (!mounted) return;
                    Navigator.pop(context);
                    Get.snackbar(
                      "Success".tr,
                      "The data has been successfully updated.".tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: primaryColor,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                    );
                  },
                  child: Text("Save changes".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. إدارة العناوين عبر Dialog
  Future<void> _showAddressesDialog(List<dynamic> addresses) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Address Management".tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 24),
                    if (addresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text("No addresses added yet.".tr, style: TextStyle(color: Colors.grey.shade500))),
                      ),
                    ...addresses.map((addr) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.location_on_rounded, color: primaryColor, size: 20),
                          ),
                          title: Text(addr['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(addr['details'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final uid = _auth.currentUser!.uid;
                              await _db.collection('users').doc(uid).update({
                                'addresses': FieldValue.arrayRemove([addr])
                              });
                              setModalState(() => addresses.remove(addr));
                            },
                          ),
                        ),
                      ),
                    )),
                    const Divider(height: 28),
                    Text("Add a new address:".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Address Name (e.g., Home)".tr,
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(
                        labelText: "Full details".tr,
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (titleController.text.isEmpty || detailsController.text.isEmpty) return;
                          final newAddr = {'title': titleController.text.trim(), 'details': detailsController.text.trim()};
                          final uid = _auth.currentUser!.uid;
                          await _db.collection('users').doc(uid).set({
                            'addresses': FieldValue.arrayUnion([newAddr])
                          }, SetOptions(merge: true));
                          setModalState(() => addresses.add(newAddr));
                          titleController.clear();
                          detailsController.clear();
                        },
                        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 20),
                        label: Text("Add Address".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. تغيير كلمة السر
  Future<void> _showChangePasswordDialog() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Update password".tr, style: const TextStyle(fontWeight: FontWeight.bold, color: darkText)),
        content: Text("${"A password reset link will be sent to the email address:".tr}\n\n$email", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5)),
        actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancellation".tr, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await _auth.sendPasswordResetEmail(email: email);
              if (!mounted) return;
              Navigator.pop(context);
              Get.snackbar(
                "Success".tr,
                "A reset link has been sent to your email.".tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: primaryColor,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );
            },
            child: Text("Send the link".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // 4. اختيار اللغة عبر Dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("اختر اللغة / Select Language", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: const Text("🇪🇬", style: TextStyle(fontSize: 22)),
                    title: const Text("العربية", style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
                    trailing: Get.locale?.languageCode == 'ar' ? const Icon(Icons.check_circle, color: primaryColor) : null,
                    onTap: () {
                      try {
                        Locale locale = const Locale("ar");
                        Intl.defaultLocale = locale.languageCode;
                        Get.updateLocale(locale);
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: const Text("🇺🇸", style: TextStyle(fontSize: 22)),
                    title: const Text("English", style: TextStyle(fontWeight: FontWeight.w600, color: darkText)),
                    trailing: Get.locale?.languageCode == 'en' ? const Icon(Icons.check_circle, color: primaryColor) : null,
                    onTap: () {
                      try {
                        Locale locale = const Locale("en");
                        Intl.defaultLocale = locale.languageCode;
                        Get.updateLocale(locale);
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _auth.currentUser != null
          ? StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.hasData && snapshot.data!.exists
              ? snapshot.data!.data() as Map<String, dynamic>
              : {};

          final name = userData['name'] ?? user.displayName ?? "مستخدم جديد";
          final phone = userData['phone'] ?? "غير محدد";
          final addresses = List<dynamic>.from(userData['addresses'] ?? []);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      bool isDesktop = constraints.maxWidth > 800;

                      if (isDesktop) {
                        // ======= تصميم الويب (IntrinsicHeight لموازنة الطول بين الجانبين) =======
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // الجانب الأيسر: كل الخيارات والإعدادات + زر تسجيل الخروج
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle("Activity & Orders".tr),
                                    const SizedBox(height: 10),
                                    _buildActivityCard(addresses),
                                    const SizedBox(height: 20),
                                    _buildSectionTitle("Account & Settings".tr),
                                    const SizedBox(height: 10),
                                    _buildSettingsCard(),
                                    const Spacer(),
                                    const SizedBox(height: 20),
                                    _buildLogoutButton(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),

                              // الجانب الأيمن: كارت البيانات الشخصية الممتد رأسياً
                              SizedBox(
                                width: 350,
                                child: _buildExpandedUserInfoCard(name, user.email, phone),
                              ),
                            ],
                          ),
                        );
                      }

                      // ======= تصميم الموبايل =======
                      return Column(
                        children: [
                          _buildUserInfoCard(name, user.email, phone),
                          const SizedBox(height: 20),
                          _buildActivityCard(addresses),
                          const SizedBox(height: 16),
                          _buildSettingsCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      )
          : const AuthNotLoginWidget(),
    );
  }

  // --- Elements البناء المخصصة ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
    );
  }

  // كارت الويب الممتد طوليًا جهة اليمين
  Widget _buildExpandedUserInfoCard(String name, String? email, String phone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showEditProfileDialog(name, phone),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.edit_rounded, color: primaryColor, size: 18),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // كارت الموبايل الهيدر
  Widget _buildUserInfoCard(String name, String? email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showEditProfileDialog(name, phone),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.edit_rounded, color: primaryColor, size: 16),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "${"phone number".tr}: $phone",
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<dynamic> addresses) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: Icons.shopping_bag_outlined,
            title: "Order List and Tracking".tr,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersScreen()),
              );
            },
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          _buildProfileTile(
            icon: Icons.favorite_border_rounded,
            title: "Favourite Product".tr,
            onTap: () {
              Get.to(UserFavouriteProduct(UserId: _auth.currentUser!.uid));
            },
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          _buildProfileTile(
            icon: Icons.history_rounded,
            title: "Search history".tr,
            onTap: () {
              Get.to(const SearchHistoryScreen());
            },
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          _buildProfileTile(
            icon: Icons.location_on_outlined,
            title: "${"My addresses (".tr}${addresses.length})",
            onTap: () => _showAddressesDialog(addresses),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileTile(
            icon: Icons.lock_outline_rounded,
            title: "Update password".tr,
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          _buildProfileTile(
            icon: Icons.language_rounded,
            title: "Change Language".tr,
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF0F0),
          foregroundColor: Colors.redAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () async {
          LogoutMethod(context);
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text("Log out".tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}