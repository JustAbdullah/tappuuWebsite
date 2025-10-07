import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/AboutUsController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class ReportProblemScreenDesktop extends StatelessWidget {
  final _problemController = TextEditingController();
  final AboutUsController aboutUsController = Get.put(AboutUsController());

  ReportProblemScreenDesktop({Key? key}) : super(key: key);

  // دالة لفتح تطبيق البريد
  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'الإبلاغ عن مشكلة في تطبيق Stay in Me',
        'body': _problemController.text
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق البريد'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // دالة لفتح الواتساب
  Future<void> _launchWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق الواتساب'.tr,
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
      final aboutUs = aboutUsController.aboutUs.value;
      
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
          title: Text('الإبلاغ عن مشكلة'.tr,
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
                      'نحن نعتذر عن أي إزعاج تواجهه. يرجى وصف المشكلة التي واجهتها بدقة لمساعدتنا على حلها.'.tr,
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
                  
                  // المشاكل الشائعة
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, 
                              color: AppColors.warning, size: 24.w),
                            SizedBox(width: 10.w),
                            Text('المشاكل الشائعة'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        
                        Wrap(
                          spacing: 15.w,
                          runSpacing: 15.h,
                          children: [
                            _buildProblemChip('عدم تحميل الصور'.tr, onTap: () {
                              _problemController.text = 'عدم تحميل الصور'.tr;
                            }),
                            _buildProblemChip('تعطل التطبيق'.tr, onTap: () {
                              _problemController.text = 'تعطل التطبيق'.tr;
                            }),
                            _buildProblemChip('مشكلة في الدفع'.tr, onTap: () {
                              _problemController.text = 'مشكلة في الدفع'.tr;
                            }),
                            _buildProblemChip('مشكلة في الإعلان'.tr, onTap: () {
                              _problemController.text = 'مشكلة في الإعلان'.tr;
                            }),
                            _buildProblemChip('مشكلة في الحساب'.tr, onTap: () {
                              _problemController.text = 'مشكلة في الحساب'.tr;
                            }),
                            _buildProblemChip('أخرى'.tr, onTap: () {
                              _problemController.text = 'مشكلة أخرى'.tr;
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // معلومات التواصل من API
                  if (aboutUs != null)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // البريد الإلكتروني
                        if (aboutUs.contactEmail != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 15.h),
                          child: _buildContactInfoDesktop(
                            icon: Icons.email,
                            title: 'البريد الإلكتروني'.tr,
                            value: aboutUs.contactEmail!,
                            onTap: () => _launchEmail(aboutUs.contactEmail!),
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        
                        // الواتساب
                        if (aboutUs.whatsapp != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 15.h),
                          child: _buildContactInfoDesktop(
                            icon: Icons.chat,
                            title: 'الواتساب'.tr,
                            value: aboutUs.whatsapp!,
                            onTap: () => _launchWhatsApp(aboutUs.whatsapp!),
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        
                        // الهاتف
                       
                        // الموقع الإلكتروني
                     
                        // العنوان
                      
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // دعم مباشر عبر الواتساب
                  if (aboutUs != null && aboutUs.whatsapp != null)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('هل تحتاج إلى دعم فوري؟'.tr,
                            style: TextStyle(
                              fontSize: AppTextStyles.xlarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          ElevatedButton.icon(
                            onPressed: () => _launchWhatsApp(aboutUs.whatsapp!),
                            icon: Icon(Icons.chat, color: Colors.white),
                            label: Text('تواصل عبر واتــساب'.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppTextStyles.medium,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildProblemChip(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(text,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            color: AppColors.primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactInfoDesktop({
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
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20.w),
            SizedBox(width: 10.w),
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
              color: AppColors.grey500, size: 16.w),
          ],
        ),
      ),
    );
  }
}