import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/localization/changelanguage.dart';
import '../../controllers/home_controller.dart';

class LanguageSettingsPageDeskTop extends StatelessWidget {
  const LanguageSettingsPageDeskTop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
    final isDarkMode = themeController.isDarkMode.value;
    final HomeController homeController = Get.find<HomeController>();
    
    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'إعدادات اللغة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
                     color: AppColors.onPrimary, 
                     size: 28.w),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر لغتك المفضلة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'سيتم عرض التطبيق باللغة التي تختارها'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            SizedBox(height: 40.h),
            
            // بطاقة اختيار اللغة
            Card(
              color: AppColors.card(isDarkMode),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(
                    homeController: homeController,
                    context: context,
                    title: 'العربية'.tr,
                    code: 'ar',
                    flag: '🇸🇾', // علم سوريا
                    isSelected: languageController.currentLocale.value.languageCode == 'ar',
                    isDarkMode: isDarkMode,
                  ),
                  Divider(
                    height: 1, 
                    indent: 20.w,
                    endIndent: 20.w,
                    color: AppColors.divider(isDarkMode).withOpacity(0.3)),
                  _buildLanguageOption(
                    homeController: homeController,
                    context: context,
                    title: 'English',
                    code: 'en',
                    flag: '🇬🇧',
                    isSelected: languageController.currentLocale.value.languageCode == 'en',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            
            // بطاقة المعلومات
            _buildInfoCard(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required HomeController homeController,
    required BuildContext context,
    required String title,
    required String code,
    required String flag,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      leading: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Text(
            flag,
            style: TextStyle(fontSize: 19.sp),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(isDarkMode),
        ),
      ),
      subtitle: Text(
        '${'رمز اللغة:'.tr} $code',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
         fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 20.w,
                color: Colors.white,
              ),
            )
          : null,
      onTap: () {
        if (!isSelected) {
          languageController.changeLanguage(code);
          homeController.fetchCategories(languageController.currentLocale.value.languageCode);
          
          // إعادة تحميل الصفحة لتطبيق التغييرات
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LanguageSettingsPageDeskTop()),
          );
        }
      },
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Card(
      color: AppColors.card(isDarkMode),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 32.r,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تم تغيير اللغة. سيتم تطبيق التغيير على جميع أجزاء التطبيق.'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                     fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(isDarkMode),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}