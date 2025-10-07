import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/FavoriteSeller.dart';
import '../core/data/model/AdResponse.dart';
import 'areaController.dart';  // لتحليل الـ JSON إلى قائمة Ad

class FavoriteSellerController extends GetxController {
  // عدّل هذا حسب عنوان الـ API عندك
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // لائحة المعلنين المفضلين
  var favoriteList       = <FavoriteSeller>[].obs;
  var isLoadingFavorites = false.obs;
  var isToggling         = false.obs;

  /// جلب جميع المعلنين الذين تابعهم المستخدم
  Future<void> fetchFavorites({ required int userId }) async {
    isLoadingFavorites.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/advertiser-follows/user/$userId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
         final list = (result['data'] as List)
    .map((e) => FavoriteSeller.fromJson(e as Map<String, dynamic>))
    .toList();
favoriteList.value = list;
        }
      }
    } catch (e) {
      print('Exception fetchFavorites: $e');
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  /// متابعة أو إلغاء متابعة (toggle)
   /// متابعة أو إلغاء متابعة (toggle) باستخدام معرف المستخدم ومعرف المعلن فقط
  Future<bool> toggleFavoriteByIds({
    required int userId,
    required int advertiserProfileId,
  }) async {
    isToggling.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/advertiser-follows/toggle');
      final body = {
        'user_id': userId,
        'advertiser_profile_id': advertiserProfileId,
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          // optional: read action and follow_id
          final action = result['action'] as String?;
          final followId = result['follow_id'];

          debugPrint('toggleFavoriteByIds: action=$action followId=$followId');

          // أفضل طريقة: إعادة جلب قائمة المفضلات للمستخدم لتكون متزامنة مع الخادم
          await fetchFavorites(userId: userId);
           Get.snackbar('نجاح'.tr, 'تم متابعة المعلن بنجاح'.tr);

          return true;
        } else {

           Get.snackbar('فشل'.tr, 'لم يتم متابعة المعلن   '.tr);
          debugPrint('toggleFavoriteByIds: success == false, body: ${res.body}');
        }
      } else {
        debugPrint('toggleFavoriteByIds: status ${res.statusCode}, body: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('Exception toggleFavoriteByIds: $e\n$st');
    } finally {
      isToggling.value = false;
    }
    return false;
  }


  // =====================================================
  // هنا نبدأ إضافة دالة جلب إعلانات كل معلن حسب معرفه
  // =====================================================

  /// قائمة إعلانات المعلِن المفضل
  var advertiserAdsList       = <Ad>[].obs;
  var isLoadingAdvertiserAds = false.obs;
var adsCount = 0.obs;
var areasText = ''.obs;

Future<void> updateAdvertiserStats(List<Ad> ads, AreaController areaController) async {
  // عدد الإعلانات
  adsCount.value = ads.length;

  final Set<String> areas = <String>{};

  // 1) اجمع areaIds التي نحتاج لجلبها + حاول الحصول على الأسماء الموجودة حالياً
  final Map<int, int> areaIdToCityId = {}; // areaId -> cityId (إن وُجد)
  for (final ad in ads) {
    final int? areaId = (ad as dynamic).areaId as int?;
    if (areaId == null) continue;

    // حاول الحصول على الاسم مباشرة (لو المنطقة محمّلة في AreaController)
    final String? nameNow = areaController.getAreaNameById(areaId);
    if (nameNow != null && nameNow.isNotEmpty) {
      areas.add(nameNow);
      continue;
    }

    // الاسم غير متوفر الآن: حاول استخلاص cityId من الإعلان (fallbacks)
    final int? cityId = (ad as dynamic).city?.id as int? ?? (ad as dynamic).cityId as int?;
    if (cityId != null) {
      areaIdToCityId[areaId] = cityId;
    } else {
      // لو ما فيه cityId، حاول استخدام اسم المنطقة من داخل العنصر نفسه كـ fallback
      final String? fallbackName = (ad as dynamic).area?.name as String?;
      if (fallbackName != null && fallbackName.isNotEmpty) {
        areas.add(fallbackName);
      }
    }
  }

  // 2) جلب المناطق للمدن الناقصة (مرة واحدة لكل مدينة) — نفّذ بشكل متوازي
  final cityIdsToFetch = areaIdToCityId.values.toSet().toList();
  try {
    await Future.wait(cityIdsToFetch.map((cid) => areaController.getAreasOrFetch(cid)));
  } catch (e, st) {
    debugPrint('Warning: failed to fetch some areas for cities: $e\n$st');
    // لا نوقف التنفيذ — نستعمل ما توافر
  }

  // 3) بعد محاولة الجلب، مرّ مرة ثانية لجمع الأسماء (واستخدم fallback إن وجد)
  for (final ad in ads) {
    final int? areaId = (ad as dynamic).areaId as int?;
    if (areaId == null) continue;

    String? name = areaController.getAreaNameById(areaId);
    if (name == null || name.isEmpty) {
      // حاول fallback من داخل الإعلان نفسه
      name = (ad as dynamic).area?.name as String?;
    }
    if (name != null && name.isNotEmpty) {
      areas.add(name);
    }
  }

  // 4) ضع النتيجة في observable (أو اعد قيمة افتراضية)
  areasText.value = areas.isNotEmpty ? areas.join('، ') : 'لا توجد مناطق محددة'.tr;
}

 Future<void> fetchAdvertiserAds({
  required int advertiserProfileId,
  String lang    = 'ar',
  String status  = 'published',
  int page       = 1,
  int perPage    = 15,
}) async {
  isLoadingAdvertiserAds.value = true;
  try {
 final queryParameters = {
  'advertiser_profile_id': advertiserProfileId.toString(),
  'lang':     lang,
  'status':   status,
  'page':     page.toString(),
  'per_page': perPage.toString(),
};

final uri = Uri.parse('$_baseUrl/ads/advertiser/$advertiserProfileId')
    .replace(queryParameters: queryParameters);



    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final adResponse = AdResponse.fromJson(jsonData);
      advertiserAdsList.value = adResponse.data;


  final areaController = Get.find<AreaController>();
  updateAdvertiserStats(advertiserAdsList, areaController);
    } else {
      print('Error fetching advertiser ads, status: ${response.statusCode}');
      try {
        final err = json.decode(response.body) as Map<String, dynamic>;
        if (err.containsKey('errors')) {
          print('▶ Validation errors:');
          (err['errors'] as Map<String, dynamic>).forEach((field, msgs) {
            print(' - $field: ${(msgs as List).join(", ")}');
          });
        } else if (err.containsKey('message')) {
          print('▶ Message: ${err['message']}');
        } else {
          print('▶ Response body: ${response.body}');
        }
      } catch (parseError) {
        print('▶ Failed to parse error body: $parseError');
        print('▶ Raw body: ${response.body}');
      }
    }
  } catch (e) {
    print('Exception fetchAdvertiserAds: $e');
  } finally {
    isLoadingAdvertiserAds.value = false;
  }
}

}
