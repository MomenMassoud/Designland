import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  /// قراءة الحالة المخزنة، والافتراضي يكون الوضع الفاتح
  bool _loadThemeFromBox() => _box.read(_key) ?? false;

  /// حفظ الحالة في الميموري
  void _saveThemeToBox(bool isDarkMode) => _box.write(_key, isDarkMode);

  /// معرفة Mode الحالي للـ GetMaterialApp
  ThemeMode get theme => _loadThemeFromBox() ? ThemeMode.dark : ThemeMode.light;

  /// الحصول على قيمة bool هل الوضع الحالي داكن أم لا
  bool get isDarkMode => _loadThemeFromBox();

  /// دالة التبديل بين الـ Themes
  void switchTheme() {
    Get.changeThemeMode(_loadThemeFromBox() ? ThemeMode.light : ThemeMode.dark);
    _saveThemeToBox(!_loadThemeFromBox());
  }
}