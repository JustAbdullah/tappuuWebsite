import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/core/localization/changelanguage.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/ThemeController.dart';
import '../../../../core/constant/app_text_styles.dart';
import '../../../../core/constant/appcolors.dart';
import '../../../../core/data/model/user.dart';
import '../../controllers/home_controller.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';
import 'SettingsDrawerDeskTop.dart';

class UserInfoPageDeskTop extends StatelessWidget {
  const UserInfoPageDeskTop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final LoadingController loadingController = Get.find<LoadingController>();
    final isDarkMode = themeController.isDarkMode.value;
    final currentUser = loadingController.currentUser;
    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(themeController.isDarkMode.value),
      body:  Column(
        children: [
            TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
         SizedBox(height: 20.h,),
          currentUser == null
              ? Center(
                  child: Text(
                    'لا تتوفر بيانات المستخدم'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة المعلومات الأساسية
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card(isDarkMode),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Row(
                          children: [
                            // الصورة الرمزية
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 36.w,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 20.w),
                            
                            // معلومات المستخدم
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                
                                  Text(
                                    currentUser.email ?? 'بريد إلكتروني غير محدد'.tr,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: AppTextStyles.medium,
                                      color: AppColors.textSecondary(isDarkMode),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Wrap(
                                    spacing: 12.w,
                                    runSpacing: 12.h,
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.calendar_today,
                                        title: 'تاريخ التسجيل'.tr,
                                        value: _formatDate(currentUser.date),
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildInfoChip(
                                        icon: Icons.verified_user,
                                        title: 'حالة الحساب'.tr,
                                        value: _getAccountStatus(currentUser),
                                        isDarkMode: isDarkMode,
                                      ),
                                      _buildInfoChip(
                                        icon: Icons.post_add,
                                        title: 'الإعلانات المجانية'.tr,
                                        value: _getFreePostsInfo(currentUser),
                                        isDarkMode: isDarkMode,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      SizedBox(height: 32.h),
                      
                      // معلومات إضافية
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card(isDarkMode),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفاصيل الحساب'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.xlarge,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(isDarkMode),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            
                            // معلومات الإشعارات
                        
                            SizedBox(height: 16.h),
                            
                            // معلومات اللغة
                            _buildDetailItem(
                              icon: Icons.language,
                              title: 'اللغة المفضلة'.tr,
                              value: Get.find<ChangeLanguageController>().currentLocale.value.languageCode=="ar"? 'العربية'.tr:'الانجليزية'.tr,
                              isDarkMode: isDarkMode,
                            ),
                            SizedBox(height: 16.h),
                            
                            // معلومات آخر نشاط
                            _buildDetailItem(
                              icon: Icons.access_time,
                              title: 'آخر نشاط'.tr,
                              value: 'الان'.tr,
                              isDarkMode: isDarkMode,
                            ),
                            SizedBox(height: 16.h),
                            
                            // معلومات الحالة
                            _buildDetailItem(
                              icon: Icons.verified_user,
                              title: 'حالة التحقق'.tr,
                              value: 'نشط'.tr,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // بطاقة الإحصائيات (تصميم مضغوط وأنيق)
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      width: 200.w, // عرض مناسب لشاشات الويب
      height: 140.h, // ارتفاع مناسب
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22.w,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xxxlarge,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // شريحة المعلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.border(isDarkMode),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18.w,
            color: AppColors.textSecondary(isDarkMode),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                 fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // عنصر المعلومات التفصيلية
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22.w,
          color: AppColors.buttonAndLinksColor,
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getAccountStatus(User user) {
    if (user.is_delete == 1) return 'محذوف';
    if (user.is_block == 1) return 'محظور';
    return 'مفعل'.tr;
  }

  String _getFreePostsInfo(User user) {
    final used = user.free_posts_used;
    final max = user.max_free_posts;
    return '$used / $max (${max - used} ${'متبقية'.tr})';
  }
}