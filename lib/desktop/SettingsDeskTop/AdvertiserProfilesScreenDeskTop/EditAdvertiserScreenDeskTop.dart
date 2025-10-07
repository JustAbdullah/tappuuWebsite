import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/AdvertiserController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

// سلوك التمرير بدون شريط تمرير
class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics();
  }
}

class EditAdvertiserScreen extends StatelessWidget {
  EditAdvertiserScreen({Key? key}) : super(key: key);

  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final AdvertiserController controller = Get.find<AdvertiserController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final HomeController _homeController = Get.find<HomeController>();

    return Scaffold(     
      endDrawer: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _homeController.isServicesOrSettings.value
            ? SettingsDrawerDeskTop(key: const ValueKey(1))
            : DesktopServicesDrawer(key: const ValueKey(2)),
      ),
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            TopAppBarDeskTop(),
            SecondaryAppBarDeskTop(),
            Expanded(
              child: ScrollConfiguration(
                behavior: NoScrollbarScrollBehavior(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 700.w,
                        minHeight: MediaQuery.of(context).size.height - 200.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          // العنوان الرئيسي
                          _buildMainTitle(isDarkMode),
                          SizedBox(height: 10.h),
                          
                          // وصف الصفحة
                          _buildDescription(isDarkMode),
                          SizedBox(height: 20.h),
                          
                          // حقل الشعار
                          _buildLogoSection(controller, isDarkMode),
                          SizedBox(height: 20.h),
                          
                          // حقل نوع الحساب
                          _buildAccountTypeField(controller, isDarkMode),
                          SizedBox(height: 20.h),
                          
                          // حقول البيانات
                          _buildFormFields(controller, isDarkMode),
                          SizedBox(height: 20.h),
                          
                          // زر الحفظ
                          _buildSaveButton(controller),
                          SizedBox(height: 10.h),
                          
                          // ملاحظة
                          _buildNote(isDarkMode),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTitle(bool isDarkMode) {
    return Center(
      child: Text(
        'تعديل بيانات المعلن'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.xlarge,
          fontWeight: FontWeight.bold,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDescription(bool isDarkMode) {
    return Center(
      child: Text(
        'قم بتحديث بياناتك ليظهر للمستخدمين بشكل صحيح'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.medium,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLogoSection(AdvertiserController controller, bool isDarkMode) {
    return Column(
      children: [
        Text(
          'شعار المعلن (اختياري)'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10.h),
        
        // تصميم دائرة الشعار
        Center(
          child: Obx(() => Container(
            width: 100.w,
            height: 100.h,
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                // عرض الصورة الحالية أو المختارة
                if (controller.logoBytes.value != null)
                  ClipOval(
                    child: Image.memory(
                      controller.logoBytes.value!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else if (controller.uploadedImageUrls.value.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      controller.uploadedImageUrls.value,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon(isDarkMode);
                      },
                    ),
                  )
                else if (controller.originalProfileForEdit?.logo != null &&
                        controller.originalProfileForEdit!.logo!.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      controller.originalProfileForEdit!.logo!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon(isDarkMode);
                      },
                    ),
                  )
                else
                  _buildPlaceholderIcon(isDarkMode),

                // زر إضافة/تغيير الصورة
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => controller.pickLogo(),
                      child: controller.logoBytes.value == null && 
                              controller.uploadedImageUrls.value.isEmpty && 
                              (controller.originalProfileForEdit?.logo == null || 
                              controller.originalProfileForEdit!.logo!.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 24.w,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    'تغيير الشعار'.tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.small,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ),
                
                // زر إزالة الصورة
                if (controller.logoBytes.value != null || 
                    controller.uploadedImageUrls.value.isNotEmpty ||
                    (controller.originalProfileForEdit?.logo != null && 
                    controller.originalProfileForEdit!.logo!.isNotEmpty))
                  Positioned(
                    bottom: 6.h,
                    right: 6.w,
                    child: GestureDetector(
                      onTap: () => controller.removeLogo(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4.w),
                        child: Icon(Icons.close, color: Colors.white, size: 12.w),
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ),
        SizedBox(height: 10.h),
        Text(
          'اضغط على الدائرة لتغيير الشعار'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.small,
            color: AppColors.textSecondary(isDarkMode),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // إضافة حقل نوع الحساب
  Widget _buildAccountTypeField(AdvertiserController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الحساب*'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildAccountTypeChoice(
                title: 'فردي'.tr,
                isSelected: controller.accountType.value == 'individual',
                onTap: () => controller.setAccountType('individual'),
                isDarkMode: isDarkMode,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildAccountTypeChoice(
                title: 'شركة'.tr,
                isSelected: controller.accountType.value == 'company',
                onTap: () => controller.setAccountType('company'),
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTypeChoice({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary(isDarkMode).withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.onPrimary
                  : AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(AdvertiserController controller, bool isDarkMode) {
    return Column(
      children: [
        // حقل اسم المعلن
        _buildInputField(
          title: 'اسم المعلن*'.tr,
          hint: controller.accountType.value == 'individual' 
            ? 'أدخل اسمك الشخصي'.tr 
            : 'أدخل اسم الشركة أو المؤسسة'.tr,
          icon: Icons.business,
          controller: controller.businessNameCtrl,
          isDarkMode: isDarkMode,
          onChanged: (value) => controller.updateButton(),
        ),
        SizedBox(height: 15.h),
        
        // حقل الوصف
        _buildInputField(
          title: 'وصف المعلن (اختياري)'.tr,
          hint: controller.accountType.value == 'individual' 
            ? 'أدخل وصفًا مختصرًا عن نشاطك'.tr 
            : 'أدخل وصفًا مختصرًا عن نشاط الشركة'.tr,
          icon: Icons.description,
          controller: controller.descriptionCtrl,
          isDarkMode: isDarkMode,
          maxLines: 3,
        ),
        SizedBox(height: 15.h),
        
        // حقل رقم الاتصال
        _buildInputField(
          title: 'رقم الاتصال*'.tr,
          hint: 'مثال: 00963XXXXXXXX'.tr,
          icon: Icons.phone,
          controller: controller.contactPhoneCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
          onChanged: (value) => controller.updateButton(),
        ),
        SizedBox(height: 15.h),
        
        // حقل واتساب
        _buildInputField(
          title: 'رقم الواتساب (اختياري)'.tr,
          hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
          icon: Icons.chat,
          controller: controller.whatsappPhoneCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 15.h),

        // حقل الاتصال المباشر بالواتساب (جديد)
        _buildInputField(
          title: 'رقم الاتصال المباشر بالواتساب (اختياري)'.tr,
          hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
          icon: Icons.phone_android,
          controller: controller.whatsappCallNumberCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _buildInputField({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDarkMode,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: AppTextStyles.small,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(icon, size: 18.w, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.0,
                ),
              ),
            ),
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AdvertiserController controller) {
    return GetBuilder<AdvertiserController>(
      id: 'button',
      builder: (btnController) {
        final isValid = btnController.businessNameCtrl.text.isNotEmpty &&
                       btnController.contactPhoneCtrl.text.isNotEmpty;
        
        final isSaving = btnController.isSaving.value;
        final userId = loadingC.currentUser?.id ?? 0;
        
        return SizedBox(
          width: double.infinity,
          height: 40.h,
          child: ElevatedButton(
            onPressed: (isValid && !isSaving)
                ? () => btnController.saveProfileChanges(userId)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isValid && !isSaving)
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.4),
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: (isValid && !isSaving) ? 4 : 0,
              shadowColor: AppColors.primary.withOpacity(0.3),
            ),
            child: isSaving
                ? CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 3,
                  )
                : Text(
                    'حفظ التعديلات'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNote(bool isDarkMode) {
    return Center(
      child: Text(
        '* الحقول الإلزامية'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.small,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isDarkMode) {
    return Center(
      child: Icon(
        Icons.business,
        size: 40.w,
        color: AppColors.primary,
      ),
    );
  }
}