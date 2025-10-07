import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart'; // لأخذ الصور من الويب
import 'package:file_picker/file_picker.dart'; // لاختيار الملفات على الويب

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File; // لا يعمل على الويب - مستخدم فقط في الفرع غير الويب
// لأجل XFile إن لم تكن مستورد سابقاً استخدم:

import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/SearchHistoryController.dart';
import '../../controllers/areaController.dart';
import '../../controllers/home_controller.dart';
import '../../core/localization/changelanguage.dart';
import '../HomeScreenDeskTop/sections/categories_sidebar_desktop.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';
import 'AdsItemDesktop.dart';
import 'FilterScreendesktop.dart';

// دالة مساعدة للعثور على عنصر أو إرجاع null
T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

class AdsScreenDesktop extends StatefulWidget {
  final int? categoryId;
  final int? subCategoryId;
  final int? subTwoCategoryId;
  final String? nameOfMain;
  final String? nameOFsub;
  final String? nameOFsubTwo;
  final String? currentTimeframe;
  final bool onlyFeatured;
  final String? categorySlug;
  final String? subCategorySlug;
  final String? subTwoCategorySlug;

  const AdsScreenDesktop({
    super.key,
    this.categoryId,
    this.subCategoryId,
    this.subTwoCategoryId,
    this.nameOfMain,
    this.nameOFsub,
    this.currentTimeframe,
    this.nameOFsubTwo,
    this.onlyFeatured = false,
    this.categorySlug,
    this.subCategorySlug,
    this.subTwoCategorySlug,
  });

  @override
  State<AdsScreenDesktop> createState() => _AdsScreenDesktopState();
}

class _AdsScreenDesktopState extends State<AdsScreenDesktop> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AdsController _adsController;
  late final ThemeController _themeController;
  String? _selectedTimePeriod;
  bool _initialDataLoaded = false;
  bool _isDisposed = false;
Future<void> _convertSlugsToIds() async {
  // إذا كان هناك categorySlug، نحتاج إلى تحويله إلى categoryId
  if (widget.categorySlug != null) {
    // انتظر حتى يتم تحميل التصنيفات الرئيسية إذا لم تكن محملة
    if (_adsController.mainCategories.isEmpty) {
      await _adsController.fetchMainCategories(
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
    }

    // ابحث عن التصنيف الرئيسي باستخدام الـ slug
    final mainCategory = firstWhereOrNull(
      _adsController.mainCategories, 
      (c) => c.slug == widget.categorySlug
    );
    
    if (mainCategory != null) {
      // عين التصنيف الرئيسي
      _adsController.selectedMainCategoryId.value = mainCategory.id;
      _adsController.currentCategoryId.value = mainCategory.id;
      
      // جلب التصنيفات الفرعية للتصنيف الرئيسي
      await _adsController.fetchSubCategories(
        mainCategory.id, 
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
      
      // إذا كان هناك subCategorySlug، ابحث عنه
      if (widget.subCategorySlug != null) {
        final subCategory = firstWhereOrNull(
          _adsController.subCategories, 
          (c) => c.slug == widget.subCategorySlug
        );
        
        if (subCategory != null) {
          _adsController.selectedSubCategoryId.value = subCategory.id;
          _adsController.currentSubCategoryLevelOneId.value = subCategory.id;
          
          // جلب التصنيفات الفرعية الثانوية
          await _adsController.fetchSubTwoCategories(
            subCategory.id
          );
          
          // إذا كان هناك subTwoCategorySlug، ابحث عنه
          if (widget.subTwoCategorySlug != null) {
            final subTwoCategory = firstWhereOrNull(
              _adsController.subTwoCategories, 
              (c) => c.slug == widget.subTwoCategorySlug
            );
            
            if (subTwoCategory != null) {
              _adsController.selectedSubTwoCategoryId.value = subTwoCategory.id;
              _adsController.currentSubCategoryLevelTwoId.value = subTwoCategory.id;
            }
          }
        }
      }
    }
  }
}@override
void initState() {
  super.initState();

  if (Get.isRegistered<AdsController>()) {
    _adsController = Get.find<AdsController>();
  } else {
    _adsController = Get.put(AdsController());
  }

  _themeController = Get.find<ThemeController>();
  _handleUrlQueryParameters();

  // جلب الإعلانات مباشرة باستخدام المعلمات المتاحة
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _adsController.fetchAds(
      categoryId: widget.categoryId,
      subCategoryLevelOneId: widget.subCategoryId,
      subCategoryLevelTwoId: widget.subTwoCategoryId,
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      timeframe: widget.currentTimeframe,
      onlyFeatured: widget.onlyFeatured,
    );
  });
  
  // تحديث عنوان URL ليعكس الـ slugs
  _updateBrowserUrl();
}
  void _handleUrlQueryParameters() {
    final AreaController _areaController = Get.put(AreaController());
    final currentUri = Uri.parse(html.window.location.href);
    
    if (currentUri.queryParameters.isNotEmpty) {
      // معالجة معلمات البحث
      if (currentUri.queryParameters.containsKey('search')) {
        final searchQuery = currentUri.queryParameters['search'];
        _adsController.currentSearch.value = searchQuery ?? '';
        _adsController.searchController.text = searchQuery ?? '';
      }
      
      // معالجة معلمات المدينة
      if (currentUri.queryParameters.containsKey('city')) {
        final cityId = int.tryParse(currentUri.queryParameters['city'] ?? '');
        if (cityId != null) {
          // ابحث عن المدينة في القائمة وعينها
          final city = firstWhereOrNull(
            _adsController.citiesList,
            (c) => c.id == cityId,
          );
          if (city != null) {
            _adsController.selectCity(city);
          }
        }
      }
      
      // معالجة معلمات المنطقة
      if (currentUri.queryParameters.containsKey('area')) {
        final areaId = int.tryParse(currentUri.queryParameters['area'] ?? '');
        if (areaId != null && _adsController.selectedCity.value != null) {
          // ابحث عن المنطقة في القائمة وعينها
          _areaController.getAreasOrFetch(_adsController.selectedCity.value!.id).then((areas) {
            final area = firstWhereOrNull(
              areas,
              (a) => a.id == areaId,
            );
            if (area != null) {
              _adsController.selectArea(area);
            }
          });
        }
      }
      
      // معالجة الفترة الزمنية
      if (currentUri.queryParameters.containsKey('timeframe')) {
        _selectedTimePeriod = currentUri.queryParameters['timeframe'];
      }
    }
  }

  void _updateBrowserUrl() {
    // بناء الرابط بناءً على الـ slugs المتاحة
    String urlPath = '/ads';
    
    if (widget.categorySlug != null) {
      urlPath += '/${widget.categorySlug}';
      
      if (widget.subCategorySlug != null) {
        urlPath += '/${widget.subCategorySlug}';
        
        if (widget.subTwoCategorySlug != null) {
          urlPath += '/${widget.subTwoCategorySlug}';
        }
      }
    }
    
    // تحديث عنوان المتصفح بدون إعادة تحميل الصفحة
    html.window.history.replaceState({}, '', urlPath);
  }

  void updateUrlWithFilters() {
    _updateUrlWithFilters();
  }

  void _updateUrlWithFilters() {
    String urlPath = '/ads';
    
    // إضافة slugs التصنيفات إذا كانت موجودة
    if (_adsController.selectedMainCategoryId.value != null) {
      final mainCategory = firstWhereOrNull(
        _adsController.mainCategories,
        (c) => c.id == _adsController.selectedMainCategoryId.value,
      );
      if (mainCategory != null && mainCategory.slug != null) {
        urlPath += '/${mainCategory.slug}';
      }
    }
    
    if (_adsController.selectedSubCategoryId.value != null) {
      final subCategory = firstWhereOrNull(
        _adsController.subCategories,
        (c) => c.id == _adsController.selectedSubCategoryId.value,
      );
      if (subCategory != null && subCategory.slug != null) {
        urlPath += '/${subCategory.slug}';
      }
    }
    
    if (_adsController.selectedSubTwoCategoryId.value != null) {
      final subTwoCategory = firstWhereOrNull(
        _adsController.subTwoCategories,
        (c) => c.id == _adsController.selectedSubTwoCategoryId.value,
      );
      if (subTwoCategory != null && subTwoCategory.slug != null) {
        urlPath += '/${subTwoCategory.slug}';
      }
    }
    
    // إضافة معلمات البحث إذا كانت موجودة
    final params = <String>[];
    
    if (_adsController.currentSearch.value.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(_adsController.currentSearch.value)}');
    }
    
    if (_adsController.selectedCity.value != null) {
      params.add('city=${_adsController.selectedCity.value!.id}');
    }
    
    if (_adsController.selectedArea.value != null) {
      params.add('area=${_adsController.selectedArea.value!.id}');
    }
    
    if (_selectedTimePeriod != null && _selectedTimePeriod != 'all') {
      params.add('timeframe=$_selectedTimePeriod');
    }
    
    if (params.isNotEmpty) {
      urlPath += '?${params.join('&')}';
    }
    
    // تحديث عنوان المتصفح
    html.window.history.replaceState({}, '', urlPath);
  }




  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_initialDataLoaded) {
    _initialDataLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        // إذا كان هناك slugs، لن نجلب الإعلانات هنا لأننا سنجلبها بعد التحويل في initState
        if (widget.categorySlug == null) {
          _adsController.fetchAds(
            categoryId: widget.categoryId,
            subCategoryLevelOneId: widget.subCategoryId,
            subCategoryLevelTwoId: widget.subTwoCategoryId,
            lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
            timeframe: widget.currentTimeframe,
            onlyFeatured: widget.onlyFeatured,
          );
        }
      }
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;

    if (_isDisposed) {
      return const SizedBox.shrink();
    }
    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        body: Column(
          children: [
         TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(isAdsScreen: true,),
          Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الشريط الجانبي الأيسر
                    Container(
                      width: 270.w,
                      margin: EdgeInsets.only(top: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDarkMode),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: CategoriesSidebarDesktop(),
                      ),
                    ),

                    // المحتوى الرئيسي
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopControls(isDarkMode),
                            SizedBox(height: 20.h),
                            Expanded(
                              child: Obx(() {
                                if (_adsController.isLoadingAds.value) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 1.5,
                                    ),
                                  );
                                }

                                if (_adsController.filteredAdsList.isEmpty) {
                                  return _buildEmptyState(isDarkMode);
                                }

                                return _buildAdsGrid(isDarkMode);
                              }),
                            ),
                            SizedBox(height: 16.h),
                            _buildPagination(isDarkMode,context),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),

                    // شريط الفلترة
                    Container(
                      width: 270.w,
                      margin: EdgeInsets.only(top: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDarkMode),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: FilterScreenDestktop(
                        categoryId: widget.categoryId,
                        currentTimeframe: widget.currentTimeframe,
                        onlyFeatured: widget.onlyFeatured,
                        onFiltersApplied: _updateUrlWithFilters, // تمرير callback لتحديث الرابط
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    
  }

  Widget _buildTopControls(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(() {
              final count = _adsController.filteredAdsList.length;
              return Text(
                "${'عرض'.tr} $count ${'من'.tr} ${_adsController.totalAdsCount.value} ${'نتيجة'.tr}",
                style: TextStyle(
                 fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              );
            }),
          ),
       
           
            SizedBox(
          width:150.w,
          child: ElevatedButton(
            onPressed: (){

                
  
    _showImageSearchDialog( );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonAndLinksColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
             'البحث من خلال الصورة'.tr,
              style: TextStyle(
               fontSize: AppTextStyles.small,
                fontWeight: FontWeight.bold,
                   fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ),
        SizedBox(width: 5.w,),
            SizedBox(
          width:100.w,
          child: ElevatedButton(
            onPressed: (){

         
_showSaveSearchDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonAndLinksColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'حفظ البحث'.tr,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.bold,
              
                                fontFamily: AppTextStyles.appFontFamily,
           ),
              ),
            ),
          ),
        
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 18.w),
                  color: _adsController.currentPage.value < _adsController.totalPages.value
                      ? AppColors.textPrimary(isDarkMode)
                      : AppColors.textSecondary(isDarkMode),
                  onPressed: _adsController.currentPage.value < _adsController.totalPages.value
                      ? () => _adsController.goToPage(_adsController.currentPage.value + 1)
                      : null,
                ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.background(isDarkMode),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                _buildSortDropdown(isDarkMode),
                SizedBox(width: 16.w),
                Container(
                  height: 24.h,
                  width: 1,
                  color: AppColors.divider(isDarkMode),
                ),
                SizedBox(width: 16.w),
                _buildViewModeToggle(isDarkMode),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSortDropdown(bool isDarkMode) {
    final sortOptions = {
      'newest': 'الأحدث',
      'oldest': 'الأقدم',
      'price_asc': 'الأرخص',
      'price_desc': 'الأغلى',
      'most_viewed': 'الأعلى مشاهدة',
    };

    return Obx(() {
      return Row(
        children: [
          Text(
            'الفرز:'.tr,
            style: TextStyle(
             fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.background(isDarkMode),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _adsController.currentSortBy.value,
                icon: Icon(Icons.keyboard_arrow_down, 
                          size: 20.w,
                          color: AppColors.textSecondary(isDarkMode)),
                elevation: 16,
                style: TextStyle(
                 fontSize: AppTextStyles.medium,
                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _adsController.fetchAds(
                      categoryId: widget.categoryId,
                      subCategoryLevelOneId: widget.subCategoryId,
                      subCategoryLevelTwoId: widget.subTwoCategoryId,
                      sortBy: newValue,
                      order: newValue == 'newest' ? 'asc' : 'desc',
                      lang: Get.locale?.languageCode ?? 'ar',
                      timeframe: _selectedTimePeriod,
                      attributes: _adsController.attrsPayload.value.isNotEmpty ? _adsController.attrsPayload.value : null,
                    );
                  }
                },
                items: sortOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                         fontSize: AppTextStyles.medium,
                          color: _adsController.currentSortBy.value == entry.key
                              ? AppColors.primary
                              : AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                dropdownColor: AppColors.card(isDarkMode),
                underline: const SizedBox(),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildViewModeToggle(bool isDarkMode) {
    return Obx(() {
      return Row(
        children: [
          Tooltip(
            message: 'عرض شبكي'.tr,
            child: IconButton(
              icon: Icon(Icons.grid_view, 
                        size: 22.w,
                        color: _adsController.viewMode.value == 'grid' 
                            ? AppColors.primary
                            : AppColors.textSecondary(isDarkMode)),
              onPressed: () => _adsController.changeViewMode('grid'),
            ),
          ),
          SizedBox(width: 4.w),
          Tooltip(
            message: 'عرض قائمة'.tr,
            child: IconButton(
              icon: Icon(Icons.view_list, 
                        size: 22.w,
                        color: _adsController.viewMode.value == 'list' 
                            ? AppColors.primary
                            : AppColors.textSecondary(isDarkMode)),
              onPressed: () => _adsController.changeViewMode('list'),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.w, color: AppColors.grey),
          SizedBox(height: 16.h),
          Text(
            'لم نعثر على إعلانات'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'جرب تغيير فلترات البحث أو معايير التصفية'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              _adsController.resetFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 32.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'إعادة تعيين الفلاتر'.tr,
              style: TextStyle(fontSize: 14.sp),
            ),
          )
        ],
      )
    );
  }

  Widget _buildAdsGrid(bool isDarkMode) {
    return Obx(() {
      final viewMode = _adsController.viewMode.value;
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 16.h),
        gridDelegate: viewMode == 'grid'
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.1,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 115.h,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
              ),
        itemCount: _adsController.filteredAdsList.length,
        itemBuilder: (context, index) {
          final ad = _adsController.filteredAdsList[index];
          return AdsItemDesktop(
            ad: ad,
            viewMode: viewMode,
            key: ValueKey(ad.id),
          );
        },
      );
    });
  }

  Widget _buildPagination(bool isDarkMode,BuildContext context) {
    return Obx(() {
      if (_adsController.totalPages.value <= 1) return const SizedBox();
      
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.card(isDarkMode),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${'الإجمالي:'.tr} ${_adsController.totalAdsCount.value} ${'إعلان'.tr}",
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 18.w),
                  color: _adsController.currentPage.value > 1
                      ? AppColors.textPrimary(isDarkMode)
                      : AppColors.textSecondary(isDarkMode),
                  onPressed: _adsController.currentPage.value > 1 
                      ? () => _adsController.goToPage(_adsController.currentPage.value - 1)
                      : null,
                ),
                ...List.generate(_adsController.totalPages.value, (index) {
                  final pageNumber = index + 1;
                  
                  if ((pageNumber - _adsController.currentPage.value).abs() > 2 &&
                      pageNumber != 1 && 
                      pageNumber != _adsController.totalPages.value) {
                    if ((pageNumber - _adsController.currentPage.value).abs() == 3) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          '...',
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  }
                  
                  return InkWell(
                    onTap: () => _adsController.goToPage(pageNumber),
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _adsController.currentPage.value == pageNumber
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                         fontSize: AppTextStyles.medium,
                          fontWeight: _adsController.currentPage.value == pageNumber
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _adsController.currentPage.value == pageNumber
                              ? Colors.white
                              : AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                  );
                }),
                
              ],
            ),
          ],
        ),
      );
    });
  }

  
  void _showSaveSearchDialog(BuildContext context) {
    SearchHistoryController searchHistoryController = Get.put(SearchHistoryController());

    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    TextEditingController searchNameController = TextEditingController();
    bool emailNotifications = true;
    bool mobileNotifications = true;
showDialog(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h), // تحكم بالفراغ حول الديلوج
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 350.w, // 👈 العرض المخصص
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surface(isDarkMode),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'حفظ البحث'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: searchNameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card(isDarkMode),
                      hintText: 'اسم البحث'.tr,
                      hintStyle: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.grey,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildNotificationOption(
                    title: 'إشعار البريد الإلكتروني'.tr,
                    value: emailNotifications,
                    isDarkMode: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        emailNotifications = value!;
                      });
                    },
                  ),
                  SizedBox(height: 12.h),
                  _buildNotificationOption(
                    title: 'إشعارات الهاتف المحمول'.tr,
                    value: mobileNotifications,
                    isDarkMode: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        mobileNotifications = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide(
                              color: AppColors.buttonAndLinksColor,
                              width: 1.2,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            'إلغاء'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final userId = Get.find<LoadingController>().currentUser?.id;
                            if (userId == null) {
                              Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                              return;
                            } else if (widget.categoryId == null) {
                              Get.snackbar('تنبيه'.tr, 'لايمكنك حفظ البحث في عمليات البحث او الاعلانات المميزة او العاجلة'.tr);
                            } else {
                              searchHistoryController.addSearchHistory(
                                userId: userId,
                                recordName: searchNameController.text,
                                categoryId: widget.categoryId!,
                                subcategoryId: widget.subCategoryId,
                                secondSubcategoryId: widget.subCategoryId,
                                notifyPhone: mobileNotifications,
                                notifyEmail: emailNotifications,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonAndLinksColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            'حفظ'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
  );
      },
    );
  },
);

       
      
       
   
   
  }

  Widget _buildNotificationOption({
    required String title,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.buttonAndLinksColor,
          activeTrackColor: AppColors.buttonAndLinksColor.withOpacity(0.4),
        ),
      ],
    );
  }

void _showImageSearchDialog() {
  final adsController = Get.find<AdsController>();
  final themeController = Get.find<ThemeController>();
  final languageController = Get.find<ChangeLanguageController>();

  // نقل المتغيرات إلى داخل الدالة لجعلها محلية وإعادة تعيينها عند كل استدعاء
  Uint8List? pickedImageWeb;
  File? pickedImage;
  bool isSearching = false;
  String? pickedImageWebName;

  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    builder: (context) {
      final isDark = themeController.isDarkMode.value;
      return StatefulBuilder(builder: (context, setState) {
        
        // دالة مساعدة لاختيار الصورة حسب المنصة
        Future<void> pickImage(ImageSource source) async {
          try {
            if (kIsWeb) {
              Uint8List? imageBytes;
              String? fileName;

              if (source == ImageSource.camera) {
                // للكاميرا على الويب
                final XFile? pickedFile = await ImagePicker().pickImage(source: source);
                if (pickedFile != null) {
                  imageBytes = await pickedFile.readAsBytes();
                  fileName = pickedFile.name;
                }
              } else {
                // للمعرض على الويب
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  allowMultiple: false,
                );
                if (result != null) {
                  imageBytes = result.files.first.bytes;
                  fileName = result.files.first.name;
                }
              }

              if (imageBytes != null) {
                setState(() {
                  pickedImageWeb = imageBytes;
                  pickedImageWebName = fileName;
                  pickedImage = null;
                });
              }
            } else {
              // على المنصات الأخرى
              final XFile? pickedFile = await ImagePicker().pickImage(
                source: source,
                imageQuality: 80,
                maxWidth: 1024,
              );
              if (pickedFile != null) {
                setState(() {
                  pickedImage = File(pickedFile.path);
                  pickedImageWeb = null;
                });
              }
            }
          } catch (e) {
            print('Image pick error: $e');
            Get.snackbar(
              'خطأ',
              'فشل اختيار الصورة',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }

        // دالة لبناء معاينة الصورة حسب المنصة
        Widget buildImagePreview() {
          if (kIsWeb) {
            return pickedImageWeb != null
                ? Image.memory(pickedImageWeb!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      'لم يتم اختيار صورة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.grey,
                      ),
                    ),
                  );
          } else {
            return pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(pickedImage!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      'لم يتم اختيار صورة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.grey,
                      ),
                    ),
                  );
          }
        }

        return Dialog(
          insetPadding: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Container(
            width: 450.w,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بحث بالصور'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xlarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'التقط صورة أو اختر من المعرض ثم اضغط "ابحث الآن"'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                SizedBox(height: 12.h),

                // معاينة الصورة
                Container(
                  height: 160.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey.withOpacity(0.12)),
                  ),
                  child: buildImagePreview(),
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_camera),
                        label: Text(
                          'كاميرا'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () => pickImage(ImageSource.camera),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          'معرض'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () => pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSearching
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          'إلغاء'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.redId,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isSearching || (pickedImage == null && pickedImageWeb == null))
                            ? null
                            : () async {
                                setState(() => isSearching = true);
                                try {
                                  XFile imageFile;
                                  if (kIsWeb) {
                                    // تحويل Uint8List إلى XFile للمنصة ويب
                                    imageFile = XFile.fromData(
                                      pickedImageWeb!,
                                      name: pickedImageWebName ?? 'image.jpg',
                                    );
                                  } else {
                                    imageFile = XFile(pickedImage!.path);
                                  }
                                  await adsController.searchAdsByImage(
                                    imageFile: imageFile,
                                    lang: languageController.currentLocale.value.languageCode,
                                    page: 1,
                                    perPage: 15,
                                    categoryId: widget.categoryId,
                                    subCategoryLevelOneId: widget.subCategoryId,
                                    subCategoryLevelTwoId: widget.subTwoCategoryId,
                                    debug: false,
                                  );
                                  Navigator.pop(context);
                                  Get.snackbar(
                                    'نجاح',
                                    'تم جلب النتائج',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e, st) {
                                  print('searchByImage error: $e');
                                  print(st);
                                  final errMsg = (e is Exception) ? e.toString() : 'حدث خطأ غير متوقع';
                                  Get.snackbar(
                                    'خطأ',
                                    errMsg,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  setState(() => isSearching = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonAndLinksColor),
                        child: isSearching
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text(
                                'ابحث الآن'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}}