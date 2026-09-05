import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desginland/Core/widgets/auth_not_found.dart';
import 'package:desginland/feature/Login/function/auth_function.dart';
import 'package:desginland/feature/Profile/widget/search_history_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'order_widget.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. تعديل بيانات الحساب (عبر Dialog مخصص للويب والموبايل)
  Future<void> _showEditProfileDialog(String currentName, String currentPhone) async {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Edit personal information".tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "full name".tr, prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "phone number".tr, prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The data has been successfully updated.".tr)));
                  },
                  child:  Text("Save changes".tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Address Management".tr , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(),
                    ...addresses.map((addr) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Color(0xFF6366F1)),
                      title: Text(addr['title'] ?? ''),
                      subtitle: Text(addr['details'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final uid = _auth.currentUser!.uid;
                          await _db.collection('users').doc(uid).update({
                            'addresses': FieldValue.arrayRemove([addr])
                          });
                          setModalState(() => addresses.remove(addr));
                        },
                      ),
                    )),
                    const Divider(height: 24),
                    Text("Add a new address:".tr, style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(controller: titleController,
                        decoration:  InputDecoration(labelText: "Address Name (e.g., Home)".tr, border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: detailsController, decoration:
                    InputDecoration(labelText: "Full details".tr, border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        child: Text("Add Address".tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Update password".tr),
        content: Text("${"A password reset link will be sent to the email address:".tr}\n$email"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child:  Text("cancellation".tr)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              await _auth.sendPasswordResetEmail(email: email);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("A reset link has been sent to your email.".tr)));
            },
            child:  Text("Send the link".tr, style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 4. اختيار اللغة عبر Dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("اختر اللغة / Select Language", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text("🇪🇬", style: TextStyle(fontSize: 22)),
              title: const Text("العربية"),
              onTap: () {
                Locale locale;
                try{
                  locale =  Locale("ar");
                  Intl.defaultLocale = locale.languageCode;
                  Get.updateLocale(locale);

                }
                catch(e){
                 print(e);
                }
              },
            ),
            ListTile(
              leading: const Text("🇺🇸", style: TextStyle(fontSize: 22)),
              title: const Text("English"),
              onTap: () {
                Locale locale;
                try{
                  locale =  Locale("en");
                  Intl.defaultLocale = locale.languageCode;
                  Get.updateLocale(locale);

                }
                catch(e){
                  print(e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // كارت البيانات
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              Text("${"phone number".tr} $phone", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                          onPressed: () => _showEditProfileDialog(name, phone),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // قائمة الخيارات
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildProfileTile(
                        icon: Icons.shopping_bag_outlined,
                        title: "Order List and Tracking".tr,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  OrdersScreen()),
                          );
                        },
                      ),
                       Divider(height: 1),
                      _buildProfileTile(
                        icon: Icons.history,
                        title: "Search history".tr,
                        onTap: (){
                          Get.to(SearchHistoryScreen());
                        },
                      ),
                      const Divider(height: 1),
                      _buildProfileTile(
                        icon: Icons.location_on_outlined,
                        title: "${"My addresses (".tr}${addresses.length})",
                        onTap: () => _showAddressesDialog(addresses),
                      ),
                      const Divider(height: 1),
                      _buildProfileTile(
                        icon: Icons.lock_outline,
                        title: "Update password".tr,
                        onTap: _showChangePasswordDialog,
                      ),
                      const Divider(height: 1),
                      _buildProfileTile(
                        icon: Icons.language,
                        title: "Change Language".tr,
                        onTap: _showLanguageDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // زر الخروج
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      LogoutMethod(context);
                    },
                    icon: const Icon(Icons.logout),
                    label:  Text("Log out".tr, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      )
          : const AuthNotLoginWidget(),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E293B)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
