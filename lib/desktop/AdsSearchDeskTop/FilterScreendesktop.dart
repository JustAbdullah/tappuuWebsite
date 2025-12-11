import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/CategoryAttributesResponse.dart';
import '../../core/data/model/City.dart';
import '../../core/localization/changelanguage.dart';

enum PriceModeDesktop { range, minOnly }

class FilterScreenDestktop extends StatefulWidget {
  final int? categoryId;
  final String? currentTimeframe;
  final bool onlyFeatured;
  final VoidCallback? onFiltersApplied; // كولباك لتحديث الرابط وغيره

  const FilterScreenDestktop({
    super.key,
    required this.categoryId,
    this.currentTimeframe,
    this.onlyFeatured = false,
    this.onFiltersApplied,
  });

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreenDestktop> {
  static const LatLng DEFAULT_LOCATION = LatLng(33.5138, 36.2765); // وسط دمشق

  bool _isApplyingFilters = false;
  final AdsController _adsController = Get.find<AdsController>();
  final themeController = Get.find<ThemeController>();
  bool get isDarkMode => themeController.isDarkMode.value;

  final _formKey = GlobalKey<FormState>();
  final AreaController _areaController = Get.put(AreaController());

  final List<Map<String, String?>> timePeriods = [
    {'value': '24h', 'label': 'آخر 24 ساعة'.tr},
    {'value': '48h', 'label': 'آخر يومين'.tr},
    {'value': 'week', 'label': 'آخر أسبوع'.tr},
    {'value': 'month', 'label': 'آخر شهر'.tr},
    {'value': 'year', 'label': 'آخر سنة'.tr},
    {'value': 'all', 'label': 'كل الأوقات'.tr},
  ];

  String? _selectedTimePeriod;
  final Map<int, dynamic> _attributeValues = {};
  TheCity? _tempSelectedCity;
  Area? _tempSelectedArea;
  bool _locationLoading = false;

  final List<Map<String, dynamic>> radiusOptions = [
    {'value': 1.0, 'label': '1 كم'.tr},
    {'value': 5.0, 'label': '5 كم'.tr},
    {'value': 10.0, 'label': '10 كم'.tr},
    {'value': 20.0, 'label': '20 كم'.tr},
    {'value': 50.0, 'label': '50 كم'.tr},
  ];
  double? _selectedDistance;

  // السعر (مثل الموبايل)
  PriceModeDesktop _priceMode = PriceModeDesktop.range;
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // نسخ الحالة الحالية مؤقتاً (عشان لو أقفل الفلترة أرجع زي ما كنت)
    _tempSelectedCity = _adsController.selectedCity.value;
    _tempSelectedArea = _adsController.selectedArea.value;

    // تعيين موقع افتراضي لو مافيه
    if (_adsController.latitude.value == null ||
        _adsController.longitude.value == null) {
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final lang =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    // التصنيفات الرئيسية
    await _adsController.fetchMainCategories(lang);

    if (widget.categoryId != null && widget.categoryId! > 0) {
      _adsController.currentCategoryId.value = widget.categoryId!;
      _adsController.selectedMainCategoryId.value = widget.categoryId!;

      await _adsController.fetchSubCategories(widget.categoryId!, lang);

      await _adsController.fetchAttributes(
        categoryId: widget.categoryId!,
        lang: lang,
      );
    }

    // المدن
    await _adsController.fetchCities('SY', lang);

    // لو لسه على الموقع الافتراضي، حاول تجيب موقع حقيقي
    if (_adsController.latitude.value == DEFAULT_LOCATION.latitude &&
        _adsController.longitude.value == DEFAULT_LOCATION.longitude) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          debugPrint('تم رفض إذن الوصول للموقع');
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('خدمة الموقع غير مفعلة');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      _adsController.latitude.value = position.latitude;
      _adsController.longitude.value = position.longitude;
    } catch (e) {
      debugPrint('خطأ في جلب الموقع: $e');
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;
    } finally {
      setState(() => _locationLoading = false);
    }
  }

  @override
  void dispose() {
    // رجّع المدينة والمنطقة اللي كانت قبل فتح الفلترة
    _adsController.selectedCity.value = _tempSelectedCity;
    _adsController.selectedArea.value = _tempSelectedArea;

    // تفريغ الحالة المحلية + الكنترولر
    _attributeValues.clear();
    _selectedTimePeriod = null;
    _selectedDistance = null;
    _adsController.resetFilterState();
    _tempSelectedCity = null;
    _tempSelectedArea = null;

    _priceMinController.dispose();
    _priceMaxController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (_adsController.isLoadingAttributes.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.0,
            ),
          );
        }

        return Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 110.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopFilterBar(),
                    SizedBox(height: 16.h),
                    _buildKeywordSearch(isDarkMode),
                    SizedBox(height: 16.h),
                    _buildCategorySection(isDarkMode),
                    SizedBox(height: 16.h),
                    _buildAttributesSection(),
                    SizedBox(height: 16.h),
                    _buildPriceSection(), // 🟢 فلترة السعر
                    SizedBox(height: 16.h),
                    _buildLocationFilterSection(isDarkMode),
                    SizedBox(height: 16.h),
                    _buildCityAreaSection(),
                    SizedBox(height: 16.h),
                    _buildTimePeriodSection(isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      bottomSheet: _buildActionButtons(),
    );
  }

  // ==================== شريط التصفية العلوي ====================
  Widget _buildTopFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(isDarkMode),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 20.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خيارات الفلترة'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'خصص النتائج حسب المدينة، الخصائص، السعر، والوقت.'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          // 🔴 زر إعادة التعيين في الأعلى تم حذفه لأنه بلا فائدة
        ],
      ),
    );
  }

  // ==================== قسم البحث بالكلمات ====================
  Widget _buildKeywordSearch(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'البحث بالكلمات'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _adsController.searchController,
            decoration: InputDecoration(
              labelText: 'ابحث في الإعلانات...'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.small,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20.w,
                color: AppColors.textSecondary(isDarkMode),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18.w,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                onPressed: () {
                  _adsController.searchController.clear();
                  _adsController.currentSearch.value = '';
                  widget.onFiltersApplied?.call();
                },
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppColors.border(isDarkMode),
                  width: 0.6,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppColors.border(isDarkMode),
                  width: 0.6,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.1,
                ),
              ),
            ),
            onChanged: (value) {
              _adsController.currentSearch.value = value;
              widget.onFiltersApplied?.call();
            },
          ),
        ],
      ),
    );
  }

  // ==================== قسم التصنيفات ====================
  Widget _buildCategorySection(bool isDarkMode) {
    return Obx(() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التصنيفات'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12.h),

            // التصنيف الرئيسي
            _buildStyledDropdown<int>(
              hint: 'التصنيف الرئيسي'.tr,
              items: _adsController.mainCategories
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name ?? '—'),
                    ),
                  )
                  .toList(),
              value: _adsController.selectedMainCategoryId.value,
              onChanged: (v) async {
                _adsController.updateMainCategory(v);
                widget.onFiltersApplied?.call();

                if (v != null) {
                  final lang =
                      Get.find<ChangeLanguageController>()
                          .currentLocale
                          .value
                          .languageCode;
                  await _adsController.fetchAttributes(
                    categoryId: v,
                    lang: lang,
                  );
                }
              },
              enabled: true,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 12.h),

            // التصنيف الفرعي
            _buildStyledDropdown<int>(
              hint: 'التصنيف الفرعي'.tr,
              items: _adsController.subCategories
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name ?? '—'),
                    ),
                  )
                  .toList(),
              value: _adsController.selectedSubCategoryId.value,
              onChanged: (v) {
                _adsController.updateSubCategory(v);
                widget.onFiltersApplied?.call();
              },
              enabled: _adsController.selectedMainCategoryId.value != null,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 12.h),

            // التصنيف الفرعي الثانوي
            _buildStyledDropdown<int>(
              hint: 'التصنيف الفرعي الثانوي'.tr,
              items: _adsController.subTwoCategories
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name ?? '—'),
                    ),
                  )
                  .toList(),
              value: _adsController.selectedSubTwoCategoryId.value,
              onChanged: (v) {
                _adsController.updateSubTwoCategory(v);
                widget.onFiltersApplied?.call();
              },
              enabled: _adsController.selectedSubCategoryId.value != null,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStyledDropdown<T>({
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required T? value,
    required ValueChanged<T?> onChanged,
    required bool enabled,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.border(isDarkMode),
          width: 0.6,
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: enabled && items.any((item) => item.value == value) ? value : null,
        items: items,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(
            Icons.category_outlined,
            size: 18.w,
            color: AppColors.textSecondary(isDarkMode),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          color: AppColors.textPrimary(isDarkMode),
        ),
        dropdownColor: AppColors.card(isDarkMode),
        hint: Text(
          hint,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ),
    );
  }

  // ==================== فلترة الموقع الجغرافي ====================
  Widget _buildLocationFilterSection(bool isDarkMode) {
    final currentLocation = LatLng(
      _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
      _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
    );

    final mapController = MapController();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الموقع الجغرافي'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.border(isDarkMode), width: 0.6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: currentLocation,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.stay_in_me_website',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentLocation,
                            child: Icon(
                              Icons.location_pin,
                              size: 46.w,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_locationLoading)
                    Container(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _buildRefreshLocationButton(onPressed: () async {
            await _adsController.refreshLocation();
            await _adsController.fetchCurrentLocation();

            final newLocation = LatLng(
              _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
              _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
            );
            mapController.move(newLocation, mapController.camera.zoom);
          }),
          SizedBox(height: 12.h),
          Text(
            'المسافة من موقعك الحالي:'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(height: 8.h),
          _buildDistanceDropdown(isDarkMode),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyLocationFilter,
              icon: Icon(Icons.my_location_rounded, size: 18.w),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              label: Text(
                'حصر الإعلانات بالقرب مني'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshLocationButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.refresh_rounded, size: 18.w),
        label: Text(
          'تحديث موقعك الحالي'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.small,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonAndLinksColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceDropdown(bool isDarkMode) {
    return DropdownButtonFormField<double>(
      value: _selectedDistance,
      decoration: InputDecoration(
        labelText: 'اختر المسافة'.tr,
        labelStyle: TextStyle(
          fontSize: AppTextStyles.small,
          color: AppColors.textSecondary(isDarkMode),
        ),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.1,
          ),
        ),
      ),
      items: radiusOptions.map((option) {
        final double val = option['value'] as double;
        final String label = option['label'] as String;
        return DropdownMenuItem<double>(
          value: val,
          child: Text(label),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedDistance = value;
        });
        _adsController.selectedRadius.value = value;
      },
    );
  }

  void _applyLocationFilter() {
    if (_selectedDistance != null &&
        _adsController.latitude.value != null &&
        _adsController.longitude.value != null) {
      final priceMin = _parsePrice(_priceMinController.text);
      final priceMax = _priceMode == PriceModeDesktop.minOnly
          ? null
          : _parsePrice(_priceMaxController.text);

      _adsController.fetchAds(
        categoryId: _adsController.currentCategoryId.value,
        subCategoryLevelOneId:
            _adsController.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId:
            _adsController.currentSubCategoryLevelTwoId.value,
        search: _adsController.currentSearch.value.isNotEmpty
            ? _adsController.currentSearch.value
            : null,
        sortBy: _adsController.currentSortBy.value,
        attributes: _adsController.attrsPayload.value.isNotEmpty
            ? _adsController.attrsPayload.value
            : null,
        lang: Get.find<ChangeLanguageController>()
            .currentLocale
            .value
            .languageCode,
        page: 1,
        timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
        onlyFeatured: widget.onlyFeatured,
        latitude: _adsController.latitude.value,
        longitude: _adsController.longitude.value,
        distanceKm: _adsController.selectedRadius.value,
        priceMin: priceMin,
        priceMax: priceMax,
      );
    } else {
      Get.snackbar(
        'تحذير'.tr,
        'يرجى تحديد المسافة والتأكد من تفعيل الموقع'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
      );
    }
  }

  // ==================== قسم الخصائص ====================
  Widget _buildAttributesSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'الخصائص'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          ..._adsController.attributesList.map((attribute) {
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      attribute.label,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ),
                  _buildAttributeInput(attribute),
                  Divider(
                    height: 20.h,
                    color: AppColors.divider(isDarkMode),
                    thickness: 0.6,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAttributeInput(CategoryAttribute attribute) {
    switch (attribute.type) {
      case 'options':
        return _buildOptionsAttribute(attribute);
      case 'boolean':
        return _buildBooleanAttribute(attribute);
      case 'text':
        return _buildTextAttribute(attribute);
      case 'number':
        return _buildNumberAttribute(attribute);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOptionsAttribute(CategoryAttribute attribute) {
    return DropdownButtonFormField<int>(
      value: _attributeValues[attribute.attributeId] as int?,
      decoration: InputDecoration(
        hintText: '${'اختر'.tr} ${attribute.label}',
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.1,
          ),
        ),
      ),
      items: attribute.options.map((option) {
        return DropdownMenuItem<int>(
          value: option.id,
          child: Text(
            option.value,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.attributeId] = value;
        });
      },
      dropdownColor: AppColors.card(isDarkMode),
    );
  }

  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final currentValue = _attributeValues[attribute.attributeId] as bool?;

    return Row(
      children: [
        _buildBooleanOption(
          'نعم'.tr,
          currentValue == true,
          () {
            setState(() {
              _attributeValues[attribute.attributeId] = true;
            });
          },
        ),
        SizedBox(width: 10.w),
        _buildBooleanOption(
          'لا'.tr,
          currentValue == false,
          () {
            setState(() {
              _attributeValues[attribute.attributeId] = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBooleanOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border(isDarkMode),
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.small,
            color:
                isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAttribute(CategoryAttribute attribute) {
    return TextFormField(
      controller: TextEditingController(
        text: _attributeValues[attribute.attributeId]?.toString() ?? '',
      ),
      onChanged: (value) {
        _attributeValues[attribute.attributeId] = value;
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.1,
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.small,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  Widget _buildNumberAttribute(CategoryAttribute attribute) {
    return TextFormField(
      controller: TextEditingController(
        text: _attributeValues[attribute.attributeId]?.toString() ?? '',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
          final latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          final normalizedValue = value
              .split('')
              .map((char) {
                final index = arabic.indexOf(char);
                return index != -1 ? latin[index] : char;
              })
              .join('');

          _attributeValues[attribute.attributeId] =
              double.tryParse(normalizedValue);
        } else {
          _attributeValues[attribute.attributeId] = null;
        }
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.1,
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.small,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  // ==================== قسم المدن والمناطق ====================
  Widget _buildCityAreaSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'الموقع'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          _buildCityDropdown(),
          if (_adsController.selectedCity.value != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _buildAreaDropdown(),
            ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.border(isDarkMode),
          width: 0.6,
        ),
      ),
      child: DropdownButtonFormField<TheCity>(
        value: _adsController.selectedCity.value,
        decoration: InputDecoration(
          labelText: 'المدينة'.tr,
          prefixIcon: Icon(
            Icons.location_city_rounded,
            size: 18.w,
            color: AppColors.textSecondary(isDarkMode),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
          border: InputBorder.none,
        ),
        items: _adsController.citiesList.map((city) {
          return DropdownMenuItem<TheCity>(
            value: city,
            child: Text(
              city.translations.first.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          );
        }).toList(),
        onChanged: (city) {
          if (city == null) return;
          setState(() {
            _adsController.selectCity(city);
            widget.onFiltersApplied?.call();
          });
        },
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,
          color: AppColors.textPrimary(isDarkMode),
        ),
        dropdownColor: AppColors.card(isDarkMode),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    final localDark = Get.find<ThemeController>().isDarkMode.value;

    return Obx(() {
      final selectedCity = _adsController.selectedCity.value;

      if (selectedCity == null) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.border(localDark),
              width: 0.6,
            ),
          ),
          child: DropdownButtonFormField<Area>(
            value: null,
            decoration: InputDecoration(
              labelText: 'المنطقة'.tr,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              filled: true,
              fillColor: AppColors.surface(localDark),
              border: InputBorder.none,
            ),
            items: const [],
            onChanged: null,
            hint: Text(
              'اختر المدينة أولاً'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(localDark),
              ),
            ),
            dropdownColor: AppColors.card(localDark),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(localDark),
            ),
          ),
        );
      }

      return FutureBuilder<List<Area>>(
        future: _areaController.getAreasOrFetch(selectedCity.id),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final list = snapshot.data ?? const <Area>[];

          return DropdownButtonFormField<Area>(
            key: ValueKey<int>(selectedCity.id),
            value: list.any((a) => a.id == _adsController.selectedArea.value?.id)
                ? _adsController.selectedArea.value
                : null,
            decoration: InputDecoration(
              labelText: 'المنطقة'.tr,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              filled: true,
              fillColor: AppColors.surface(localDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppColors.border(localDark),
                  width: 0.6,
                ),
              ),
            ),
            items: list.map((area) {
              return DropdownMenuItem<Area>(
                value: area,
                child: Text(
                  area.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textPrimary(localDark),
                  ),
                ),
              );
            }).toList(),
            onChanged: (area) {
              if (area != null) {
                _adsController.selectArea(area);
                widget.onFiltersApplied?.call();
              }
            },
            hint: Text(
              isLoading
                  ? 'جارٍ تحميل المناطق...'.tr
                  : (hasError
                      ? 'حدث خطأ أثناء الجلب'.tr
                      : 'اختر المنطقة'.tr),
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(localDark),
              ),
            ),
            dropdownColor: AppColors.card(localDark),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(localDark),
            ),
          );
        },
      );
    });
  }

  // ==================== قسم الفترة الزمنية ====================
  Widget _buildTimePeriodSection(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفترة الزمنية'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.small,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: timePeriods.map((period) {
              final value = period['value']!;
              final label = period['label']!;
              final isSelected = _selectedTimePeriod == value;

              return ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary(isDarkMode),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTimePeriod = selected ? value : null;
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface(isDarkMode),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border(isDarkMode),
                  width: 0.7,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== قسم السعر ====================
  Widget _buildPriceSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: [
              _buildPriceModeChip(
                label: 'نطاق (من–إلى)'.tr,
                selected: _priceMode == PriceModeDesktop.range,
                onTap: () {
                  setState(() {
                    _priceMode = PriceModeDesktop.range;
                  });
                },
              ),
              _buildPriceModeChip(
                label: 'أعلى من'.tr,
                selected: _priceMode == PriceModeDesktop.minOnly,
                onTap: () {
                  setState(() {
                    _priceMode = PriceModeDesktop.minOnly;
                    _priceMaxController.clear();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceMinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9٠-٩,،,]'),
                    ),
                  ],
                  onChanged: (v) => _formatControllerText(_priceMinController),
                  decoration: InputDecoration(
                    labelText: 'السعر من'.tr,
                    prefixIcon: const Icon(Icons.arrow_upward, size: 18),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.border(isDarkMode),
                        width: 0.6,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.border(isDarkMode),
                        width: 0.6,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextFormField(
                  controller: _priceMaxController,
                  enabled: _priceMode == PriceModeDesktop.range,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9٠-٩,،,]'),
                    ),
                  ],
                  onChanged: (v) => _formatControllerText(_priceMaxController),
                  decoration: InputDecoration(
                    labelText: 'السعر إلى'.tr,
                    prefixIcon: const Icon(Icons.arrow_downward, size: 18),
                    suffixIcon: _priceMode == PriceModeDesktop.minOnly
                        ? const Icon(Icons.lock_outline, size: 18)
                        : (_priceMaxController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _priceMaxController.clear();
                                  });
                                },
                              )),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.border(isDarkMode),
                        width: 0.6,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.border(isDarkMode),
                        width: 0.6,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary(isDarkMode),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _priceSummary(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color:
                    selected ? Colors.white : AppColors.textPrimary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== منطق السعر ====================

  String _normalizeDigits(String input) {
    const arabic = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
      '٬',
      '،',
      ','
    ];
    const latin = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '',
      ''
    ];
    final buf = StringBuffer();
    for (final ch in input.trim().split('')) {
      final i = arabic.indexOf(ch);
      buf.write(i == -1 ? ch : latin[i]);
    }
    return buf.toString();
  }

  double? _parsePrice(String s) {
    final t = _normalizeDigits(s).replaceAll(',', '').trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null ? null : max(0, v);
  }

  String _formatWithGrouping(num value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return buf.toString();
  }

  String _priceSummary() {
    final min = _parsePrice(_priceMinController.text);
    final max = _parsePrice(_priceMaxController.text);

    if (_priceMode == PriceModeDesktop.minOnly) {
      if (min == null) {
        return 'اكتب الحد الأدنى لعرض إعلانات أعلى من هذه القيمة.'.tr;
      }
      return 'سيتم عرض الإعلانات بسعر أعلى من ${_formatWithGrouping(min)}.'.tr;
    }

    // نطاق
    if (min == null && max == null) {
      return 'اترك السعر فارغًا لتجاهله.'.tr;
    }
    if (min != null && max == null) {
      return 'سيتم عرض الإعلانات من ${_formatWithGrouping(min)} وحتى أي سعر أعلى.'.tr;
    }
    if (min == null && max != null) {
      return 'سيتم عرض الإعلانات حتى ${_formatWithGrouping(max)}.'.tr;
    }
    if (min != null && max != null) {
      if (min > max) {
        return 'تنبيه: "من" أكبر من "إلى" — صحّح القيم.'.tr;
      }
      return 'سيتم عرض الإعلانات ضمن ${_formatWithGrouping(min)} – ${_formatWithGrouping(max)}.'.tr;
    }
    return '';
  }

  void _formatControllerText(TextEditingController ctrl) {
    final parsed = _parsePrice(ctrl.text);
    final newText = parsed == null ? '' : _formatWithGrouping(parsed);
    ctrl
      ..text = newText
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    setState(() {}); // لتحديث الملخص / الأيقونات
  }

  // ==================== تطبيق الفلاتر ====================
  void _applyFilters() async {
    if (!_formKey.currentState!.validate()) return;

    final priceMin = _parsePrice(_priceMinController.text);
    final priceMax = _priceMode == PriceModeDesktop.minOnly
        ? null
        : _parsePrice(_priceMaxController.text);

    if (_priceMode == PriceModeDesktop.range &&
        priceMin != null &&
        priceMax != null &&
        priceMin > priceMax) {
      Get.snackbar(
        'تنبيه'.tr,
        'قيمة "من" يجب أن تكون أقل من أو تساوي "إلى"'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isApplyingFilters = true);

    final attrsPayload = _buildAttributesPayload();
    _adsController.attrsPayload.value = attrsPayload;

    final selectedCityId = _adsController.selectedCity.value?.id;
    final selectedAreaId = _adsController.selectedArea.value?.id;

    try {
      await _adsController.fetchAds(
        categoryId: _adsController.currentCategoryId.value,
        subCategoryLevelOneId:
            _adsController.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId:
            _adsController.currentSubCategoryLevelTwoId.value,
        search: _adsController.currentSearch.value.isNotEmpty
            ? _adsController.currentSearch.value
            : null,
        sortBy: _adsController.currentSortBy.value,
        cityId: selectedCityId,
        areaId: selectedAreaId,
        attributes: attrsPayload.isNotEmpty ? attrsPayload : null,
        lang: Get.find<ChangeLanguageController>()
            .currentLocale
            .value
            .languageCode,
        page: 1,
        timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
        onlyFeatured: widget.onlyFeatured,
        priceMin: priceMin,
        priceMax: priceMax,
      );

      final count = _adsController.adsList.length;
      Future.delayed(const Duration(milliseconds: 250), () {
        final msg = count == 0
            ? 'لا توجد إعلانات مطابقة'.tr
            : 'تم العثور على $count إعلان'.tr;
        Get.snackbar(
          'نتيجة الفلترة'.tr,
          msg,
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } catch (e) {
      Get.snackbar(
        'خطأ'.tr,
        'فشل الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isApplyingFilters = false);
    }
  }

  List<Map<String, dynamic>> _buildAttributesPayload() {
    return _attributeValues.entries.map((entry) {
      final attributeId = entry.key;
      final value = entry.value;

      final attribute = _adsController.attributesList.firstWhere(
        (attr) => attr.attributeId == attributeId,
        orElse: () => throw Exception('Attribute not found: $attributeId'),
      );

      return {
        'attribute_id': attributeId,
        'attribute_type': attribute.type,
        'value': value,
      };
    }).toList();
  }

  void _resetFilters() {
    _formKey.currentState?.reset();

    setState(() {
      _adsController.currentSearch.value = '';
      _adsController.searchController.clear();
      _adsController.isSearching.value = false;

      _adsController.selectedCity.value = _tempSelectedCity;
      _adsController.selectedArea.value = _tempSelectedArea;

      _selectedTimePeriod = null;
      _attributeValues.clear();
      _selectedDistance = null;
      _adsController.currentAttributes.clear();

      _priceMode = PriceModeDesktop.range;
      _priceMinController.clear();
      _priceMaxController.clear();

      _adsController.resetFilterState();

      // رجّع التصنيف الرئيسي إلى التصنيف الأصلي للشاشة
      _adsController.selectedMainCategoryId?.value = widget.categoryId;
      _adsController.selectedSubCategoryId?.value = null;
      _adsController.selectedSubTwoCategoryId?.value = null;

      if (widget.categoryId != null) {
        final lang = Get.find<ChangeLanguageController>()
            .currentLocale
            .value
            .languageCode;
        _adsController.fetchAttributes(
          categoryId: widget.categoryId ?? 1,
          lang: lang,
        );
      }

      if (_adsController.latitude.value == null ||
          _adsController.longitude.value == null) {
        _adsController.latitude.value = DEFAULT_LOCATION.latitude;
        _adsController.longitude.value = DEFAULT_LOCATION.longitude;
      }

      _adsController.fetchAds(
        categoryId: _adsController.currentCategoryId.value,
        subCategoryLevelOneId:
            _adsController.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId:
            _adsController.currentSubCategoryLevelTwoId.value,
        search: _adsController.currentSearch.value.isNotEmpty
            ? _adsController.currentSearch.value
            : null,
        sortBy: _adsController.currentSortBy.value,
        attributes: _adsController.attrsPayload.value.isNotEmpty
            ? _adsController.attrsPayload.value
            : null,
        lang: Get.find<ChangeLanguageController>()
            .currentLocale
            .value
            .languageCode,
        page: 1,
        timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
        onlyFeatured: widget.onlyFeatured,
        latitude: _adsController.latitude.value,
        longitude: _adsController.longitude.value,
        distanceKm: _adsController.selectedRadius.value,
      );
    });

    _applyFilters();
  }

  // ==================== أزرار الأسفل ====================
  Widget _buildActionButtons() {
    final localDark = themeController.isDarkMode.value;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.card(localDark),
        border: Border(
          top: BorderSide(
            color: AppColors.divider(localDark),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isApplyingFilters ? null : _resetFilters,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  side: BorderSide(
                    color: AppColors.border(localDark),
                    width: 0.9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'مسح الفلاتر'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _isApplyingFilters ? null : _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _isApplyingFilters
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'تطبيق الفلترة'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
