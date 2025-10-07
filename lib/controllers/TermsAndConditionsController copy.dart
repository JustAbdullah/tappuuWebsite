// lib/controllers/TermsAndConditionsController.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/TermsAndConditions.dart';
import '../core/localization/changelanguage.dart';

enum SnackType { success, error, info }

class TermsAndConditionsController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // الحالة العامة
  final isLoading = false.obs;
  final isGetFirstTime = false.obs;

  // قائمة الشروط (للطبقات الإدارية أو لو أردنا عرض قائمة)
  final RxList<TermsAndConditions> termsList = <TermsAndConditions>[].obs;

  // العنصر المحدد (الشروط باللغة الحالية)
  final Rxn<TermsAndConditions> terms = Rxn<TermsAndConditions>();

  // ---- رؤوس افتراضية (أضف توكن لو احتجت) ----
  Map<String, String> _defaultHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  @override
  void onInit() {
    super.onInit();
      final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
      fetchTerms(lang: lang);
    
  }

  // -----------------------
  // Snackbar helper (احترافي)
  // -----------------------
  void _showSnack({
    required String title,
    required String message,
    SnackType type = SnackType.info,
    IconData? icon,
    int seconds = 3,
  }) {
    final LinearGradient gradient;
    final Color textColor = Colors.white;
    switch (type) {
      case SnackType.success:
        gradient = LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]);
        break;
      case SnackType.error:
        gradient = LinearGradient(colors: [Colors.red.shade700, Colors.red.shade400]);
        break;
      case SnackType.info:
      default:
        gradient = LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]);
        break;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundGradient: gradient,
      colorText: textColor,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
      shouldIconPulse: true,
      duration: Duration(seconds: seconds),
      maxWidth: 800,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutQuad,
      reverseAnimationCurve: Curves.easeInQuad,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  // -----------------------
  // Fetch all terms (index)
  // GET /terms
  // -----------------------
  Future<void> fetchTerms({required String lang, String? token}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms');
      final res = await http.get(uri, headers: _defaultHeaders(token: token));

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          final list = (result['data'] as List)
              .map((e) => TermsAndConditions.fromJson(e as Map<String, dynamic>))
              .toList();

          termsList.assignAll(list);

          // اختر العنصر بحسب لغة المستخدم أو الافتراضي أول عنصر
          final found = list.firstWhere((t) => t.language == lang, orElse: () => list.first);
          terms.value = found;
        } else {
          termsList.clear();
          terms.value = null;
          _showSnack(title: 'تنبيه', message: 'لا توجد شروط حالياً', type: SnackType.info, icon: Icons.info_outline);
        }
      } else {
        _showSnack(title: 'خطأ', message: 'فشل جلب الشروط. الحالة: ${res.statusCode}', type: SnackType.error, icon: Icons.error_outline);
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ أثناء جلب الشروط: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------
  // Fetch single term (show)
  // GET /terms/show/{id}
  // -----------------------
  Future<TermsAndConditions?> fetchTermById({required int id, String? token}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms/show/$id');
      final res = await http.get(uri, headers: _defaultHeaders(token: token));

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          final term = TermsAndConditions.fromJson(result['data'] as Map<String, dynamic>);
          // حدِّث القائمة أو العنصر المحلي إن رغبت
          final idx = termsList.indexWhere((t) => t.id == term.id);
          if (idx >= 0) termsList[idx] = term;
          terms.value = term;
          return term;
        } else {
          _showSnack(title: 'خطأ', message: result['message']?.toString() ?? 'فشل الجلب', type: SnackType.error, icon: Icons.error_outline);
        }
      } else {
        _showSnack(title: 'خطأ', message: 'فشل جلب العنصر. الحالة: ${res.statusCode}', type: SnackType.error, icon: Icons.error_outline);
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  // -----------------------
  // Create (store)
  // POST /terms/store
  // -----------------------
  Future<bool> createTerm({
    required String title,
    required String content,
    String? language,
    String? token,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms/store');
      final body = json.encode({'title': title, 'content': content, 'language': language});
      final res = await http.post(uri, headers: _defaultHeaders(token: token), body: body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          final term = TermsAndConditions.fromJson(result['data'] as Map<String, dynamic>);
          termsList.add(term);
          terms.value = term; // اختياري: اجعلها العنصر الحالي
          _showSnack(title: 'تمت الإضافة', message: 'تم إنشاء شرط جديد بنجاح.', type: SnackType.success, icon: Icons.check_circle);
          return true;
        } else {
          _showSnack(title: 'فشل', message: result['message']?.toString() ?? 'فشل الإضافة', type: SnackType.error, icon: Icons.error_outline);
        }
      } else {
        _showSnack(title: 'خطأ', message: 'فشل الإضافة. الحالة: ${res.statusCode}', type: SnackType.error, icon: Icons.error_outline);
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ أثناء الإضافة: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // -----------------------
  // Update
  // POST /terms/update/{id}
  // -----------------------
  Future<bool> updateTerm({
    required int id,
    required String title,
    required String content,
    String? language,
    String? token,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms/update/$id');
      final body = json.encode({'title': title, 'content': content, 'language': language});
      final res = await http.post(uri, headers: _defaultHeaders(token: token), body: body);

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          final updated = TermsAndConditions.fromJson(result['data'] as Map<String, dynamic>);
          final idx = termsList.indexWhere((t) => t.id == updated.id);
          if (idx >= 0) termsList[idx] = updated;
          terms.value = updated;
          _showSnack(title: 'تم التعديل', message: 'تم تحديث الشروط بنجاح.', type: SnackType.success, icon: Icons.edit);
          return true;
        } else {
          _showSnack(title: 'فشل', message: result['message']?.toString() ?? 'فشل التعديل', type: SnackType.error, icon: Icons.error_outline);
        }
      } else {
        _showSnack(title: 'خطأ', message: 'فشل التعديل. الحالة: ${res.statusCode}', type: SnackType.error, icon: Icons.error_outline);
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ أثناء التعديل: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  // -----------------------
  // Delete (destroy)
  // DELETE /terms/delete/{id}
  // -----------------------
  Future<bool> deleteTerm({required int id, String? token}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms/delete/$id');
      final res = await http.delete(uri, headers: _defaultHeaders(token: token));

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          // إزالة محليًا إن وجد
          termsList.removeWhere((t) => t.id == id);
          if (terms.value != null && terms.value!.id == id) terms.value = null;
          _showSnack(title: 'تم الحذف', message: result['message']?.toString() ?? 'تم الحذف بنجاح.', type: SnackType.success, icon: Icons.delete_forever);
          return true;
        } else {
          _showSnack(title: 'فشل', message: result['message']?.toString() ?? 'فشل الحذف', type: SnackType.error, icon: Icons.error_outline);
        }
      } else {
        _showSnack(title: 'خطأ', message: 'فشل الحذف. الحالة: ${res.statusCode}', type: SnackType.error, icon: Icons.error_outline);
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ أثناء الحذف: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
    return false;
  }
}
