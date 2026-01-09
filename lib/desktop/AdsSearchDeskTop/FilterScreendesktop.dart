import 'dart:async';
import 'dart:math' show max, min;

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
  final VoidCallback? onFiltersApplied;

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

  final AdsController _adsController = Get.find<AdsController>();
  final ThemeController themeController = Get.find<ThemeController>();
  bool get isDarkMode => themeController.isDarkMode.value;

  final _formKey = GlobalKey<FormState>();
  final AreaController _areaController = Get.put(AreaController());

  final MapController _mapController = MapController();

  Timer? _searchDebounce;

  bool _didApply = false;
  TheCity? _tempSelectedCity;
  Area? _tempSelectedArea;

  bool _isApplyingFilters = false;

  // ==========================
  // ✅ Fix: منع الرجوع للقيم السابقة بعد async init
  // ==========================
  bool _initialDataLoaded = false;

  int _categorySwitchToken = 0; // لمنع سباقات تبديل التصنيف الخارجي
  int _initToken = 0; // لمنع سباقات initState async
  bool _userTouchedCategory = false; // المستخدم غيّر التصنيف يدويًا
  // ==========================

  final List<Map<String, String?>> timePeriods = [
    {'value': '24h', 'label': 'آخر 24 ساعة'.tr},
    {'value': '48h', 'label': 'آخر يومين'.tr},
    {'value': 'week', 'label': 'آخر أسبوع'.tr},
    {'value': 'month', 'label': 'آخر شهر'.tr},
    {'value': 'year', 'label': 'آخر سنة'.tr},
    {'value': 'all', 'label': 'كل الأوقات'.tr},
  ];

  String? _selectedTimePeriod;

  /// ✅ attributeId -> value
  /// - options: List<int> (حتى لو single)
  /// - boolean: bool
  /// - text: String
  /// - number: double
  final Map<int, dynamic> _attributeValues = {};

  final Map<int, TextEditingController> _attrTextCtrls = {};
  final Map<int, TextEditingController> _attrNumberCtrls = {};

  bool _locationLoading = false;

  final List<Map<String, dynamic>> radiusOptions = [
    {'value': 1.0, 'label': '1 كم'.tr},
    {'value': 5.0, 'label': '5 كم'.tr},
    {'value': 10.0, 'label': '10 كم'.tr},
    {'value': 20.0, 'label': '20 كم'.tr},
    {'value': 50.0, 'label': '50 كم'.tr},
  ];
  double? _selectedDistance;

  PriceModeDesktop _priceMode = PriceModeDesktop.range;
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _tempSelectedCity = _adsController.selectedCity.value;
    _tempSelectedArea = _adsController.selectedArea.value;

    _selectedTimePeriod = widget.currentTimeframe;
    _selectedDistance = _adsController.selectedRadius.value;

    if (_adsController.latitude.value == null || _adsController.longitude.value == null) {
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;
    }

    final token = ++_initToken;
    _loadInitialData(token).then((_) {
      if (!mounted) return;
      _initialDataLoaded = true;
    });
  }

  /// ✅ لو تغيّرت props من الأب (تنقل/ديب لينك)
  @override
  void didUpdateWidget(covariant FilterScreenDestktop oldWidget) {
    super.didUpdateWidget(oldWidget);

    // لو تغيّرت الفترة الزمنية فقط
    if (oldWidget.currentTimeframe != widget.currentTimeframe) {
      setState(() => _selectedTimePeriod = widget.currentTimeframe);
    }

    final oldId = oldWidget.categoryId ?? 0;
    final newId = widget.categoryId ?? 0;

    if (!_initialDataLoaded) return;
    if (oldId == newId) return;
    if (newId <= 0) return;

    // ✅ مهم: إذا الأب أعاد بناء الواجهة فقط ليعكس اختيار المستخدم داخل الفلترة
    // لا تعمل تنظيف/تحميل مرة ثانية.
    if (_userTouchedCategory && newId == (_adsController.selectedMainCategoryId.value ?? 0)) {
      _userTouchedCategory = false;
      return;
    }

    // ✅ إلغاء أي init قديم + اعتبره تغيير خارجي
    _initToken++;
    _userTouchedCategory = false;

    _onCategoryChangedExternally(newId);
  }

  Future<void> _loadInitialData(int token) async {
    final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    await _adsController.fetchMainCategories(lang);
    if (!mounted || token != _initToken) return;

    // ✅ لا تكتب widget.categoryId فوق اختيار موجود في الكنترولر
    final effectiveCatId = _adsController.selectedMainCategoryId.value ?? widget.categoryId;

    if (effectiveCatId != null && effectiveCatId > 0) {
      // إذا المستخدم ما لمس التصنيف يدويًا، نسمح للـ init يضبطه
      if (!_userTouchedCategory) {
        _adsController.currentCategoryId.value = effectiveCatId;
        _adsController.selectedMainCategoryId.value = effectiveCatId;
      }

      await _adsController.fetchSubCategories(effectiveCatId, lang);
      if (!mounted || token != _initToken) return;

      await _adsController.fetchAttributes(categoryId: effectiveCatId, lang: lang);
      if (!mounted || token != _initToken) return;
    }

    await _adsController.fetchCities('SY', lang);
    if (!mounted || token != _initToken) return;

    if (_adsController.latitude.value == DEFAULT_LOCATION.latitude &&
        _adsController.longitude.value == DEFAULT_LOCATION.longitude) {
      await _getCurrentLocation(moveMap: true);
    }
  }

  /// ✅ تغيير تصنيف من الأب/روت (خارجي)
  Future<void> _onCategoryChangedExternally(int categoryId) async {
    final token = ++_categorySwitchToken;

    _searchDebounce?.cancel();

    setState(() {
      _didApply = true;

      _clearAttributesState();

      try {
        _adsController.subCategories.clear();
        _adsController.subTwoCategories.clear();
      } catch (_) {}

      _adsController.selectedMainCategoryId.value = categoryId;
      _adsController.selectedSubCategoryId.value = null;
      _adsController.selectedSubTwoCategoryId.value = null;

      _adsController.currentCategoryId.value = categoryId;
      _adsController.currentSubCategoryLevelOneId.value = null;
      _adsController.currentSubCategoryLevelTwoId.value = null;

      try {
        _adsController.attributesList.clear();
      } catch (_) {}

      _adsController.attrsPayload.value = [];
    });

    final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    try {
      await _adsController.fetchSubCategories(categoryId, lang);
      if (!mounted) return;
      if (token != _categorySwitchToken) return;

      await _adsController.fetchAttributes(categoryId: categoryId, lang: lang);
      if (!mounted) return;
      if (token != _categorySwitchToken) return;
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('خطأ'.tr, 'فشل تحديث بيانات التصنيف: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _getCurrentLocation({bool moveMap = false}) async {
    if (!mounted) return;
    setState(() => _locationLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          debugPrint('تم رفض إذن الوصول للموقع');
          return;
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('خدمة الموقع غير مفعلة');
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      _adsController.latitude.value = position.latitude;
      _adsController.longitude.value = position.longitude;

      if (moveMap) {
        final newLoc = LatLng(position.latitude, position.longitude);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(newLoc, _mapController.camera.zoom);
        });
      }
    } catch (e) {
      debugPrint('خطأ في جلب الموقع: $e');
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;

      if (moveMap) {
        final newLoc = LatLng(DEFAULT_LOCATION.latitude, DEFAULT_LOCATION.longitude);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(newLoc, _mapController.camera.zoom);
        });
      }
    } finally {
      if (!mounted) return;
      setState(() => _locationLoading = false);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    if (!_didApply) {
      _adsController.selectedCity.value = _tempSelectedCity;
      _adsController.selectedArea.value = _tempSelectedArea;
    }

    for (final c in _attrTextCtrls.values) {
      c.dispose();
    }
    for (final c in _attrNumberCtrls.values) {
      c.dispose();
    }
    _attrTextCtrls.clear();
    _attrNumberCtrls.clear();

    _priceMinController.dispose();
    _priceMaxController.dispose();

    super.dispose();
  }

  void _clearAttributesState() {
    _attributeValues.clear();

    for (final c in _attrTextCtrls.values) {
      c.dispose();
    }
    for (final c in _attrNumberCtrls.values) {
      c.dispose();
    }
    _attrTextCtrls.clear();
    _attrNumberCtrls.clear();

    _adsController.attrsPayload.value = [];
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
                    _buildPriceSection(),
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
          Icon(Icons.tune_rounded, size: 20.w, color: AppColors.primary),
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
        ],
      ),
    );
  }

  // ==================== البحث بالكلمات ====================
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
                  _searchDebounce?.cancel();
                  _adsController.searchController.clear();
                  _adsController.currentSearch.value = '';
                  _applyFilters();
                },
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.1),
              ),
            ),
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                _adsController.currentSearch.value = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ==================== التصنيفات ====================
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
            _buildStyledDropdown<int>(
              hint: 'التصنيف الرئيسي'.tr,
              items: _adsController.mainCategories
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name ?? '—'),
                      ))
                  .toList(),
              value: _adsController.selectedMainCategoryId.value,
              onChanged: (v) async {
                // ✅ هذه أهم سطور تمنع رجوع القيمة بعد 5 ثواني
                _userTouchedCategory = true;
                _initToken++; // يلغي init async القديم فورًا

                _adsController.updateMainCategory(v);
                _clearAttributesState();

                if (v != null) {
                  final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                  await _adsController.fetchSubCategories(v, lang);
                  await _adsController.fetchAttributes(categoryId: v, lang: lang);
                }
              },
              enabled: true,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 12.h),
            _buildStyledDropdown<int>(
              hint: 'التصنيف الفرعي'.tr,
              items: _adsController.subCategories
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name ?? '—'),
                      ))
                  .toList(),
              value: _adsController.selectedSubCategoryId.value,
              onChanged: (v) {
                _adsController.updateSubCategory(v);
              },
              enabled: _adsController.selectedMainCategoryId.value != null,
              isDarkMode: isDarkMode,
            ),
            SizedBox(height: 12.h),
            _buildStyledDropdown<int>(
              hint: 'التصنيف الفرعي الثانوي'.tr,
              items: _adsController.subTwoCategories
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name ?? '—'),
                      ))
                  .toList(),
              value: _adsController.selectedSubTwoCategoryId.value,
              onChanged: (v) {
                _adsController.updateSubTwoCategory(v);
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
        border: Border.all(color: AppColors.border(isDarkMode), width: 0.6),
      ),
      child: DropdownButtonFormField<T>(
        value: enabled && items.any((item) => item.value == value) ? value : null,
        items: items,
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(Icons.category_outlined, size: 18.w, color: AppColors.textSecondary(isDarkMode)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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

  // ==================== الخصائص ====================
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
      case 'multi_options':
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

  bool _isMulti(CategoryAttribute a) {
    return a.isMultiSelect == true || a.type == 'multi_options';
  }

  List<int> _getSelectedIds(CategoryAttribute attribute) {
    final v = _attributeValues[attribute.attributeId];

    if (v is List<int>) return v;

    if (v is List) {
      final out = <int>[];
      for (final x in v) {
        if (x is int && x > 0) out.add(x);
        if (x is String) {
          final p = int.tryParse(x);
          if (p != null && p > 0) out.add(p);
        }
      }
      return out;
    }

    if (v is int && v > 0) return [v];
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null && p > 0) return [p];
    }

    return <int>[];
  }

  Widget _buildOptionsAttribute(CategoryAttribute attribute) {
    final opts = attribute.options;
    if (opts.isEmpty) {
      return Text(
        'لا توجد خيارات لهذا الحقل'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,
          color: AppColors.textSecondary(isDarkMode),
        ),
      );
    }

    if (_isMulti(attribute)) {
      return _buildMultiOptionsAttribute(attribute);
    }

    return _buildSingleOptionAttribute(attribute);
  }

  Widget _buildSingleOptionAttribute(CategoryAttribute attribute) {
    final opts = attribute.options;
    final selectedIds = _getSelectedIds(attribute);
    final selectedOne = selectedIds.isEmpty ? null : selectedIds.first;

    return DropdownButtonFormField<int>(
      value: selectedOne,
      decoration: InputDecoration(
        hintText: '${'اختر'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.1),
        ),
      ),
      items: opts.map((option) {
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
          if (value == null) {
            _attributeValues.remove(attribute.attributeId);
          } else {
            _attributeValues[attribute.attributeId] = <int>[value];
          }
        });
      },
      dropdownColor: AppColors.card(isDarkMode),
    );
  }

  Widget _buildMultiOptionsAttribute(CategoryAttribute attribute) {
    final opts = attribute.options;
    if (opts.isEmpty) {
      return Text(
        'لا توجد خيارات لهذا الحقل'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,
          color: AppColors.textSecondary(isDarkMode),
        ),
      );
    }

    final selectedIds = _getSelectedIds(attribute);

    return _MultiOptionsDropdown(
      isDarkMode: isDarkMode,
      label: attribute.label,
      options: opts,
      selectedIds: selectedIds,
      onChanged: (ids) {
        setState(() {
          if (ids.isEmpty) {
            _attributeValues.remove(attribute.attributeId);
          } else {
            _attributeValues[attribute.attributeId] = ids;
          }
        });
      },
    );
  }

  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final currentValue = _attributeValues[attribute.attributeId] as bool?;
    return Row(
      children: [
        _buildBooleanOption('نعم'.tr, currentValue == true, () {
          setState(() => _attributeValues[attribute.attributeId] = true);
        }),
        SizedBox(width: 10.w),
        _buildBooleanOption('لا'.tr, currentValue == false, () {
          setState(() => _attributeValues[attribute.attributeId] = false);
        }),
      ],
    );
  }

  Widget _buildBooleanOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.small,
            color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
          ),
        ),
      ),
    );
  }

  TextEditingController _textCtrlForAttr(int id) {
    return _attrTextCtrls.putIfAbsent(
      id,
      () => TextEditingController(text: _attributeValues[id]?.toString() ?? ''),
    );
  }

  TextEditingController _numberCtrlForAttr(int id) {
    return _attrNumberCtrls.putIfAbsent(
      id,
      () => TextEditingController(text: _attributeValues[id]?.toString() ?? ''),
    );
  }

  Widget _buildTextAttribute(CategoryAttribute attribute) {
    final ctrl = _textCtrlForAttr(attribute.attributeId);

    return TextFormField(
      controller: ctrl,
      onChanged: (value) {
        if (value.trim().isEmpty) {
          _attributeValues.remove(attribute.attributeId);
        } else {
          _attributeValues[attribute.attributeId] = value;
        }
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.1),
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
    final ctrl = _numberCtrlForAttr(attribute.attributeId);

    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isEmpty) {
          _attributeValues.remove(attribute.attributeId);
          return;
        }

        final arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
        final latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

        final normalized = value.split('').map((ch) {
          final idx = arabic.indexOf(ch);
          return idx != -1 ? latin[idx] : ch;
        }).join('');

        _attributeValues[attribute.attributeId] = double.tryParse(normalized);
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.1),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.small,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  // ==================== المدن والمناطق ====================
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
        border: Border.all(color: AppColors.border(isDarkMode), width: 0.6),
      ),
      child: DropdownButtonFormField<TheCity>(
        value: _adsController.selectedCity.value,
        decoration: InputDecoration(
          labelText: 'المدينة'.tr,
          prefixIcon: Icon(Icons.location_city_rounded, size: 18.w, color: AppColors.textSecondary(isDarkMode)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
          border: InputBorder.none,
        ),
        items: _adsController.citiesList.map((city) {
          final cityName = city.translations.isNotEmpty ? city.translations.first.name : '—';
          return DropdownMenuItem<TheCity>(
            value: city,
            child: Text(
              cityName,
              overflow: TextOverflow.ellipsis,
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
          _adsController.selectCity(city);
          _adsController.selectArea(null);
          setState(() {});
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
            border: Border.all(color: AppColors.border(localDark), width: 0.6),
          ),
          child: DropdownButtonFormField<Area>(
            value: null,
            decoration: InputDecoration(
              labelText: 'المنطقة'.tr,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              filled: true,
              fillColor: AppColors.surface(localDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.border(localDark), width: 0.6),
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
              _adsController.selectArea(area);
              setState(() {});
            },
            hint: Text(
              isLoading
                  ? 'جارٍ تحميل المناطق...'.tr
                  : (hasError ? 'حدث خطأ أثناء الجلب'.tr : 'اختر المنطقة'.tr),
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

  // ==================== الفترة الزمنية ====================
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
                    color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedTimePeriod = selected ? value : null);
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface(isDarkMode),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border(isDarkMode),
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

  // ==================== السعر ====================
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
                onTap: () => setState(() => _priceMode = PriceModeDesktop.range),
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
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩,،,]')),
                  ],
                  onChanged: (v) => _formatControllerText(_priceMinController),
                  decoration: InputDecoration(
                    labelText: 'السعر من'.tr,
                    prefixIcon: const Icon(Icons.arrow_upward, size: 18),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.1),
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
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩,،,]')),
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
                                onPressed: () => setState(() => _priceMaxController.clear()),
                              )),
                    filled: true,
                    fillColor: AppColors.surface(isDarkMode),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary(isDarkMode)),
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
          border: Border.all(color: AppColors.border(isDarkMode), width: 0.6),
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
                color: selected ? Colors.white : AppColors.textPrimary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== منطق السعر ====================
  String _normalizeDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '٬', '،', ','];
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '', '', ''];

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
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _priceSummary() {
    final minV = _parsePrice(_priceMinController.text);
    final maxV = _parsePrice(_priceMaxController.text);

    if (_priceMode == PriceModeDesktop.minOnly) {
      if (minV == null) return 'اكتب الحد الأدنى لعرض إعلانات أعلى من هذه القيمة.'.tr;
      return 'سيتم عرض الإعلانات بسعر أعلى من ${_formatWithGrouping(minV)}.'.tr;
    }

    if (minV == null && maxV == null) return 'اترك السعر فارغًا لتجاهله.'.tr;
    if (minV != null && maxV == null) {
      return 'سيتم عرض الإعلانات من ${_formatWithGrouping(minV)} وحتى أي سعر أعلى.'.tr;
    }
    if (minV == null && maxV != null) return 'سيتم عرض الإعلانات حتى ${_formatWithGrouping(maxV)}.'.tr;

    if (minV != null && maxV != null) {
      if (minV > maxV) return 'تنبيه: "من" أكبر من "إلى" — صحّح القيم.'.tr;
      return 'سيتم عرض الإعلانات ضمن ${_formatWithGrouping(minV)} – ${_formatWithGrouping(maxV)}.'.tr;
    }
    return '';
  }

  void _formatControllerText(TextEditingController ctrl) {
    final parsed = _parsePrice(ctrl.text);
    final newText = parsed == null ? '' : _formatWithGrouping(parsed);
    ctrl
      ..text = newText
      ..selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    setState(() {});
  }

  // ==================== تطبيق الفلاتر ====================
  Future<void> _applyFilters() async {
    if (!_formKey.currentState!.validate()) return;

    final priceMin = _parsePrice(_priceMinController.text);
    final priceMax = _priceMode == PriceModeDesktop.minOnly ? null : _parsePrice(_priceMaxController.text);

    if (_priceMode == PriceModeDesktop.range && priceMin != null && priceMax != null && priceMin > priceMax) {
      Get.snackbar('تنبيه'.tr, 'قيمة "من" يجب أن تكون أقل من أو تساوي "إلى"'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isApplyingFilters = true);

    final attrsPayload = _buildAttributesPayload();
    _adsController.attrsPayload.value = attrsPayload;

    final selectedCityId = _adsController.selectedCity.value?.id;
    final selectedAreaId = _adsController.selectedArea.value?.id;

    final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    final hasDistance = _selectedDistance != null &&
        _adsController.latitude.value != null &&
        _adsController.longitude.value != null;

    try {
      _didApply = true;

      await _adsController.fetchAds(
        categoryId: _adsController.currentCategoryId.value,
        subCategoryLevelOneId: _adsController.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId: _adsController.currentSubCategoryLevelTwoId.value,
        search: _adsController.currentSearch.value.isNotEmpty ? _adsController.currentSearch.value : null,
        sortBy: _adsController.currentSortBy.value,
        cityId: selectedCityId,
        areaId: selectedAreaId,
        attributes: attrsPayload.isNotEmpty ? attrsPayload : null,
        lang: lang,
        page: 1,
        timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
        onlyFeatured: widget.onlyFeatured,
        priceMin: priceMin,
        priceMax: priceMax,
        latitude: hasDistance ? _adsController.latitude.value : null,
        longitude: hasDistance ? _adsController.longitude.value : null,
        distanceKm: hasDistance ? _selectedDistance : null,
      );

      widget.onFiltersApplied?.call();

      final count = _adsController.adsList.length;
      Future.delayed(const Duration(milliseconds: 250), () {
        final msg = count == 0 ? 'لا توجد إعلانات مطابقة'.tr : 'تم العثور على $count إعلان'.tr;
        Get.snackbar('نتيجة الفلترة'.tr, msg, snackPosition: SnackPosition.BOTTOM);
      });
    } catch (e) {
      Get.snackbar('خطأ'.tr, 'فشل الاتصال: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (!mounted) return;
      setState(() => _isApplyingFilters = false);
    }
  }

  List<Map<String, dynamic>> _buildAttributesPayload() {
    if (_attributeValues.isEmpty) return [];

    final payload = <Map<String, dynamic>>[];

    for (final entry in _attributeValues.entries) {
      final attributeId = entry.key;
      final value = entry.value;

      if (value == null) continue;
      if (value is List && value.isEmpty) continue;

      final attribute = _adsController.attributesList.firstWhere(
        (attr) => attr.attributeId == attributeId,
        orElse: () => throw Exception('Attribute not found: $attributeId'),
      );

      String type = attribute.type;
      dynamic outValue = value;

      if (type == 'multi_options') type = 'options';
      if (type == 'options') {
        final ids = <int>[];
        if (value is List<int>) {
          ids.addAll(value.where((x) => x > 0));
        } else if (value is List) {
          for (final v in value) {
            if (v is int && v > 0) ids.add(v);
            if (v is String) {
              final p = int.tryParse(v);
              if (p != null && p > 0) ids.add(p);
            }
          }
        } else if (value is int && value > 0) {
          ids.add(value);
        } else if (value is String) {
          final p = int.tryParse(value);
          if (p != null && p > 0) ids.add(p);
        }
        final cleaned = ids.toSet().toList()..sort();
        if (cleaned.isEmpty) continue;
        outValue = cleaned;
      }

      payload.add({
        'attribute_id': attributeId,
        'attribute_type': type,
        'value': outValue,
      });
    }

    return payload;
  }

  void _resetFilters() {
    _formKey.currentState?.reset();

    setState(() {
      _didApply = true;

      _adsController.currentSearch.value = '';
      _adsController.searchController.clear();
      _adsController.isSearching.value = false;

      _adsController.selectCity(null);
      _adsController.selectArea(null);

      _selectedTimePeriod = null;

      _selectedDistance = null;
      _adsController.selectedRadius.value = null;

      _clearAttributesState();

      _priceMode = PriceModeDesktop.range;
      _priceMinController.clear();
      _priceMaxController.clear();

      _adsController.selectedMainCategoryId.value = widget.categoryId;
      _adsController.selectedSubCategoryId.value = null;
      _adsController.selectedSubTwoCategoryId.value = null;

      if (_adsController.latitude.value == null || _adsController.longitude.value == null) {
        _adsController.latitude.value = DEFAULT_LOCATION.latitude;
        _adsController.longitude.value = DEFAULT_LOCATION.longitude;
      }
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
        border: Border(top: BorderSide(color: AppColors.divider(localDark), width: 0.6)),
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
                  side: BorderSide(color: AppColors.border(localDark), width: 0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _isApplyingFilters
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  // ==================== الموقع الجغرافي ====================
  Widget _buildLocationFilterSection(bool isDarkMode) {
    final currentLocation = LatLng(
      _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
      _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
    );

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
              fontFamily: AppTextStyles.appFontFamily,
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
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentLocation,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.stay_in_me_website',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentLocation,
                            child: Icon(Icons.location_pin, size: 46.w, color: AppColors.primary),
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
          _buildRefreshLocationButton(
            onPressed: () async {
              await _getCurrentLocation(moveMap: true);
            },
          ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              label: Text(
                'حصر الإعلانات بالقرب مني'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      ),
    );
  }

  Widget _buildDistanceDropdown(bool isDarkMode) {
    return DropdownButtonFormField<double>(
      value: _selectedDistance,
      decoration: InputDecoration(
        labelText: 'اختر المسافة'.tr,
        labelStyle: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDarkMode)),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.border(isDarkMode), width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.1),
        ),
      ),
      items: radiusOptions.map((option) {
        final double val = option['value'] as double;
        final String label = option['label'] as String;
        return DropdownMenuItem<double>(value: val, child: Text(label));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedDistance = value);
        _adsController.selectedRadius.value = value;
      },
    );
  }

  void _applyLocationFilter() {
    if (_selectedDistance == null || _adsController.latitude.value == null || _adsController.longitude.value == null) {
      Get.snackbar(
        'تحذير'.tr,
        'يرجى تحديد المسافة والتأكد من تفعيل الموقع'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
      );
      return;
    }

    _didApply = true;
    _applyFilters();
  }
}

/// ============================================================
/// ✅ Multi Options Dropdown (Overlay) — قائمة منسدلة حقيقية
/// ============================================================
class _MultiOptionsDropdown extends StatefulWidget {
  final bool isDarkMode;
  final String label;
  final List<dynamic> options; // عناصرها: id , value
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  const _MultiOptionsDropdown({
    required this.isDarkMode,
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  State<_MultiOptionsDropdown> createState() => _MultiOptionsDropdownState();
}

class _MultiOptionsDropdownState extends State<_MultiOptionsDropdown> {
  final LayerLink _link = LayerLink();
  final GlobalKey _targetKey = GlobalKey();

  OverlayEntry? _entry;

  bool _openDown = true;
  double _maxHeight = 280;
  Size _targetSize = Size.zero;

  void _closeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _toggleOverlay() {
    if (_entry != null) {
      _closeOverlay();
      return;
    }

    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    _targetSize = size;

    final screenH = MediaQuery.of(context).size.height;
    final top = pos.dy;
    final fieldBottom = pos.dy + size.height;

    final availableBelow = screenH - fieldBottom - 12;
    final availableAbove = top - 12;

    _openDown = availableBelow >= 220 || availableBelow >= availableAbove;

    final available = max(0.0, _openDown ? availableBelow : availableAbove);

    final maxHeight = max(180.0, min(360.0, available));
    _maxHeight = maxHeight;

    final current = Set<int>.from(widget.selectedIds);
    final searchCtrl = TextEditingController();
    String q = '';

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: const SizedBox(),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, _openDown ? (size.height + 8) : -(_maxHeight + 8)),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: _targetSize.width,
                  child: StatefulBuilder(
                    builder: (context, setLocal) {
                      final filtered = q.trim().isEmpty
                          ? widget.options
                          : widget.options
                              .where((o) => (o.value.toString()).toLowerCase().contains(q.toLowerCase()))
                              .toList();

                      final allSelected = filtered.isNotEmpty && filtered.every((o) => current.contains(o.id as int));

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.card(widget.isDarkMode),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: _maxHeight),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
                                child: Row(
                                  children: [
                                    Icon(Icons.playlist_add_check_rounded,
                                        size: 18.w, color: AppColors.textSecondary(widget.isDarkMode)),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        '${'اختيار'.tr} ${widget.label}',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: AppTextStyles.medium,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary(widget.isDarkMode),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'إغلاق'.tr,
                                      onPressed: _closeOverlay,
                                      icon: Icon(Icons.close_rounded,
                                          size: 18.w, color: AppColors.textSecondary(widget.isDarkMode)),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (v) => setLocal(() => q = v),
                                  decoration: InputDecoration(
                                    hintText: 'بحث داخل الخيارات...'.tr,
                                    prefixIcon: Icon(Icons.search_rounded, size: 18.w),
                                    filled: true,
                                    fillColor: AppColors.surface(widget.isDarkMode),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                      borderSide: BorderSide(color: AppColors.border(widget.isDarkMode), width: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
                                child: Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: filtered.isEmpty
                                          ? null
                                          : () {
                                              setLocal(() {
                                                if (allSelected) {
                                                  for (final o in filtered) {
                                                    current.remove(o.id as int);
                                                  }
                                                } else {
                                                  for (final o in filtered) {
                                                    current.add(o.id as int);
                                                  }
                                                }
                                              });
                                            },
                                      icon: Icon(allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                          size: 18.w),
                                      label: Text(allSelected ? 'إلغاء تحديد الكل'.tr : 'تحديد الكل'.tr),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        textStyle: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: AppTextStyles.small,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => setLocal(() => current.clear()),
                                      icon: Icon(Icons.delete_outline, size: 18.w, color: Colors.redAccent),
                                      label: Text(
                                        'مسح'.tr,
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: AppTextStyles.small,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: AppColors.divider(widget.isDarkMode)),
                              Flexible(
                                child: Container(
                                  color: AppColors.surface(widget.isDarkMode),
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(14.w),
                                            child: Text(
                                              'لا توجد نتائج'.tr,
                                              style: TextStyle(
                                                fontFamily: AppTextStyles.appFontFamily,
                                                fontSize: AppTextStyles.small,
                                                color: AppColors.textSecondary(widget.isDarkMode),
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: filtered.length,
                                          itemBuilder: (_, i) {
                                            final o = filtered[i];
                                            final id = o.id as int;
                                            final checked = current.contains(id);

                                            return CheckboxListTile(
                                              value: checked,
                                              onChanged: (v) {
                                                setLocal(() {
                                                  if (v == true) {
                                                    current.add(id);
                                                  } else {
                                                    current.remove(id);
                                                  }
                                                });
                                              },
                                              title: Text(
                                                o.value.toString(),
                                                style: TextStyle(
                                                  fontFamily: AppTextStyles.appFontFamily,
                                                  fontSize: AppTextStyles.small,
                                                  color: AppColors.textPrimary(widget.isDarkMode),
                                                ),
                                              ),
                                              controlAffinity: ListTileControlAffinity.leading,
                                              activeColor: AppColors.primary,
                                              dense: true,
                                            );
                                          },
                                        ),
                                ),
                              ),
                              Divider(height: 1, color: AppColors.divider(widget.isDarkMode)),
                              Padding(
                                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _closeOverlay,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: AppColors.border(widget.isDarkMode), width: 0.9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                        ),
                                        child: Text(
                                          'إلغاء'.tr,
                                          style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final ids = current.toList()..sort();
                                          widget.onChanged(ids);
                                          _closeOverlay();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                        ),
                                        child: Text(
                                          'تطبيق'.tr,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.options.where((o) => widget.selectedIds.contains(o.id as int)).toList();
    final selectedText = selectedItems.isEmpty
        ? 'اختر عدة خيارات'.tr
        : (selectedItems.length <= 2
            ? selectedItems.map((e) => e.value.toString()).join(' ، ')
            : '${'تم اختيار'.tr} ${selectedItems.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _link,
          child: InkWell(
            key: _targetKey,
            borderRadius: BorderRadius.circular(10.r),
            onTap: _toggleOverlay,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface(widget.isDarkMode),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.6),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_add_check_rounded,
                      size: 18.w, color: AppColors.textSecondary(widget.isDarkMode)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      selectedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: selectedItems.isEmpty
                            ? AppColors.textSecondary(widget.isDarkMode)
                            : AppColors.textPrimary(widget.isDarkMode),
                      ),
                    ),
                  ),
                  if (selectedItems.isNotEmpty)
                    IconButton(
                      tooltip: 'مسح'.tr,
                      onPressed: () => widget.onChanged([]),
                      icon: Icon(Icons.close_rounded, size: 18.w, color: Colors.redAccent),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22.w, color: AppColors.textSecondary(widget.isDarkMode)),
                ],
              ),
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) SizedBox(height: 10.h),
        if (selectedItems.isNotEmpty)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: selectedItems.map((item) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.card(widget.isDarkMode),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value.toString(),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textPrimary(widget.isDarkMode),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    InkWell(
                      onTap: () {
                        final updated = List<int>.from(widget.selectedIds)..remove(item.id as int);
                        widget.onChanged(updated);
                      },
                      child: Icon(Icons.close_rounded, size: 16.w, color: AppColors.textSecondary(widget.isDarkMode)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
