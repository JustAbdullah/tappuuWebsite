import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_website/controllers/home_controller.dart';
import 'package:tappuu_website/desktop/AuthScreenDeskTop/LoginDesktopScreen.dart';
import 'package:tappuu_website/desktop/HomeScreenDeskTop/home_web_desktop_screen.dart';
import 'package:tappuu_website/desktop/ServicesDrawerWeb/servicesItemsDesktop/ReportProblemScreenDesktop.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/LoadingController.dart';
import '../controllers/ThemeController.dart';
import '../core/constant/app_text_styles.dart';
import '../core/constant/appcolors.dart';
import 'AdsManageDeskTop/AddAdScreenDeskTop.dart';
import 'AdsSearchDeskTop/AdsScreenDesktop.dart';
import 'AuthScreenDeskTop/SignupDesktopScreen.dart';

class SecondaryAppBarDeskTop extends StatefulWidget {
  final bool isAdsScreen;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SecondaryAppBarDeskTop({
    Key? key,
    this.isAdsScreen = false,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  State<SecondaryAppBarDeskTop> createState() => _SecondaryAppBarDeskTopState();
}

class _SecondaryAppBarDeskTopState extends State<SecondaryAppBarDeskTop> {
  int _hoveredIndex = -1;
  bool _isSearchHovered = false;
  bool _isAdButtonHovered = false;

  // ✅ نجهز الكنترولرات كفيلدز بدل ما ننادي Get.find داخل build كل مرة
  final ThemeController themeController = Get.find<ThemeController>();
  final HomeController homeController = Get.find<HomeController>();
  final LoadingController loadingController = Get.find<LoadingController>();

  @override
  Widget build(BuildContext context) {
    // ✅ نخلي الـ AppBar كله Reactive مع تغيير الثيم
    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      return Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0f0f0f) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2a2a2a) : const Color(0xFFf0f0f0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Navigation Items - Clean Design
            Row(
              children: [
                _ElegantNavItem(
                  label: 'الرئيسية'.tr,
                  icon: Icons.home_outlined,
                  isHovered: _hoveredIndex == 0,
                  onHover: (hover) =>
                      setState(() => _hoveredIndex = hover ? 0 : -1),
                  onTap: () => Get.to(() => HomeWebDeskTopScreen()),
                ),
                SizedBox(width: 8.w),
                _ElegantNavItem(
                  label: 'الخدمات'.tr,
                  icon: Icons.apps_outlined,
                  isHovered: _hoveredIndex == 1,
                  onHover: (hover) =>
                      setState(() => _hoveredIndex = hover ? 1 : -1),
                  onTap: () =>
                      homeController.openServicesDrawer(widget.scaffoldKey),
                ),
                SizedBox(width: 8.w),
                _ElegantNavItem(
                  label: 'الإعدادات'.tr,
                  icon: Icons.settings_outlined,
                  isHovered: _hoveredIndex == 2,
                  onHover: (hover) =>
                      setState(() => _hoveredIndex = hover ? 2 : -1),
                  onTap: () {
                    if (loadingController.currentUser == null) {
                      _showElegantLoginDialog(context);
                    } else {
                      homeController.openSettingsDrawer(widget.scaffoldKey);
                    }
                  },
                ),
                SizedBox(width: 8.w),
                _ElegantNavItem(
                  label: 'الدعم'.tr,
                  icon: Icons.help_outline,
                  isHovered: _hoveredIndex == 3,
                  onHover: (hover) =>
                      setState(() => _hoveredIndex = hover ? 3 : -1),
                  onTap: () => Get.to(() => ReportProblemScreenDesktop()),
                ),
                SizedBox(width: 8.w),
                _ElegantNavItem(
                  label: 'المدونة'.tr,
                  icon: Icons.article_outlined,
                  isHovered: _hoveredIndex == 4,
                  onHover: (hover) =>
                      setState(() => _hoveredIndex = hover ? 4 : -1),
                  onTap: () async {
                    final Uri url =
                        Uri.parse("http://testing.arabiagroup.net/blog");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      Get.snackbar("خطأ", "تعذر فتح الرابط");
                    }
                  },
                ),
              ],
            ),

            // Search + New Ad Button - Enhanced Design
            Row(
              children: [
                // Enhanced Search Field
                Visibility(
                  visible: !widget.isAdsScreen,
                  child: _EnhancedSearchField(
                    isDark: isDark,
                    isHovered: _isSearchHovered,
                    onHover: (hover) =>
                        setState(() => _isSearchHovered = hover),
                    onTap: () => Get.to(
                      () => const AdsScreenDesktop(categoryId: null),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),

                // Enhanced New Ad Button
                _EnhancedAdButton(
                  isDark: isDark,
                  isHovered: _isAdButtonHovered,
                  onHover: (hover) =>
                      setState(() => _isAdButtonHovered = hover),
                  onTap: () {
                    if (loadingController.currentUser == null) {
                      _showElegantLoginDialog(context, forAd: true);
                    } else {
                      Get.to(() => AddAdScreenDesktop());
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showElegantLoginDialog(BuildContext context, {bool forAd = false}) {
    final bool isDark = themeController.isDarkMode.value;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a1a) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? const Color(0xFF333333) : const Color(0xFFf0f0f0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16.w,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تسجيل الدخول مطلوب'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            forAd
                                ? 'سجّل الدخول لإنشاء إعلان جديد'.tr
                                : 'هذه الميزة تتطلب تسجيل الدخول'.tr,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFe0e0e0),
                              ),
                            ),
                            child: Text(
                              'إغلاق'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              Get.to(() => const LoginDesktopScreen());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            child: Text(
                              'تسجيل الدخول'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const SignupDesktopScreen());
                      },
                      child: Text(
                        'إنشاء حساب جديد'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= NAV ITEM =======================

class _ElegantNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHovered;
  final Function(bool) onHover;

  const _ElegantNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<ThemeController>().isDarkMode.value;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            border: isHovered
                ?  Border(
                    bottom: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform:
                    Matrix4.translationValues(isHovered ? -2 : 0, 0, 0),
                child: Icon(
                  icon,
                  size: 17.w,
                  color: isHovered
                      ? AppColors.primary
                      : isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight:
                      isHovered ? FontWeight.w600 : FontWeight.w500,
                  color: isHovered
                      ? AppColors.primary
                      : isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= SEARCH FIELD =======================

class _EnhancedSearchField extends StatelessWidget {
  final bool isDark;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onTap;

  const _EnhancedSearchField({
    required this.isDark,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 300.w,
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a1a1a) : const Color(0xFFf8f9fa),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isHovered
                  ? AppColors.primary.withOpacity(0.6)
                  : isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFe0e0e0),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.search_rounded,
                  size: 16.w,
                  color: isHovered
                      ? AppColors.primary
                      : isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'ابحث في  الإعلانات...'.tr,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isHovered
                        ? AppColors.primary.withOpacity(0.8)
                        : isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                    fontFamily: AppTextStyles.appFontFamily,
                    fontWeight:
                        isHovered ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isHovered ? 1.0 : 0.0,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Enter',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.primary,
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= NEW AD BUTTON =======================

class _EnhancedAdButton extends StatelessWidget {
  final bool isDark;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onTap;

  const _EnhancedAdButton({
    required this.isDark,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHovered
                  ? const [Color(0xFF4a6cf7), Color(0xFF6a11cb)]
                  :  [AppColors.primary, Color(0xFF5a6cf7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform:
                    Matrix4.translationValues(isHovered ? -2 : 0, 0, 0),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  size: 14.w,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform:
                    Matrix4.translationValues(isHovered ? -1 : 0, 0, 0),
                child: Text(
                  'إعلان جديد'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: AppTextStyles.appFontFamily,
                    letterSpacing: isHovered ? 0.3 : 0.1,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isHovered ? 1.0 : 0.0,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 12.w,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
