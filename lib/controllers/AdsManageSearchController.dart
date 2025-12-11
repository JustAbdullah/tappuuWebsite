import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as fo;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tappuu_website/core/data/model/subcategory_level_two.dart';
import '../core/data/model/AdResponse.dart';
import '../core/data/model/Area.dart' as area;
import '../core/data/model/CategoryAttributesResponse.dart';
import '../core/data/model/City.dart';
import '../core/data/model/category.dart';
import '../core/data/model/subcategory_level_one.dart';
import '../core/localization/changelanguage.dart';
import 'dart:html' as html;

class AdsController extends GetxController {

  /// نستخدمها لكي نضمن أن سكاشن الهوم تنطلب مرة واحدة عند نجاح التحميل فقط
final RxBool homeInitialized = false.obs;
final RxBool homeLoading = false.obs;

Future<void> ensureHomeInitialized() async {
  // لا تكرر لو جاري تحميل
  if (homeLoading.value) return;

  // لو سبق وتحملت بنجاح، خلاص
  if (homeInitialized.value) return;

  homeLoading.value = true;

  try {
    // ✅ نخلي الطلبات "تسلسلية" بدل Future.wait (لتخفيف ضغط 429)
    await loadFeaturedAds();                 // الإعلانات المميزة
    await fetchLatestAds();                  // أحدث الإعلانات
    await fetchAdsByCategory(categoryId: 1); // عقارات للبيع
    await fetchAdsByCategory(categoryId: 2); // عقارات للإيجار
    await fetchAdsByCategory(categoryId: 3); // مركبات للبيع
    await fetchAdsByCategory(categoryId: 4); // مركبات للإيجار

    // فقط لو كل شيء عدّى بدون استثناء نوصل هنا
    homeInitialized.value = true;
  } catch (e, st) {
    debugPrint('❌ ensureHomeInitialized error: $e');
    debugPrint('$st');
    // مهم: لا نغيّر homeInitialized هنا
    // بحيث لو صار Error (مثلاً 429) نقدر نحاول مرة ثانية لاحقاً
  } finally {
    homeLoading.value = false;
  }
}



   RxBool showMap = false.obs;

  // ==================== متغيرات 'طريقة العرض'.tr ====================
  var viewMode = 'list'.obs;
  void changeViewMode(String mode) => viewMode.value = mode;
  var currentAttributes = <Map<String, dynamic>>[].obs;

  // ==================== إعدادات API ====================
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  
  // ==================== قوائم البيانات الرئيسية ====================
  var adsList = <Ad>[].obs;

  var filteredAdsList = <Ad>[].obs;
  RxBool isLoadingAds = false.obs;
  var allAdsList = <Ad>[].obs;

  // ==================== قائمة الإعلانات المميزة ====================
  var featuredAds = <Ad>[].obs;
  RxBool isLoadingFeatured = false.obs;

  // فترة الجلب: '24h', '48h' أو null
  Rxn<String> currentTimeframe = Rxn<String>();
  // هل نريد فقط الإعلانات المميزة؟
  RxBool onlyFeatured = false.obs;

  // ==================== إدارة البحث ====================
  var currentSearch = ''.obs;
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  RxBool isSearching = false.obs;
  RxBool serverSideSearchEnabled = true.obs;

  // ==================== معايير الجلب الحالية ====================
  var currentCategoryId = 0.obs;
  var currentSubCategoryLevelOneId = Rxn<int>();
  var currentSubCategoryLevelTwoId = Rxn<int>();
  var currentLang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
  
  // ==================== إضافة المتغيرات الناقصة ====================
  var currentSortBy = Rxn<String>();
  var currentOrder = 'desc'.obs;
  
  // ==================== إدارة الموقع الجغرافي ====================
  Rxn<double> latitude = Rxn<double>();
  Rxn<double> longitude = Rxn<double>();
  RxBool isLoadingLocation = false.obs;
  RxDouble selectedRadius = RxDouble(0.0);
  final List<double> radiusOptions = [1, 5, 10, 20, 50];
  Timer? _filterTimer; // إضافة مؤقت للفلترة الجغرافية

  // ==================== إدارة المدن والمناطق ====================
  var citiesList = <TheCity>[].obs;
  var isLoadingCities = false.obs;
  var selectedCity = Rxn<TheCity>();       // المدينة المختارة
  var selectedArea = Rxn<area.Area>();   

  // ==================== إدارة التصنيفات ====================
  var mainCategories = <Category>[].obs;
  var subCategories = <SubcategoryLevelOne>[].obs;
  var subTwoCategories = <SubcategoryLevelTwo>[].obs;
  RxnInt selectedMainCategoryId = RxnInt();
  RxnInt selectedSubCategoryId = RxnInt();
  RxnInt selectedSubTwoCategoryId = RxnInt();

  RxBool isLoadingMainCategories = false.obs;
  RxBool isLoadingSubCategories = false.obs;
  RxBool isLoadingSubTwoCategories = false.obs;

  // ==================== إدارة السمات ====================
  var attributesList = <CategoryAttribute>[].obs;
  RxBool isLoadingAttributes = false.obs;
  RxBool isGetData = false.obs;

  @override
  void onInit() {
    super.onInit();
        loadFeaturedAds();

    if (!isGetData.value) {
      _loadDataConcurrently();
      isGetData.value = true;
    }

    currentSearch.listen((query) {
      if (query.isEmpty) {
        filteredAdsList.assignAll(adsList);
      } else {
        if (serverSideSearchEnabled.value) {
          _searchDebounceTimer?.cancel();
          _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
            fetchAds(
              categoryId: currentCategoryId.value,
              subCategoryLevelOneId: currentSubCategoryLevelOneId.value,
              subCategoryLevelTwoId: currentSubCategoryLevelTwoId.value,
              search: query,
              lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
            );
          });
        } else {
          _localSearch(query);
        }
      }
    });
  }

  // ==================== تحميل البيانات المتوازي ====================
  Future<void> _loadDataConcurrently() async {
    try {
      await Future.wait([
        _loadFeaturedAds(),
        fetchLatestAds(),
        _fetchInitialCategoriesParallel(),
        fetchMainCategories("ar"),
      ]);
      print('✅ جميع البيانات جاهزة');
    } catch (e) {
      print('‼️ خطأ في التحميل المتوازي: $e');
    }
  }

  // ==================== جلب التصنيفات الرئيسية ====================
  Future<void> fetchMainCategories(String language) async {
    isLoadingMainCategories.value = true;
    print("isStart");
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories/$language'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> categoriesData = [];
        
        if (data is List) {
          categoriesData = data;
        } else if (data is Map && data.containsKey('data')) {
          categoriesData = data['data'];
        }
        
        mainCategories.assignAll(
          categoriesData.map((e) => Category.fromJson(e)).toList()
        );
        
        if (currentCategoryId.value > 0) {
          selectedMainCategoryId?.value = currentCategoryId.value;
          fetchSubCategories(currentCategoryId.value,"ar");
        }
      }
    } catch (e) {
      print('خطأ في جلب التصنيفات الرئيسية: $e');
    } finally {
      isLoadingMainCategories.value = false;
    }

    print("isEnd");
  }

  var categoriesList = <Category>[].obs;
  var isLoadingCategories = false.obs;
  var selectedMainCategory = Rxn<Category>();
  // جلب التصنيفات الرئيسية
  Future<void> fetchCategories(String language) async {
    isLoadingCategories.value = true;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/$language'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var fetchedCategories = (data['data'] as List)
            .map((category) => Category.fromJson(category))
            .toList();
        categoriesList.value = fetchedCategories;
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // ==================== جلب التصنيفات الفرعية ====================
  Future<void> fetchSubCategories(int parentId, String language) async {
    isLoadingSubCategories.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subcategories?category_id=$parentId&language=$language'),
        headers: {'Accept': 'application/json'},
      );
      
     
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          subCategories.value = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();}
        
        if (currentSubCategoryLevelOneId.value != null) {
          selectedSubCategoryId?.value = currentSubCategoryLevelOneId.value!;
          fetchSubTwoCategories(currentSubCategoryLevelOneId.value!);
        }
      }
    } catch (e) {
      print('خطأ في جلب التصنيفات الفرعية: $e');
    } finally {
      isLoadingSubCategories.value = false;
    }
  }

  // ==================== جلب التصنيفات الفرعية الثانوية ====================
  Future<void> fetchSubTwoCategories(int parentId) async {
    isLoadingSubTwoCategories.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subcategories-level-two?sub_category_level_one_id=$parentId&language=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> subTwoCategoriesData = [];
        
        if (data is List) {
          subTwoCategoriesData = data;
        } else if (data is Map && data.containsKey('data')) {
          subTwoCategoriesData = data['data'];
        }
        
        subTwoCategories.assignAll(
          subTwoCategoriesData.map((e) => SubcategoryLevelTwo.fromJson(e)).toList()
        );
        
        if (currentSubCategoryLevelTwoId.value != null) {
          selectedSubTwoCategoryId?.value = currentSubCategoryLevelTwoId.value!;
        }
      }
    } catch (e) {
      print('خطأ في جلب التصنيفات الفرعية الثانوية: $e');
    } finally {
      isLoadingSubTwoCategories.value = false;
    }
  }

  // ==================== تحديث التصنيفات عند الاختيار ====================
  void updateMainCategory(int? categoryId) {
    selectedMainCategoryId?.value = categoryId!;
    selectedSubCategoryId?.value = null;
    selectedSubTwoCategoryId?.value = null;
    currentCategoryId.value = categoryId ?? 0;
    
    if (categoryId != null) {
            fetchAttributes(categoryId: categoryId, lang: "ar");

      fetchSubCategories(categoryId,"ar");
    } else {
      subCategories.clear();
      subTwoCategories.clear();
    }
    
    fetchAds(
      categoryId: categoryId,
      lang: currentLang,
    );
  }

  void updateSubCategory(int? subCategoryId) {
    selectedSubCategoryId?.value = subCategoryId;
    selectedSubTwoCategoryId?.value = null;
    currentSubCategoryLevelOneId.value = subCategoryId;
    
    if (subCategoryId != null) {
      fetchSubTwoCategories(subCategoryId);
    } else {
      subTwoCategories.clear();
    }
    
    fetchAds(
      categoryId: selectedMainCategoryId?.value,
      subCategoryLevelOneId: subCategoryId,
      lang: currentLang,
    );
  }

  void updateSubTwoCategory(int? subTwoCategoryId) {
    selectedSubTwoCategoryId?.value = subTwoCategoryId;
    currentSubCategoryLevelTwoId.value = subTwoCategoryId;
    
    fetchAds(
      categoryId: selectedMainCategoryId?.value,
      subCategoryLevelOneId: selectedSubCategoryId?.value,
      subCategoryLevelTwoId: subTwoCategoryId,
      lang: currentLang,
    );
  }

  // ==================== البحث المحلي ====================
  void _localSearch(String query) {
    final lowerQuery = query.toLowerCase();
    filteredAdsList.assignAll(adsList.where((ad) {
      return ad.title.toLowerCase().contains(lowerQuery) ||
             ad.description.toLowerCase().contains(lowerQuery) ||
             (ad.price != null && _formatPrice(ad.price!).toLowerCase().contains(lowerQuery)) ||
             (ad.city?.name.toLowerCase().contains(lowerQuery) ?? false);
    }).toList());
  }

/*نسخة الويب القديم
  // ==================== جلب الإعلانات (الوظيفة الأساسية) ====================
  Future<void> fetchAds({
  // التصنيفات
  int? categoryId,
  int? subCategoryLevelOneId,
  int? subCategoryLevelTwoId,

  // البحث والفرز
  String? search,
  String? sortBy,        // 'price', 'date', 'views', ...
  String order = 'desc', // 'asc' أو 'desc'

  // الفلترة الجغرافية
  int? cityId,
  int? areaId,

  // فلترة السمات
  List<Map<String, dynamic>>? attributes,

  // **الفلاتر الجديدة**
  String? timeframe,     // '24h', '48h' أو null (كل الإعلانات)
  bool onlyFeatured = false, // جلب المميزة فقط؟

  // إعدادات عامة
  required String lang,
  int page = 1,
  int perPage = 15,
}) async {
  // 1) حفظ الحالة بمحاذاة الـ Rx
  currentCategoryId.value            = categoryId??0;
  currentSubCategoryLevelOneId.value = subCategoryLevelOneId;
  currentSubCategoryLevelTwoId.value = subCategoryLevelTwoId;
  currentSearch.value                = search?.trim() ?? '';
  currentSortBy.value                = sortBy;
  currentOrder.value                 = order;
  // (cityId, areaId, attributes handled similarly إذا كنت تستخدمهم في الواجهة)
  currentTimeframe.value             = timeframe;
  this.onlyFeatured.value            = onlyFeatured;
  currentLang                        = lang;

  isLoadingAds.value = true;
  try {
    // 2) قرر متى تستخدم POST /ads/filter
    final bool useFilterEndpoint = 
         categoryId != null
      || subCategoryLevelOneId != null
      || subCategoryLevelTwoId != null
      || (search?.isNotEmpty ?? false)
      || sortBy != null
      || cityId != null
      || areaId != null
      || (attributes != null && attributes.isNotEmpty)
      || onlyFeatured
      || (timeframe != null && timeframe != 'all');

    late http.Response response;

    if (useFilterEndpoint) {
      // === POST إلى /ads/filter ===
      final uri = Uri.parse('$_baseUrl/ads/filter');
      final body = <String, dynamic>{
        if (categoryId != null)            'category_id':             categoryId,
        if (subCategoryLevelOneId != null) 'sub_category_level_one_id': subCategoryLevelOneId,
        if (subCategoryLevelTwoId != null) 'sub_category_level_two_id': subCategoryLevelTwoId,
        if (search?.isNotEmpty ?? false)   'search':                    search!.trim(),
        if (sortBy != null)                'sort_by':                   sortBy,
        'order':                           order,
        if (cityId != null)                'city_id':                   cityId,
        if (areaId != null)                'area_id':                   areaId,
        if (attributes != null && attributes.isNotEmpty)
                                           'attributes':                attributes,
        if (timeframe != null && timeframe != 'all')
                                           'timeframe':                 timeframe,
        if (onlyFeatured)                  'only_featured':             true,
        'lang':                            lang,
        'page':                            page,
        'per_page':                        perPage,
      };

      print('📤 [POST REQUEST] URL: $uri');
      print('📤 [POST BODY] ${json.encode(body)}');

      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } else {
      // === GET إلى /ads ===
      final params = <String, String>{
        'lang':      lang,
        'page':      page.toString(),
        'per_page':  perPage.toString(),
        'order':     order,
      };
      // لا نضيف categoryId أو أي فلتر آخر هنا
      final uri = Uri.parse('$_baseUrl/ads').replace(queryParameters: params);
      print('📤 [GET REQUEST] URL: $uri');
      response = await http.get(uri);
    }

    // 3) تسجيل الاستجابة
    print('📥 [RESPONSE] Status: ${response.statusCode}');
    print('📥 [RESPONSE BODY] ${response.body}');

    // 4) المعالجة
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final rawList = (jsonData['data'] as List<dynamic>);
      print('✅ [DATA COUNT] ${rawList.length} items');

      final adResponse = AdResponse.fromJson({'data': rawList});
      adsList.value         = adResponse.data;
      filteredAdsList.value = adResponse.data;
    } else {
      print('❌ [ERROR] HTTP ${response.statusCode}');
      Get.snackbar("خطأ", "تعذّر جلب الإعلانات (${response.statusCode})");
    }
  } catch (e, st) {
    print('‼️ [EXCEPTION] $e');
    print(st);
    Get.snackbar("خطأ", "حدث خطأ أثناء جلب الإعلانات");
  } finally {
    isLoadingAds.value = false;
  }
}
*/




// ==================== جلب الإعلانات (الوظيفة الأساسية) ====================
Future<void> fetchAds({
  // التصنيفات
  int? categoryId,
  int? subCategoryLevelOneId,
  int? subCategoryLevelTwoId,

  // البحث والفرز
  String? search,
  String? sortBy,        // 'price_asc','price_desc','newest',...
  String order = 'desc',

  // الجغرافيا
  double? latitude,
  double? longitude,
  double? distanceKm,

  // السمات
  List<Map<String, dynamic>>? attributes,

  // المدينة/المنطقة
  int? cityId,
  int? areaId,

  // الفلاتر الجديدة
  String? timeframe,
  bool onlyFeatured = false,

  // ✅ السعر
  double? priceMin,
  double? priceMax,

  // عام
  required String lang,
  int page = 1,
  int perPage = 15,
}) async {
  // 1) حفظ حالة أساسية
  currentCategoryId.value            = categoryId ?? 0;
  currentSubCategoryLevelOneId.value = subCategoryLevelOneId;
  currentSubCategoryLevelTwoId.value = subCategoryLevelTwoId;
  currentSearch.value                = search?.trim() ?? '';
  currentSortBy.value                = sortBy;
  currentOrder.value                 = order;

  currentAttributes.value            = attributes ?? [];
  currentTimeframe.value             = timeframe;
  this.onlyFeatured.value            = onlyFeatured;
  currentLang                        = lang;

  isLoadingAds.value = true;
  try {
    final bool useFilterEndpoint =
         categoryId != null
      || subCategoryLevelOneId != null
      || subCategoryLevelTwoId != null
      || (search?.isNotEmpty ?? false)
      || sortBy != null
      || latitude != null
      || longitude != null
      || distanceKm != null
      || (attributes != null && attributes.isNotEmpty)
      || cityId != null
      || areaId != null
      || onlyFeatured
      || (timeframe != null && timeframe != 'all')
      || priceMin != null
      || priceMax != null;

    late http.Response response;

    if (useFilterEndpoint) {
      final uri = Uri.parse('$_baseUrl/ads/filter');
      final body = <String, dynamic>{
        if (categoryId != null)            'category_id':               categoryId,
        if (subCategoryLevelOneId != null) 'sub_category_level_one_id': subCategoryLevelOneId,
        if (subCategoryLevelTwoId != null) 'sub_category_level_two_id': subCategoryLevelTwoId,
        if (search?.isNotEmpty ?? false)   'search':                    search!.trim(),
        if (sortBy != null)                'sort_by':                   sortBy,
        'order':                           order,
        if (latitude  != null)             'latitude':                  latitude,
        if (longitude != null)             'longitude':                 longitude,
        if (distanceKm!= null)             'distance':                  distanceKm,
        if (attributes != null && attributes.isNotEmpty)
                                           'attributes':                attributes,
        if (cityId != null)                'city_id':                   cityId,
        if (areaId != null)                'area_id':                   areaId,
        if (timeframe != null && timeframe != 'all')
                                           'timeframe':                 timeframe,
        if (onlyFeatured)                  'only_featured':             true,
        // ✅ السعر
        if (priceMin != null)              'price_min':                 priceMin,
        if (priceMax != null)              'price_max':                 priceMax,
        'lang':                            lang,
        'page':                            page,
        'per_page':                        perPage,
      };

      print('📤 [POST REQUEST] URL: $uri');
      print('📤 [POST BODY] ${json.encode(body)}');

      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } else {
      final params = <String, String>{
        'lang':     lang,
        'page':     page.toString(),
        'per_page': perPage.toString(),
        'order':    order,
      };
      final uri = Uri.parse('$_baseUrl/ads').replace(queryParameters: params);
      print('📤 [GET REQUEST] URL: $uri');
      response = await http.get(uri);
    }

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final rawList = (jsonData['data'] as List<dynamic>);
      var ads = AdResponse.fromJson({'data': rawList}).data;

      // ترتيب حسب قرب الموقع إن أُرسل
      if (latitude != null && longitude != null) {
        double _deg2rad(double deg) => deg * pi / 180;
        double haversine(double lat1, double lng1, double lat2, double lng2) {
          const R = 6371;
          final dLat = _deg2rad(lat2 - lat1);
          final dLon = _deg2rad(lng2 - lng1);
          final a = sin(dLat/2)*sin(dLat/2)
                  + cos(_deg2rad(lat1))*cos(_deg2rad(lat2))
                  * sin(dLon/2)*sin(dLon/2);
          final c = 2*atan2(sqrt(a), sqrt(1 - a));
          return R*c;
        }

        ads.sort((a, b) {
          final da = haversine(latitude, longitude, a.latitude!, a.longitude!);
          final db = haversine(latitude, longitude, b.latitude!, b.longitude!);
          return da.compareTo(db);
        });
      }

      adsList.value         = ads;
      filteredAdsList.value = ads;
      allAdsList.value      = ads;
    } else {
      print('❌ [ERROR] HTTP ${response.statusCode}');
      Get.snackbar("خطأ", "تعذّر جلب الإعلانات (${response.statusCode})");
    }
  } catch (e, st) {
    print('‼️ [EXCEPTION] $e');
    print(st);
    Get.snackbar("خطأ", "حدث خطأ أثناء جلب الإعلانات");
  } finally {
    isLoadingAds.value = false;
  }
}


///
  /// دالة تحميل الإعلانات المميزة (POST /ads/filter)
  Future<void> _loadFeaturedAds() async {
    isLoadingFeatured.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/ads/filter');
      final body = {
        'only_featured': true,
        'per_page':      7,
        'lang':          Get.find<ChangeLanguageController>()
                            .currentLocale
                            .value
                            .languageCode,
        'timeframe':     'all',
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        featuredAds.assignAll(AdResponse.fromJson({'data': data}).data);
      }
    } catch (e) {
      print('‼️ Featured exception: $e');
    } finally {
      isLoadingFeatured.value = false;
    }
  }



  // ==================== وظائف الموقع الجغرافي ====================
  
  Future<void> ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        Get.snackbar("خطأ", "يرجى منح إذن الوصول إلى الموقع الجغرافي");
      }
    }
  }
  
  Future<void> fetchCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      await ensureLocationPermission();
      
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.snackbar("خطأ", "يرجى تفعيل خدمة الموقع الجغرافي");
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () async {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium
        );
      });
      
      latitude.value = position.latitude;
      longitude.value = position.longitude;
    } catch (e) {
      Get.snackbar("خطأ", "تعذر الحصول على الموقع: ${e.toString()}");
    } finally {
      isLoadingLocation.value = false;
    }
  }
  
  /*void applyLocationFilter(double radius) {
    selectedRadius.value = radius;
    
    if (latitude.value != null && longitude.value != null) {
      fetchAds(
        lat: latitude.value,
        lng: longitude.value,
        radius: radius,
        lang: currentLang,
      );
    } else {
      Get.snackbar("تحذير", "يرجى تحديد الموقع أولاً");
    }
  }*/

  
  
  
  void clearLocation() {
    latitude.value = null;
    longitude.value = null;
    selectedRadius.value = 0.0;
  }

  // ==================== وظائف السمات ====================
  Future<void> fetchAttributes({
    required int categoryId,
    String lang = 'ar',
  }) async {
    isLoadingAttributes.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/categories/$categoryId/attributes')
          .replace(queryParameters: {'lang': lang});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        CategoryAttributesResponse resp;
        
        if (jsonData is Map<String, dynamic>) {
          resp = CategoryAttributesResponse.fromJson(jsonData);
        } else {
          resp = CategoryAttributesResponse(
            success: true,
            attributes: (jsonData as List)
                .map((e) => CategoryAttribute.fromJson(e))
                .toList(),
          );
        }
        
        if (resp.success) {
          attributesList.value = resp.attributes;
        }
      }
    } catch (e) {
      print('خطأ في جلب السمات: $e');
    } finally {
      isLoadingAttributes.value = false;
    }
  }

  // ==================== وظائف المدن والمناطق ====================
  Future<void> fetchCities(String countryCode, String language) async {
    isLoadingCities.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cities/$countryCode/$language')
      );
      
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        
        if (decodedData is List) {
          citiesList.value = decodedData
            .map((jsonCity) => TheCity.fromJson(jsonCity))
            .toList();
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          final List<dynamic> listJson = decodedData['data'];
          citiesList.value = listJson
            .map((jsonCity) => TheCity.fromJson(jsonCity))
            .toList();
        } else if (decodedData is Map && decodedData.containsKey('cities')) {
          final List<dynamic> listJson = decodedData['cities'];
          citiesList.value = listJson
            .map((jsonCity) => TheCity.fromJson(jsonCity))
            .toList();
        }
      }
    } catch (e) {
      print("خطأ في جلب المدن: $e");
    } finally {
      isLoadingCities.value = false;
    }
  }
  

  void selectCity(TheCity? city) {
    selectedCity.value = city;
    selectedArea.value = null;
  }
  
  void selectArea(area.Area? area) {
    selectedArea.value = area;
  }

  // ==================== وظائف إضافية ====================
  Future<int> incrementViews(int adId) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}/ads/$adId/views')
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['views'] as int;
      } else {
        throw Exception('فشل في زيادة المشاهدات: ${response.statusCode}');
      }
    } catch (e) {
      print("خطأ في زيادة المشاهدات: $e");
      rethrow;
    }
  }

  // ==================== أدوات مساعدة ====================
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف';
    }
    return price.toStringAsFixed(0);
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    _filterTimer?.cancel();
    super.onClose();
  }
  
  /// يمسح كل الفلاتر ويعيد القيم إلى الافتراضي
  void clearAllFilters() {
    currentSearch.value = '';
    searchController.clear();
    isSearching.value = false;
    currentAttributes.clear();
    selectedCity.value = null;
    selectedArea.value = null;
    currentSortBy.value = null;
    currentOrder.value = 'desc';
    clearLocation();
  }

  // ==================== إدارة الإعلانات حسب التصنيف ====================
  var categoryAdsMap = <int, List<Ad>>{}.obs;
  var isLoadingCategoryMap = <int, bool>{}.obs;

 Future<void> fetchAdsByCategory({
  required int categoryId,
  int count = 7,
}) async {
  // لو فيه تحميل شغال لهذا التصنيف لا تكرر
  if (isLoadingCategoryMap[categoryId] == true) return;

  // لو عندك بيانات قديمة ومبسوط عليها وما تبغى تعيد التحميل:
  if (categoryAdsMap.containsKey(categoryId)) return;

  isLoadingCategoryMap[categoryId] = true;
  try {
    final uri = Uri.parse('$_baseUrl/ads/filter');
    final body = {
      'category_id': categoryId,
      'sort_by': 'newest',
      'order': 'desc',
      'per_page': count,
      'lang': Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode,
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final rawList = jsonData['data'] as List<dynamic>;
      // ✅ نحدّث الماب فقط عند نجاح الريسبونس
      categoryAdsMap[categoryId] =
          AdResponse.fromJson({'data': rawList}).data;
    } else if (response.statusCode == 429) {
      debugPrint(
          '⚠️ fetchAdsByCategory($categoryId) -> 429 Too Many Requests (بنخلي الداتا الحالية كما هي)');
    } else {
      debugPrint(
          '❌ fetchAdsByCategory($categoryId) error ${response.statusCode}: ${response.body}');
    }
  } on TimeoutException {
    debugPrint('⏱️ تم تجاوز وقت تحميل التصنيف $categoryId');
  } catch (e, st) {
    debugPrint('❌ حدث خطأ أثناء جلب إعلانات التصنيف $categoryId: $e');
    debugPrint('$st');
  } finally {
    isLoadingCategoryMap[categoryId] = false;
  }
}


  // ==================== إدارة الترقيم ====================
  var totalAdsCount = 0.obs;
  var totalPages = 0.obs;
  var currentPage = 1.obs;
  
  void goToPage(int page) {
    currentPage.value = page;
    fetchAds(
      page: page,
      lang: currentLang,
    );
  }
  
  void resetFilters() {
    clearAllFilters();
    fetchAds(
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      page: 1,
    );
  }
  
  // ==================== جلب أحدث الإعلانات ====================
  var adsListLatest = <Ad>[].obs;
  RxBool isLoadingAdsLatest = false.obs;

 Future<void> fetchLatestAds({int count = 7}) async {
  // لو فيه تحميل شغال لا تكرر
  if (isLoadingAdsLatest.value) return;

  // لو عندك داتا قديمة وتبغى تمنع إعادة التحميل تلقائياً:
  if (adsListLatest.isNotEmpty) return;

  isLoadingAdsLatest.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/ads/filter');
    final body = {
      'sort_by': 'newest',
      'order': 'desc',
      'per_page': count,
      'lang': Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode,
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final rawList = jsonData['data'] as List<dynamic>;
      // ✅ نحدث فقط عند نجاح الريسبونس
      adsListLatest.value =
          AdResponse.fromJson({'data': rawList}).data;
    } else if (response.statusCode == 429) {
      debugPrint('⚠️ fetchLatestAds -> 429 Too Many Requests (بنخلي الداتا الحالية كما هي)');
      // تقدر تضيف Snackbar لو حاب
      // Get.snackbar("تنبيه", "تم تجاوز حد الطلبات، حاول بعد لحظات");
    } else {
      debugPrint(
          '❌ fetchLatestAds error ${response.statusCode}: ${response.body}');
      // Get.snackbar("خطأ", "حدث خطأ أثناء جلب أحدث الإعلانات");
    }
  } on TimeoutException {
    debugPrint('⏱️ fetchLatestAds timeout');
    // Get.snackbar("تحذير", "تم تجاوز وقت تحميل الإعلانات");
  } catch (e, st) {
    debugPrint('❌ fetchLatestAds exception: $e');
    debugPrint('$st');
    // Get.snackbar("خطأ", "حدث خطأ أثناء جلب أحدث الإعلانات");
  } finally {
    isLoadingAdsLatest.value = false;
  }
}


  // ==================== تحميل التصنيفات بشكل متوازي ====================
  Future<void> _fetchInitialCategoriesParallel() async {
    final initialCategories = [1, 2, 3, 4];
    final tasks = initialCategories.map((categoryId) {
      return fetchAdsByCategory(categoryId: categoryId);
    }).toList();
    await Future.wait(tasks);
  }

  Future<void> refreshLocation() async {
    try {
      // التحقق من صلاحيات الموقع
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('خطأ', 'خدمة الموقع غير مفعلة. يرجى تفعيلها');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('خطأ', 'تم رفض صلاحيات الموقع');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('خطأ', 'صلاحيات الموقع مرفوضة بشكل دائم');
        return;
      } 

      // جلب الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      latitude?.value = position.latitude;
      longitude?.value = position.longitude;

      Get.snackbar('نجاح', 'تم تحديث الموقع بنجاح', 
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 2)
      );

    } catch (e) {
      print('حدث خطأ أثناء جلب الموقع: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الموقع: ${e.toString()}');
    }
  }


String? toTimeframe(int? hours) {
  if (hours == null)   return null;    // كل الإعلانات
  if (hours == 24)     return '24h';
  if (hours == 48)     return '48h';
  // لو حاب تدعم less common periods:
  if (hours == 2*24)   return '2_days';
  return null; // الافتراضي
}

  /// دالة تحميل الإعلانات المميزة (POST /ads/filter)
  /// دالة تحميل الإعلانات المميزة (POST /ads/filter)
Future<void> loadFeaturedAds() async {
  // لو فيه تحميل شغال لا تكرر
  if (isLoadingFeatured.value) return;

  isLoadingFeatured.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/ads/filter');
    final body = {
      'only_featured': true,
      'per_page': 7,
      'lang': Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode,
      'timeframe': 'all',
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final rawList = jsonData['data'] as List<dynamic>;
      // ✅ نحدث القائمة فقط عند نجاح الريسبونس
      featuredAds.assignAll(
        AdResponse.fromJson({'data': rawList}).data,
      );
    } else if (response.statusCode == 429) {
      debugPrint('⚠️ loadFeaturedAds -> 429 Too Many Requests (بنخلي الداتا الحالية كما هي)');
    } else {
      debugPrint('❌ loadFeaturedAds error ${response.statusCode}: ${response.body}');
    }
  } on TimeoutException {
    debugPrint('⏱️ loadFeaturedAds timeout');
  } catch (e, st) {
    debugPrint('‼️ Featured exception: $e');
    debugPrint('$st');
  } finally {
    isLoadingFeatured.value = false;
  }
}



  final RxList<Map<String, dynamic>> attrsPayload = <Map<String, dynamic>>[].obs;

  void resetFilterState() {
  // إعادة تعيين متغيرات البحث والفرز
  currentSearch.value = "";
  searchController.clear();
  isSearching.value = false;
  
  // إعادة تعيين متغيرات التصنيفات
  selectedMainCategoryId.value = null;
  selectedSubCategoryId.value = null;
  selectedSubTwoCategoryId.value = null;
  
  // إعادة تعيين متغيرات الموقع الجغرافي
  latitude.value = null;
  longitude.value = null;
  selectedRadius.value = 0.0;
  
  // إعادة تعيين متغيرات المدن والمناطق
  selectedCity.value = null;
  selectedArea.value = null;
  
  // إعادة تعيين متغيرات الوقت والسمات
  currentTimeframe.value = null;
  currentAttributes.clear();
  attrsPayload.clear();
  
  // إعادة تعيين متغيرات الفلترة
  onlyFeatured.value = false;
  currentSortBy.value = null;
  
  print("✅ تم تفريغ حالة الفلترة بنجاح");
}

////


  /// يجلب تفاصيل الإعلان من API ويعيد الـ Ad إذا نجحت العملية، أو null عند الفشل.
 Rx<Ad?> adDetails = Rx<Ad?>(null);
  RxBool isLoadingAd = false.obs;
  
  Future<Ad?> fetchAdDetails({
  required String adId, // يجب أن تكون من نوع String
  String lang = 'ar',
  Duration timeout = const Duration(seconds:60),
}) async {
    isLoadingAd.value = true;

    final Uri uri = Uri.parse('$_baseUrl/ads/details')
        .replace(queryParameters: {'ad_id': adId, 'lang': lang});

    try {
      debugPrint('>> fetchAdDetails - GET: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers).timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('Request timed out after ${timeout.inSeconds}s');
            },
          );

      debugPrint('<< fetchAdDetails - status: ${res.statusCode}');
      debugPrint('<< fetchAdDetails - body: ${res.body}');

      if (res.statusCode != 200) {
        dynamic errorJson;
        try {
          errorJson = jsonDecode(res.body);
        } catch (_) {
          errorJson = null;
        }

        if (res.statusCode == 422 && errorJson != null && errorJson['errors'] != null) {
          final errors = errorJson['errors'];
          final String errorMessage = (errors is Map)
              ? errors.values.map((v) => (v is List ? v.join(', ') : v.toString())).join('\n')
              : 'Validation error';
          debugPrint('!! Validation (422) errors: $errors');
          Get.snackbar('خطأ'.tr, errorMessage, duration: const Duration(seconds: 4));
        } else {
          final serverMsg = errorJson != null
              ? (errorJson['message'] ?? errorJson['error'] ?? res.body)
              : res.body;
          debugPrint('!! Server error (${res.statusCode}): $serverMsg');
          Get.snackbar('خطأ من الخادم'.tr, 'حدث خطأ (${res.statusCode}).'.tr,
              duration: const Duration(seconds: 4));
        }

        adDetails.value = null;
        return null;
      }

      // هنا status code == 200
      dynamic jsonData;
      try {
        jsonData = jsonDecode(res.body);
      } on FormatException catch (fe, st) {
        debugPrint('!! JSON FormatException: $fe\n$st');
        Get.snackbar('خطأ في البيانات'.tr, 'استجابة الخادم ليست بصيغة صحيحة.'.tr,
            duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      final statusRaw = jsonData['status'];
      final bool isSuccess = (statusRaw == true) ||
          (statusRaw is String && statusRaw.toString().toLowerCase() == 'success');

      if (jsonData is Map && isSuccess && jsonData['data'] != null) {
        try {
          final Ad ad = Ad.fromJson(jsonData['data']);
          adDetails.value = ad;
          return ad;
        } catch (parseErr, st) {
          debugPrint('!! Error parsing Ad.fromJson: $parseErr\n$st');
          Get.snackbar('خطأ'.tr, 'فشل تحويل بيانات الإعلان.'.tr, duration: const Duration(seconds: 4));
          adDetails.value = null;
          return null;
        }
      }

      if (statusRaw is String && statusRaw.toLowerCase() == 'fail') {
        final errors = jsonData['errors'];
        debugPrint('!! Server validation fail: $errors');
        final String errorMessage = errors is Map
            ? errors.values.map((v) => (v is List ? v.join(', ') : v.toString())).join('\n')
            : (jsonData['message'] ?? 'فشل في جلب الإعلان');
        Get.snackbar('خطأ'.tr, errorMessage, duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      if (statusRaw is String && statusRaw.toLowerCase() == 'error') {
        final serverMsg = jsonData['message'] ?? jsonData['error'] ?? 'حدث خطأ من الخادم';
        debugPrint('!! Server returned error: $serverMsg');
        Get.snackbar('خطأ من الخادم'.tr, serverMsg.toString(), duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      debugPrint('!! Unexpected response structure: $jsonData');
      Get.snackbar('خطأ'.tr, 'استجابة غير متوقعة من الخادم.'.tr, duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on SocketException catch (se, st) {
      debugPrint('!! SocketException: $se\n$st');
      Get.snackbar('خطأ في الاتصال'.tr, 'لا يوجد اتصال بالإنترنت أو لا يمكن الوصول إلى الخادم.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on TimeoutException catch (te, st) {
      debugPrint('!! TimeoutException: $te\n$st');
      Get.snackbar('انتهت المهلة'.tr, 'انتهت مهلة الاتصال بالخادم، حاول لاحقًا.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on HttpException catch (he, st) {
      debugPrint('!! HttpException: $he\n$st');
      Get.snackbar('خطأ من الخادم'.tr, 'حدث خطأ أثناء الاتصال بالخادم.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } catch (e, st) {
      debugPrint('!! Unknown error in fetchAdDetails: $e\n$st');
      Get.snackbar('خطأ'.tr, 'فشل تحميل تفاصيل الإعلان: ${e.toString()}', duration: const Duration(seconds: 5));
      adDetails.value = null;
      return null;
    } finally {
      isLoadingAd.value = false;
    }
  }


// افترض أن المتغيرات التالية موجودة في الكلاس:
// final RxBool isLoadingAds = false.obs;
// final String _baseUrl = 'https://...';
// final RxList<Ad> adsList = <Ad>[].obs; // مثال

Future<void> searchAdsByImage({
  required XFile imageFile,
  required String lang,
  int page = 1,
  int perPage = 15,
  int? categoryId,
  int? subCategoryLevelOneId,
  int? subCategoryLevelTwoId,
  bool debug = false,
}) async {
  try {
    isLoadingAds.value = true;

    // قراءة بيانات الصورة بطريقة متوافقة مع جميع المنصات
    Uint8List bytes;
    String fileName;
    
    if (fo.kIsWeb) {
      // على الويب: قراءة البايتات مباشرة من XFile
      bytes = await imageFile.readAsBytes();
      fileName = imageFile.name;
    } else {
      // على المنصات الأخرى: استخدام المسار
      bytes = await File(imageFile.path).readAsBytes();
      fileName = imageFile.path;
    }

    final base64Str = base64Encode(bytes);

    // تحديد نوع MIME من اسم الملف
    final lower = fileName.toLowerCase();
    String mime = 'image/jpeg';
    if (lower.endsWith('.png')) mime = 'image/png';
    else if (lower.endsWith('.webp')) mime = 'image/webp';
    else if (lower.endsWith('.gif')) mime = 'image/gif';

    final dataUrl = 'data:$mime;base64,$base64Str';

    final uri = Uri.parse('$_baseUrl/ads/search-by-image');

    final body = {
      'image': dataUrl,
      'lang': lang,
      'page': page,
      'per_page': perPage,
      'debug': debug,
    };

    // إضافة الحقول الاختيارية فقط إذا كانت موجودة
    if (categoryId != null) body['category_id'] = categoryId;
    if (subCategoryLevelOneId != null) body['sub_category_level_one_id'] = subCategoryLevelOneId;
    if (subCategoryLevelTwoId != null) body['sub_category_level_two_id'] = subCategoryLevelTwoId;

    print('📤 [IMAGE SEARCH] POST $uri, payload size ~ ${(base64Str.length / 1024).toStringAsFixed(1)} KB');

    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body))
        .timeout(const Duration(seconds: 120));

    print('📥 [IMAGE SEARCH] Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      if (map['status'] == 'success') {
        if (debug && map['info'] != null) {
          print("📊 Debug info: ${json.encode(map['info'])}");
        }
        final rawList = (map['data'] as List<dynamic>);
        final ads = AdResponse.fromJson({'data': rawList}).data;

        // تحديث قوائم الإعلانات
        adsList.value = ads;
        filteredAdsList.value = ads;
        allAdsList.value = ads;

        // إظهار رسالة نجاح إذا كان هناك نتائج
        if (ads.isNotEmpty) {
          Get.snackbar(
            'نجاح',
            'تم العثور على ${ads.length} نتيجة',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        } else {
          Get.snackbar(
            'تنبيه',
            'لم يتم العثور على نتائج',
            snackPosition: SnackPosition.BOTTOM,
            duration: Duration(seconds: 3),
          );
        }
      } else {
        final msg = map['message'] ?? 'خطأ من السيرفر';
        print('❌ IMAGE SEARCH failed: $msg');
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      print('❌ IMAGE SEARCH HTTP error ${response.statusCode} : ${response.body}');
      Get.snackbar(
        'خطأ', 
        'تعذّر البحث بالصور (${response.statusCode})', 
        snackPosition: SnackPosition.BOTTOM
      );
    }
  } catch (e, st) {
    print('⚠️ Exception searchAdsByImage: $e');
    print(st);
    Get.snackbar(
      'خطأ', 
      'حدث خطأ أثناء البحث بالصور', 
      snackPosition: SnackPosition.BOTTOM
    );
  } finally {
    isLoadingAds.value = false;
  }
}
  /// جلب بيانات SEO من API
  Future<Map<String, dynamic>> fetchSeoData(int adId, {String lang = 'ar'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/ad-seo/$adId?lang=$lang');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // قد يعيد الـ API لاحقًا غلافًا آخر؛ ضمّن فحصًا بسيطًا
        if (decoded is Map<String, dynamic>) return decoded;
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching SEO data: $e');
      return {};
    }
  }

  /// تحديث رأس الصفحة ببيانات SEO (نسخة محسنة وكاملة)
  void updateDocumentHead(Map<String, dynamic> seoData) {
    try {
      // تأكد من وجود الوثيقة
      if (html.document == null) {
        debugPrint('HTML document is not available');
        return;
      }

      // title
      final title = seoData['metaTitle']?.toString();
      if (title != null && title.isNotEmpty) {
        html.document.title = title;
        _injectOrUpdateAdH1(title);
      }

      // meta description
      final description = seoData['metaDescription']?.toString();
      if (description != null && description.isNotEmpty) {
        _updateMetaTag('description', description);
      }

      // canonical
      final canonical = seoData['canonical']?.toString();
      if (canonical != null && canonical.isNotEmpty) {
        final normalizedCanonical = _normalizeCanonical(canonical);
        _updateLinkTag('canonical', normalizedCanonical);
        _updateMetaTag('og:url', normalizedCanonical);
      } else {
        // غلاف احتياطي: استخدم رابط الصفحة الحالية إن لم توجد canonical
        final fallback = html.window.location.href;
        _updateLinkTag('canonical', fallback);
        _updateMetaTag('og:url', fallback);
      }

      // og:image
      final ogImage = seoData['ogImage']?.toString();
      if (ogImage != null && ogImage.isNotEmpty) {
        final normalizedOgImage = _normalizeCanonical(ogImage);
        _updateMetaTag('og:image', normalizedOgImage);
        _updateMetaTag('og:image:alt', title ?? '');
      }

      // twitter tags
      if (title != null && title.isNotEmpty) _updateMetaTag('twitter:title', title);
      if (description != null && description.isNotEmpty) _updateMetaTag('twitter:description', description);
      if (ogImage != null && ogImage.isNotEmpty) _updateMetaTag('twitter:image', _normalizeCanonical(ogImage));

      // JSON-LD
      final jsonLd = seoData['jsonLd'];
      if (jsonLd != null) {
        try {
          final Map<String, dynamic> normalizedJsonLd =
              jsonDecode(jsonEncode(jsonLd)) as Map<String, dynamic>;

          if (normalizedJsonLd['url'] != null && normalizedJsonLd['url'] is String) {
            normalizedJsonLd['url'] =
                _normalizeCanonical(normalizedJsonLd['url'] as String);
          }

          if (normalizedJsonLd['image'] != null) {
            if (normalizedJsonLd['image'] is String) {
              normalizedJsonLd['image'] =
                  _normalizeCanonical(normalizedJsonLd['image'] as String);
            } else if (normalizedJsonLd['image'] is List) {
              normalizedJsonLd['image'] = (normalizedJsonLd['image'] as List).map((e) {
                if (e is String) return _normalizeCanonical(e);
                return e;
              }).toList();
            }
          }

          _updateJsonLd(normalizedJsonLd);
        } catch (e) {
          // لو فشل التطبيع، جرّب إضافة الـ jsonLd كما هو
          try {
            _updateJsonLd(jsonLd as Map<String, dynamic>);
          } catch (_) {
            debugPrint('Failed to update JSON-LD: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating document head: $e');
    }
  }

  /// دالة لحقن/تحديث H1 داخل DOM (تضمن وجود H1 مرئي لكل إعلان)
  void _injectOrUpdateAdH1(String title) {
    try {
      final t = title.trim();
      if (t.isEmpty) return;

      final existing = html.document.getElementById('ad-title-h1');
      if (existing != null) {
        existing.text = t;
        return;
      }

      final h1 = html.Element.tag('h1')
        ..id = 'ad-title-h1'
        ..text = t;

      h1.setAttribute('itemprop', 'headline');
      h1.setAttribute('role', 'heading');

      // ستايل افتراضي — يمكن تعديله من index.html عبر CSS
      h1.style.margin = '10px 0';
      h1.style.fontSize = '20px';
      h1.style.fontWeight = '700';
      h1.style.color = '#222';

      final anchor = html.document.getElementById('ad-seo-anchor');
      if (anchor != null) {
        anchor.append(h1);
      } else {
        final body = html.document.body;
        if (body != null) {
          body.insertBefore(h1, body.firstChild);
        } else {
          html.document.head?.append(h1); // حل أخير
        }
      }
    } catch (e) {
      debugPrint('inject H1 error: $e');
    }
  }

  /// تطبيع canonical و/أو روابط الصور
  String _normalizeCanonical(String url) {
    try {
      if (url.isEmpty) return url;

      // قاعدة استبدال بسيطة كما طلبت — عدلها حسب بيئة deploy الحقيقية
      if (url.contains('/lar_stayInMe/public')) {
        return url.replaceAll(
            'https://stayinme.arabiagroup.net/lar_stayInMe/public',
            'https://testing.arabiagroup.net');
      }

      if (url.startsWith('https://stayinme.arabiagroup.net')) {
        return url.replaceFirst(
            'https://stayinme.arabiagroup.net', 'https://testing.arabiagroup.net');
      }

      return url;
    } catch (e) {
      return url;
    }
  }

  /// تحديث/إضافة وسم meta (name أو property)
  void _updateMetaTag(String name, String content) {
    try {
      final isOgOrTwitter = name.startsWith('og:') || name.startsWith('twitter:');
      final selector = isOgOrTwitter ? 'meta[property="$name"]' : 'meta[name="$name"]';
      html.Element? element = html.document.querySelector(selector);

      if (element == null) {
        final meta = html.MetaElement();
        if (isOgOrTwitter) {
          meta.setAttribute('property', name);
        } else {
          meta.setAttribute('name', name);
        }
        html.document.head?.append(meta);
        element = meta;
      }
      element.setAttribute('content', content);
    } catch (e) {
      debugPrint('Error updating meta tag $name: $e');
    }
  }

  /// تحديث/إضافة وسم link (مثل canonical)
  void _updateLinkTag(String rel, String href) {
    try {
      html.Element? element = html.document.querySelector('link[rel="$rel"]');
      if (element == null) {
        final link = html.LinkElement();
        link.setAttribute('rel', rel);
        html.document.head?.append(link);
        element = link;
      }
      element.setAttribute('href', href);
    } catch (e) {
      debugPrint('Error updating link tag $rel: $e');
    }
  }

  /// تحديث JSON-LD في head (نستبدل أي JSON-LD موجود)
  void _updateJsonLd(Map<String, dynamic> jsonLd) {
    try {
      html.document.querySelectorAll('script[type="application/ld+json"]').forEach((element) {
        element.remove();
      });

      final script = html.ScriptElement();
      script.type = 'application/ld+json';
      script.text = jsonEncode(jsonLd);
      html.document.head?.append(script);
    } catch (e) {
      debugPrint('Error updating JSON-LD: $e');
    }
  }

  /// دالة مساعدة للتعامل مع حالة عدم توفر بيانات SEO (قيمة افتراضية)
  void handleMissingSeoData() {
    final defaultTitle = 'طابوو - سوق الإعلانات المبوبة في سوريا';
    final defaultDescription =
        'أفضل منصة للإعلانات المبوبة في سوريا - عقارات للبيع والإيجار، سيارات، دراجات نارية وقطع غيار.';
    final defaultUrl = html.window.location.href;

    try {
      html.document.title = defaultTitle;
      _updateMetaTag('description', defaultDescription);
      _updateLinkTag('canonical', defaultUrl);
      _updateMetaTag('og:title', defaultTitle);
      _updateMetaTag('og:description', defaultDescription);
      _updateMetaTag('og:url', defaultUrl);

      // حقن H1 افتراضي (يساعد في الـ Inspector قبل وصول SEO الحقيقي)
      _injectOrUpdateAdH1(defaultTitle);
    } catch (e) {
      debugPrint('Error setting default SEO data: $e');
    }
  }
}