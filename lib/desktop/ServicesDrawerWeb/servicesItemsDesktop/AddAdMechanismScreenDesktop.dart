import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';


import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class AddAdMechanismScreenDesktop extends StatelessWidget {
  const AddAdMechanismScreenDesktop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isRTL = true; // تخطيط من اليمين لليسار للغة العربية

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
          title: Text('آلية إضافة إعلان'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimary,
                fontFamily: AppTextStyles.appFontFamily,
              )),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
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
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'لإضافة إعلان جديد في تطبيق Stay in Me، يرجى اتباع الخطوات التالية بدقة. هذه الآلية تضمن وصول إعلانك للجمهور المستهدف بفعالية.'.tr,
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
              
              // خطوات الإضافة
              Column(
                children: [
                  _buildStepCardDesktop(
                    stepNumber: '١',
                    title: 'تسجيل الدخول أو إنشاء حساب',
                    content: '• يجب أن يكون لديك حساب مسجل في التطبيق\n• كل حساب له عدد محدود من الإعلانات المجانية\n• يمكنك الاشتراك في إحدى الباقات لزيادة عدد الإعلانات المسموحة',
                    icon: Icons.account_circle,
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: 15.h),
                  
                  _buildStepCardDesktop(
                    stepNumber: '٢',
                    title: 'إنشاء ملف المعلن',
                    content: '• كل إعلان يحتاج إلى ملف معلن مرتبط به\n• يمكنك إنشاء أكثر من ملف معلن لحساب واحد\n• ملف المعلن يحتوي على:\n   - الاسم الظاهر في الإعلان\n   - الشعار (صورة شخصية/لوجو)\n   - وصف مختصر عن المعلن\n   - معلومات التواصل',
                    icon: Icons.business_center,
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: 15.h),
                  
                  _buildStepCardDesktop(
                    stepNumber: '٣',
                    title: 'اختيار التصنيفات المناسبة',
                    content: '• اختر التصنيف الرئيسي بدقة (مثل: عقارات، سيارات، أجهزة)\n• حدد التصنيف الفرعي الأول (مثل: شقق للإيجار)\n• اختر التصنيف الفرعي الثانوي إن وجد (مثل: شقق مفروشة)\n• حدد الخصائص المميزة للإعلان من القائمة',
                    icon: Icons.category,
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: 15.h),
                  
                  _buildStepCardDesktop(
                    stepNumber: '٤',
                    title: 'إدخال تفاصيل الإعلان',
                    content: '• اكتب عنوانًا واضحًا وجذابًا للإعلان\n• صف الإعلان بدقة وباللغة العربية الفصحى\n• حدد السعر المناسب مع العملة\n• أضف صورًا عالية الجودة (بحد أدنى 3 صور)\n   - الصور يجب أن تكون واضحة وذات دقة عالية\n   - تجنب الصور المحمية بحقوق الملكية',
                    icon: Icons.description,
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: 15.h),
                  
                  _buildStepCardDesktop(
                    stepNumber: '٥',
                    title: 'تحديد الموقع الجغرافي',
                    content: '• اختر المحافظة (مثل: دمشق، حلب، اللاذقية)\n• حدد المنطقة أو الحي بدقة\n• استخدم خريطة التطبيق لتحديد الموقع الجغرافي الدقيق\n• الموقع الدقيق يساعد المشترين في الوصول إليك بسهولة',
                    icon: Icons.location_on,
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: 15.h),
                  
                  _buildStepCardDesktop(
                    stepNumber: '٦',
                    title: 'مراجعة الإعلان ونشره',
                    content: '• راجع جميع المعلومات المدخلة قبل النشر\n• تأكد من صحة البيانات ودقتها\n• اضغط على زر "نشر الإعلان"\n• سيمر الإعلان بمرحلة مراجعة من قبل الفريق\n• سيتم إشعارك عند الموافقة على الإعلان ونشره',
                    icon: Icons.check_circle,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              
              SizedBox(height: 30.h),
              
              // نصائح مهمة
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                          color: AppColors.warning, size: 24.w),
                        SizedBox(width: 10.w),
                        Text('نصائح لإعلان ناجح'.tr,
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
                    _buildTipDesktop('استخدم صورًا واضحة وجذابة من زوايا متعددة'.tr),
                    _buildTipDesktop('اكتب وصفًا دقيقًا وشاملاً للإعلان'.tr),
                    _buildTipDesktop('حدد السعر المناسب حسب السوق المحلي'.tr),
                    _buildTipDesktop('تأكد من صحة معلومات التواصل'.tr),
                    _buildTipDesktop('حدد التصنيفات بدقة لتظهر للجمهور المستهدف'.tr),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              
              // ملاحظة ختامية
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, 
                      color: AppColors.success, size: 20.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'للاستفسارات أو المساعدة، يرجى التواصل مع دعم التطبيق عبر البريد الإلكتروني: support@stayinme.com'.tr,
                        style: TextStyle(
                         fontSize: AppTextStyles.medium,
                          height: 1.6,
                          color: textColor,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildStepCardDesktop({
    required String stepNumber,
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final textColor = AppColors.textPrimary(isDarkMode);
    
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الخطوة
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(stepNumber.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
          ),
          SizedBox(width: 20.w),
          
          // محتوى الخطوة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 24.w),
                    SizedBox(width: 10.w),
                    Text(title.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(height: 1, color: Colors.grey[400]),
                SizedBox(height: 12.h),
                Text(content.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    height: 1.8,
                    color: textColor,
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
  
  Widget _buildTipDesktop(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, color: AppColors.primary, size: 18.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                height: 1.6,
                color: AppColors.textPrimary(false),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}