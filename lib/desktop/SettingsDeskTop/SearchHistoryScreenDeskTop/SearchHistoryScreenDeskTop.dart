import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/ThemeController.dart';
import '../../../../controllers/ViewsController.dart';
import '../../../../core/constant/app_text_styles.dart';
import '../../../../core/constant/appcolors.dart';
import '../../../controllers/home_controller.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'SearchHistoryAdItemDeskTop.dart';

class SearchHistoryScreenDeskTop extends StatelessWidget {
  const SearchHistoryScreenDeskTop({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final viewsController = Get.put(ViewsController());
    final LoadingController loadingC = Get.find<LoadingController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadingC.currentUser != null) {
        viewsController.fetchViews(
          userId: loadingC.currentUser?.id ?? 0,
        );
      }
    });

    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(themeController.isDarkMode.value),
      body:Column(
        children: [          TopAppBarDeskTop(),
                SecondaryAppBarDeskTop(),
               SizedBox(height: 20.h,),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200.w),
                child: Obx(() {
                  return Column(
                    children: [
              
                      _buildTopControls(isDarkMode, viewsController),
                      Expanded(
                        child: viewsController.isLoading.value
                            ? _buildShimmerLoader(isDarkMode, viewsController.viewMode.value)
                            : viewsController.views.isEmpty
                                ? _buildEmptyState(isDarkMode)
                                : _buildViewsGrid(isDarkMode, viewsController,context),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(bool isDarkMode, ViewsController controller) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w), // تصغير الحشوة
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h), // تصغير الهوامش
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18.sp, color: AppColors.primary), // تصغير حجم الأيقونة
              SizedBox(width: 8.w),
              Text(
                "الإعلانات التي شاهدتها".tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium, // تصغير حجم الخط
                  fontWeight: FontWeight.w700,
                  color: AppColors.buttonAndLinksColor,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h), // تصغير الحشوة
                decoration: BoxDecoration(
                  color: AppColors.buttonAndLinksColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  controller.views.length.toString(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.medium, // تصغير حجم الخط
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonAndLinksColor,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'طريقة العرض'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                 fontSize: AppTextStyles.medium, // تصغير حجم الخط
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(width: 8.w),
              _buildViewModeToggle(isDarkMode, controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(bool isDarkMode, ViewsController controller) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildViewModeButton(
              icon: Icons.grid_view,
              mode: 'grid',
              label: 'شبكة'.tr,
              isActive: controller.viewMode.value == 'grid',
              controller: controller,
              isDarkMode: isDarkMode,
            ),
            Container(
              height: 20.h,
              width: 1,
              color: AppColors.divider(isDarkMode),
            ),
            _buildViewModeButton(
              icon: Icons.view_list,
              mode: 'list',
              label: 'قائمة'.tr,
              isActive: controller.viewMode.value == 'list',
              controller: controller,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String mode,
    required String label,
    required bool isActive,
    required ViewsController controller,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () => controller.changeViewMode(mode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h), // تصغير الحشوة
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: mode == 'grid' 
              ? BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  bottomLeft: Radius.circular(8.r))
              : BorderRadius.only(
                  topRight: Radius.circular(8.r),
                  bottomRight: Radius.circular(8.r)),
        ),
        child: Row(
          children: [
            Icon(icon, 
              size: 16.sp, // تصغير حجم الأيقونة
              color: isActive ? AppColors.primary : AppColors.textSecondary(isDarkMode)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
               fontSize: AppTextStyles.medium, // تصغير حجم الخط
                color: isActive ? AppColors.primary : AppColors.textSecondary(isDarkMode),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 70.w, // تصغير حجم الأيقونة
              color: AppColors.textSecondary(isDarkMode).withOpacity(0.5),
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد سجلات بحث'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium, // تصغير حجم الخط
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'سيتم حفظ الإعلانات التي تتصفحها هنا لتتمكن من العودة إليها لاحقًا'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
               fontSize: AppTextStyles.medium, // تصغير حجم الخط
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewsGrid(bool isDarkMode, ViewsController controller, BuildContext context) {
    return Obx(() {
      final viewMode = controller.viewMode.value;
      return RefreshIndicator(
        onRefresh: () async {
          if (Get.find<LoadingController>().currentUser != null) {
            await controller.fetchViews(
              userId: Get.find<LoadingController>().currentUser?.id ?? 0,
            );
          }
        },
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h), // تصغير الحشوة
          gridDelegate: viewMode == 'grid'
              ? SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 4 : 3,
                  crossAxisSpacing: 16.w, // تصغير المسافة
                  mainAxisSpacing: 16.h, // تصغير المسافة
                  childAspectRatio: 1.25, // تعديل النسبة
                )
              : SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 170.h, // تصغير الارتفاع
                  mainAxisSpacing: 12.h, // تصغير المسافة
                  crossAxisSpacing: 8.w // تصغير المسافة
                ),
          itemCount: controller.views.length,
          itemBuilder: (context, index) {
            return SearchHistoryAdItemDeskTop(
              ad: controller.views[index],
              viewMode: viewMode,
            );
          },
        ),
      );
    });
  }

  Widget _buildShimmerLoader(bool isDarkMode, String viewMode) {
    final crossAxisCount = viewMode == 'grid' 
        ? (MediaQuery.of(Get.context!).size.width > 1000 ? 4 : 3)
        : 2;
    
    final itemCount = viewMode == 'grid' ? 8 : 4;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h), // تصغير الحشوة
      gridDelegate: viewMode == 'grid'
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.w, // تصغير المسافة
              mainAxisSpacing: 16.h, // تصغير المسافة
              childAspectRatio: 1.4, // تعديل النسبة
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 130.h, // تصغير الارتفاع
              mainAxisSpacing: 12.h, // تصغير المسافة
              crossAxisSpacing: 8.w // تصغير المسافة
            ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: viewMode == 'grid'
                ? _buildGridShimmer()
                : _buildListShimmer(),
          ),
        );
      },
    );
  }

  Widget _buildGridShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 130.h, // تصغير الارتفاع
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12.w), // تصغير الحشوة
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14.h, // تصغير الارتفاع
                width: double.infinity,
                color: Colors.white,
              ),
              SizedBox(height: 8.h),
              Container(
                height: 12.h, // تصغير الارتفاع
                width: 100.w,
                color: Colors.white,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    height: 12.h, // تصغير الارتفاع
                    width: 12.w,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    height: 12.h, // تصغير الارتفاع
                    width: 80.w,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 20.h, // تصغير الارتفاع
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListShimmer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160.w, // تصغير العرض
          height: 100.h, // تصغير الارتفاع
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(10.r)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(12.w), // تصغير الحشوة
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16.h, // تصغير الارتفاع
                  width: double.infinity,
                  color: Colors.white,
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 14.h, // تصغير الارتفاع
                  width: 120.w,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      height: 12.h, // تصغير الارتفاع
                      width: 12.w,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      height: 12.h, // تصغير الارتفاع
                      width: 140.w,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 20.h, // تصغير الارتفاع
                      width: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}