import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/TermsAndConditionsController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class TermsAndConditionsScreenDesktop extends StatelessWidget {
  final TermsAndConditionsController termsController = Get.put(TermsAndConditionsController());

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      final bgColor = AppColors.background(isDarkMode);
      final textColor = AppColors.textPrimary(isDarkMode);

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
          title: Text('الشروط والأحكام'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xxxlarge,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
                fontFamily: AppTextStyles.appFontFamily,
              )),
        ),
        body: Obx(() {
          if (termsController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final terms = termsController.terms.value;
          if (terms == null) {
            return Center(
              child: Text(
                'لا يوجد شروط وأحكام متاحة حالياً'.tr,
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
                // مقدمة
                Container(
                  padding: EdgeInsets.all(24.w),
                  margin: EdgeInsets.only(bottom: 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'مرحبًا بك في تطبيق Stay in Me للإعلانات المبوبة. يرجى قراءة هذه الشروط والأحكام بعناية قبل استخدام التطبيق.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextStyles.xlarge,
                      height: 1.5,
                      color: textColor,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),
                
                // محتوى الشروط والأحكام من API
                Text(
                  terms.content,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // إقرار بالموافقة
                Container(
                  padding: EdgeInsets.all(24.w),
                  margin: EdgeInsets.only(top: 24.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, 
                        color: AppColors.warning, size: 24.w),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'باستمرارك في استخدام تطبيق Stay in Me، فإنك تقر بأنك قد قرأت وفهمت ووافقت على هذه الشروط والأحكام بكاملها.'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            height: 1.5,
                            color: textColor,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // تاريخ التحديث
               
                
                SizedBox(height: 40.h),
              ],
            ),
          );
        }),
      );
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    
    final day = date.day;
    final month = date.month;
    final year = date.year;
    
    return '$day/$month/$year';
  }
}