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

class HomeWebDeskTopScreen extends StatelessWidget {
  final ThemeController themeC = Get.find<ThemeController>();
  final AdsController adsController = Get.put(AdsController());
  final AreaController areasController = Get.put(AreaController());
  final CurrencyController curr = Get.put(CurrencyController());
  final HomeController _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;

    return Obx(() {
      return Scaffold(
        endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        body: CustomScrollView(
          slivers: [
            // Top AppBar - fixed
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: TopAppBarDeskTop(),
                height:85.h,
              ),
            ),
            // Secondary AppBar - fixed
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverHeaderDelegate(
                child: SecondaryAppBarDeskTop(),
                height: 70.h,
              ),
            ),
            // Spacing below app bars
            SliverToBoxAdapter(
              child: SizedBox(height: 30.h),
            ),
            // Main content
            SliverToBoxAdapter(
              child: _buildMainContent(context),
            ),
            // Footer
            SliverToBoxAdapter(
              child: Footer(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          SizedBox(
            width: 270.w,
            child: CategoriesSidebarDesktop(),
          ),
          SizedBox(width: 20.w),
          // Main content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                FeaturedAdsSectionDesktop(adsController: adsController),
                SizedBox(height: 10.h),
                LatestAdsSectionDestop(adsController: adsController),
                SizedBox(height: 10.h),
                CategoryAdsSectionDeskTop(
                  categoryId: 1,
                  categoryName: 'عقارات للبيع'.tr,
                  adsController: adsController,
                ),
                SizedBox(height: 10.h),
                CategoryAdsSectionDeskTop(
                  categoryId: 2,
                  categoryName: 'عقارات للإيجار'.tr,
                  adsController: adsController,
                ),
                SizedBox(height: 10.h),
                CategoryAdsSectionDeskTop(
                  categoryId: 3,
                  categoryName: 'مركبات للبيع'.tr,
                  adsController: adsController,
                ),
                SizedBox(height: 10.h),
                CategoryAdsSectionDeskTop(
                  categoryId: 4,
                  categoryName: 'مركبات للإيجار'.tr,
                  adsController: adsController,
                ),
                SizedBox(height: 15.h),
                PopularTagsSectionDeskTop(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A delegate that makes a widget have a fixed height and pin it.
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
