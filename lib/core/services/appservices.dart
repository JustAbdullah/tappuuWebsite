// lib/core/services/appservices.dart
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../controllers/editable_text_controller.dart';

class AppServices {
  late SharedPreferences sharedPreferences;

  AppServices._private();

  /// استدعاء للتهيئة:
  /// - يجهّز SharedPreferences.
  /// - يسجل EditableTextController (لو مش مسجل).
  /// - يطلق جلب النصوص المتغيرة والخطوط في الخلفية (بدون await).
  static Future<AppServices> init() async {
    AppServices services = AppServices._private();
    services.sharedPreferences = await SharedPreferences.getInstance();

    try {
      // نضمن وجود الكنترولر بشكل دائم، لكن بدون شغل شبكات ثقيل هنا
      if (!Get.isRegistered<EditableTextController>()) {
        Get.put(EditableTextController(), permanent: true);
      }
      final editableCtrl = Get.find<EditableTextController>();

      // الشبكات + تحميل الخطوط في الخلفية، بدون تعطيل الإقلاع
      () async {
        try {
          await editableCtrl.fetchAll();
          if (kDebugMode) {
            debugPrint(
              'AppServices (WEB): editable texts fetched in background (count=${editableCtrl.items.length})',
            );
          }

          try {
            final futures = editableCtrl.items.map(
              (e) => editableCtrl.ensureFontLoaded(e),
            );
            await Future.wait(futures);
            if (kDebugMode) {
              debugPrint('AppServices (WEB): fonts preloaded for editable texts.');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('AppServices (WEB): error preloading fonts: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'AppServices (WEB): failed to fetch editable texts in background: $e',
            );
          }
        }
      }();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppServices (WEB): EditableTextController init error: $e');
      }
    }

    return services;
  }

  // ------ إعدادات الـ API ------
  final String _baseUrl =
      'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  String get baseUrl => _baseUrl;

  // ------ مفاتيح SharedPreferences ------
  static const String _kAppLogoKey = 'app_logo_url';
  static const String _kAppLogoRawKey = 'app_logo_raw';

  static const String _kWaitingScreenKey = 'waiting_screen';
  static const String _kWaitingScreenRawKey = 'waiting_screen_raw';

  // ------ حالات / flags ------
  RxBool isRefreshingPremium = false.obs;

  // ============================
  // App logo helpers
  // ============================
  Future<void> fetchAndStoreAppLogo(
      {Duration timeout = const Duration(seconds: 30)}) async {
    final uri = Uri.parse('$_baseUrl/app-logo');
    try {
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body;
        final prevRaw = sharedPreferences.getString(_kAppLogoRawKey);

        if (prevRaw != null && prevRaw == raw) {
          if (kDebugMode) debugPrint('App logo: no change detected.');
          return;
        }

        final body = json.decode(raw);
        String? url;
        if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            url = (data['url'] ?? data['image'] ?? data['image_url'])?.toString();
          } else if (data is String) {
            url = data;
          }
        } else if (body is String) {
          url = body;
        }

        if (url != null && url.isNotEmpty) {
          await sharedPreferences.setString(_kAppLogoKey, url);
          await sharedPreferences.setString(_kAppLogoRawKey, raw);
          if (kDebugMode) debugPrint('App logo updated and saved: $url');
          return;
        } else {
          if (sharedPreferences.containsKey(_kAppLogoKey)) {
            await sharedPreferences.remove(_kAppLogoKey);
            await sharedPreferences.remove(_kAppLogoRawKey);
            if (kDebugMode) {
              debugPrint(
                  'App logo response has no url -> cleared cached logo.');
            }
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'fetchAndStoreAppLogo HTTP error: ${res.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchAndStoreAppLogo error: $e');
    }
  }

  String? getStoredAppLogoUrl() {
    try {
      return sharedPreferences.getString(_kAppLogoKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearStoredAppLogo() async {
    try {
      if (sharedPreferences.containsKey(_kAppLogoKey)) {
        await sharedPreferences.remove(_kAppLogoKey);
      }
      if (sharedPreferences.containsKey(_kAppLogoRawKey)) {
        await sharedPreferences.remove(_kAppLogoRawKey);
      }
      if (kDebugMode) debugPrint('App logo cleared.');
    } catch (e) {
      if (kDebugMode) debugPrint('clearStoredAppLogo error: $e');
    }
  }

  // ============================
  // Waiting screen helpers
  // ============================
  Future<Map<String, dynamic>?> fetchAndStoreWaitingScreen(
      {Duration timeout = const Duration(seconds: 8)}) async {
    final uri = Uri.parse('$_baseUrl/waiting-screen');
    try {
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body;
        final prevRaw = sharedPreferences.getString(_kWaitingScreenRawKey);

        if (prevRaw != null && prevRaw == raw) {
          if (kDebugMode) debugPrint('WaitingScreen: no change detected.');
          return null;
        }

        final body = json.decode(raw);
        if (body is Map<String, dynamic> &&
            (body['success'] == true) &&
            body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          await sharedPreferences.setString(
              _kWaitingScreenKey, json.encode(data));
          await sharedPreferences.setString(_kWaitingScreenRawKey, raw);
          if (kDebugMode) debugPrint('WaitingScreen updated and cached.');
          return data;
        } else {
          if (sharedPreferences.containsKey(_kWaitingScreenKey)) {
            await sharedPreferences.remove(_kWaitingScreenKey);
            await sharedPreferences.remove(_kWaitingScreenRawKey);
            if (kDebugMode) {
              debugPrint(
                  'WaitingScreen response invalid -> cleared cached.');
            }
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'fetchAndStoreWaitingScreen HTTP error: ${res.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchAndStoreWaitingScreen error: $e');
      }
    }
    return null;
  }

  Map<String, dynamic>? getStoredWaitingScreen() {
    try {
      final raw = sharedPreferences.getString(_kWaitingScreenKey);
      if (raw == null) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      return map;
    } catch (e) {
      if (kDebugMode) debugPrint('getStoredWaitingScreen error: $e');
      return null;
    }
  }

  Future<void> clearStoredWaitingScreen() async {
    try {
      if (sharedPreferences.containsKey(_kWaitingScreenKey)) {
        await sharedPreferences.remove(_kWaitingScreenKey);
      }
      if (sharedPreferences.containsKey(_kWaitingScreenRawKey)) {
        await sharedPreferences.remove(_kWaitingScreenRawKey);
      }
      if (kDebugMode) debugPrint('WaitingScreen cleared.');
    } catch (e) {
      if (kDebugMode) debugPrint('clearStoredWaitingScreen error: $e');
    }
  }

  // ============================
  // Utilities
  // ============================
  Future<void> refreshPremiumAdsOnServer() async {
    try {
      isRefreshingPremium.value = true;
      final uri = Uri.parse('$_baseUrl/ads/refresh-premium');
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (kDebugMode) debugPrint('refreshPremiumAdsOnServer: $body');
      } else {
        if (kDebugMode) {
          debugPrint(
              'refreshPremiumAdsOnServer failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('refreshPremiumAdsOnServer error: $e');
      }
    } finally {
      isRefreshingPremium.value = false;
    }
  }
}
