import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/AuthController.dart';
import 'package:tappuu_website/core/recaptcha/recaptcha_mini_webview.dart';

import '../../controllers/home_controller.dart';
import '../HomeScreenDeskTop/home_web_desktop_screen.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';

class ResetPasswordDesktopScreen extends StatefulWidget {
  const ResetPasswordDesktopScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordDesktopScreenState createState() =>
      _ResetPasswordDesktopScreenState();
}

class _ResetPasswordDesktopScreenState
    extends State<ResetPasswordDesktopScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // نستخدم نفس AuthController إن وُجد
  final AuthController authC = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  // ================= reCAPTCHA v3 Mini =================

  static const String kRecaptchaBaseUrl =
      'https://testing.arabiagroup.net/recaptcha.html';

  /// المنصّات التي تدعم Mini WebView
  bool get _supportsRecaptchaMini {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  // step 0 → إرسال كود استعادة كلمة المرور
  late final Widget _recaptchaResetEmail = const RecaptchaMiniWebView(
    key: ValueKey('recaptcha_reset_email_v3_desktop'),
    baseUrl: kRecaptchaBaseUrl,
    action: 'reset_email',
    invisible: true,
  );

  // step 2 → تعيين كلمة المرور الجديدة
  late final Widget _recaptchaResetPassword = const RecaptchaMiniWebView(
    key: ValueKey('recaptcha_reset_password_v3_desktop'),
    baseUrl: kRecaptchaBaseUrl,
    action: 'reset_password',
    invisible: true,
  );

  @override
  Widget build(BuildContext context) {
    // نخلي قراءة الـ Rx جوّا الـ Obx عشان ما يطلع الخطأ
    return Obx(() {
      final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
      final HomeController _homeController = Get.find<HomeController>();
      final size = MediaQuery.of(context).size;

      return Scaffold(
        key: _scaffoldKey,
        endDrawer: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _homeController.drawerType.value == DrawerType.settings
                ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
                : const DesktopServicesDrawer(key: ValueKey('services')),
          ),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        body: SafeArea(
          child: Stack(
            children: [
              // ================== UI الرئيسي ==================
              Column(
                children: [
                  TopAppBarDeskTop(),
                  SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: size.width * 0.35,
                        constraints: BoxConstraints(
                          maxWidth: 600.w,
                          minHeight: 600.h,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 40.w,
                          vertical: 20.h,
                        ),
                        child: GetX<AuthController>(
                          builder: (_authC) {
                            return SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // عنوان الصفحة
                                  Text(
                                    'إعادة تعيين كلمة المرور'.tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.xxlarge,
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          AppTextStyles.appFontFamily,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),

                                  // وصف الصفحة
                                  Text(
                                    'أدخل بريدك الإلكتروني لإرسال رمز التحقق وإعادة تعيين كلمة المرور'
                                        .tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.medium,
                                      fontFamily:
                                          AppTextStyles.appFontFamily,
                                      color: AppColors.textSecondary(
                                          isDarkMode),
                                    ),
                                  ),
                                  SizedBox(height: 40.h),

                                  // مؤشر التقدم
                                  _buildProgressIndicator(isDarkMode, authC),
                                  SizedBox(height: 40.h),

                                  // محتوى الخطوات
                                  if (_authC.currentStep.value == 0)
                                    _buildEmailStep(isDarkMode, authC),
                                  if (_authC.currentStep.value == 1)
                                    _buildVerificationStep(
                                        isDarkMode, authC),
                                  if (_authC.currentStep.value == 2)
                                    _buildPasswordStep(isDarkMode, authC),
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

              // ================== reCAPTCHA Mini (1×1) ==================
              Obx(() {
                if (!_supportsRecaptchaMini) {
                  // منصّات لا تدعم Mini WebView → نعتمد فقط على g_recaptcha_v3 في AuthController
                  return const SizedBox.shrink();
                }

                final step = authC.currentStep.value;
                if (step == 0) {
                  // إرسال كود الاستعادة
                  return Positioned.fill(child: _recaptchaResetEmail);
                } else if (step == 2) {
                  // تأكيد تعيين كلمة المرور الجديدة
                  return Positioned.fill(child: _recaptchaResetPassword);
                } else {
                  // خطوة الكود ما تحتاج reCAPTCHA
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      );
    });
  }

  // ================== مؤشر الخطوات ==================
  Widget _buildProgressIndicator(bool isDarkMode, AuthController authCrl) {
    Color activeColor = AppColors.primary;
    Color inactiveColor = AppColors.greyLight;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          _buildProgressStep(
            number: 1,
            label: 'البريد الإلكتروني'.tr,
            isActive: authCrl.currentStep.value >= 0,
            isDarkMode: isDarkMode,
          ),
          Expanded(
            child: Divider(
              thickness: 2,
              color:
                  authCrl.currentStep.value >= 1 ? activeColor : inactiveColor,
              height: 2.h,
            ),
          ),
          _buildProgressStep(
            number: 2,
            label: 'رمز التحقق'.tr,
            isActive: authCrl.currentStep.value >= 1,
            isDarkMode: isDarkMode,
          ),
          Expanded(
            child: Divider(
              thickness: 2,
              color:
                  authCrl.currentStep.value >= 2 ? activeColor : inactiveColor,
              height: 2.h,
            ),
          ),
          _buildProgressStep(
            number: 3,
            label: 'كلمة المرور الجديدة'.tr,
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
            color: isActive
                ? AppColors.primary
                : AppColors.textSecondary(isDarkMode),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ================== خطوة البريد ==================
  Widget _buildEmailStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني لتأكيد هويتك'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
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
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 18.h,
              ),
            ),
          ),
        ),
        SizedBox(height: 60.h),
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: authCrl.sendVerificationCodeForReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Obx(
              () => authCrl.isLoading.value
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
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
        ),
      ],
    );
  }

  // ================== خطوة الكود ==================
  Widget _buildVerificationStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              counterText: '',
              labelText: 'رمز التحقق'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
              prefixIcon: Icon(
                Icons.lock_outlined,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 18.h,
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
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
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: authCrl.verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 2,
            ),
            child: Obx(
              () => authCrl.isLoading.value
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
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
        ),
        SizedBox(height: 20.h),
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

  // ================== خطوة كلمة المرور الجديدة ==================
  Widget _buildPasswordStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أنشئ كلمة مرور جديدة'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
        Obx(
          () => Container(
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
                labelText: 'كلمة المرور الجديدة'.tr,
                labelStyle: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    authCrl.showPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
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
                  horizontal: 20.w,
                  vertical: 18.h,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Text(
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
          ),
        ),
        SizedBox(height: 60.h),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: authCrl.isPasswordValid.value
                  ? () async {
                      authCrl.isLoading.value = true;
                      final result = await authCrl.resetGooglePassword(
                        email: authCrl.emailCtrl.text,
                        code: authCrl.codeCtrl.text,
                        password: authCrl.passwordCtrl.text,
                      );
                      authCrl.isLoading.value = false;

                      if (result['status'] == true) {
                        Get.offAll(() => const PasswordResetSuccessScreen());
                      } else {
                        Get.snackbar(
                          'خطأ'.tr,
                          result['message'],
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor:
                              AppColors.error.withOpacity(0.2),
                          colorText: AppColors.error,
                          duration: const Duration(seconds: 3),
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
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 3,
              ),
              child: authCrl.isLoading.value
                  ? SizedBox(
                      width: 28.w,
                      height: 28.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'إعادة تعيين كلمة المرور'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
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

// ================== شاشة نجاح إعادة التعيين ==================
class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey),
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                constraints: BoxConstraints(maxWidth: 600.w),
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 100.w,
                      color: AppColors.success,
                    ),
                    SizedBox(height: 30.h),
                    Text(
                      'تم إعادة تعيين كلمة المرور بنجاح'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 50.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.offAll(() => HomeWebDeskTopScreen()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'تسجيل الدخول'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: () =>
                            Get.offAll(() => HomeWebDeskTopScreen()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'العودة للرئيسية'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.primary,
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
