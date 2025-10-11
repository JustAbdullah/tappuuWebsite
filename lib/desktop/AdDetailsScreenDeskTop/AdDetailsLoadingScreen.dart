// lib/desktop/AdDetailsScreenDeskTop/AdDetailsLoadingScreen.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/HomeDeciderView.dart';
import 'package:tappuu_website/mobile/viewAdsScreen/AdDetailsScreen.dart';

import '../../controllers/ThemeController.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../core/data/model/AdResponse.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/images_path.dart';
import '../../core/services/appservices.dart';

// شاشات التفاصيل — عدّل المسارات لو عندك أسماء مختلفة
import 'package:tappuu_website/mobile/viewAdsScreen/AdDetailsScreen.dart';

import 'AdDetailsScreen_desktop.dart';

class AdDetailsLoadingScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const AdDetailsLoadingScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<AdDetailsLoadingScreen> createState() => _AdDetailsLoadingScreenState();
}

class _AdDetailsLoadingScreenState extends State<AdDetailsLoadingScreen>
    with SingleTickerProviderStateMixin {
  final AdsController _adsController = Get.find<AdsController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  bool _isLoading = true;
  String? _errorMessage;
  late final AnimationController _logoAnimCtr;

  // تحديد نوع الجهاز بناءً على عرض الشاشة
  bool get isDesktop => MediaQuery.of(Get.context!).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _logoAnimCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startLoad());
  }

  @override
  void dispose() {
    _logoAnimCtr.dispose();
    super.dispose();
  }

  Future<void> _startLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) إن كانت الشاشة استُدعيت مع object الإعلان — استخدمه فوراً لتجنّب fetch
      final passedAd = widget.arguments?['ad'] as Ad?;
      if (passedAd != null) {
        _navigateToDetails(passedAd);
        return;
      }

      // 2) اقرأ raw من arguments أو من Get.parameters
      final rawFromArgs = widget.arguments?['raw'] as String?;
      final rawFromParams = Get.parameters['raw'];
      final raw = (rawFromArgs != null && rawFromArgs.isNotEmpty) ? rawFromArgs : rawFromParams;

      if (raw == null || raw.isEmpty) {
        throw Exception('معرّف الإعلان غير موجود');
      }

      // 3) حاول استخراج id و slug بأمان
      String adId;
      String? slug;

      final m = RegExp(r'^(\d+)(?:-(.*))?$').firstMatch(raw);
      if (m != null) {
        adId = m.group(1)!;
        slug = m.group(2);
      } else {
        // fallback: افصل عند أول dash
        final idx = raw.indexOf('-');
        if (idx > 0) {
          adId = raw.substring(0, idx);
          slug = raw.substring(idx + 1);
        } else {
          adId = raw;
          slug = null;
        }
      }

      // 4) جلب الإعلان عبر الكنترولر (تأكد أن الدالة لديك تطابق هذا النداء)
      final ad = await _adsController.fetchAdDetails(adId: adId.toString());

      if (ad == null) {
        setState(() => _errorMessage = 'فشل تحميل الإعلان'.tr);
        return;
      }

      // 5) حدث URL المتصفّح إلى canonical (اختياري لكن مفيد)
      try {
        final finalSlug = (ad.slug != null && ad.slug!.isNotEmpty) ? ad.slug : (slug ?? '');
        final newUrl = (finalSlug != null && finalSlug.isNotEmpty) ? '/ad/${ad.id}-$finalSlug' : '/ad/${ad.id}';
        html.window.history.replaceState({}, '', newUrl);
      } catch (e) {
        debugPrint('Could not replace browser URL: $e');
      }

      // 6) الانتقال إلى شاشة التفاصيل (نستبدل شاشة التحميل)
      _navigateToDetails(ad);
      return;
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ في الاتصال: ${e.toString()}'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetails(Ad ad) {
    try {
      if (isDesktop) {
        // AdDetailsDesktop يجب أن يستقبل Ad في الكونستركتور
        Get.off(() => AdDetailsDesktop(ad: ad));
      } else {
        Get.off(() => AdDetailsScreen(ad: ad));
      }
    } catch (e) {
      debugPrint('Navigation to details error: $e');
      // fallback: افتح شاشة الجوال لو فشل
      try {
        Get.off(() => AdDetailsScreen(ad: ad));
      } catch (_) {}
    }
  }

  Widget _buildAnimatedLogo() {
    final isDark = _themeController.isDarkMode.value;
    final appServices = Get.find<AppServices>();
    final logoUrl = appServices.getStoredAppLogoUrl();

    return ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.06).animate(CurvedAnimation(parent: _logoAnimCtr, curve: Curves.easeInOut)),
      child: Container(
        width: 140.w,
        height: 110.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
         
      
        ),
        child: Center(
          child: logoUrl != null && logoUrl.isNotEmpty
              ? Image.network(logoUrl, width: double.infinity, height: 150, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Image.asset(ImagesPath.logo, width: 86.w, height: 64.h))
              : Image.asset(ImagesPath.logo, width: double.infinity, height: 150, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    final isDark = _themeController.isDarkMode.value;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(16.r), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('جارٍ تحميل تفاصيل الإعلان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
          SizedBox(height: 8.h),
          Text('اسمح لنا بجلب أفضل عرض للتفاصيل — لن يأخذ وقتًا طويلًا.'.tr, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily,fontSize: AppTextStyles.medium, color: AppColors.textSecondary(isDark))),
          SizedBox(height: 14.h),
          const AnimatedDotsLoader(),
          SizedBox(height: 12.h),
          Text('المعرف: ${widget.arguments?['raw'] ?? ''}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily,fontSize: AppTextStyles.medium, color: AppColors.textSecondary(isDark))),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final isDark = _themeController.isDarkMode.value;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.error.withOpacity(0.12))),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 44.r, color: AppColors.error),
          SizedBox(height: 10.h),
          Text(_errorMessage ?? 'حصل خطأ غير متوقع'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.textPrimary(isDark))),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _startLoad();
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12.h), backgroundColor: AppColors.buttonAndLinksColor),
                  child: Text('إعادة المحاولة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.onPrimary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Get.offAll(() => HomeDeciderView());
                  },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary), padding: EdgeInsets.symmetric(vertical: 12.h)),
                  child: Text('العودة للرئيسية'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode.value;

    return ScreenUtilInit(
      designSize: isDesktop ? Size(1440, 900) : Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => Scaffold(
        backgroundColor: AppColors.background(isDark),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedLogo(),
                  SizedBox(height: 18.h),
                  if (_isLoading)
                    _buildLoadingCard()
                  else
                    _errorMessage != null
                        ? _buildErrorCard()
                        : _buildLoadingCard(),
                  SizedBox(height: 18.h),
                  Text('إذا بقيت هذه الشاشة مدة أطول من المتوقع، استخدم زر "إعادة المحاولة" أو اغلق إلى الرئيسية.'.tr, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily,fontSize: AppTextStyles.medium, color: AppColors.textSecondary(isDark))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedDotsLoader extends StatefulWidget {
  const AnimatedDotsLoader({Key? key}) : super(key: key);

  @override
  State<AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<AnimatedDotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctr, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final t = (_anim.value + i * 0.25) % 1.0;
              final scale = 0.6 + (0.8 * (1 - (t - 0.5).abs() * 2));
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                width: 10.w * scale,
                height: 10.w * scale,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.24), blurRadius: 6)],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
