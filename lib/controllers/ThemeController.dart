import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  /// تبديل الوضع بين الفاتح والمظلم
  void toggleTheme() {
    if (isDarkMode.value) {
      enableLightMode();
    } else {
      enableDarkMode();
    }
  }

  /// تفعيل المود الفاتح
  void enableLightMode() async {
    isDarkMode.value = false;
    Get.changeThemeMode(ThemeMode.light); // تغيير الثيم إلى الفاتح
    _saveTheme(isDarkMode.value);        // حفظ الحالة
  }

  /// تفعيل المود المظلم
  void enableDarkMode() async {
    isDarkMode.value = true;
    Get.changeThemeMode(ThemeMode.dark); // تغيير الثيم إلى المظلم
    _saveTheme(isDarkMode.value);        // حفظ الحالة
  }

  /// حفظ الوضع المختار في التخزين المحلي
  void _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  /// تحميل الوضع المحفوظ عند تشغيل التطبيق
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    Get.changeThemeMode(
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
