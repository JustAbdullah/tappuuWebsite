import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class ContactUsScreenDesktop extends StatelessWidget {
  const ContactUsScreenDesktop({Key? key}) : super(key: key);

  // دالة لفتح تطبيق البريد
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@stayinme.com',
      queryParameters: {'subject': 'استفسار عن تطبيق Stay in Me'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق البريد'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // دالة لفتح الرابط في المتصفح
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح الرابط'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      final bgColor = AppColors.background(isDarkMode);
      final textColor = AppColors.textPrimary(isDarkMode);
      final cardColor = AppColors.card(isDarkMode);
      
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, 
                color: AppColors.onPrimary, size: 20.w),
            onPressed: () => Get.back(),
          ),
          title: Text('التواصل معنا'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
                fontFamily: AppTextStyles.appFontFamily,
              )),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مقدمة
                  Container(
                    padding: EdgeInsets.all(20.w),
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'يسعدنا تواصلكم معنا! فريق Stay in Me دائمًا متاح للإجابة على استفساراتكم ومساعدتكم في أي وقت.'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        height: 1.8,
                        color: textColor,
                        fontFamily: AppTextStyles.appFontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // بطاقات معلومات الاتصال
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20.h,
                    crossAxisSpacing: 20.w,
                    childAspectRatio: 2.5,
                    children: [
                      _buildContactCardDesktop(
                        icon: Icons.email,
                        title: 'البريد الإلكتروني'.tr,
                        value: 'support@stayinme.com',
                        onTap: _launchEmail,
                        isDarkMode: isDarkMode,
                      ),
                      _buildContactCardDesktop(
                        icon: Icons.phone,
                        title: 'الهاتف'.tr,
                        value: '+963 11 123 4567',
                        onTap: () => _launchURL('tel:+963111234567'),
                        isDarkMode: isDarkMode,
                      ),
                      _buildContactCardDesktop(
                        icon: Icons.language,
                        title: 'الموقع الإلكتروني'.tr,
                        value: 'www.stayinme.com',
                        onTap: () => _launchURL('https://www.stayinme.com'),
                        isDarkMode: isDarkMode,
                      ),
                      _buildContactCardDesktop(
                        icon: Icons.location_on,
                        title: 'العنوان'.tr,
                        value: 'دمشق، سوريا'.tr,
                        onTap: () => _launchURL('https://maps.app.goo.gl/'),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // ساعات العمل
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, 
                              color: AppColors.primary, size: 24.w),
                            SizedBox(width: 10.w),
                            Text('ساعات العمل'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.h),
                        _buildWorkingHoursDesktop('الأحد - الخميس'.tr, '9:00 ص - 5:00 م'.tr),
                        _buildWorkingHoursDesktop('الجمعة'.tr, '10:00 ص - 2:00 م'.tr),
                        _buildWorkingHoursDesktop('السبت'.tr, 'عطلة رسمية'.tr),
                      ],
                    ),
                ),
                  
                  
                 
                  
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildContactCardDesktop({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.card(isDarkMode),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24.w),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(value,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDarkMode),
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
              color: AppColors.grey500, size: 18.w),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkingHoursDesktop(String day, String hours) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          Text(hours,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.grey600,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 30.w),
          ),
          SizedBox(height: 8.h),
          Text(label,
            style: TextStyle(
             fontSize: AppTextStyles.medium,
              color: AppColors.grey700,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}