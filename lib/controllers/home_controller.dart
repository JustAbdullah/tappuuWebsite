import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/data/model/Attribute.dart';
import '../core/data/model/category.dart' as cate;
import 'package:http/http.dart' as http;
import '../core/data/model/subcategory_level_one.dart';
import '../core/data/model/subcategory_level_two.dart';
import '../core/localization/changelanguage.dart';

enum DrawerType { services, settings }

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // تخزين التصنيفات المفتوحة
  final RxList<int> expandedCategoryIds = <int>[].obs;
  final RxList<int> expandedSubCategoryIds = <int>[].obs;

  final RxBool isDesktop = false.obs;
  final RxBool isTablet = false.obs;
  final RxBool isMobile = false.obs;

  RxBool isGetFirstTime = false.obs;
  RxList<cate.Category> categoriesList = <cate.Category>[].obs;
  RxBool isLoadingCategories = false.obs;

  // تخزين التصنيفات الفرعية لكل تصنيف رئيسي
  final RxMap<int, List<SubcategoryLevelOne>> subCategoriesMap = <int, List<SubcategoryLevelOne>>{}.obs;

  // تتبع حالة التحميل لكل تصنيف
  final RxMap<int, bool> isLoadingSubcategoriesMap = <int, bool>{}.obs;

  RxList<SubcategoryLevelOne> subCategories = <SubcategoryLevelOne>[].obs;
  RxBool isLoadingSubcategoryLevelOne = false.obs;

  // التخزين الجديد للتصنيفات الفرعية من المستوى الثاني
  final RxMap<int, List<SubcategoryLevelTwo>> subCategoriesLevelTwoMap = <int, List<SubcategoryLevelTwo>>{}.obs;
  final RxMap<int, bool> isLoadingSubcategoriesLevelTwoMap = <int, bool>{}.obs;
  
  RxList<SubcategoryLevelTwo> subCategoriesLevelTwo = <SubcategoryLevelTwo>[].obs;
  RxBool isLoadingSubcategoryLevelTwo = false.obs;
  
  RxList<Attribute> attributes = <Attribute>[].obs;
  RxBool isLoadingAttributes = false.obs;

  Rx<String?> nameOfMainCate = Rx<String?>(null);
  Rx<int?> idOfMainCate = Rx<int?>(null);
  Rx<String?> nameOfSubCate = Rx<String?>(null);
  Rx<int?> idOfSubCate = Rx<int?>(null);
  Rx<String?> nameOfSubTwo = Rx<String?>(null);
  Rx<int?> idOFSubTwo = Rx<int?>(null);

  // تخزين مؤقت للتصنيفات الرئيسية
  final RxMap<int, cate.Category> _categoriesCache = <int, cate.Category>{}.obs;

  // ================= caching & period tracking ================
  final Map<int, String> lastAdsPeriodForCategory = {};
  final Map<int, String> lastAdsPeriodForSubOne = {};
  final Map<int, String> lastAdsPeriodForSubTwo = {};

  var currentAdsPeriod = ''.obs;

  // تتبع الحالة الحالية
  Rx<int?> currentCategoryId = Rx<int?>(null);
  Rx<int?> currentSubCategoryId = Rx<int?>(null);

  final String _baseUrl = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";

  @override
  void onInit() {
    super.onInit();
    if (!isGetFirstTime.value) {
      fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      isGetFirstTime.value = true;
    }
  }

  void clearDeif() {
    nameOfMainCate.value = null;
    idOfMainCate.value = null;
    nameOfSubCate.value = null;
    idOfSubCate.value = null;
    nameOfSubTwo.value = null;
    idOFSubTwo.value = null;
  }

  // ==================== [الدوال الجديدة المطلوبة] ====================

  void clearCategoryData(int categoryId) {
    subCategoriesMap.remove(categoryId);
    lastAdsPeriodForCategory.remove(categoryId);
    isLoadingSubcategoriesMap.remove(categoryId);
  }

  void clearSubCategoryData(int subCategoryId) {
    subCategoriesLevelTwoMap.remove(subCategoryId);
    lastAdsPeriodForSubOne.remove(subCategoryId);
    isLoadingSubcategoriesLevelTwoMap.remove(subCategoryId);
    subCategoriesLevelTwo.clear();
  }

  // الدوال الجديدة التي تستدعيها الواجهة
  bool isSubCategoriesLevelTwoLoading(int subCategoryId) {
    return isLoadingSubcategoriesLevelTwoMap[subCategoryId] ?? false;
  }

  List<SubcategoryLevelTwo> getSubCategoriesLevelTwoForSubCategory(int subCategoryId) {
    return subCategoriesLevelTwoMap[subCategoryId] ?? [];
  }

  int getSubCategoriesLevelTwoCountForSubCategory(int subCategoryId) {
    final list = getSubCategoriesLevelTwoForSubCategory(subCategoryId);
    return list.fold(0, (sum, subCategory) => sum + subCategory.adsCount);
  }

  // ==================== [دوال جلب البيانات المعدلة] ====================
Future<void> fetchCategories(
  String language, {
  String? adsPeriod,
}) async {
  // لو فيه تحميل شغال حالياً لا تكرر
  if (isLoadingCategories.value) return;

  isLoadingCategories.value = true;
  currentAdsPeriod.value = adsPeriod ?? '';

  try {
    Uri uri = Uri.parse('$_baseUrl/categories/$language');

    if (adsPeriod != null && adsPeriod.isNotEmpty) {
      uri = uri.replace(queryParameters: {'ads_period': adsPeriod});
    }

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse =
          json.decode(response.body);

      if (jsonResponse['status'] == 'success') {
        final List<dynamic> data =
            jsonResponse['data'] as List<dynamic>;

        /// ✅ نبني قائمة مؤقتة ثم نحدّث القائمة الأساسية مرة واحدة
        final loadedCategories = data
            .map((category) => cate.Category.fromJson(
                  category as Map<String, dynamic>,
                ))
            .toList();

        // نمسح الكاش السابق ونضيف الجديد
        _categoriesCache.clear();
        for (var category in loadedCategories) {
          _categoriesCache[category.id] = category;
        }

        // نحدّث الـ RxList مرة واحدة (بدون clear في حال فشل الريسبونس)
        categoriesList
          ..clear()
          ..addAll(loadedCategories);

        // نوسّع كل التصنيفات افتراضياً
        expandedCategoryIds.value =
            categoriesList.map((c) => c.id).toList();

        // ⚠️ تحميل التصنيفات الفرعية بالتسلسل لتقليل 429
        for (final category in categoriesList) {
          try {
            await fetchSubcategories(
              category.id,
              Get.find<ChangeLanguageController>()
                  .currentLocale
                  .value
                  .languageCode,
              adsPeriod: adsPeriod,
            );
          } catch (e, st) {
            debugPrint(
                '❌ fetchSubcategories error for category ${category.id}: $e');
            debugPrint('$st');
          }
        }
      } else {
        debugPrint(
            "❌ Success=false in categories: ${jsonResponse['message']}");
      }
    } else if (response.statusCode == 429) {
      debugPrint(
          "⚠️ fetchCategories -> 429 Too Many Requests (بنترك التصنيفات الحالية كما هي)");
      // مهم: ما نعمل clear() عشان الواجهة ما تفضى
    } else {
      debugPrint(
          "❌ Error ${response.statusCode} in categories: ${response.body}");
    }
  } on TimeoutException {
    debugPrint("⏱️ fetchCategories timeout");
  } catch (e, st) {
    debugPrint("❌ Error fetching categories: $e\n$st");
  } finally {
    isLoadingCategories.value = false;
  }
}


  Future<void> fetchSubcategories(int categoryId, String language, {String? adsPeriod, bool force = false, }) async {
    final String period = adsPeriod ?? '';

    final bool needsRefresh = force ||
        currentCategoryId.value != categoryId ||
        lastAdsPeriodForCategory[categoryId] != period ||
        !subCategoriesMap.containsKey(categoryId) ||
        subCategoriesMap[categoryId]?.isEmpty == true;

    if (!needsRefresh && subCategoriesMap.containsKey(categoryId)) {
      subCategories.value = subCategoriesMap[categoryId]!;
      return;
    }

    currentCategoryId.value = categoryId;
    lastAdsPeriodForCategory[categoryId] = period;
    currentAdsPeriod.value = period;

    isLoadingSubcategoriesMap[categoryId] = true;
    isLoadingSubcategoryLevelOne.value = true;

    try {
      Map<String, String> queryParams = {
        'category_id': categoryId.toString(),
        'language': language,
      };

      if (period.isNotEmpty) {
        queryParams['ads_period'] = period;
      }

      final uri = Uri.parse('$_baseUrl/subcategories').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          final fetched = list.map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>)).toList();

          subCategoriesMap[categoryId] = fetched;
          subCategories.value = fetched;
        } else {
          subCategoriesMap[categoryId] = [];
          subCategories.value = [];
        }
      } else {
        print('Error ${response.statusCode} when fetching subcategories for category $categoryId');
        subCategoriesMap[categoryId] = [];
        subCategories.value = [];
      }
    } catch (e, st) {
      print('Exception fetchSubcategories($categoryId): $e\n$st');
      lastAdsPeriodForCategory.remove(categoryId);
      subCategoriesMap[categoryId] = [];
      subCategories.value = [];
    } finally {
      isLoadingSubcategoriesMap[categoryId] = false;
      isLoadingSubcategoryLevelOne.value = false;
      subCategoriesMap.refresh();
    }
  }

  Future<void> fetchSubcategoriesLevelTwo(int subOneId, String language, {String? adsPeriod, bool force = false}) async {
    final String period = adsPeriod ?? '';

    final bool needsRefresh = force ||
        currentSubCategoryId.value != subOneId ||
        lastAdsPeriodForSubOne[subOneId] != period ||
        !subCategoriesLevelTwoMap.containsKey(subOneId) ||
        subCategoriesLevelTwoMap[subOneId]?.isEmpty == true;

    if (!needsRefresh && subCategoriesLevelTwoMap.containsKey(subOneId)) {
      subCategoriesLevelTwo.value = subCategoriesLevelTwoMap[subOneId]!;
      return;
    }

    currentSubCategoryId.value = subOneId;
    lastAdsPeriodForSubOne[subOneId] = period;
    currentAdsPeriod.value = period;

    isLoadingSubcategoriesLevelTwoMap[subOneId] = true;
    isLoadingSubcategoryLevelTwo.value = true;

    try {
      Map<String, String> queryParams = {
        'sub_category_level_one_id': subOneId.toString(),
        'language': language,
      };

      if (period.isNotEmpty) {
        queryParams['ads_period'] = period;
      }

      final uri = Uri.parse('$_baseUrl/subcategories-level-two').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          final fetched = list.map((e) => SubcategoryLevelTwo.fromJson(e as Map<String, dynamic>)).toList();

          subCategoriesLevelTwoMap[subOneId] = fetched;
          subCategoriesLevelTwo.value = fetched;
        } else {
          subCategoriesLevelTwoMap[subOneId] = [];
          subCategoriesLevelTwo.clear();
        }
      } else {
        print('Error ${response.statusCode} when fetching subcategories level two for subOne $subOneId');
        subCategoriesLevelTwoMap[subOneId] = [];
        subCategoriesLevelTwo.clear();
      }
    } catch (e, st) {
      print('Exception fetchSubcategoriesLevelTwo($subOneId): $e\n$st');
      lastAdsPeriodForSubOne.remove(subOneId);
      subCategoriesLevelTwoMap[subOneId] = [];
      subCategoriesLevelTwo.clear();
    } finally {
      isLoadingSubcategoriesLevelTwoMap[subOneId] = false;
      isLoadingSubcategoryLevelTwo.value = false;
      subCategoriesLevelTwoMap.refresh();
    }
  }

  // ==================== [الدوال المساعدة الموجودة] ====================

  List<SubcategoryLevelOne> getSubCategoriesForCategory(int categoryId) {
    return subCategoriesMap[categoryId] ?? [];
  }

  bool isSubCategoriesLoading(int categoryId) {
    return isLoadingSubcategoriesMap[categoryId] ?? false;
  }

  int getSubCategoriesCountForCategory(int categoryId) {
    final list = getSubCategoriesForCategory(categoryId);
    return list.fold(0, (sum, subCategory) => sum + subCategory.adsCount);
  }

  // ==================== [بقية الدوال الموجودة] ====================

  Future<cate.Category> getMainCategory(int categoryId) async {
    if (_categoriesCache.containsKey(categoryId)) {
      return _categoriesCache[categoryId]!;
    }

    if (categoriesList.isEmpty) {
      await fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    }

    final category = categoriesList.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => cate.Category(
          id: 0,
          translations: [
            cate.Translation(name: "Unknown", language: 'ar', id: 0, description: '', categoryId: 0)
          ],
          adsCount: 0,
          image: "",
          slug: '',
          date: ''),
    );

    _categoriesCache[categoryId] = category;
    return category;
  }

  bool isCategoryExpanded(int categoryId) {
    return expandedCategoryIds.contains(categoryId);
  }

  void toggleCategory(int categoryId) {
    if (expandedCategoryIds.contains(categoryId)) {
      expandedCategoryIds.remove(categoryId);
    } else {
      expandedCategoryIds.add(categoryId);

      if (!subCategoriesMap.containsKey(categoryId)) {
        fetchSubcategories(
            categoryId, Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
            adsPeriod: currentAdsPeriod.value);
      }
    }
  }

  bool isSubCategoryExpanded(int subCategoryId) {
    return expandedSubCategoryIds.contains(subCategoryId);
  }

  void toggleSubCategory(int subCategoryId) {
    if (expandedSubCategoryIds.contains(subCategoryId)) {
      expandedSubCategoryIds.remove(subCategoryId);
    } else {
      expandedSubCategoryIds.add(subCategoryId);
    }
  }

  final RxList<SubcategoryLevelOne> sidebarSubcategories = <SubcategoryLevelOne>[].obs;
  final RxBool isLoadingSidebar = false.obs;

  Future<void> fetchSidebarCategories(String language) async {
    isLoadingSidebar.value = true;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/$language'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] as List<dynamic>;
          categoriesList.value = data
              .map((category) => cate.Category.fromJson(category as Map<String, dynamic>))
              .toList();
        } else {
          print("Success false: ${jsonResponse['message']}");
        }
      } else {
        print("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e, st) {
      print("Error fetching sidebar categories: $e\n$st");
    } finally {
      isLoadingSidebar.value = false;
    }
  }

  Future<void> fetchSidebarSubcategories(int categoryId, String language) async {
    sidebarSubcategories.clear();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/subcategories?category_id=$categoryId&language=$language'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          sidebarSubcategories.value = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e, st) {
      print('Exception fetchSidebarSubcategories: $e\n$st');
    }
  }


////Open Settings And Services..///


 final drawerType = DrawerType.services.obs;

  void openServicesDrawer(GlobalKey<ScaffoldState> scaffoldKey) {
    drawerType.value = DrawerType.services;
    _openDrawer(scaffoldKey);
  }

  void openSettingsDrawer(GlobalKey<ScaffoldState> scaffoldKey) {
    drawerType.value = DrawerType.settings;
    _openDrawer(scaffoldKey);
  }

  void _openDrawer(GlobalKey<ScaffoldState> scaffoldKey) {
    // نضمن إنه يتم الفتح بعد تحديث الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffoldKey.currentState?.openEndDrawer();
    });
  }


  Future<void> fetchAttributes(int categoryId, String language) async {
    attributes.clear();

    if (attributes.isEmpty) {
      isLoadingAttributes.value = true;
      try {
        final uri = Uri.parse(
            '$_baseUrl/categories/$categoryId/attributes?lang=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data != null && data is Map<String, dynamic> && data['success'] == true) {
            final List<dynamic> list = data['attributes'];
            attributes.value = list
                .map((json) => Attribute.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            attributes.clear();
          }
        } else {
          print('HTTP ${response.statusCode}');
        }
      } catch (e, st) {
        print(e);
      } finally {
        isLoadingAttributes.value = false;
      }
    }
  }

  int get totalSubCategoriesAdsCount {
    return subCategories.fold(0, (sum, subCategory) => sum + subCategory.adsCount);
  }

  void resetSubcategoriesForCategory(int categoryId) {
    lastAdsPeriodForCategory.remove(categoryId);
    subCategoriesMap[categoryId]?.clear();
    subCategoriesMap.refresh();
    subCategories.clear();
  }

  void resetSubcategoriesLevelTwoForSubOne(int subOneId) {
    lastAdsPeriodForSubOne.remove(subOneId);
    subCategoriesLevelTwoMap.remove(subOneId);
    subCategoriesLevelTwo.clear();
  }

  void resetAdsPeriod() {
    currentAdsPeriod.value = '';
  }

  void setAdsPeriod(String period) {
    currentAdsPeriod.value = period;
  }

   // ------ مسح بيانات التصنيفات الفرعية فقط ------
  void clearSubCategories() {
    subCategories.clear();
    subCategoriesLevelTwo.clear();
    currentSubCategoryId.value = null;
  }

  // ------ مسح بيانات المستوى الثاني فقط ------
  void clearSubCategoriesLevelTwo() {
    subCategoriesLevelTwo.clear();
  }

}