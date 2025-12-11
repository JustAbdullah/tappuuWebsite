import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controllers/AdsManageController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../AdsManageDeskTop/AddAdScreenDeskTop.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'UserAdItemDeskTop.dart';

class UserAdsScreenDeskTop extends StatelessWidget {
  final String statusAds;
  const UserAdsScreenDeskTop({super.key, required this.statusAds});

  @override
  Widget build(BuildContext context) {
      final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final adsController = Get.put(ManageAdController());
    final LoadingController loadingC = Get.find<LoadingController>();

    // جلب إعلانات المستخدم عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadingC.currentUser != null) {
        adsController.fetchUserAds(
            userId: loadingC.currentUser?.id ?? 0, status: statusAds.toString());
      }
    });
final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
        key: _scaffoldKey,
    endDrawer: Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _homeController.drawerType.value == DrawerType.settings
            ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
            : const DesktopServicesDrawer(key: ValueKey('services')),
      ),
    ),
        backgroundColor: AppColors.background(themeController.isDarkMode.value),
      body: Column(
        children: [  
            TopAppBarDeskTop(),
      SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey,),
         SizedBox(height: 20.h,),
          Expanded(
         
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200.w),
                child: Obx(() {
                  return Column(
                    children: [
                      // شريط التحكم العلوي
                      _buildTopControls(isDarkMode, adsController),
                      
                      SizedBox(height: 16.h),
                      
                      // محتوى الإعلانات
                      Expanded(
                        child: adsController.isLoadingUserAds.value
                            ? _buildShimmerLoader(isDarkMode, adsController.viewMode.value)
                            : adsController.userAdsList.isEmpty
                                ? _buildEmptyState(isDarkMode)
                                : _buildAdsGrid(isDarkMode, adsController),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
            Get.to(() => AddAdScreenDesktop());
        },
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.white, size: 26.w),
        label: Text('إعلان جديد', 
          style: TextStyle( fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // شريط التحكم العلوي
  Widget _buildTopControls(bool isDarkMode, ManageAdController adsController) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // عدد الإعلانات
          Obx(() {
            final count = adsController.userAdsList.length;
            return Row(
              children: [
                Icon(Icons.list_alt_rounded, size: 24.w, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text(
                  "عرض $count إعلان",
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            );
          }),
          
          // أزرار التحكم
          Row(
            children: [
              Text(
                'طريقة العرض'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(width: 12.w),
              _buildViewModeToggle(isDarkMode, adsController),
            ],
          ),
        ],
      ),
    );
  }

  // تبديل وضع العرض
  Widget _buildViewModeToggle(bool isDarkMode, ManageAdController adsController) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          borderRadius: BorderRadius.circular(10.r),
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

             
              isActive: adsController.viewMode.value == 'grid',
              controller: adsController,
              isDarkMode: isDarkMode,
            ),
            Container(
              height: 24.h,
              width: 1,
              color: AppColors.divider(isDarkMode),
            ),
            _buildViewModeButton(
              icon: Icons.view_list,
              mode: 'list',
              label: 'قائمة'.tr,
              isActive: adsController.viewMode.value == 'list',
              controller: adsController,
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
    required ManageAdController controller,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () => controller.changeViewMode(mode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: mode == 'grid' 
              ? BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  bottomLeft: Radius.circular(10.r))
              : BorderRadius.only(
                  topRight: Radius.circular(10.r),
                  bottomRight: Radius.circular(10.r)),
        ),
        child: Row(
          children: [
            Icon(icon, 
              size: 20.w,
              color: isActive ? AppColors.primary : AppColors.textSecondary(isDarkMode)),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: isActive ? AppColors.primary : AppColors.textSecondary(isDarkMode),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // حالة عدم وجود إعلانات
  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 100.w,
             
              color: AppColors.textSecondary(isDarkMode).withOpacity(0.5),
            ),
            SizedBox(height: 24.h),
            Text(

              statusAds=="published"?
              'لا توجد إعلانات منشورة'.tr: 'لا توجد إعلانات في حالة المراجعة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'يمكنك البدء بإنشاء إعلان جديد بالضغط على زر "إعلان جديد" في الأسفل'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                 Get.to(() => AddAdScreenDesktop());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.add, size: 24.w),
              label: Text(
                'إنشاء إعلان جديد',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // شبكة الإعلانات
  Widget _buildAdsGrid(bool isDarkMode, ManageAdController adsController) {
    return Obx(() {
      final viewMode = adsController.viewMode.value;
      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        gridDelegate: viewMode == 'grid'
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(Get.context!).size.width > 1000 ? 4 : 3,
                crossAxisSpacing: 24.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 1.05,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 195.h,
                mainAxisSpacing: 5.h,
                crossAxisSpacing: 10.w
              ),
        itemCount: adsController.userAdsList.length,
        itemBuilder: (context, index) {
          return UserAdItemDeskTop(
            ad: adsController.userAdsList[index],
            viewMode: viewMode,
          );
        },
      );
    });
  }

  // مؤشر التحميل الوميضي
  Widget _buildShimmerLoader(bool isDarkMode, String viewMode) {
    final crossAxisCount = viewMode == 'grid' 
        ? (MediaQuery.of(Get.context!).size.width > 1000 ? 4 : 3)
        : 2;
    
    final itemCount = viewMode == 'grid' ? 8 : 4;

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      gridDelegate: viewMode == 'grid'
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24.w,
              mainAxisSpacing: 24.h,
              childAspectRatio: 1.30,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 160.h,
              mainAxisSpacing: 16.h,  crossAxisSpacing: 10.w
            ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4),
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
        // صورة الشيمر
        Container(
          height: 160.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
           )   ),
          
        // محتوى الشيمر
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 18.h,
                width: double.infinity,
                color: Colors.white,
              ),
              SizedBox(height: 12.h),
              Container(
                height: 16.h,
                width: 120.w,
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    height: 14.h,
                    width: 14.w,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    height: 14.h,
                    width: 100.w,
                    color: Colors.white,
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            
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
        // صورة الشيمر
        Container(
          width: 200.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12.r)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20.h,
                  width: double.infinity,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 18.h,
                  width: 150.w,
                  color: Colors.white,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      height: 16.h,
                      width: 16.w,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      height: 16.h,
                      width: 180.w,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
              
              ],
            ),
          ),
        ),
      ],
    );
  }
}