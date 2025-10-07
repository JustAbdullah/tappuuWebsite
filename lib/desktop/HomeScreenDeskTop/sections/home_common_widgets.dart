import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/images_path.dart';

import '../../../controllers/ThemeController.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/services/appservices.dart';
import '../../AdsSearchDeskTop/AdsScreenDesktop.dart';
import '../../SettingsDeskTop/UserInfoPageDeskTop.dart';

// ================ عناصر شريط التبويب العلوي ================
class LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
        final appServices = Get.find<AppServices>();
  final logoUrl = appServices.getStoredAppLogoUrl();
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r)),
          child:logoUrl != null && logoUrl.isNotEmpty
        ? Image.network(
            logoUrl,
         
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Image.asset(ImagesPath.logo,  ),
          )
        : Image.asset(
            ImagesPath.logo,
           
            fit: BoxFit.contain,
          ),
          
       
        ),
        SizedBox(width: 10.w),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.primary, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'Stay in me',
            style: TextStyle(
              fontSize: AppTextStyles.xxxlarge,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return GestureDetector(
      onTap: () => themeController.toggleTheme(),
      child: Container(
        width: 34.w,
        height: 34.h,
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: AppColors.textPrimary(isDarkMode),
          size: 16.sp,
        ),
      ),
    );
  }
}

class UserIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<ThemeController>().isDarkMode.value;

    return GestureDetector(
      onTap: () => Get.to(() => UserInfoPageDeskTop()),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 42.w,
          height: 42.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: isDark ? Color(0xFF2A2A2A) : Colors.grey[100],
            child: Icon(
              Icons.person_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }
}

// ================ عناصر شريط التبويب الثانوي ================
class NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
    void Function()? onTap;
  
    


  NavItem(this.title, this.icon, this.onTap,{this.isActive = false} );

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return InkWell(
    onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          border: isActive ? Border(
            bottom: BorderSide(
              color: AppColors.primary,
              width: 2.0.w,
            ),
          ) : null,
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
          ),
          onPressed: () {},
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textPrimary(isDarkMode),
                size: 16.sp,
              ),
              SizedBox(width: 5.w),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                 fontSize: AppTextStyles.medium,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedSearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return InkWell(
      onTap: (){
        Get.to(()=> AdsScreenDesktop(categoryId: null,));
      },
      child: Container(
        width: 250.w,
        height: 35.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.grey,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'ابحث عن إعلان...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                     fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAdButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(Icons.add, size: 15.sp),
        label: Text(
          'إنشاء إعلان مجانًا',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
           fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}

// ================ عناصر التذييل ================
class FooterLink extends StatelessWidget {
  final String text;

  FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios_new,
              size: 11.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              text,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  ContactInfo(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialIcon extends StatelessWidget {
  final IconData icon;

  SocialIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return Container(
      width: 30.w,
      height: 30.h,
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16.sp,
        color: AppColors.primary,
      ),
    );
  }
}