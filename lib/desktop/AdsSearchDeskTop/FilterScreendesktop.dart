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

  // ========================= UI HELPERS =========================
  BorderRadius get _radius => BorderRadius.circular(12.r);

  TextStyle _hintStyle(bool dark) => TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.small,
        color: AppColors.textSecondary(dark),
      );

  TextStyle _valueStyle(bool dark) => TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.small,
        color: AppColors.textPrimary(dark),
        height: 1.0,
      );

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    final dark = isDarkMode;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: _hintStyle(dark),
      hintStyle: _hintStyle(dark),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 18.w, color: AppColors.textSecondary(dark)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface(dark),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppColors.border(dark), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppColors.border(dark), width: 0.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppColors.border(dark).withOpacity(0.7), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    IconData? icon,
    String? subtitle,
  }) {
    final dark = isDarkMode;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18.w, color: AppColors.primary),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(dark),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownText(String text) {
    final dark = isDarkMode;
    return Tooltip(
      message: text,
      waitDuration: const Duration(milliseconds: 250),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _valueStyle(dark),
        ),
      ),
    );
  }

  List<_DDValue<T>> _uniqueValues<T>(List<_DDValue<T>> input) {
    final seen = <String>{};
    final out = <_DDValue<T>>[];
    for (final v in input) {
      final key = '${v.value}';
      if (seen.add(key)) out.add(v);
    }
    return out;
  }

  List<DropdownMenuItem<T>> _ddItems<T>(List<_DDValue<T>> values) {
    return values
        .map(
          (v) => DropdownMenuItem<T>(
            value: v.value,
            child: _dropdownText(v.label),
          ),
        )
        .toList();
  }

  List<Widget> _ddSelectedBuilder<T>(List<_DDValue<T>> values) {
    return values.map((v) => _dropdownText(v.label)).toList();
  }

  Widget _niceDropdown<T>({
    required String label,
    required List<_DDValue<T>> values,
    required T? value,
    required ValueChanged<T?> onChanged,
    required bool enabled,
    IconData? prefixIcon,
    String? hint,
  }) {
    final dark = isDarkMode;

    final safeValues = _uniqueValues(values);
    final items = _ddItems(safeValues);

    // ✅ مهم جدًا: لا تمرّر value إلا إذا كانت موجودة مرة واحدة بالضبط
    T? safeValue;
    if (enabled && value != null) {
      final matches = safeValues.where((e) => e.value == value).length;
      if (matches == 1) safeValue = value;
    }

    return DropdownButtonFormField<T>(
      value: safeValue,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      isDense: true,
      // ✅ لا نضع itemHeight لتجنب Assertion (يجب >= 48)
      menuMaxHeight: 320, // ثابت وآمن
      borderRadius: _radius,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary(dark)),
      dropdownColor: AppColors.card(dark),
      style: _valueStyle(dark),
      selectedItemBuilder: (_) => _ddSelectedBuilder(safeValues),
      decoration: _fieldDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon,
        enabled: enabled,
      ),
    );
  }

  Widget _softFieldCard({required Widget child}) {
    final dark = isDarkMode;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.card(dark),
        borderRadius: _radius,
        border: Border.all(color: AppColors.border(dark).withOpacity(0.65), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.10 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
  // ===========================================================

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

  @override
  void didUpdateWidget(covariant FilterScreenDestktop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentTimeframe != widget.currentTimeframe) {
      setState(() => _selectedTimePeriod = widget.currentTimeframe);
    }

    final oldId = oldWidget.categoryId ?? 0;
    final newId = widget.categoryId ?? 0;

    if (!_initialDataLoaded) return;
    if (oldId == newId) return;
    if (newId <= 0) return;

    if (_userTouchedCategory && newId == (_adsController.selectedMainCategoryId.value ?? 0)) {
      _userTouchedCategory = false;
      return;
    }

    _initToken++;
    _userTouchedCategory = false;

    _onCategoryChangedExternally(newId);
  }

  Future<void> _loadInitialData(int token) async {
    final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    await _adsController.fetchMainCategories(lang);
    if (!mounted || token != _initToken) return;

    final effectiveCatId = _adsController.selectedMainCategoryId.value ?? widget.categoryId;

    if (effectiveCatId != null && effectiveCatId > 0) {
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildKeywordSearch(isDarkMode)),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildCategorySection(isDarkMode)),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildAttributesSection()),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildPriceSection()),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildLocationFilterSection(isDarkMode)),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildCityAreaSection()),
                    ),
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _softFieldCard(child: _buildTimePeriodSection(isDarkMode)),
                    ),
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
                    fontWeight: FontWeight.w900,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'البحث بالكلمات'.tr,
          icon: Icons.search_rounded,
          subtitle: 'اكتب كلمة أو أكثر للبحث داخل الإعلانات.'.tr,
        ),
        TextField(
          controller: _adsController.searchController,
          decoration: _fieldDecoration(
            label: 'ابحث في الإعلانات...'.tr,
            prefixIcon: Icons.search_rounded,
            suffixIcon: _adsController.searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'مسح'.tr,
                    icon: Icon(Icons.close_rounded, size: 18.w, color: AppColors.textSecondary(isDarkMode)),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _adsController.searchController.clear();
                      _adsController.currentSearch.value = '';
                      _applyFilters();
                      setState(() {});
                    },
                  ),
          ),
          style: _valueStyle(isDarkMode),
          onChanged: (value) {
            setState(() {});
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 350), () {
              _adsController.currentSearch.value = value;
            });
          },
        ),
      ],
    );
  }

  // ==================== التصنيفات ====================
  Widget _buildCategorySection(bool isDarkMode) {
    return Obx(() {
      final mainValues = _adsController.mainCategories
          .map((c) => _DDValue<int>(value: c.id, label: (c.name ?? '—')))
          .toList();

      final subValues = _adsController.subCategories
          .map((c) => _DDValue<int>(value: c.id, label: (c.name ?? '—')))
          .toList();

      final subTwoValues = _adsController.subTwoCategories
          .map((c) => _DDValue<int>(value: c.id, label: (c.name ?? '—')))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'التصنيفات'.tr,
            icon: Icons.category_outlined,
            subtitle: 'اختر التصنيف لتصفية النتائج بدقة.'.tr,
          ),
          _niceDropdown<int>(
            label: 'التصنيف الرئيسي'.tr,
            values: mainValues,
            value: _adsController.selectedMainCategoryId.value,
            enabled: true,
            prefixIcon: Icons.category_outlined,
            hint: 'اختر التصنيف'.tr,
            onChanged: (v) async {
              _userTouchedCategory = true;
              _initToken++;

              _adsController.updateMainCategory(v);
              _clearAttributesState();

              if (v != null) {
                final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                await _adsController.fetchSubCategories(v, lang);
                await _adsController.fetchAttributes(categoryId: v, lang: lang);
              }
            },
          ),
          SizedBox(height: 12.h),
          _niceDropdown<int>(
            label: 'التصنيف الفرعي'.tr,
            values: subValues,
            value: _adsController.selectedSubCategoryId.value,
            enabled: _adsController.selectedMainCategoryId.value != null,
            prefixIcon: Icons.account_tree_outlined,
            hint: 'اختر التصنيف الفرعي'.tr,
            onChanged: (v) {
              _adsController.updateSubCategory(v);
            },
          ),
          SizedBox(height: 12.h),
          _niceDropdown<int>(
            label: 'التصنيف الفرعي الثانوي'.tr,
            values: subTwoValues,
            value: _adsController.selectedSubTwoCategoryId.value,
            enabled: _adsController.selectedSubCategoryId.value != null,
            prefixIcon: Icons.subdirectory_arrow_right_outlined,
            hint: 'اختر التصنيف الفرعي الثانوي'.tr,
            onChanged: (v) {
              _adsController.updateSubTwoCategory(v);
            },
          ),
        ],
      );
    });
  }

  // ==================== الخصائص ====================
  Widget _buildAttributesSection() {
    final dark = isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'الخصائص'.tr,
          icon: Icons.tune_rounded,
          subtitle: 'حدد خصائص إضافية حسب التصنيف.'.tr,
        ),
        if (_adsController.attributesList.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'لا توجد خصائص لهذا التصنيف'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                color: AppColors.textSecondary(dark),
              ),
            ),
          ),
        ..._adsController.attributesList.map((attribute) {
          return Container(
            margin: EdgeInsets.only(top: 10.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.surface(dark),
              borderRadius: _radius,
              border: Border.all(color: AppColors.border(dark).withOpacity(0.75), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: attribute.label,
                  waitDuration: const Duration(milliseconds: 250),
                  child: Text(
                    attribute.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(dark),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _buildAttributeInput(attribute),
              ],
            ),
          );
        }).toList(),
      ],
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

    final values = opts.map((o) => _DDValue<int>(value: o.id, label: o.value)).toList();

    return _niceDropdown<int>(
      label: attribute.label,
      values: values,
      value: selectedOne,
      enabled: true,
      prefixIcon: Icons.list_alt_rounded,
      hint: '${'اختر'.tr} ${attribute.label}',
      onChanged: (value) {
        setState(() {
          if (value == null) {
            _attributeValues.remove(attribute.attributeId);
          } else {
            _attributeValues[attribute.attributeId] = <int>[value];
          }
        });
      },
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

  // ✅ نعم/لا بشكل احترافي
  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final dark = isDarkMode;
    final currentValue = _attributeValues[attribute.attributeId] as bool?;

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        _pillChoice(
          label: 'نعم'.tr,
          icon: Icons.check_rounded,
          selected: currentValue == true,
          onTap: () => setState(() => _attributeValues[attribute.attributeId] = true),
          dark: dark,
        ),
        _pillChoice(
          label: 'لا'.tr,
          icon: Icons.close_rounded,
          selected: currentValue == false,
          onTap: () => setState(() => _attributeValues[attribute.attributeId] = false),
          dark: dark,
        ),
        if (currentValue != null)
          _pillChoice(
            label: 'مسح'.tr,
            icon: Icons.delete_outline_rounded,
            selected: false,
            onTap: () => setState(() => _attributeValues.remove(attribute.attributeId)),
            dark: dark,
            isDanger: true,
          ),
      ],
    );
  }

  Widget _pillChoice({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool dark,
    bool isDanger = false,
  }) {
    final baseBorder = isDanger ? Colors.redAccent : AppColors.border(dark);
    final activeColor = isDanger ? Colors.redAccent : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.card(dark),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? activeColor : baseBorder.withOpacity(0.8),
            width: 0.9,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(dark ? 0.35 : 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.w,
              color: selected ? Colors.white : (isDanger ? Colors.redAccent : AppColors.textSecondary(dark)),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : (isDanger ? Colors.redAccent : AppColors.textPrimary(dark)),
                height: 1.0,
              ),
            ),
          ],
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
      decoration: _fieldDecoration(
        label: attribute.label,
        hint: '${'أدخل'.tr} ${attribute.label}',
        prefixIcon: Icons.text_fields_rounded,
      ),
      style: _valueStyle(isDarkMode),
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
      decoration: _fieldDecoration(
        label: attribute.label,
        hint: '${'أدخل'.tr} ${attribute.label}',
        prefixIcon: Icons.numbers_rounded,
      ),
      style: _valueStyle(isDarkMode),
    );
  }

  // ==================== المدن والمناطق ====================
  Widget _buildCityAreaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'الموقع'.tr,
          icon: Icons.location_on_outlined,
          subtitle: 'اختر المدينة والمنطقة لتضييق النتائج.'.tr,
        ),
        _buildCityDropdown(),
        if (_adsController.selectedCity.value != null)
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: _buildAreaDropdown(),
          ),
      ],
    );
  }

  // ✅ City Dropdown باستخدام id لتجنب Assertion (object equality)
  Widget _buildCityDropdown() {
    final values = _adsController.citiesList.map((city) {
      final cityName = city.translations.isNotEmpty ? city.translations.first.name : '—';
      return _DDValue<int>(value: city.id, label: cityName);
    }).toList();

    final selectedCityId = _adsController.selectedCity.value?.id;

    return _niceDropdown<int>(
      label: 'المدينة'.tr,
      values: values,
      value: selectedCityId,
      enabled: values.isNotEmpty,
      prefixIcon: Icons.location_city_rounded,
      hint: values.isEmpty ? 'جارٍ تحميل المدن...'.tr : 'اختر المدينة'.tr,
      onChanged: (id) {
        if (id == null) return;
        final city = _adsController.citiesList.firstWhereOrNull((c) => c.id == id);
        if (city == null) return;
        _adsController.selectCity(city);
        _adsController.selectArea(null);
        setState(() {});
      },
    );
  }

  // ✅ Area Dropdown باستخدام id لتجنب Assertion (object equality)
  Widget _buildAreaDropdown() {
    final localDark = Get.find<ThemeController>().isDarkMode.value;

    return Obx(() {
      final selectedCity = _adsController.selectedCity.value;

      if (selectedCity == null) {
        return DropdownButtonFormField<int>(
          value: null,
          items: const [],
          onChanged: null,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.card(localDark),
          decoration: _fieldDecoration(
            label: 'المنطقة'.tr,
            hint: 'اختر المدينة أولاً'.tr,
            prefixIcon: Icons.map_outlined,
            enabled: false,
          ),
          style: _valueStyle(localDark),
        );
      }

      return FutureBuilder<List<Area>>(
        future: _areaController.getAreasOrFetch(selectedCity.id),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final list = snapshot.data ?? const <Area>[];

          final values = list.map((a) => _DDValue<int>(value: a.id, label: a.name)).toList();
          final selectedAreaId = _adsController.selectedArea.value?.id;

          return _niceDropdown<int>(
            label: 'المنطقة'.tr,
            values: values,
            value: selectedAreaId,
            enabled: !isLoading && !hasError && values.isNotEmpty,
            prefixIcon: Icons.map_outlined,
            hint: isLoading
                ? 'جارٍ تحميل المناطق...'.tr
                : (hasError ? 'حدث خطأ أثناء الجلب'.tr : 'اختر المنطقة'.tr),
            onChanged: (id) {
              if (id == null) return;
              final area = list.firstWhereOrNull((a) => a.id == id);
              _adsController.selectArea(area);
              setState(() {});
            },
          );
        },
      );
    });
  }

  // ==================== الفترة الزمنية ====================
  Widget _buildTimePeriodSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'الفترة الزمنية'.tr,
          icon: Icons.schedule_rounded,
          subtitle: 'حدد إطارًا زمنيًا لعرض الإعلانات.'.tr,
        ),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: timePeriods.map((period) {
            final value = period['value']!;
            final label = period['label']!;
            final isSelected = _selectedTimePeriod == value;

            return ChoiceChip(
              label: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.small,
                  fontWeight: FontWeight.w800,
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
                width: 0.8,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== السعر ====================
  Widget _buildPriceSection() {
    final dark = isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'السعر'.tr,
          icon: Icons.payments_outlined,
          subtitle: 'اختر نمط السعر ثم أدخل القيم.'.tr,
        ),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
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
        SizedBox(height: 12.h),
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
                decoration: _fieldDecoration(
                  label: 'السعر من'.tr,
                  prefixIcon: Icons.arrow_upward_rounded,
                ),
                style: _valueStyle(dark),
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
                decoration: _fieldDecoration(
                  label: 'السعر إلى'.tr,
                  prefixIcon: Icons.arrow_downward_rounded,
                  suffixIcon: _priceMode == PriceModeDesktop.minOnly
                      ? Icon(Icons.lock_outline, size: 18.w, color: AppColors.textSecondary(dark))
                      : (_priceMaxController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح'.tr,
                              icon: Icon(Icons.clear, size: 18.w, color: AppColors.textSecondary(dark)),
                              onPressed: () => setState(() => _priceMaxController.clear()),
                            )),
                  enabled: _priceMode == PriceModeDesktop.range,
                ),
                style: _valueStyle(dark),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary(dark)),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                _priceSummary(),
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.small,
                  color: AppColors.textSecondary(dark),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final dark = isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: _radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface(dark),
          borderRadius: _radius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border(dark),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18.w,
              color: selected ? Colors.white : AppColors.textSecondary(dark),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textPrimary(dark),
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

  // ==================== الموقع الجغرافي ====================
  Widget _buildLocationFilterSection(bool isDarkMode) {
    final currentLocation = LatLng(
      _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
      _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'الموقع الجغرافي'.tr,
          icon: Icons.my_location_rounded,
          subtitle: 'حدد موقعك والمسافة لعرض القريب منك.'.tr,
        ),
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: _radius,
            border: Border.all(color: AppColors.border(isDarkMode), width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: _radius,
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
        SizedBox(height: 12.h),
        _buildRefreshLocationButton(
          onPressed: () async {
            await _getCurrentLocation(moveMap: true);
          },
        ),
        SizedBox(height: 14.h),
        Text(
          'المسافة من موقعك الحالي:'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.small,
            fontWeight: FontWeight.w800,
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
              shape: RoundedRectangleBorder(borderRadius: _radius),
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
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonAndLinksColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: _radius),
        ),
      ),
    );
  }

  Widget _buildDistanceDropdown(bool isDarkMode) {
    final values = radiusOptions.map((o) {
      final double val = o['value'] as double;
      final String label = o['label'] as String;
      return _DDValue<double>(value: val, label: label);
    }).toList();

    return _niceDropdown<double>(
      label: 'اختر المسافة'.tr,
      values: values,
      value: _selectedDistance,
      enabled: true,
      prefixIcon: Icons.social_distance_rounded,
      hint: 'اختر المسافة'.tr,
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
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.card(localDark),
        border: Border(top: BorderSide(color: AppColors.divider(localDark), width: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(localDark ? 0.10 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isApplyingFilters ? null : _resetFilters,
                icon: Icon(Icons.restart_alt_rounded, size: 18.w),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  side: BorderSide(color: AppColors.border(localDark), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: _radius),
                  foregroundColor: AppColors.textPrimary(localDark),
                ),
                label: Text(
                  'مسح الفلاتر'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isApplyingFilters ? null : _applyFilters,
                icon: _isApplyingFilters
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.check_rounded, size: 18.w),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: _radius),
                ),
                label: Text(
                  'تطبيق الفلترة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w900,
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

// ============================================================
// ✅ Helper model for dropdown values
// ============================================================
class _DDValue<T> {
  final T value;
  final String label;
  const _DDValue({required this.value, required this.label});
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
    _maxHeight = max(180.0, min(360.0, available));

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
                          border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
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
                                          fontWeight: FontWeight.w900,
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
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      borderSide: BorderSide(color: AppColors.border(widget.isDarkMode), width: 0.8),
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
                                          fontWeight: FontWeight.w900,
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
                                          fontWeight: FontWeight.w900,
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
                                              title: Tooltip(
                                                message: o.value.toString(),
                                                waitDuration: const Duration(milliseconds: 250),
                                                child: Text(
                                                  o.value.toString(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: AppTextStyles.appFontFamily,
                                                    fontSize: AppTextStyles.small,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary(widget.isDarkMode),
                                                  ),
                                                ),
                                              ),
                                              controlAffinity: ListTileControlAffinity.leading,
                                              activeColor: AppColors.primary,
                                              dense: true,
                                              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
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
                                          side: BorderSide(color: AppColors.border(widget.isDarkMode), width: 1.0),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        ),
                                        child: Text(
                                          'إلغاء'.tr,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,
                                            fontWeight: FontWeight.w800,
                                          ),
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                        ),
                                        child: Text(
                                          'تطبيق'.tr,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,
                                            fontWeight: FontWeight.w900,
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
            borderRadius: BorderRadius.circular(12.r),
            onTap: _toggleOverlay,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface(widget.isDarkMode),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.9),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_add_check_rounded,
                      size: 18.w, color: AppColors.textSecondary(widget.isDarkMode)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Tooltip(
                      message: selectedText,
                      waitDuration: const Duration(milliseconds: 250),
                      child: Text(
                        selectedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          fontWeight: FontWeight.w700,
                          color: selectedItems.isEmpty
                              ? AppColors.textSecondary(widget.isDarkMode)
                              : AppColors.textPrimary(widget.isDarkMode),
                        ),
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
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border(widget.isDarkMode), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: item.value.toString(),
                      waitDuration: const Duration(milliseconds: 250),
                      child: Text(
                        item.value.toString(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(widget.isDarkMode),
                        ),
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
