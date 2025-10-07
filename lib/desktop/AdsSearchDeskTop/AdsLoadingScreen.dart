import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/AdsManageSearchController.dart';
import 'package:tappuu_website/app_routes.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/localization/changelanguage.dart';

class AdsLoadingScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const AdsLoadingScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _AdsLoadingScreenState createState() => _AdsLoadingScreenState();
}

class _AdsLoadingScreenState extends State<AdsLoadingScreen> {
  late final AdsController _adsController;
  bool _isInitializing = true;
  String? _errorMessage;
  final Duration _requestTimeout = const Duration(seconds: 60);
  final Duration _overallTimeout = const Duration(seconds: 60);
  bool _isScreenUtilInitialized = false;

  // تحديد نوع الجهاز بناءً على عرض الشاشة
  bool get isDesktop => MediaQuery.of(Get.context!).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _initializeScreenUtil();
    _initializeApp();
  }

  Future<void> _initializeScreenUtil() async {
    await ScreenUtil.ensureScreenSize();
    
    setState(() {
      _isScreenUtilInitialized = true;
    });
  }

  Future<void> _initializeApp() async {
    if (!_isScreenUtilInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _initializeApp();
    }

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    // تهيئة المتحكم بأمان
    if (Get.isRegistered<AdsController>()) {
      _adsController = Get.find<AdsController>();
    } else {
      _adsController = Get.put(AdsController());
    }

    try {
      // اجعل كل العمليات تكتمل خلال overall timeout
      await _initializeData().timeout(_overallTimeout);
      
      // الانتقال إلى شاشة الإعلانات بعد التهيئة الناجحة
      if (mounted) {
        Get.offAllNamed(
          isDesktop ? AppRoutes.adsScreen : AppRoutes.adsScreenMobile,
          arguments: {
            ...?widget.arguments,
            'categoryId': _adsController.currentCategoryId.value,
            'subCategoryId': _adsController.currentSubCategoryLevelOneId.value,
            'subTwoCategoryId': _adsController.currentSubCategoryLevelTwoId.value,
          },
        );
      }
    } on TimeoutException catch (_) {
      _onInitError('انتهى وقت الانتظار، يرجى المحاولة لاحقاً.');
    } catch (e, st) {
      debugPrint('AdsLoadingScreen init error: $e\n$st');
      _onInitError('حدث خطأ أثناء التحميل: ${e.toString()}');
    }
  }

  void _onInitError(String message) {
    if (!mounted) return;
    setState(() {
      _isInitializing = false;
      _errorMessage = message;
    });

    // عرض رسالة الخطأ للمستخدم
    Get.snackbar(
      'خطأ'.tr,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  Future<void> _initializeData() async {
    // 1) ضمان أن اللغة جاهزة (نستخدمها لطلبات API)
    final langController = Get.find<ChangeLanguageController>();
    final lang = langController.currentLocale.value.languageCode;

    // 2) تأكد من أن التصنيفات الرئيسية جاهزة
    await _safeCallWithTimeout(
      () => _adsController.fetchMainCategories(lang),
      timeout: _requestTimeout,
      onTimeoutMessage: 'لم نتمكن من جلب التصنيفات الرئيسية (timeout).',
    );

    // إذا كان المستخدم وصل عبر رابط يحتوي على slugs — حولها إلى IDs
    final hasCategorySlug = widget.arguments?['categorySlug'] != null;
    if (hasCategorySlug) {
      await _convertSlugsToIdsOrThrow(lang);
    }

    // 3) بعد أن تكون الـ category ids جاهزة (أو لا يوجد slug)، جلب الإعلانات
    await _safeCallWithTimeout(
      () => _adsController.fetchAds(
        categoryId: widget.arguments?['categoryId'] ?? _adsController.currentCategoryId.value,
        subCategoryLevelOneId: widget.arguments?['subCategoryId'] ?? _adsController.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId: widget.arguments?['subTwoCategoryId'] ?? _adsController.currentSubCategoryLevelTwoId.value,
        lang: lang,
        timeframe: widget.arguments?['currentTimeframe'],
        onlyFeatured: widget.arguments?['onlyFeatured'] ?? false,
      ),
      timeout: _requestTimeout,
      onTimeoutMessage: 'لم نتمكن من جلب الإعلانات (timeout).',
    );

    // 4) انتظر حتى تنتهي عملية التحميل الداخلية للإعلانات أو حتى توجد نتائج/قيمة معقولة
    final adsReady = await _waitForCondition(
      () => !_adsController.isLoadingAds.value,
      timeout: const Duration(seconds: 8),
    );

    if (!adsReady && _adsController.filteredAdsList.isEmpty) {
      // إذا لم تعطِ بيانات بعد الانتظار — رمي خطأ
      throw Exception('فشل في جلب بيانات الإعلانات أو القائمة فارغة.');
    }
  }

  /// يحوّل slugs إلى ids — ويُخرِج استثناءً واضحًا إذا فشل
  Future<void> _convertSlugsToIdsOrThrow(String lang) async {
    final categorySlug = widget.arguments?['categorySlug'] as String?;
    final subCategorySlug = widget.arguments?['subCategorySlug'] as String?;
    final subTwoCategorySlug = widget.arguments?['subTwoCategorySlug'] as String?;

    // تأكد أن mainCategories محمّلة
    if (_adsController.mainCategories.isEmpty) {
      await _safeCallWithTimeout(
        () => _adsController.fetchMainCategories(lang),
        timeout: _requestTimeout,
        onTimeoutMessage: 'انتهى وقت جلب التصنيفات الرئيسية أثناء تحويل السلاجز.',
      );
    }

    final mainCategory = _findBySlug(_adsController.mainCategories, categorySlug);

    if (mainCategory == null) {
      throw Exception('التصنيف الرئيسي غير موجود: $categorySlug');
    }

    // عين الـ ids
    try {
      _adsController.selectedMainCategoryId.value = mainCategory.id;
      _adsController.currentCategoryId.value = mainCategory.id;
    } catch (_) {}

    // جلب التصنيفات الفرعية
    await _safeCallWithTimeout(
      () => _adsController.fetchSubCategories(mainCategory.id, lang),
      timeout: _requestTimeout,
      onTimeoutMessage: 'انتهى وقت جلب التصنيفات الفرعية.',
    );

    if (subCategorySlug != null) {
      final subCategory = _findBySlug(_adsController.subCategories, subCategorySlug);
      if (subCategory == null) {
        throw Exception('التصنيف الفرعي الأول غير موجود: $subCategorySlug');
      }

      try {
        _adsController.selectedSubCategoryId.value = subCategory.id;
        _adsController.currentSubCategoryLevelOneId.value = subCategory.id;
      } catch (_) {}

      await _safeCallWithTimeout(
        () => _adsController.fetchSubTwoCategories(subCategory.id),
        timeout: _requestTimeout,
        onTimeoutMessage: 'انتهى وقت جلب التصنيفات الفرعية الثانوية.',
      );

      if (subTwoCategorySlug != null) {
        final subTwoCategory = _findBySlug(_adsController.subTwoCategories, subTwoCategorySlug);
        if (subTwoCategory == null) {
          throw Exception('التصنيف الفرعي الثاني غير موجود: $subTwoCategorySlug');
        }

        try {
          _adsController.selectedSubTwoCategoryId.value = subTwoCategory.id;
          _adsController.currentSubCategoryLevelTwoId.value = subTwoCategory.id;
        } catch (_) {}
      }
    }
  }

  /// استدعاء دالة مع timeout ورفع خطأ معيّن لو انتهى الوقت
  Future<void> _safeCallWithTimeout(
    Future<void> Function() fn, {
    required Duration timeout,
    String? onTimeoutMessage,
  }) async {
    try {
      await fn().timeout(timeout);
    } on TimeoutException {
      throw Exception(onTimeoutMessage ?? 'انتهى وقت العملية.');
    } catch (e) {
      rethrow;
    }
  }

  /// polling helper: يختبر الشرط كل 200ms حتى يصبح true أو ينتهي الوقت
  Future<bool> _waitForCondition(bool Function() condition, {required Duration timeout}) async {
    final completer = Completer<bool>();
    final sw = Stopwatch()..start();
    Timer? timer;

    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (condition()) {
        timer?.cancel();
        completer.complete(true);
      } else if (sw.elapsed >= timeout) {
        timer?.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// يبحث في قائمة العناصر عن عنصر يملك حقل slug يطابق القيمة
  dynamic _findBySlug(Iterable list, String? slug) {
    if (slug == null) return null;
    for (final item in list) {
      try {
        final s = (item as dynamic).slug;
        if (s == slug) return item;
      } catch (_) {
        // تخطى العناصر التي لا تملك slug
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isScreenUtilInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
              SizedBox(height: 16.h),
              Text(
                'جاري تهيئة التطبيق...'.tr,
                style: TextStyle(fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    return ScreenUtilInit(
      designSize: isDesktop ? Size(1440, 900) : Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 64.w,
                    color: Colors.red,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'حدث خطأ'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xxxlarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      textStyle: TextStyle(fontSize: 16.sp),
                    ),
                    child: Text('إعادة المحاولة'.tr),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => Get.offAllNamed('/'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      textStyle: TextStyle(fontSize: 16.sp),
                    ),
                    child: Text('العودة إلى الرئيسية'.tr),
                  ),
                ] else ...[
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    strokeWidth: 4.w,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'جاري تحميل المحتوى...'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'قد تستغرق هذه العملية بضع ثوان'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}