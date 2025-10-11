import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/AdvertiserController.dart';
import '../../controllers/LoadingController.dart';
import '../../core/data/model/AdvertiserProfile.dart';
import '../HomeScreen/home_screen.dart';

class AdvertiserDataScreen extends StatelessWidget {
  AdvertiserDataScreen({Key? key}) : super(key: key);

  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final AdvertiserController advController = Get.put(AdvertiserController());

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () {
            Get.back();
            Get.back();
          },
        ),
        title: Text(
          'بيانات المعلن'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (advController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 900.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        'أنشئ بياناتك كمعلن'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.xxxlarge,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Description
                    Center(
                      child: Text(
                        'هذه البيانات ستظهر للمستخدمين عند نشر الإعلانات'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Form layout: two columns on wide screens
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _leftColumn(advController, isDarkMode)),
                                SizedBox(width: 24.w),
                                Expanded(child: _rightColumn(advController, isDarkMode)),
                              ],
                            )
                          : Column(
                              children: [
                                _leftColumn(advController, isDarkMode),
                                SizedBox(height: 18.h),
                                _rightColumn(advController, isDarkMode),
                              ],
                            );
                    }),

                    SizedBox(height: 22.h),

                    // Save button
                    GetBuilder<AdvertiserController>(
                      id: 'button',
                      builder: (btnController) {
                        final isValid = btnController.businessNameCtrl.text.isNotEmpty &&
                            btnController.contactPhoneCtrl.text.isNotEmpty;

                        final isSaving = btnController.isSaving.value;

                        return SizedBox(
                          width: double.infinity,
                          height: 55.h,
                          child: ElevatedButton(
                            onPressed: (isValid && !isSaving)
                                ? () async {
                                    try {
                                      btnController.setSaving(true);

                                      if (btnController.logoPath.value != null) {
                                        await btnController.uploadLogoToServer();
                                      }

                                      final profile = AdvertiserProfile(
                                        userId: loadingC.currentUser?.id ?? 0,
                                        logo: btnController.uploadedImageUrls.value,
                                        name: btnController.businessNameCtrl.text,
                                        description: btnController.descriptionCtrl.text,
                                        contactPhone: btnController.contactPhoneCtrl.text,
                                        whatsappPhone: btnController.whatsappPhoneCtrl.text,
                                        whatsappCallNumber:
                                            btnController.whatsappCallNumberCtrl.text,
                                        accountType: btnController.accountType.value,
                                      );

                                      await btnController.createProfile(profile);
                                      Get.offAll(() => HomeScreen());
                                    } catch (e) {
                                      Get.snackbar('خطأ'.tr,
                                          '${'فشل في حفظ البيانات:'.tr} $e');
                                    } finally {
                                      btnController.setSaving(false);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isValid && !isSaving)
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.4),
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
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
                                    'حفظ البيانات'.tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.xlarge,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppTextStyles.appFontFamily,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 14.h),
                    Center(
                      child: Text(
                        '* الحقول الإلزامية'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _leftColumn(AdvertiserController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Center(
          child: Column(
            children: [
              Text(
                'شعار المعلن (اختياري)'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              SizedBox(height: 12.h),
              Obx(() => GestureDetector(
                    onTap: () => controller.pickLogo(),
                    child: Container(
                      width: 200.w,
                      height: 200.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface(isDarkMode),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (controller.logoPath.value != null)
                            ClipOval(
                              child: Image.file(
                                controller.logoPath.value!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 34.w, color: AppColors.primary),
                                  SizedBox(height: 8.h),
                                  Text('إضافة شعار'.tr, style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          if (controller.logoPath.value != null)
                            Positioned(
                              bottom: 10.h,
                              right: 10.w,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: AppColors.primary,
                                onPressed: () => controller.removeLogo(),
                                child: Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
              SizedBox(height: 10.h),
              Text('اضغط على الدائرة لإضافة أو تغيير الشعار'.tr, style: TextStyle(color: AppColors.textSecondary(isDarkMode))),
            ],
          ),
        ),

        SizedBox(height: 22.h),

        // Account type
        _buildAccountTypeField(controller, isDarkMode),
        SizedBox(height: 18.h),

        // Business name (reactive hint)
        Obx(() => _buildInputField(
              title: 'اسم المعلن*'.tr,
              hint: controller.accountType.value == 'individual'
                  ? 'أدخل اسمك الشخصي'.tr
                  : 'أدخل اسم الشركة أو المؤسسة'.tr,
              icon: Icons.business,
              controller: controller.businessNameCtrl,
              isDarkMode: isDarkMode,
              onChanged: (v) => controller.updateButton(),
            )),

        SizedBox(height: 18.h),

        // Description (reactive hint)
        Obx(() => _buildInputField(
              title: 'وصف المعلن (اختياري)'.tr,
              hint: controller.accountType.value == 'individual'
                  ? 'أدخل وصفًا مختصرًا عن نشاطك'.tr
                  : 'أدخل وصفًا مختصرًا عن نشاط الشركة'.tr,
              icon: Icons.description,
              controller: controller.descriptionCtrl,
              isDarkMode: isDarkMode,
              maxLines: 4,
            )),
      ],
    );
  }

  Widget _rightColumn(AdvertiserController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          title: 'رقم الاتصال*'.tr,
          hint: 'مثال: 00963XXXXXXXX'.tr,
          icon: Icons.phone,
          controller: controller.contactPhoneCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
          onChanged: (v) => controller.updateButton(),
        ),
        SizedBox(height: 18.h),
        _buildInputField(
          title: 'رقم الواتساب (اختياري)'.tr,
          hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
          icon: Icons.wallet,
          controller: controller.whatsappPhoneCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 18.h),
        _buildInputField(
          title: 'رقم الاتصال المباشر بالواتساب (اختياري)'.tr,
          hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
          icon: Icons.phone_android,
          controller: controller.whatsappCallNumberCtrl,
          isDarkMode: isDarkMode,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildAccountTypeField(AdvertiserController controller, bool isDarkMode) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نوع الحساب*'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.w600,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => controller.setAccountType('individual'),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 220),
                        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: controller.accountType.value == 'individual'
                              ? AppColors.primary
                              : AppColors.surface(isDarkMode),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: controller.accountType.value == 'individual'
                                ? AppColors.primary
                                : AppColors.textSecondary(isDarkMode).withOpacity(0.5),
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text('فردي'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.large,
                                fontWeight: FontWeight.w600,
                                color: controller.accountType.value == 'individual'
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary(isDarkMode),
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => controller.setAccountType('company'),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 220),
                        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: controller.accountType.value == 'company'
                              ? AppColors.primary
                              : AppColors.surface(isDarkMode),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: controller.accountType.value == 'company'
                                ? AppColors.primary
                                : AppColors.textSecondary(isDarkMode).withOpacity(0.5),
                            width: 1.4,
                          ),
                        ),
                        child: Center(
                          child: Text('شركة'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.large,
                                fontWeight: FontWeight.w600,
                                color: controller.accountType.value == 'company'
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary(isDarkMode),
                              )),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
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
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            prefixIcon: Icon(icon, size: 22.w, color: AppColors.textSecondary(isDarkMode)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      ],
    );
  }
}
