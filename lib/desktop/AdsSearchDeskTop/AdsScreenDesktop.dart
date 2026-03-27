import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    if (test(item)) return item;
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
  final ScrollController _adsScrollController = ScrollController();

  String? _selectedTimePeriod;
  bool _isDisposed = false;
  bool _hasUrlQuery = false;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<AdsController>()) {
      _adsController = Get.find<AdsController>();
    } else {
      _adsController = Get.put(AdsController());
    }

    _themeController = Get.find<ThemeController>();

    _handleUrlQueryParameters();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed || !mounted) return;
      await _loadAds(resetSearchAndFiltersIfNoQuery: !_hasUrlQuery);
    });
  }

  @override
  void didUpdateWidget(covariant AdsScreenDesktop oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool changed =
        widget.categoryId != oldWidget.categoryId ||
        widget.subCategoryId != oldWidget.subCategoryId ||
        widget.subTwoCategoryId != oldWidget.subTwoCategoryId ||
        widget.categorySlug != oldWidget.categorySlug ||
        widget.subCategorySlug != oldWidget.subCategorySlug ||
        widget.subTwoCategorySlug != oldWidget.subTwoCategorySlug ||
        widget.currentTimeframe != oldWidget.currentTimeframe ||
        widget.onlyFeatured != oldWidget.onlyFeatured;

    if (!changed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed || !mounted) return;

      if (widget.currentTimeframe != null) {
        _selectedTimePeriod = widget.currentTimeframe;
      }

      await _loadAds(resetSearchAndFiltersIfNoQuery: true);
    });
  }

  Future<void> _scrollToTop() async {
    if (!_adsScrollController.hasClients) return;
    await _adsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToPage(int page) async {
    await _adsController.goToPage(page);
    if (!_isDisposed && mounted) {
      await _scrollToTop();
    }
    if (!_isDisposed && mounted) {
      _updateUrlWithFilters(); // يحافظ على query مع pagination/filters
    }
  }

  Future<void> _loadAds({required bool resetSearchAndFiltersIfNoQuery}) async {
    if (_isDisposed || !mounted) return;

    final lang =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    int? catId = widget.categoryId;
    int? subId = widget.subCategoryId;
    int? sub2Id = widget.subTwoCategoryId;
    String? timeframe = widget.currentTimeframe;

    final args = Get.arguments;
    if (args is Map) {
      if (args['categoryId'] != null) catId = args['categoryId'] as int;
      if (args['subCategoryId'] != null) subId = args['subCategoryId'] as int;
      if (args['subTwoCategoryId'] != null) sub2Id = args['subTwoCategoryId'] as int;
      if (args['currentTimeframe'] != null) timeframe = args['currentTimeframe'] as String;
    }

    if (timeframe != null) _selectedTimePeriod = timeframe;

    // Reset عند تغيير التصنيف/الدخول
    if (resetSearchAndFiltersIfNoQuery) {
      _adsController.currentPage.value = 1;
      _adsController.currentSearch.value = '';
      _adsController.searchController.clear();
      _adsController.attrsPayload.value = <Map<String, dynamic>>[];
    }

    if (catId != null) {
      _adsController.selectedMainCategoryId.value = catId;
      _adsController.currentCategoryId.value = catId;
    }

    _adsController.selectedSubCategoryId.value = subId;
    _adsController.currentSubCategoryLevelOneId.value = subId;

    _adsController.selectedSubTwoCategoryId.value = sub2Id;
    _adsController.currentSubCategoryLevelTwoId.value = sub2Id;

    final bool hasAnySlug =
        widget.categorySlug != null ||
        widget.subCategorySlug != null ||
        widget.subTwoCategorySlug != null;

    final bool noIdsProvided = catId == null && subId == null && sub2Id == null;

    if (hasAnySlug && noIdsProvided) {
      await _convertSlugsToIds();
    }

    final effectiveCategoryId = _adsController.selectedMainCategoryId.value;
    final effectiveSubCategoryId = _adsController.selectedSubCategoryId.value;
    final effectiveSubTwoCategoryId = _adsController.selectedSubTwoCategoryId.value;

    await _adsController.fetchAds(
      categoryId: effectiveCategoryId,
      subCategoryLevelOneId: effectiveSubCategoryId,
      subCategoryLevelTwoId: effectiveSubTwoCategoryId,
      lang: lang,
      timeframe: widget.currentTimeframe ?? _selectedTimePeriod,
      onlyFeatured: widget.onlyFeatured,
      page: _adsController.currentPage.value,
      perPage: _adsController.perPageRx.value,
      cityId: _adsController.selectedCity.value?.id,
      areaId: _adsController.selectedArea.value?.id,
      attributes: _adsController.attrsPayload.value.isNotEmpty
          ? _adsController.attrsPayload.value
          : null,
      search: _adsController.currentSearch.value.isNotEmpty
          ? _adsController.currentSearch.value
          : null,
      sortBy: _adsController.currentSortBy.value,
      order: _adsController.currentOrder.value,
    );

    if (!_isDisposed && mounted) {
      _updateBrowserUrl(); // الآن يكتب query params
    }
  }

  Future<void> _convertSlugsToIds() async {
    if (widget.categorySlug == null &&
        widget.subCategorySlug == null &&
        widget.subTwoCategorySlug == null) {
      return;
    }

    final langCode =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    if (_adsController.mainCategories.isEmpty) {
      await _adsController.fetchMainCategories(langCode);
    }

    if (widget.categorySlug != null) {
      final mainCategory = firstWhereOrNull(
        _adsController.mainCategories,
        (c) => c.slug == widget.categorySlug,
      );

      if (mainCategory != null) {
        _adsController.selectedMainCategoryId.value = mainCategory.id;
        _adsController.currentCategoryId.value = mainCategory.id;

        await _adsController.fetchSubCategories(mainCategory.id, langCode);

        if (widget.subCategorySlug != null) {
          final subCategory = firstWhereOrNull(
            _adsController.subCategories,
            (c) => c.slug == widget.subCategorySlug,
          );

          if (subCategory != null) {
            _adsController.selectedSubCategoryId.value = subCategory.id;
            _adsController.currentSubCategoryLevelOneId.value = subCategory.id;

            await _adsController.fetchSubTwoCategories(subCategory.id);

            if (widget.subTwoCategorySlug != null) {
              final subTwoCategory = firstWhereOrNull(
                _adsController.subTwoCategories,
                (c) => c.slug == widget.subTwoCategorySlug,
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
  }

  void _handleUrlQueryParameters() {
    final AreaController areaController = Get.put(AreaController());
    final currentUri = Uri.parse(html.window.location.href);

    if (currentUri.queryParameters.isNotEmpty) {
      _hasUrlQuery = true;

      if (currentUri.queryParameters.containsKey('search')) {
        final searchQuery = currentUri.queryParameters['search'];
        _adsController.currentSearch.value = searchQuery ?? '';
        _adsController.searchController.text = searchQuery ?? '';
      }

      if (currentUri.queryParameters.containsKey('city')) {
        final cityId = int.tryParse(currentUri.queryParameters['city'] ?? '');
        if (cityId != null) {
          final city = firstWhereOrNull(_adsController.citiesList, (c) => c.id == cityId);
          if (city != null) _adsController.selectCity(city);
        }
      }

      if (currentUri.queryParameters.containsKey('area')) {
        final areaId = int.tryParse(currentUri.queryParameters['area'] ?? '');
        if (areaId != null && _adsController.selectedCity.value != null) {
          areaController.getAreasOrFetch(_adsController.selectedCity.value!.id).then((areas) {
            final area = firstWhereOrNull(areas, (a) => a.id == areaId);
            if (area != null) _adsController.selectArea(area);
          });
        }
      }

      if (currentUri.queryParameters.containsKey('timeframe')) {
        _selectedTimePeriod = currentUri.queryParameters['timeframe'];
      }
    }
  }

  // ✅ محدث: يكتب path + query (search/city/area/timeframe)
  void _updateBrowserUrl() {
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

    html.window.history.replaceState({}, '', urlPath);
  }

  void _updateUrlWithFilters() {
    String urlPath = '/ads';

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

    html.window.history.replaceState({}, '', urlPath);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _adsScrollController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  if (_isDisposed) return const SizedBox.shrink();

  final HomeController homeController = Get.find<HomeController>();

  return Obx(() {
    final isDarkMode = _themeController.isDarkMode.value;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: homeController.drawerType.value == DrawerType.settings
              ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
              : const DesktopServicesDrawer(key: ValueKey('services')),
        ),
      ),
      backgroundColor: AppColors.background(isDarkMode),

      // ✅ مهم جدًا أحيانًا: ضع لون خلفية للـ body نفسه (لتغطي أي فراغ)
      body: Container(
        color: AppColors.background(isDarkMode),
        child:Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey, isAdsScreen: true),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: 1400.w),
                margin: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sidebar
                    Container(
                      width: 260.w,
                      margin: EdgeInsets.only(top: 4.h),
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
                        physics: const ClampingScrollPhysics(),
                        child: CategoriesSidebarDesktop(),
                      ),
                    ),

                    // Main
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الإعلانات'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.xlarge,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(isDarkMode),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'استعرض الإعلانات وفلتر النتائج كما تشاء'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            _buildTopControls(isDarkMode, context),
                            SizedBox(height: 16.h),

                            Expanded(
                              child: Obx(() {
                                final isLoading = _adsController.isLoadingAds.value;
                                final ads = _adsController.filteredAdsList;
                                final viewMode = _adsController.viewMode.value;

                                if (isLoading) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 1.5,
                                    ),
                                  );
                                }

                                if (ads.isEmpty) {
                                  return _buildEmptyState(isDarkMode);
                                }

                                return Scrollbar(
                                  controller: _adsScrollController,
                                  thumbVisibility: true,
                                  child: _buildAdsGrid(
                                    isDarkMode: isDarkMode,
                                    viewMode: viewMode,
                                    ads: ads,
                                  ),
                                );
                              }),
                            ),

                            SizedBox(height: 16.h),
                            _buildPagination(isDarkMode),
                            SizedBox(height: 8.h),
                          ],
                        ),
                      ),
                    ),

                    // Filter
                    Container(
                      width: 260.w,
                      margin: EdgeInsets.only(top: 4.h),
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
                        categoryId: _adsController.selectedMainCategoryId.value ?? widget.categoryId,
                        currentTimeframe: widget.currentTimeframe ?? _selectedTimePeriod,
                        onlyFeatured: widget.onlyFeatured,
                       onFiltersApplied: () async {
  _adsController.currentPage.value = 1;
  _updateUrlWithFilters();
  await _scrollToTop();
  // ✅ لا تعمل fetch هنا لأن FilterScreen بالفعل عمل fetchAds مع priceMin/priceMax
},

                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
));});
  }

  Widget _buildTopControls(bool isDarkMode, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // count
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

          // حفظ البحث
          SizedBox(
            width: 130.w,
            child: ElevatedButton(
              onPressed: () => _showSaveSearchDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonAndLinksColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 16.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text(
                    'حفظ البحث'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // التالي (Shortcut)
          Obx(() {
            final currentPage = _adsController.currentPage.value;
            final totalPages = _adsController.totalPages.value;
            final canGoNext = currentPage < totalPages;

            return Tooltip(
              message: 'التالي'.tr,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 18.w),
                color: canGoNext
                    ? AppColors.textPrimary(isDarkMode)
                    : AppColors.textSecondary(isDarkMode),
                onPressed: canGoNext ? () => _goToPage(currentPage + 1) : null,
              ),
            );
          }),

          // sort + view
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
                Container(height: 24.h, width: 1, color: AppColors.divider(isDarkMode)),
                SizedBox(width: 16.w),
                _buildViewModeToggle(isDarkMode),
              ],
            ),
          ),
        ],
      ),
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

    // ✅ محدث: order الصحيح لكل sort
    final orderBySort = <String, String>{
      'newest': 'desc',
      'oldest': 'asc',
      'price_asc': 'asc',
      'price_desc': 'desc',
      'most_viewed': 'desc',
    };

    return Obx(() {
      final currentSort = _adsController.currentSortBy.value;

      return Row(
        children: [
          Text(
            'الفرز:'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: AppColors.background(isDarkMode),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentSort,
                icon: Icon(Icons.keyboard_arrow_down, size: 20.w, color: AppColors.textSecondary(isDarkMode)),
                elevation: 16,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
                onChanged: (String? newValue) async {
                  if (newValue == null) return;

                  final lang = Get.locale?.languageCode ?? 'ar';

                  final effectiveCategoryId = _adsController.selectedMainCategoryId.value ?? widget.categoryId;
                  final effectiveSubCategoryId = _adsController.selectedSubCategoryId.value ?? widget.subCategoryId;
                  final effectiveSubTwoCategoryId = _adsController.selectedSubTwoCategoryId.value ?? widget.subTwoCategoryId;

                  _adsController.currentPage.value = 1;

                  await _adsController.fetchAds(
                    categoryId: effectiveCategoryId,
                    subCategoryLevelOneId: effectiveSubCategoryId,
                    subCategoryLevelTwoId: effectiveSubTwoCategoryId,
                    sortBy: newValue,
                    order: orderBySort[newValue] ?? 'desc',
                    lang: lang,
                    timeframe: widget.currentTimeframe ?? _selectedTimePeriod,
                    page: 1,
                    perPage: _adsController.perPageRx.value,
                    cityId: _adsController.selectedCity.value?.id,
                    areaId: _adsController.selectedArea.value?.id,
                    attributes: _adsController.attrsPayload.value.isNotEmpty ? _adsController.attrsPayload.value : null,
                    search: _adsController.currentSearch.value.isNotEmpty ? _adsController.currentSearch.value : null,
                  );

                  _updateUrlWithFilters();
                  await _scrollToTop();
                },
                items: sortOptions.entries.map((entry) {
                  final key = entry.key;
                  final label = entry.value;

                  return DropdownMenuItem<String>(
                    value: key,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: currentSort == key ? AppColors.primary : AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                dropdownColor: AppColors.card(isDarkMode),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildViewModeToggle(bool isDarkMode) {
    return Obx(() {
      final mode = _adsController.viewMode.value;

      return Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.grid_view,
              size: 22.w,
              color: mode == 'grid' ? AppColors.primary : AppColors.textSecondary(isDarkMode),
            ),
            onPressed: () => _adsController.changeViewMode('grid'),
          ),
          SizedBox(width: 4.w),
          IconButton(
            icon: Icon(
              Icons.view_list,
              size: 22.w,
              color: mode == 'list' ? AppColors.primary : AppColors.textSecondary(isDarkMode),
            ),
            onPressed: () => _adsController.changeViewMode('list'),
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
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'جرب تغيير فلترات البحث أو معايير التصفية'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => _adsController.resetFilters(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 32.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              'إعادة تعيين الفلاتر'.tr,
              style: TextStyle(fontSize: 14.sp, fontFamily: AppTextStyles.appFontFamily),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdsGrid({
    required bool isDarkMode,
    required String viewMode,
    required List<dynamic> ads,
  }) {
    final isGrid = viewMode == 'grid';

    return GridView.builder(
      controller: _adsScrollController,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 5.h),
      gridDelegate: isGrid
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.78,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 140.h,
              mainAxisSpacing: 5.h,
              crossAxisSpacing: 16.w,
            ),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return AdsItemDesktop(
          ad: ad,
          viewMode: viewMode,
          key: ValueKey(ad.id),
        );
      },
    );
  }

  Widget _buildPagination(bool isDarkMode) {
    return Obx(() {
      final totalPages = _adsController.totalPages.value;
      final currentPage = _adsController.currentPage.value;
      final totalAdsCount = _adsController.totalAdsCount.value;

      if (totalPages <= 1) return const SizedBox();

      final canPrev = currentPage > 1;
      final canNext = currentPage < totalPages;

      return Container(
        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.card(isDarkMode),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${'الإجمالي:'.tr} $totalAdsCount ${'إعلان'.tr}",
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: canPrev ? () => _goToPage(currentPage - 1) : null,
                  icon: Icon(Icons.arrow_back_ios, size: 16.w),
                  label: Text('السابق'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: canPrev
                        ? AppColors.textPrimary(isDarkMode)
                        : AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(width: 8.w),

                ...List.generate(totalPages, (index) {
                  final pageNumber = index + 1;

                  if ((pageNumber - currentPage).abs() > 2 &&
                      pageNumber != 1 &&
                      pageNumber != totalPages) {
                    if ((pageNumber - currentPage).abs() == 3) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Text(
                          '...',
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDarkMode),
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  }

                  final isActive = currentPage == pageNumber;

                  return InkWell(
                    onTap: () => _goToPage(pageNumber),
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.white : AppColors.textPrimary(isDarkMode),
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(width: 8.w),

                TextButton.icon(
                  onPressed: canNext ? () => _goToPage(currentPage + 1) : null,
                  icon: Icon(Icons.arrow_forward_ios, size: 16.w),
                  label: Text('التالي'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: canNext
                        ? AppColors.textPrimary(isDarkMode)
                        : AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showSaveSearchDialog(BuildContext context) {
    final SearchHistoryController searchHistoryController =
        Get.put(SearchHistoryController());

    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final TextEditingController searchNameController = TextEditingController();
    bool emailNotifications = true;
    bool mobileNotifications = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 350.w),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                        onChanged: (value) => setState(() => emailNotifications = value ?? false),
                      ),
                      SizedBox(height: 12.h),
                      _buildNotificationOption(
                        title: 'إشعارات الهاتف المحمول'.tr,
                        value: mobileNotifications,
                        isDarkMode: isDarkMode,
                        onChanged: (value) => setState(() => mobileNotifications = value ?? false),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: BorderSide(color: AppColors.buttonAndLinksColor, width: 1.2),
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
                                }

                                final effectiveCategoryId =
                                    _adsController.selectedMainCategoryId.value ?? widget.categoryId;

                                if (effectiveCategoryId == null) {
                                  Get.snackbar(
                                    'تنبيه'.tr,
                                    'لايمكنك حفظ البحث في عمليات البحث او الاعلانات المميزة او العاجلة'.tr,
                                  );
                                  return;
                                }

                                searchHistoryController.addSearchHistory(
                                  userId: userId,
                                  recordName: searchNameController.text,
                                  categoryId: effectiveCategoryId,
                                  subcategoryId: _adsController.selectedSubCategoryId.value ?? widget.subCategoryId,
                                  secondSubcategoryId: _adsController.selectedSubTwoCategoryId.value ?? widget.subTwoCategoryId,
                                  notifyPhone: mobileNotifications,
                                  notifyEmail: emailNotifications,
                                );

                                Navigator.pop(dialogContext);
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

  // ====== Image Search Dialog (محدث: بدون dart:io + يشتغل Web وغير Web) ======
  void _showImageSearchDialog() {
    final AdsController adsController = Get.find<AdsController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();

    Uint8List? pickedBytes;
    String? pickedName;
    XFile? pickedXFile;
    bool isSearching = false;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isDark = themeController.isDarkMode.value;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                if (kIsWeb) {
                  if (source == ImageSource.camera) {
                    final XFile? x = await ImagePicker().pickImage(source: ImageSource.camera);
                    if (x != null) {
                      final bytes = await x.readAsBytes();
                      setState(() {
                        pickedBytes = bytes;
                        pickedName = x.name;
                        pickedXFile = XFile.fromData(bytes, name: x.name);
                      });
                    }
                  } else {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final bytes = result.files.first.bytes;
                      final name = result.files.first.name;
                      if (bytes != null) {
                        setState(() {
                          pickedBytes = bytes;
                          pickedName = name;
                          pickedXFile = XFile.fromData(bytes, name: name);
                        });
                      }
                    }
                  }
                } else {
                  final XFile? x = await ImagePicker().pickImage(
                    source: source,
                    imageQuality: 80,
                    maxWidth: 1024,
                  );
                  if (x != null) {
                    final bytes = await x.readAsBytes();
                    setState(() {
                      pickedBytes = bytes;
                      pickedName = x.name;
                      pickedXFile = x;
                    });
                  }
                }
              } catch (e) {
                debugPrint('Image pick error: $e');
                Get.snackbar('خطأ', 'فشل اختيار الصورة', snackPosition: SnackPosition.BOTTOM);
              }
            }

            Widget buildImagePreview() {
              return pickedBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.memory(pickedBytes!, fit: BoxFit.cover),
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
                            icon: const Icon(Icons.photo_camera),
                            label: Text(
                              'كاميرا'.tr,
                              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.black),
                            ),
                            onPressed: isSearching ? null : () => pickImage(ImageSource.camera),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              'معرض'.tr,
                              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.black),
                            ),
                            onPressed: isSearching ? null : () => pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSearching ? null : () => Navigator.pop(dialogContext),
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
                            onPressed: (isSearching || pickedXFile == null)
                                ? null
                                : () async {
                                    setState(() => isSearching = true);
                                    try {
                                      final lang = languageController.currentLocale.value.languageCode;

                                      final effectiveCategoryId =
                                          _adsController.selectedMainCategoryId.value ?? widget.categoryId;
                                      final effectiveSubCategoryId =
                                          _adsController.selectedSubCategoryId.value ?? widget.subCategoryId;
                                      final effectiveSubTwoCategoryId =
                                          _adsController.selectedSubTwoCategoryId.value ?? widget.subTwoCategoryId;

                                      await adsController.searchAdsByImage(
                                        imageFile: pickedXFile!,
                                        lang: lang,
                                        page: 1,
                                        perPage: 15,
                                        categoryId: effectiveCategoryId,
                                        subCategoryLevelOneId: effectiveSubCategoryId,
                                        subCategoryLevelTwoId: effectiveSubTwoCategoryId,
                                        debug: false,
                                      );

                                      Navigator.pop(dialogContext);
                                      Get.snackbar('نجاح', 'تم جلب النتائج', snackPosition: SnackPosition.BOTTOM);

                                      await _scrollToTop();
                                    } catch (e, st) {
                                      debugPrint('searchByImage error: $e\n$st');
                                      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
                                      setState(() => isSearching = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonAndLinksColor,
                            ),
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
          },
        );
      },
    );
  }
}
