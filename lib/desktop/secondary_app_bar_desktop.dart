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

class SecondaryAppBarDeskTop extends StatelessWidget {
  bool  isAdsScreen = false;
   SecondaryAppBarDeskTop({super.key, this.isAdsScreen= false});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    final homeController = Get.put(HomeController());
    final loadingController = Get.put(LoadingController());
    final isDark = themeController.isDarkMode.value;

    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border(isDark),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🧭 Navigation Items
          Row(
            children: [
              _NavItem(
                label: 'الرئيسية'.tr,
                icon: Icons.home_rounded,
                onTap: () => Get.to(HomeWebDeskTopScreen()),
              ),
              _NavItem(
                label: 'الخدمات'.tr,
                icon: Icons.widgets_rounded,
                onTap: () {
                  homeController.toggleDrawerType(false);
                Scaffold.of(context).openEndDrawer();
                },
              ),
              _NavItem(
                label: 'الإعدادات'.tr,
                icon: Icons.settings_rounded,
                onTap: () {
                  if (loadingController.currentUser == null) {
                   _showLoginRequiredDialog(context);
                  } else {
                    homeController.toggleDrawerType(true);
                    Scaffold.of(context).openEndDrawer();
                  }
                },
              ),
              _NavItem(
                label: 'الدعم'.tr,
                icon: Icons.support_agent_rounded,
                onTap: () => Get.to(() => ReportProblemScreenDesktop()),
              ), _NavItem(
  label: 'المدونة'.tr,
  icon: Icons.web,
  onTap: () async {
    final Uri url = Uri.parse("http://testing.arabiagroup.net/blog");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("خطأ", "تعذر فتح الرابط");
    }
  },
),
            ],
          ),

          // 🔍 البحث + زر إعلان جديد
         Row(
              children: [
                // 🔍 Search Field (clickable)
                Visibility(
            visible:!isAdsScreen,
            child:  InkWell(
                  onTap: () => Get.to(() => AdsScreenDesktop(categoryId: null)),
                  borderRadius: BorderRadius.circular(25.r),
                  child: Container(
                    width: 320.w,
                    height: 44.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface(isDark),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: AppColors.border(isDark),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.icon(isDark), size: 20.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'ابحث عن إعلانات...'.tr,
                          style: TextStyle(
                           fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDark),
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                
                
                ),
            
                SizedBox(width: 20.w),
            
                // 📢 زر "إعلان جديد"
                InkWell(
                  onTap: () {
                    if (loadingController.currentUser == null) {
                      _showLoginRequiredDialog(context, forAd: true);
                    } else {
                      Get.to(() => AddAdScreenDesktop());
                    }
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.buttonAndLinksColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonAndLinksColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'إعلان جديد'.tr,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context, {bool forAd = false}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        contentPadding: EdgeInsets.all(24.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48.sp, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'تسجيل الدخول مطلوب'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w700,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              forAd
                  ? 'سجّل الدخول لإنشاء إعلان جديد'.tr
                  : 'هذه الميزة تتطلب تسجيل الدخول'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: Colors.grey,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('إغلاق'.tr,
                     textAlign: TextAlign.center,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: Colors.grey,
                fontFamily: AppTextStyles.appFontFamily,),
                  ),
                  )),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.to(() => LoginDesktopScreen());
                    },
                    child: Text('تسجيل الدخول'.tr  , style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: Colors.grey,
                fontFamily: AppTextStyles.appFontFamily,),
                    
                ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Get.back();
                Get.to(() => SignupDesktopScreen());
              },
              child: Text('إنشاء حساب جديد'.tr,   style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: Colors.grey,
                fontFamily: AppTextStyles.appFontFamily,),
                  ),
                  
            )
          ],
        ),
      ),
    );
  }
}
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<ThemeController>().isDarkMode.value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.icon(isDark)),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                 fontSize: AppTextStyles.medium,
                  color: AppColors.textPrimary(isDark),
                  fontFamily: AppTextStyles.appFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
