import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_website/desktop/HomeScreenDeskTop/home_web_desktop_screen.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/AuthController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../controllers/home_controller.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';
import 'ResetPasswordDesktopScreen.dart';
import 'SignupDesktopScreen.dart';

class LoginDesktopScreen extends StatefulWidget {
  const LoginDesktopScreen({super.key});

  @override
  State<LoginDesktopScreen> createState() => _LoginDesktopScreenState();
}

class _LoginDesktopScreenState extends State<LoginDesktopScreen> { 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authC = Get.put(AuthController());

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final size = MediaQuery.of(context).size;
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
          SizedBox(height: 60.h,),
         Center(
              child: Container(
                width: size.width * 0.35,
               
                decoration: BoxDecoration(
                  color: AppColors.background(isDarkMode),
                 
                ),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 0.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الشعار مع تأثير ظل
                
                 
          
                
                    SizedBox(height: 24.h),
          
                    // تحذير مهم مع خلفية صفراء خفيفة
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // أيقونة تحذير مع النص
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 24.w,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تسجيل الدخول'.tr,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.medium,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: AppTextStyles.appFontFamily,
                                        letterSpacing: 0.5,
                                        height: 1.3,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'قم بإدخال البريد الالكتروني المُسجل به وكلمة المرور لتسجيل الدخول للدخول او المزامنة فورًا من خلال جوجل وفي حال ليس لديك حساب قم بإنشاء واحد الان مجانًا'
                                          .tr,
                                      style: TextStyle(
                                       fontSize: AppTextStyles.medium,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: AppColors.textSecondary(
                                            isDarkMode),
                                      ),
                                    ),

                                  
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
          
                    // حقل البريد الإلكتروني
                    _buildInputField(
                      label: 'البريد الإلكتروني'.tr,
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      isPassword: false,
                    ),
                    SizedBox(height: 4.h),
          
                    // حقل كلمة المرور
                    _buildInputField(
                      label: 'كلمة المرور'.tr,
                      icon: Icons.lock_outlined,
                      controller: _passwordController,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    SizedBox(height: 10.h),
          
                    // نسيت كلمة المرور
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                              Get.to(() => ResetPasswordDesktopScreen());
                        },
                        child: Text(
                          'نسيت كلمة المرور؟'.tr,
                          style: TextStyle(
                           fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
          
                    // زر تسجيل الدخول
                    _buildLoginButton(isDarkMode),
                    SizedBox(height: 10.h),
          
                    // تسجيل الدخول عبر جوجل
                 /*   _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'تسجيل الدخول باستخدام Google'.tr,
                      onPressed: () {
                  _authC.signInWithGoogle();
                      },
                      isDarkMode: isDarkMode,
                    ),*/
                    SizedBox(height: 30.h),
          
                    // رابط إنشاء حساب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        TextButton(
                          onPressed: () {
                           Get.off(() => SignupDesktopScreen());
                          },
                          child: Text(
                            'إنشاء حساب جديد'.tr,
                            style: TextStyle(
                               fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTextStyles.medium,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
         
     ] ),
    );
  });}

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: AppColors.grey100.withOpacity(0.5),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        style: TextStyle(
          fontSize: AppTextStyles.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary(isDarkMode),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(isDarkMode),
          ),
          prefixIcon: Icon(
            icon,
            size: 24.w,
            color: AppColors.primary,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    size: 24.w,
                    color: AppColors.primary,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 18.h,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            AppColors.buttonAndLinksColor,
            AppColors.buttonAndLinksColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.onPrimary,
          shadowColor: Colors.transparent,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? SizedBox(
                width: 28.w,
                height: 28.h,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(
                'تسجيل الدخول'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
      
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.w,
              color: AppColors.primary,
            ),
            SizedBox(width: 15.w),
            Text(
              text,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w600,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'الحقول مطلوبة'.tr,
        'يرجى ملء جميع الحقول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.onPrimary,
      );
      return;
    }

    setState(() => _isLoading = true);

    // إعداد بيانات AuthController
    _authC.emailCtrl.text = _emailController.text.trim();
    _authC.passwordCtrl.text = _passwordController.text.trim();

    // استدعاء دالة تسجيل الدخول
    final result = await _authC.loginApi();

    setState(() => _isLoading = false);

    if (result['status'] == true) {
      Get.back();
      Get.snackbar(
        'نجاح'.tr,
        result['message'] ?? 'تم تسجيل الدخول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
      // الانتقال للصفحة الرئيسية
      Get.offAll(()=>HomeWebDeskTopScreen());
    } else {
      Get.snackbar(
        'فشل'.tr,
        result['message'] ?? 'خطأ في تسجيل الدخول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.onPrimary,
      );
    }
  }
}