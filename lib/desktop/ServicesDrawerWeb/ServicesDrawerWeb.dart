import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/localization/changelanguage.dart';
import 'servicesItemsDesktop/PremiumPackagesDesktopScreen.dart';
import 'servicesItemsDesktop/ReportProblemScreenDesktop.dart';
import 'servicesItemsDesktop/AboutUsScreenDeskTop.dart';
import 'servicesItemsDesktop/AddAdMechanismScreenDesktop.dart';
import 'servicesItemsDesktop/ContactUsScreenDesktop.dart';
import 'servicesItemsDesktop/TermsAndConditionsScreenDesktop.dart';

class DesktopServicesDrawer extends StatelessWidget {
  const DesktopServicesDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final isRTL = Get.find<ChangeLanguageController>().currentLocale.value.languageCode== 'ar'; // تحديد اتجاه اللغة

    return Obx(() {
      final bgColor = AppColors.surface(isDarkMode);
      final cardColor = AppColors.card(isDarkMode);
      final primary = AppColors.primary;
      final textColor = AppColors.textPrimary(isDarkMode);
      final iconColor = AppColors.icon(isDarkMode);

      return Row(

        children: [
          Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              width: 340.w,
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  // تحديد الجانب بناءً على اللغة
                  left: isRTL ? BorderSide.none : BorderSide(
                    color: AppColors.divider(isDarkMode),
                    width: 1.w,
                  ),
                  right: isRTL ? BorderSide(
                    color: AppColors.divider(isDarkMode),
                    width: 1.w,
                  ) : BorderSide.none,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20.r,
                    // تحديد اتجاه الظل بناءً على اللغة
                    offset: isRTL ? const Offset(-5, 0) : const Offset(5, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header with elegant styling
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                    decoration: BoxDecoration(
                      color: AppColors.appBar(isDarkMode),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider(isDarkMode),
                          width: 1.w,
                        ),
                     )),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (!isRTL) ...[
                          Icon(Icons.widgets_rounded, 
                            color: AppColors.onPrimary, 
                            size: 28.w),
                          SizedBox(width: 16.w),
                        ],
                        Expanded(
                          child: Text('خدماتنا'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.onPrimary,
                                fontSize: AppTextStyles.xxlarge,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              )),
                        ),
                        if (isRTL) ...[
                          SizedBox(width: 16.w),
                          Icon(Icons.widgets_rounded, 
                            color: AppColors.onPrimary, 
                            size: 28.w),
                        ],
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
                      children: [
                        // Services Section - Desktop Design
                        _desktopSection(
                          title: 'الخدمات المتاحة'.tr,
                          icon: Icons.design_services,
                          items: [
                            _buildDesktopItem(
                              title: 'من نحن'.tr,
                              subtitle: 'تعرف على شركتنا ورسالتنا'.tr,
                              icon: Icons.business_center,
                              onTap: () => _handleAboutUs(),
                              isRTL: isRTL,
                            ),
                            _buildDesktopItem(
                              title: 'الشروط والأحكام'.tr,
                              subtitle: 'سياسات الاستخدام وشروط الخدمة'.tr,
                              icon: Icons.description,
                              onTap: () => _handleTermsAndConditions(),
                              isRTL: isRTL,
                            ),
                            _buildDesktopItem(
                              title: 'الباقات'.tr,
                              subtitle: 'اختر الباقة المناسبة لاحتياجاتك'.tr,
                              icon: Icons.credit_card,
                              onTap: () => _handlePackages(),
                              isRTL: isRTL,
                            ),
                            _buildDesktopItem(
                              title: 'آلية إضافة إعلان'.tr,
                              subtitle: 'كيفية نشر الإعلانات على المنصة'.tr,
                              icon: Icons.add_box,
                              onTap: () => _handleAddAdMechanism(),
                              isRTL: isRTL,
                            ),
                          
                            _buildDesktopItem(
                              title: 'الإبلاغ عن مشكلة'.tr,
                              subtitle: 'بلغنا عن أي مشكلة تواجهك'.tr,
                              icon: Icons.report_problem,
                              onTap: () => _handleReportProblem(),
                              isRTL: isRTL,
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                          isRTL: isRTL,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDesktopItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isRTL, // إضافة معلمة اتجاه اللغة
  }) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final iconColor = AppColors.icon(isDarkMode);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          hoverColor: AppColors.primary.withOpacity(0.1),
          splashColor: AppColors.primary.withOpacity(0.2),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider(isDarkMode),
                  width: 0.5.w,
                ),
              ),
            ),
            child: Row(
              // تغيير الترتيب بناءً على اللغة
              children: isRTL 
                ? _buildRTLItem(icon, title, subtitle, iconColor, isDarkMode)
                : _buildLTRItem(icon, title, subtitle, iconColor, isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRTLItem(IconData icon, String title, String subtitle, Color iconColor, bool isDarkMode) {
    return [
      Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: AppColors.primary, size: 26.w),
      ),
      SizedBox(width: 16.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
            SizedBox(height: 4.h),
            Text(subtitle,
                style: TextStyle(
                 fontSize: AppTextStyles.small,
                  color: AppColors.textSecondary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
          ],
        ),
      ),
      Icon(Icons.arrow_forward_ios_rounded, 
            size: 18.w, 
            color: iconColor),
    ];
  }

  List<Widget> _buildLTRItem(IconData icon, String title, String subtitle, Color iconColor, bool isDarkMode) {
    return [
      Icon(Icons.arrow_forward_ios_rounded, 
            size: 18.w, 
            color: iconColor),
      SizedBox(width: 16.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
            SizedBox(height: 4.h),
            Text(subtitle,
                textAlign: TextAlign.end,
                style: TextStyle(
                 fontSize: AppTextStyles.small,
                  color: AppColors.textSecondary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
          ],
        ),
      ),
      SizedBox(width: 16.w),
      Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: AppColors.primary, size: 26.w),
      ),
    ];
  }

  Widget _desktopSection({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required Color cardColor,
    required Color primary,
    required Color textColor,
    required Color iconColor,
    required bool isRTL, // إضافة معلمة اتجاه اللغة
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with elegant design
        Padding(
          padding: isRTL 
            ? EdgeInsets.only(left: 16.w, bottom: 16.h)
            : EdgeInsets.only(right: 16.w, bottom: 16.h),
          child: Row(
            // تغيير اتجاه الصف بناءً على اللغة
            mainAxisAlignment: isRTL ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isRTL) ...[
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: primary, size: 19.w),
                ),
                SizedBox(width: 12.w),
              ],
              Text(title,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  )),
              if (!isRTL) ...[
                SizedBox(width: 12.w),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: primary, size: 19.w),
                ),
              ],
            ],
          ),
        ),
        
        // Section items with card layout
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15.r,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  // ============== Event Handlers ============== //
  
  void _handleAboutUs() {
Get.to(()=> AboutUsScreenDesktop());
  }

  void _handleTermsAndConditions() {
  Get.to(()=> TermsAndConditionsScreenDesktop());
  }

  void _handlePackages() {
   Get.to(()=>const PremiumPackagesDesktopScreen());

    
    Get.snackbar('الباقات', 'صفحة تعرض الباقات المتاحة والاشتراكات');
  }

  void _handleAddAdMechanism() {
   Get.to(()=>const AddAdMechanismScreenDesktop());
  }

  void _handleContactUs() {
 Get.to(()=>const ContactUsScreenDesktop());
  }

  void _handleReportProblem() {
  Get.to(()=> ReportProblemScreenDesktop());
  }
}