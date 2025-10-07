// lib/core/localization/changelanguage.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/appservices.dart';

class ChangeLanguageController extends GetxController {
  // اللغة الحالية (مخزن كنمط Rx لتحديث الواجهة لو احتجنا)
  var currentLocale = const Locale.fromSubtags(languageCode: 'ar', scriptCode: 'Arab').obs;

  // قائمة اللغات المدعومة: هنا قيدناها للعربية فقط
  static const Map<String, Locale> _supported = {
    'ar': Locale.fromSubtags(languageCode: 'ar', scriptCode: 'Arab'),
    // 'en': Locale('en'), // تم قفل الإنجليزية مؤقتاً — إن أردت تفعيلها شغّل هذا السطر
  };

  /// تغيير اللغة - هنا نمنع أي تغيير غير العربية (قيد صارم)
  void changeLanguage(String langCode) {
    // إذا حاولت تغير لأي شيء غير 'ar' نتجاهل الطلب
    if (langCode != 'ar') {
      // إن أردت إظهار وسيلة للمستخدم: استخدم snackbar، لكن الآن نمنعه هادئًا
      debugPrint('changeLanguage blocked: only Arabic is allowed currently.');
      return;
    }

    final locale = _supported['ar']!;
    currentLocale.value = locale;
    Get.updateLocale(locale);
    saveLanguage('ar');
    // لا حاجة لإعادة تحميل التطبيق بالكامل
  }

  // حفظ اللغة في SharedPreferences (سيبقى 'ar')
  void saveLanguage(String langCode) {
    try {
      final prefs = Get.find<AppServices>().sharedPreferences;
      prefs.setString('lang', langCode);
    } catch (_) {
      // إذا AppServices غير مسجل بعد فلا نكسر التطبيق
    }
  }

  // استعادة اللغة عند التشغيل (ستُجبر على العربية دوماً)
  @override
  void onInit() {
    super.onInit();
    try {
      final prefs = Get.find<AppServices>().sharedPreferences;
      final savedLang = prefs.getString('lang');

      // لو كان محفوظ 'ar' نستخدمه، وإلا نجبر العربية
      final code = (savedLang == 'ar') ? 'ar' : 'ar';

      final locale = _supported[code]!;
      currentLocale.value = locale;
      Get.updateLocale(locale);
    } catch (_) {
      // لو فشل أي شيء — استخدم العربية بشكل افتراضي
      final locale = _supported['ar']!;
      currentLocale.value = locale;
      Get.updateLocale(locale);
    }
  }
}
