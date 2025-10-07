import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/AuthController.dart';

import '../../controllers/home_controller.dart';
import '../HomeScreenDeskTop/home_web_desktop_screen.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';

class SignupDesktopScreen extends StatefulWidget {
  const SignupDesktopScreen({Key? key}) : super(key: key);

  @override
  _SignupDesktopScreenState createState() => _SignupDesktopScreenState();
}

class _SignupDesktopScreenState extends State<SignupDesktopScreen> {  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final AuthController authC = Get.put(AuthController());
  final size = MediaQuery.of(Get.context!).size;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
final HomeController
   _homeController = Get.find<HomeController>();

    return  Obx(() {
    return
     Scaffold(     
    endDrawer: AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _homeController.isServicesOrSettings.value
      ? SettingsDrawerDeskTop(key: const ValueKey(1))
      :DesktopServicesDrawer(key: const ValueKey(2)),
),
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(), // تمرير المفتاح
          Expanded(
            child: Center(
              child: Container(
                width: size.width * 0.35,
                constraints: BoxConstraints(maxWidth: 600.w, minHeight: 600.h),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
                child: GetX<AuthController>(
                  builder: (_authC) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان الصفحة
                          Text(
                            'إنشاء حساب جديد'.tr,
                            style: TextStyle(
                              fontSize: AppTextStyles.xxlarge,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          
                          // وصف الصفحة
                          Text(
                            'انضم إلينا الآن وتمتع بجميع الميزات الحصرية'.tr,
                            style: TextStyle(
                              fontSize: AppTextStyles.medium,
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                          ),
                          SizedBox(height: 40.h),
                          
                          // مؤشر التقدم
                          _buildProgressIndicator(isDarkMode, authC),
                          SizedBox(height: 40.h),
                          
                          // محتوى الخطوات
                          if (_authC.currentStep.value == 0) _buildEmailStep(isDarkMode, authC),
                          if (_authC.currentStep.value == 1) _buildVerificationStep(isDarkMode, authC),
                          if (_authC.currentStep.value == 2) _buildPasswordStep(isDarkMode, authC),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
     }); }

  Widget _buildProgressIndicator(bool isDarkMode, AuthController authCrl) {
    Color activeColor = AppColors.primary;
    Color inactiveColor = AppColors.greyLight;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          // الخطوة 1 - البريد الإلكتروني
          _buildProgressStep(
            number: 1,
            label: 'البريد الإلكتروني'.tr,
            isActive: authCrl.currentStep.value >= 0,
            isDarkMode: isDarkMode,
          ),
          
          // الخط المتصل
          Expanded(
            child: Divider(
              thickness: 2,
              color: authCrl.currentStep.value >= 1 ? activeColor : inactiveColor,
              height: 2.h,
            ),
          ),
          
          // الخطوة 2 - رمز التحقق
          _buildProgressStep(
            number: 2,
            label: 'رمز التحقق'.tr,
            isActive: authCrl.currentStep.value >= 1,
            isDarkMode: isDarkMode,
          ),
          
          // الخط المتصل
          Expanded(
            child: Divider(
              thickness: 2,
              color: authCrl.currentStep.value >= 2 ? activeColor : inactiveColor,
              height: 2.h,
            ),
          ),
          
          // الخطوة 3 - كلمة المرور
          _buildProgressStep(
            number: 3,
            label: 'كلمة المرور'.tr,
            isActive: authCrl.currentStep.value >= 2,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required int number,
    required String label,
    required bool isActive,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22.r,
          backgroundColor: isActive ? AppColors.primary : AppColors.greyLight,
          child: Text(
            '$number',
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.onSurfaceLight,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
            color: isActive ? AppColors.primary : AppColors.textSecondary(isDarkMode),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الخطوة
        Text(
          'أدخل بريدك الإلكتروني'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        Text(
          'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني للتأكد من ملكيته'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل البريد الإلكتروني
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
            ],
          ),
          child: TextFormField(
            controller: authCrl.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(Icons.email_outlined, 
                color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 18.h),
            ),
          ),
        ),
        SizedBox(height: 60.h),
        
        // زر المتابعة
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: authCrl.sendVerificationCodeForSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'إرسال رمز التحقق'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الخطوة
        Text(
          'أدخل رمز التحقق'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        RichText(
          text: TextSpan(
            text: 'تم إرسال رمز مكون من 6 أرقام إلى '.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            children: [
              TextSpan(
                text: authCrl.emailCtrl.text,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل إدخال رمز التحقق
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
            ],
          ),
          child: TextFormField(
            controller: authCrl.codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
            decoration: InputDecoration(
              labelText: 'رمز التحقق'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(Icons.lock_outlined, 
                color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 18.h),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        
        // إعادة إرسال الرمز
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'لم تستلم الرمز؟'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            TextButton(
              onPressed: authCrl.resendCode,
              child: Text(
                'إعادة الإرسال'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 60.h),
        
        // زر التحقق
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: authCrl.verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'تحقق من الرمز'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
          ),
        ),
        SizedBox(height: 20.h),
        
        // العودة لتغيير البريد
        Center(
          child: TextButton(
            onPressed: () => authCrl.currentStep.value = 0,
            child: Text(
              'تغيير البريد الإلكتروني'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الخطوة
        Text(
          'أنشئ كلمة مرورك'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        Text(
          'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل كلمة المرور
        Obx(() => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
            ],
          ),
          child: TextFormField(
            controller: authCrl.passwordCtrl,
            obscureText: !authCrl.showPassword.value,
            onChanged: authCrl.validatePassword,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textPrimary(isDarkMode),
            ),
            decoration: InputDecoration(
              labelText: 'كلمة المرور'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(Icons.lock_outline, 
                color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  authCrl.showPassword.value ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.primary,
                ),
                onPressed: () => authCrl.showPassword.toggle(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 18.h),
            ),
          ),
        )),
        SizedBox(height: 10.h),
        
        // مؤشر قوة كلمة المرور
        Obx(() => Text(
          authCrl.isPasswordValid.value 
            ? 'كلمة المرور صالحة'.tr
            : 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            color: authCrl.isPasswordValid.value 
              ? AppColors.success 
              : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        )),
        SizedBox(height: 60.h),
        
        // زر الإنشاء
        Obx(() => SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: authCrl.isPasswordValid.value
              ? () async {
                  authCrl.isLoading.value = true;
                  final result = await authCrl.completeRegistration();
                  authCrl.isLoading.value = false;

                  if (result['status'] == true) {
                    // Navigate to success screen
                    Get.offAll(() => AccountCreatedSuccessScreen());
                  } else {
                    Get.snackbar(
                      'خطأ'.tr,
                      result['message'],
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error.withOpacity(0.2),
                      colorText: AppColors.error,
                      duration: Duration(seconds: 3),
                    );
                  }
                }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: authCrl.isPasswordValid.value 
                ? AppColors.primary 
                : AppColors.primary.withOpacity(0.5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 3,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 28.w,
                  height: 28.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'إنشاء الحساب'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
          ),
        )),
        SizedBox(height: 20.h),
        
        // العودة للخطوة السابقة
        Center(
          child: TextButton(
            onPressed: () => authCrl.prevStep(),
            child: Text(
              'العودة'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Scaffold(     

      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(), // تمرير المفتاح
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                constraints: BoxConstraints(maxWidth: 600.w),
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة نجاح
                    Icon(
                      Icons.check_circle_outline,
                      size: 100.w,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 30.h),
                    
                    // رسالة التهنئة
                    Text(
                      'مبروك لقد تم إنشاء حسابك بنجاح'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    
                    // نص توجيهي
                    Text(
                      'يمكنك الآن البدء باستخدام جميع المميزات '.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 50.h),
                    
                    // زر العودة للرئيسية
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () =>   Get.offAll(()=> HomeWebDeskTopScreen()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'الذهاب إلى الصفحة الرئيسية'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}