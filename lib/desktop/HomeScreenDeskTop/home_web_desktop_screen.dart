import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/areaController.dart';
import 'package:tappuu_website/controllers/home_controller.dart';
import 'package:tappuu_website/desktop/HomeScreenDeskTop/sections/featured_ads_section_desktop.dart';
import 'package:tappuu_website/desktop/secondary_app_bar_desktop.dart';
import 'package:tappuu_website/desktop/top_app_bar_desktop.dart';

import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/CurrencyController.dart';
import '../../core/constant/appcolors.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import 'sections/CategoryAdsSection_desktop.dart';
import 'sections/LatestAdsSection_desktop.dart';
import 'sections/PopularTagsSectionDestTok.dart';
import 'sections/categories_sidebar_desktop.dart';
import 'sections/footer_desktop.dart';

class HomeWebDeskTopScreen extends StatefulWidget {
  const HomeWebDeskTopScreen({super.key});

  @override
  State<HomeWebDeskTopScreen> createState() => _HomeWebDeskTopScreenState();
}

class _HomeWebDeskTopScreenState extends State<HomeWebDeskTopScreen> {
  late final ThemeController themeC;
  late final HomeController _homeController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // 🧠 تسجيل الكنترولرات بطريقة lazy (لو مش مسجلين)
    if (!Get.isRegistered<AdsController>()) {
      Get.lazyPut<AdsController>(() => AdsController(), fenix: true);
    }

    if (!Get.isRegistered<AreaController>()) {
      Get.lazyPut<AreaController>(() => AreaController(), fenix: true);
    }

    if (!Get.isRegistered<CurrencyController>()) {
      Get.lazyPut<CurrencyController>(() => CurrencyController(), fenix: true);
    }

    themeC = Get.find<ThemeController>();
    _homeController = Get.find<HomeController>();

    // ✅ اطلب تهيئة بيانات الهوم بعد أول فريم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adsController = Get.find<AdsController>();
      adsController.ensureHomeInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeC.isDarkMode.value;

      // AdsController يُنشأ هنا لأول مرة فقط (بسبب lazyPut في initState)
      final AdsController adsController = Get.find<AdsController>();

      return Scaffold(
        key: _scaffoldKey,
        endDrawer: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _homeController.drawerType.value == DrawerType.settings
                ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
                : const DesktopServicesDrawer(key: ValueKey('services')),
          ),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        body: CustomScrollView(
          slivers: [
            // Top AppBar - ثابت
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: TopAppBarDeskTop(),
                height: 85.h,
              ),
            ),
            // Secondary AppBar - ثابت
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey),
                height: 70.h,
              ),
            ),
            // مسافة بسيطة تحت الترويسات
            SliverToBoxAdapter(
              child: SizedBox(height: 20.h),
            ),
            // المحتوى الرئيسي
            SliverToBoxAdapter(
              child: _buildMainContent(context, isDarkMode, adsController),
            ),
            // الفوتر
            SliverToBoxAdapter(
              child: Footer(scaffoldKey: _scaffoldKey),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isDarkMode,
    AdsController adsController,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: 1400.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الشريط الجانبي ككرت أنيق
            Container(
              width: 260.w,
              margin: EdgeInsets.only(bottom: 24.h),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.card(isDarkMode) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CategoriesSidebarDesktop(),
            ),
            SizedBox(width: 24.w),

            // العمود الرئيسي
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.h),

                  // الإعلانات المميزة
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: FeaturedAdsSectionDesktop(
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // أحدث الإعلانات
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: LatestAdsSectionDestop(
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // عقارات للبيع
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: CategoryAdsSectionDeskTop(
                      categoryId: 1,
                      categoryName: 'عقارات للبيع'.tr,
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // عقارات للإيجار
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: CategoryAdsSectionDeskTop(
                      categoryId: 2,
                      categoryName: 'عقارات للإيجار'.tr,
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // مركبات للبيع
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: CategoryAdsSectionDeskTop(
                      categoryId: 3,
                      categoryName: 'مركبات للبيع'.tr,
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // مركبات للإيجار
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: CategoryAdsSectionDeskTop(
                      categoryId: 4,
                      categoryName: 'مركبات للإيجار'.tr,
                      adsController: adsController,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // الوسوم الشائعة
                  _buildSectionCard(
                    isDarkMode: isDarkMode,
                    child: PopularTagsSectionDeskTop(),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// كرت قياسي لكل سكشن رئيسي
  Widget _buildSectionCard({
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.card(isDarkMode) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03),
          width: 0.4,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: child,
      ),
    );
  }
}

/// Delegate للترويسات المثبتة
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
