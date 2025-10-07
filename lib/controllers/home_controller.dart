import 'dart:convert';
import 'package:get/get.dart';
import '../core/data/model/Attribute.dart';
import '../core/data/model/category.dart' as cate;
import 'package:http/http.dart' as http;
import '../core/data/model/subcategory_level_one.dart';
import '../core/data/model/subcategory_level_two.dart';
import '../core/localization/changelanguage.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    isGetFirstTime.value = true;
  }

  void clearDeif() {
    nameOfMainCate.value = null;
    idOfMainCate.value = null;
    nameOfSubCate.value = null;
    idOfSubCate.value = null;
    nameOfSubTwo.value = null;
    idOFSubTwo.value = null;
  }

  // ==================== [واجهة API] ====================
  final String _baseUrl = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";


  // ==================== [دوال جلب البيانات] ====================
  Future<void> fetchCategories(String language) async {
    categoriesList.clear();
    isLoadingCategories.value = true;

    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/categories/$language'
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] as List<dynamic>;
          categoriesList.value = data
              .map((category) =>cate. Category.fromJson(category as Map<String, dynamic>))
              .toList();

          // تحديث الذاكرة المؤقتة
          for (var category in categoriesList) {
            _categoriesCache[category.id] = category;
          }
          
          // فتح جميع التصنيفات تلقائياً عند جلب البيانات
          expandedCategoryIds.value = categoriesList.map((c) => c.id).toList();
          
          // جلب التصنيفات الفرعية لجميع التصنيفات الرئيسية
          for (final category in categoriesList) {
            fetchSubcategories(category.id, Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
          }
        } else {
          print("Success false: ${jsonResponse['message']}");
        }
      } else {
        print("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  RxList<SubcategoryLevelOne> subCategories = <SubcategoryLevelOne>[].obs;
  RxBool isLoadingSubcategoryLevelOne = false.obs;

  Future<void> fetchSubcategories(int categoryId, String language) async {
    isLoadingSubcategoriesMap[categoryId] = true;
    isLoadingSubcategoryLevelOne.value = true;

    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/subcategories?category_id=$categoryId&language=$language',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          subCategoriesMap[categoryId] = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();

          subCategories.value = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          subCategoriesMap[categoryId] = [];
        }
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetchSubcategories: $e');
    } finally {
      isLoadingSubcategoriesMap[categoryId] = false;
      isLoadingSubcategoryLevelOne.value = false;
      subCategoriesMap.refresh();
    }
  }

  Future<void> fetchSubcategoriesLevelTwo(int Theid, String language) async {
    subCategoriesLevelTwo.clear();
    isLoadingSubcategoryLevelTwo.value = true;

    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/subcategories-level-two?sub_category_level_one_id=$Theid&language=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          subCategoriesLevelTwo.value = list
              .map((e) => SubcategoryLevelTwo.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          subCategoriesLevelTwo.clear();
        }
      } else {
        print('Error ${response.statusCode}');
      }
    } catch (e) {
      print('Exception fetchSubcategoriesLevelTwo: $e');
    } finally {
      isLoadingSubcategoryLevelTwo.value = false;
    }
  }

  // دالة آمنة للحصول على التصنيف الرئيسي
  Future<cate.Category> getMainCategory(int categoryId) async {
    // التحقق من وجود التصنيف في الذاكرة المؤقتة
    if (_categoriesCache.containsKey(categoryId)) {
      return _categoriesCache[categoryId]!;
    }
    
    // إذا لم يتم تحميل التصنيفات بعد
    if (categoriesList.isEmpty) {
      await fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    }
    
    // البحث في القائمة بعد التحميل
    final category = categoriesList.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => cate.Category(
        id: 0,
        translations: [ cate.Translation(name: "Unknown",language: 'ar',id: 0,description: '',categoryId: 0)],
        adsCount: 0,
        image: "",
        slug: '',
        date: ''
      ),
    );
    
    // تخزين في الذاكرة المؤقتة
    _categoriesCache[categoryId] = category;
    return category;
  }

  // ==================== [دوال التحكم في التصنيفات] ====================
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
          categoryId,
          Get.find<ChangeLanguageController>().currentLocale.value.languageCode
        );
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

  // ==================== [الدوال الجانبية] ====================
  final RxList<SubcategoryLevelOne> sidebarSubcategories = <SubcategoryLevelOne>[].obs;
  final RxBool isLoadingSidebar = false.obs;

  Future<void> fetchSidebarCategories(String language) async {
    isLoadingSidebar.value = true;
    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/categories/$language'
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] as List<dynamic>;
          categoriesList.value = data
              .map((category) =>cate. Category.fromJson(category as Map<String, dynamic>))
              .toList();
        } else {
          print("Success false: ${jsonResponse['message']}");
        }
      } else {
        print("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("Error fetching sidebar categories: $e");
    } finally {
      isLoadingSidebar.value = false;
    }
  }

  Future<void> fetchSidebarSubcategories(int categoryId, String language) async {
    sidebarSubcategories.clear();
    try {
      final response = await http.get(Uri.parse(
        '$_baseUrl/subcategories?category_id=$categoryId&language=$language',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          sidebarSubcategories.value = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Exception fetchSidebarSubcategories: $e');
    }
  }

  RxBool isServicesOrSettings = false.obs;

  void toggleDrawerType(bool isServices) {
    isServicesOrSettings.value = isServices;
  }
}