import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/AboutUsController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AboutUs.dart';

class AboutUsScreenDesktop extends StatelessWidget {
  final AboutUsController aboutUsController = Get.put(AboutUsController());

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
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 30.w),
            onPressed: () => Get.back(),
          ),
          title: Text('من نحن'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xxxlarge,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
                fontFamily: AppTextStyles.appFontFamily,
              )),
        ),
        body: Obx(() {
          if (aboutUsController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final aboutUs = aboutUsController.aboutUs.value;
          if (aboutUs == null) {
            return Center(
              child: Text(
                'لا يوجد بيانات عن من نحن'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: textColor,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 100.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان رئيسي
                Text(
                  aboutUs.title,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxxlarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 20.h),
                
                // وصف التطبيق
                Text(
                  aboutUs.description,
                  style: TextStyle(
                    fontSize: AppTextStyles.xlarge,
                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 40.h),

                // بطاقات المعلومات
                _buildInfoRow(
                  title: 'رسالتنا'.tr,
                  content: 'تقديم منصة شاملة وآمنة تتيح للمستخدمين التواصل التجاري بسلاسة وثقة، مع الحفاظ على خصوصية وأمان مستخدمينا.'.tr,
                  icon: Icons.message,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 30.h),

                _buildInfoRow(
                  title: 'رؤيتنا'.tr,
                  content: 'أن نكون التطبيق الأول والوجهة المفضلة للاعلانات المبوبة في سوريا والوطن العربي، من خلال تحديثات مستمرة وخدمات مميزة.'.tr,
                  icon: Icons.visibility,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 30.h),

                _buildInfoRow(
                  title: 'مميزاتنا'.tr,
                  content: '• واجهة مستخدم سهلة ومبسطة\n• تصنيفات دقيقة ومتنوعة\n• إدارة فعالة للإعلانات\n• دعم فني متواصل\n• تحديثات مستمرة لتحسين التجربة'.tr,
                  icon: Icons.star,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 40.h),

                // فريق العمل
                Text(
                  'فريق العمل'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxxlarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 20.h),

                Text(
                  'نحن فريق من المطورين والمصممين والمختصين في التسويق الرقمي، نعمل بجهد لتطوير التطبيق باستمرار وتقديم أفضل تجربة للمستخدمين.'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.xlarge,
                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 30.h),

                // روابط التواصل الاجتماعي
                if (aboutUs.facebook != null || 
                    aboutUs.twitter != null || 
                    aboutUs.instagram != null || 
                    aboutUs.youtube != null || 
                    aboutUs.whatsapp != null)
                  _buildSocialLinks(aboutUs: aboutUs),

                SizedBox(height: 40.h),

                // حقوق النشر
                Center(
                  child: Text(
                    '© 2025 Stay in Me. جميع الحقوق محفوظة'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      color: AppColors.grey500,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildInfoRow({
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
    required Color cardColor,
  }) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 40.w),
          ),
          SizedBox(width: 25.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxlarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 15.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    height: 1.7,
                    color: AppColors.textPrimary(isDarkMode),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks({required AboutUs aboutUs}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل معنا'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 20.h),
        Wrap(
          spacing: 20.w,
          children: [
            if (aboutUs.facebook != null)
              _buildSocialIcon(
                icon: Icons.facebook,
                color: Colors.blue[700]!,
                onTap: () => _launchURL(aboutUs.facebook!),
              ),
            if (aboutUs.twitter != null)
              _buildSocialIcon(
                icon: Icons.camera,
                color: Colors.lightBlue,
                onTap: () => _launchURL(aboutUs.twitter!),
              ),
            if (aboutUs.instagram != null)
              _buildSocialIcon(
                icon: Icons.camera_alt,
                color: Colors.pink,
                onTap: () => _launchURL(aboutUs.instagram!),
              ),
            if (aboutUs.youtube != null)
              _buildSocialIcon(
                icon: Icons.video_library,
                color: Colors.red,
                onTap: () => _launchURL(aboutUs.youtube!),
              ),
            if (aboutUs.whatsapp != null)
              _buildSocialIcon(
                icon: Icons.chat,
                color: Colors.green,
                onTap: () => _launchURL('https://wa.me/${aboutUs.whatsapp}'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 28.w),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}