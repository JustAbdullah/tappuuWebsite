import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/CurrencyController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../controllers/home_controller.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';
import 'SettingsDrawerDeskTop.dart';

class CurrencySettingsPageDeskTop extends StatelessWidget {
  const CurrencySettingsPageDeskTop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final CurrencyController currencyController = Get.put(CurrencyController());
    final isDarkMode = themeController.isDarkMode.value;
    
     
    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(themeController.isDarkMode.value),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
         SizedBox(height: 20.h,),
          Text(
            'اختر العملة المفضلة'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'سيتم عرض جميع الأسعار بالعملة التي تختارها'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
             fontSize: AppTextStyles.small,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(height: 40.h),
          
          // بطاقة اختيار العملة
          Card(
            color: AppColors.card(isDarkMode),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              children: [
                _buildCurrencyOption(
                  title: 'الليرة السورية'.tr,
                  code: 'SYP',
                  symbol: 'ل.س'.tr,
                  isSelected: currencyController.currentCurrency.value == 'SYP',
                  isDarkMode: isDarkMode,
                ),
                Divider(
                  height: 1, 
                  indent: 20.w,
                  endIndent: 20.w,
                  color: AppColors.divider(isDarkMode).withOpacity(0.3)),
                _buildCurrencyOption(
                  title: 'الدولار الأمريكي'.tr,
                  code: 'USD',
                  symbol: '\$',
                  isSelected: currencyController.currentCurrency.value == 'USD',
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
    );
  }

  Widget _buildCurrencyOption({
    required String title,
    required String code,
    required String symbol,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    final CurrencyController currencyController = Get.find<CurrencyController>();
    
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
            symbol,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
            ),
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
        code,
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
          currencyController.changeCurrency(code);
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
                    'سيتم عرض جميع الأسعار بالعملة المحددة. يمكنك تغييرها في أي وقت من هذه الصفحة.'.tr,
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