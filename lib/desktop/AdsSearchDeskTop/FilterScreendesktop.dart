import 'package:flutter/material.dart';
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

class FilterScreenDestktop extends StatefulWidget {
  final int ?categoryId;
  final String? currentTimeframe;
  final bool onlyFeatured;
  final VoidCallback? onFiltersApplied; // إضافة callback

  const FilterScreenDestktop({
    super.key, 
    required this.categoryId, 
    this.currentTimeframe,    
    this.onlyFeatured = false,
        this.onFiltersApplied, // إضافة callback

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
  {'value': '24h',    'label': 'آخر 24 ساعة'.tr},
  {'value': '48h',    'label': 'آخر يومين'.tr},
  {'value': 'week',   'label': 'آخر أسبوع'.tr},
  {'value': 'month',  'label': 'آخر شهر'.tr},
  {'value': 'year',   'label': 'آخر سنة'.tr},
  {'value': 'all',    'label': 'كل الأوقات'.tr},
];


  String? _selectedTimePeriod;
  final Map<int, dynamic> _attributeValues = {};
  TheCity? _tempSelectedCity;
  Area? _tempSelectedArea;
  bool _locationLoading = false;

  // خيارات المسافات للفلترة الجغرافية
  
  final List<Map<String, dynamic>> radiusOptions = [
    {'value': 1.0, 'label': '1 كم'.tr},
    {'value': 5.0, 'label': '5 كم'.tr},
    {'value': 10.0, 'label': '10 كم'.tr},
    {'value': 20.0, 'label': '20 كم'.tr},
    {'value': 50.0, 'label': '50 كم'.tr},
  ];
  double? _selectedDistance;

  @override
  void initState() {
    super.initState();
    
    // 1. خزّن الحالة المؤقتة
    _tempSelectedCity = _adsController.selectedCity.value;
    _tempSelectedArea = _adsController.selectedArea.value;

    // 2. تعيين الموقع الافتراضي إذا لم يكن موجوداً
    if (_adsController.latitude.value == null || _adsController.longitude.value == null) {
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;
    }

    // 3. جلب البيانات الأولية
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // جلب التصنيفات الرئيسية أولًا
    await _adsController.fetchMainCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    
    if (widget.categoryId != null && widget.categoryId! > 0) {
      // 3. عيّن currentCategoryId و selectedMainCategoryId
      _adsController.currentCategoryId.value = widget.categoryId!;
      _adsController.selectedMainCategoryId.value = widget.categoryId!;

      // 4. جلب التصنيفات الفرعية لهذا المعرف
      await _adsController.fetchSubCategories(widget.categoryId!, Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      
      // 5. جلب السمات الخاصة بالتصنيف الرئيسي
      await _adsController.fetchAttributes(
        categoryId: widget.categoryId!,
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
    }
    
    // جلب المدن
    await _adsController.fetchCities(
      'SY',
      Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
    );
    
    // جلب الموقع الحالي إذا لم يكن محدداً
    if (_adsController.latitude.value == DEFAULT_LOCATION.latitude && 
        _adsController.longitude.value == DEFAULT_LOCATION.longitude) {
      await _getCurrentLocation();
    }
  }

  // جلب الموقع الحالي للمستخدم مع التحقق من الصلاحيات
  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      // التحقق من إذن الوصول للموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && 
            permission != LocationPermission.always) {
          print('تم رفض إذن الوصول للموقع');
          return;
        }
      }
      
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('خدمة الموقع غير مفعلة');
        return;
      }
      
      // جلب الموقع الحالي
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best
      );
      _adsController.latitude.value = position.latitude;
      _adsController.longitude.value = position.longitude;
    } catch (e) {
      print('خطأ في جلب الموقع: $e');
      // الحفاظ على الموقع الافتراضي في حالة الخطأ
      _adsController.latitude.value = DEFAULT_LOCATION.latitude;
      _adsController.longitude.value = DEFAULT_LOCATION.longitude;
    } finally {
      setState(() => _locationLoading = false);
    }
  }

  @override
  void dispose() {
    _adsController.selectedCity.value = _tempSelectedCity;
    _adsController.selectedArea.value = _tempSelectedArea;


      // 1. تفريغ المتغيرات المحلية في الواجهة
  _attributeValues.clear();
  _selectedTimePeriod = null;
  _selectedDistance = null;
  
  // 2. تفريغ متغيرات الكنترولر
  _adsController.resetFilterState();
  
  // 3. إعادة تعيين المتغيرات المؤقتة
  _tempSelectedCity = null;
  _tempSelectedArea = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط التصفية العلوي
                _buildTopFilterBar(),
                SizedBox(height: 16.h),
                
                // البحث بالكلمات
                _buildKeywordSearch(isDarkMode),
                SizedBox(height: 16.h),
                
                // التصنيفات
                _buildCategorySection(isDarkMode),
                SizedBox(height: 16.h),
                
                // الخصائص
                _buildAttributesSection(),
                SizedBox(height: 16.h),
                
                // الموقع الجغرافي
                _buildLocationFilterSection(isDarkMode),
                SizedBox(height: 16.h),
                
                // المدن والمناطق
                _buildCityAreaSection(),
                SizedBox(height: 16.h),
                
                // الفترة الزمنية
                _buildTimePeriodSection(),
              ],
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
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'حذف النتائج النتائج'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
                 fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          Row(
            children: [
              // زر مسح الفلاتر
              IconButton(
                icon: Icon(Icons.filter_alt_off, size: 20.w),
                onPressed: _resetFilters,
                tooltip: 'مسح الفلاتر'.tr,
                color: AppColors.primary,
              ),
             
            ],
          ),
        ],
      ),
    );
  }

  // ==================== قسم البحث ====================
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
          SizedBox(height: 6.h),
          TextField(
            controller: _adsController.searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الإعلانات...'.tr,
              hintStyle: TextStyle(fontSize: 12.sp),
              prefixIcon: Icon(Icons.search, 
                            size: 18.w, 
                            color: AppColors.textSecondary(isDarkMode)),
              filled: true,
              fillColor: AppColors.background(isDarkMode),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            ),
            onChanged: (value) {
 _adsController.currentSearch.value = value;
              if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }
            }
          ),
        ],
      ),
    );
  }

  // ==================== قسم التصنيفات ====================
 // ==================== قسم التصنيفات (بتصميم مطابق لقسم المدن) ====================
// ==================== قسم التصنيفات ====================
Widget _buildCategorySection(bool isDarkMode) {
  return Obx(() {  // هنا Obx وحيد فقط
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
                .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name ?? '—'),
                    ))
                .toList(),
            value: _adsController.selectedMainCategoryId.value,
            onChanged: (v) {
              _adsController.updateMainCategory(v);
             
      widget.onFiltersApplied!();
    
              if (v != null) _adsController.fetchAttributes(categoryId: v, lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
            },
            enabled: true,
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 12.h),

          // التصنيف الفرعي
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
               if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }
            },
           
            enabled: _adsController.selectedMainCategoryId.value != null,
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 12.h),

          // التصنيف الفرعي الثانوي
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
               if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }
            } ,
            enabled: _adsController.selectedSubCategoryId.value != null,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  });
}

/// ويدجت Dropdown عامة ولكن _دون_ Obx داخليّ
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
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: AppColors.border(isDarkMode), width: 0.5),
    ),
    child: DropdownButtonFormField<T>(
      value: enabled && items.any((item) => item.value == value) ? value : null,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: hint,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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

// ==================== فلترة الموقع الجغرافي (مُحسَّنة) ====================


// ==================== فلترة الموقع الجغرافي - النسخة المحسنة ====================
Widget _buildLocationFilterSection(bool isDarkMode) {
  final currentLocation = LatLng(
    _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
    _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
  );

  // متحكم جديد للخريطة لتحديثها فورياً
  final mapController = MapController();

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Text(
          'الموقع الجغرافي'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 16.h),
        
        // خريطة تفاعلية
        Container(
          height: 200.h, // زيادة ارتفاع الخريطة
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r), // زوايا أكثر استدارة
            border: Border.all(
              color: AppColors.border(isDarkMode),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: FlutterMap(
              mapController: mapController, // إضافة متحكم للخريطة
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 15,
                 interactionOptions: const InteractionOptions(
    flags: InteractiveFlag.none, // ✅ يمنع كل التفاعل: سحب، تكبير، تدوير...
  ),
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
                      child: Icon(Icons.location_pin, 
                        size: 48.w, 
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        
        // زر تحديث الموقع - أكثر وضوحاً
        _buildRefreshLocationButton(
          onPressed: () async {
            // تحديث الموقع
            await _adsController.refreshLocation();
            
            await _adsController.fetchCurrentLocation();
            // تحديث الخريطة فورياً
            final newLocation = LatLng(
              _adsController.latitude.value ?? DEFAULT_LOCATION.latitude,
              _adsController.longitude.value ?? DEFAULT_LOCATION.longitude,
            );
            
            mapController.move(
              newLocation, 
              mapController.camera.zoom
            );
          }
        ),
        SizedBox(height: 16.h),
        
        // اختيار المسافة
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المسافة من موقعك الحالي:'.tr,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
             ) ),
            SizedBox(height: 10.h),
            _buildDistanceDropdown(isDarkMode),
          ],
        ),
        SizedBox(height: 20.h),
        
        // زر تطبيق الفلتر
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _applyLocationFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'حصر الاعلانات'.tr,
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

// زر تحديث الموقع - تصميم جديد
Widget _buildRefreshLocationButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.refresh, size: 20.w),
      label: Text(
        'تحديث موقعك الحالي'.tr,
        style: TextStyle(fontSize: 13.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonAndLinksColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12.h),
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
      filled: true,
      fillColor: AppColors.background(isDarkMode),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    ),
    // هنا نعرض العناصر من قائمة الخُريطة
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
      // لو كنت تستخدم GetX:
      _adsController.selectedRadius.value = value;
    },
    hint: Text(
      'اختر المسافة'.tr,
      style: TextStyle(
       fontSize: AppTextStyles.medium,
        color: AppColors.textSecondary(isDarkMode),
      ),
    ),
  );
}



  void _applyLocationFilter() {
    if (_selectedDistance != null && 
        _adsController.latitude.value != null && 
        _adsController.longitude.value != null) {
     _adsController.fetchAds(
      categoryId: _adsController.currentCategoryId.value,
      subCategoryLevelOneId: _adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: _adsController.currentSubCategoryLevelTwoId.value,
      search: _adsController.currentSearch.value.isNotEmpty
          ? _adsController.currentSearch.value
          : null,
      sortBy: _adsController.currentSortBy.value,
   attributes: _adsController. attrsPayload.value.isNotEmpty ? _adsController. attrsPayload.value : null,
      lang: Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode,
      page: 1,
      // أرسل timeframe فقط إذا لم تكن null
     timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
  onlyFeatured: widget.onlyFeatured,
    latitude: _adsController.latitude.value,
      longitude: _adsController.longitude.value,
      distanceKm: _adsController.selectedRadius.value,
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
      padding: EdgeInsets.symmetric(horizontal: 6.w),
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
              padding: EdgeInsets.only(bottom: 5.h),
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
                    height: 24.h,
                    color: AppColors.divider(isDarkMode),
                    thickness: 0.7,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
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
      hint: Text(
        '${'اختر'.tr} ${attribute.label}',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
         fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
       fontSize: AppTextStyles.medium,
        color: AppColors.textPrimary(isDarkMode),
      ),
      dropdownColor: AppColors.card(isDarkMode),
    );
  }

  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final currentValue = _attributeValues[attribute.attributeId] as bool?;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildBooleanOption('نعم'.tr, currentValue == true, () {
          setState(() {
            _attributeValues[attribute.attributeId] = true;
          });
        }),
        SizedBox(width: 16.w),
        _buildBooleanOption('لا'.tr, currentValue == false, () {
          setState(() {
            _attributeValues[attribute.attributeId] = false;
          });
        }),
      ],
    );
  }

  Widget _buildBooleanOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 0.5,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
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
          
          _attributeValues[attribute.attributeId] = double.tryParse(normalizedValue);
        } else {
          _attributeValues[attribute.attributeId] = null;
        }
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
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
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.border(isDarkMode),
          width: 0.5,
        ),
      ),
      child: DropdownButtonFormField<TheCity>(
        value: _adsController.selectedCity.value,
        decoration: InputDecoration(
          labelText: 'المدينة'.tr,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
          setState(() {
            _adsController.selectCity(city!);
             if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }
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
  final isDarkMode =  Get.find<ThemeController>().isDarkMode.value;


  return Obx(() {
    final selectedCity = _adsController.selectedCity.value;

    // لو المدينة غير محددة لسه
    if (selectedCity == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        child: DropdownButtonFormField<Area>(
          value: null,
          decoration: InputDecoration(
            labelText: 'المنطقة'.tr,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: InputBorder.none,
          ),
          items: const [],
          onChanged: null, // معطّل
          hint: Text(
            'اختر المدينة أولاً',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          dropdownColor: AppColors.card(isDarkMode),
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      );
    }

    // جلب المناطق من الكنترولر
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
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
      ),
      items: list.map((area) {
        return DropdownMenuItem<Area>(
          value: area,
          child: Text(
            area.name, // فقط الاسم بدون أي معرفات
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (area) {
        if (area != null) {
          _adsController.selectArea(area);
           if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }
        }
      },
      hint: Text(
        isLoading
            ? 'جارٍ تحميل المناطق...'
            : (hasError ? 'حدث خطأ أثناء الجلب' : 'اختر المنطقة'),
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      dropdownColor: AppColors.card(isDarkMode),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.medium,
        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  },
);
});}
  // ==================== قسم الفترة الزمنية ====================
Widget _buildTimePeriodSection() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
          spacing: 8.w,
          runSpacing: 8.h,
          children: timePeriods.map((period) {
            final isSelected = _selectedTimePeriod == period['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimePeriod = period['value'];
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary 
                    : AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.border(isDarkMode),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  period['label']!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.small,
                    color: isSelected 
                      ? Colors.white 
                      : AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

void _applyFilters() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isApplyingFilters = true);

  final attrsPayload = _buildAttributesPayload();
  _adsController.attrsPayload.value = _buildAttributesPayload();
  final selectedCityId = _adsController.selectedCity.value?.id;
  final selectedAreaId = _adsController.selectedArea.value?.id;

  try {
    await _adsController.fetchAds(
      categoryId: _adsController.currentCategoryId.value,
      subCategoryLevelOneId: _adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: _adsController.currentSubCategoryLevelTwoId.value,
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
      // أرسل timeframe فقط إذا لم تكن null
     timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
  onlyFeatured: widget.onlyFeatured,
    );

    final count = _adsController.adsList.length;
    Future.delayed(Duration(milliseconds: 300), () {
      final msg = count == 0
          ? 'لا توجد إعلانات مطابقة'
          : 'تم العثور على $count إعلان';
      Get.snackbar('نتيجة الفلترة', msg,
          snackPosition: SnackPosition.BOTTOM);
    });
  } catch (e) {
    Get.snackbar('خطأ', 'فشل الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM);
  } finally {
    setState(() => _isApplyingFilters = false);
  }
}


  List<Map<String, dynamic>> _buildAttributesPayload() {
    return _attributeValues.entries.map((entry) {
      final attributeId = entry.key;
      final value       = entry.value;

      // ابحث عن الـ attribute object من الـ attributesList
      final attribute = _adsController.attributesList.firstWhere(
        (attr) => attr.attributeId == attributeId,
        orElse: () => throw Exception('Attribute not found: $attributeId'),
      );

      return {
        'attribute_id':   attributeId,
        'attribute_type': attribute.type,       // ← النوع المطلوب
        'value':          value,
      };
    }).toList();
  }

  void _resetFilters() {
    _formKey.currentState?.reset();
    setState(() {
      _adsController.currentSearch.value = "";
      _adsController.searchController.clear();
      _adsController.isSearching.value = false;
      _adsController.selectedCity.value = _tempSelectedCity;
      _adsController.selectedArea.value = _tempSelectedArea;
      _selectedTimePeriod = null;
      _attributeValues.clear();
      _selectedDistance = null;
      _adsController.currentAttributes.clear();

       _adsController.selectedCity.value = _tempSelectedCity;
    _adsController.selectedArea.value = _tempSelectedArea;


      // 1. تفريغ المتغيرات المحلية في الواجهة
  _attributeValues.clear();
  _selectedTimePeriod = null;
  _selectedDistance = null;
  
  // 2. تفريغ متغيرات الكنترولر
  _adsController.resetFilterState();
  
  // 3. إعادة تعيين المتغيرات المؤقتة
  _tempSelectedCity = null;
  _tempSelectedArea = null;
      
      // إعادة ضبط التصنيفات إلى القيم الأولية
      _adsController.selectedMainCategoryId?.value = widget.categoryId;
      _adsController.selectedSubCategoryId?.value = null;
      _adsController.selectedSubTwoCategoryId?.value = null;
      
      // إعادة جلب السمات للتصنيف الرئيسي الأصلي
      if (widget.categoryId != null) {
        _adsController.fetchAttributes(
          categoryId: widget.categoryId??1,
          lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
        );
      }
      
      // إعادة تعيين الموقع إلى القيمة الافتراضية
      if (_adsController.latitude.value == null || 
          _adsController.longitude.value == null) {
        _adsController.latitude.value = DEFAULT_LOCATION.latitude;
        _adsController.longitude.value = DEFAULT_LOCATION.longitude;
      }
       _adsController.fetchAds(
      categoryId: _adsController.currentCategoryId.value,
      subCategoryLevelOneId: _adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: _adsController.currentSubCategoryLevelTwoId.value,
      search: _adsController.currentSearch.value.isNotEmpty
          ? _adsController.currentSearch.value
          : null,
      sortBy: _adsController.currentSortBy.value,
   attributes: _adsController. attrsPayload.value.isNotEmpty ? _adsController. attrsPayload.value : null,
      lang: Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode,
      page: 1,
      // أرسل timeframe فقط إذا لم تكن null
     timeframe: _selectedTimePeriod == 'all' ? null : _selectedTimePeriod,
  onlyFeatured: widget.onlyFeatured,
    latitude: _adsController.latitude.value,
      longitude: _adsController.longitude.value,
      distanceKm: _adsController.selectedRadius.value,
    );
    });
    
    // تطبيق الفلاتر بعد الإعادة
    _applyFilters();
  }


  Widget _buildActionButtons() {
    return ElevatedButton(
        onPressed: _isApplyingFilters ? null : _applyFilters,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h,horizontal: 50.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: _isApplyingFilters
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
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
      
    
  );
  }
}