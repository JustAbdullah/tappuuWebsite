import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/images_path.dart';
import 'package:tappuu_website/desktop/HomeScreenDeskTop/home_web_desktop_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/AboutUsController.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/services/appservices.dart';
import '../../ServicesDrawerWeb/servicesItemsDesktop/AboutUsScreenDeskTop.dart';
import '../../ServicesDrawerWeb/servicesItemsDesktop/TermsAndConditionsScreenDesktop.dart';

class Footer extends StatelessWidget {
  final AboutUsController aboutUsController = Get.put(AboutUsController());

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final appServices = Get.find<AppServices>();
    final logoUrl = appServices.getStoredAppLogoUrl();
    
    return Obx(() {
      final aboutUs = aboutUsController.aboutUs.value;
      
      return Container(
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          border: Border(
            top: BorderSide(
              color: AppColors.border(isDarkMode).withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FooterColumn(
                    title: 'عن الشركة'.tr,
                    isDarkMode: isDarkMode,
                    children: [
                      SizedBox(height: 18.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         Container(
  width: 45.w,
  height: 45.h,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
      )
    ],
  ),
  child: logoUrl != null && logoUrl.isNotEmpty
      ? Image.network(
          logoUrl,
          fit: BoxFit.contain,
          // إضافة key فريد بناءً على الرابط
          key: ValueKey(logoUrl),
          // إضافة loadingBuilder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            );
          },
          errorBuilder: (_, __, ___) =>
              Image.asset(ImagesPath.logo, fit: BoxFit.contain),
        )
      : Image.asset(
          ImagesPath.logo,
          fit: BoxFit.contain,
        ),
),
                          SizedBox(width: 14.w),
                          Flexible(
                            child: Text(
                              aboutUs?.description ?? "منصة للاعلانات المبوبة الأولى في سوريا ومتخصصة في إعلانات المركبات بمختلف أنواعها والعقارات".tr,
                              style: TextStyle(
                               fontSize: AppTextStyles.medium,
                                height: 1.6,
                                color: AppColors.textSecondary(isDarkMode),
                                fontFamily: AppTextStyles.appFontFamily,
                                
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22.h),
                      Row(
                        children: [
                          if (aboutUs?.facebook != null && aboutUs!.facebook!.isNotEmpty)
                            SocialIcon(
                              icon: Icons.facebook, 
                              isDarkMode: isDarkMode,
                              onTap: () => _launchURL(aboutUs.facebook!),
                            ),
                          if (aboutUs?.instagram != null && aboutUs!.instagram!.isNotEmpty) ...[
                            SizedBox(width: 12.w),
                            SocialIcon(
                              icon: Icons.camera_alt,
                              isDarkMode: isDarkMode,
                              onTap: () => _launchURL(aboutUs.instagram!),
                            ),
                          ],
                          if (aboutUs?.twitter != null && aboutUs!.twitter!.isNotEmpty) ...[
                            SizedBox(width: 12.w),
                            SocialIcon(
                              icon: Icons.language,
                              isDarkMode: isDarkMode,
                              onTap: () => _launchURL(aboutUs.twitter!),
                            ),
                          ],
                          if (aboutUs?.youtube != null && aboutUs!.youtube!.isNotEmpty) ...[
                            SizedBox(width: 12.w),
                            SocialIcon(
                              icon: Icons.play_circle_fill,
                              isDarkMode: isDarkMode,
                              onTap: () => _launchURL(aboutUs.youtube!),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  FooterColumn(
                    title: 'روابط سريعة'.tr,
                    isDarkMode: isDarkMode,
                    children: [
                      FooterLink(text: 'الرئيسية'.tr, isDarkMode: isDarkMode, onTap: () {
                        Get.offAll(HomeWebDeskTopScreen());
                      }),
                      FooterLink(text: 'خدماتنا'.tr, isDarkMode: isDarkMode, onTap: () {
                        Get.find<HomeController>().toggleDrawerType(false);
                        Scaffold.of(context).openEndDrawer();
                      }),
                      FooterLink(text: 'من نحن'.tr, isDarkMode: isDarkMode, onTap: () {
                        Get.to(() => AboutUsScreenDesktop());
                      }),
                      FooterLink(text: 'الشروط والأحكام'.tr, isDarkMode: isDarkMode, onTap: () {
                        Get.to(() => TermsAndConditionsScreenDesktop());
                      }), FooterLink(text: 'المدونة'.tr, isDarkMode: isDarkMode, onTap: () async {
    final Uri url = Uri.parse("http://testing.arabiagroup.net/blog");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("خطأ", "تعذر فتح الرابط");
    }
  },),
                    ],
                  ),
                  FooterColumn(
                    title: 'اتصل بنا'.tr,
                    isDarkMode: isDarkMode,
                    children: [
                    
                      if (aboutUs?.contactNumber != null && aboutUs!.contactNumber!.isNotEmpty)
                        ContactInfo(
                          icon: Icons.phone, 
                          text: aboutUs.contactNumber!, 
                          isDarkMode: isDarkMode
                        ),
                      if (aboutUs?.contactEmail != null && aboutUs!.contactEmail!.isNotEmpty)
                        ContactInfo(
                          icon: Icons.email, 
                          text: aboutUs.contactEmail!, 
                          isDarkMode: isDarkMode
                        ),
                      ContactInfo(
                        icon: Icons.access_time, 
                        text: '24/7 خدمة العملاء'.tr, 
                        isDarkMode: isDarkMode
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            Divider(
              color: AppColors.border(isDarkMode).withOpacity(0.3),
              thickness: 1.2,
            ),
            SizedBox(height: 20.h),
            Text(
              '© 2025 TaaPuu  . جميع الحقوق محفوظة'.tr,
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                letterSpacing: 0.3,
                color: AppColors.textSecondary(isDarkMode).withOpacity(0.8),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح الرابط'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class FooterColumn extends StatelessWidget {
  final String title;
  final bool isDarkMode;
  final List<Widget> children;

  FooterColumn({
    required this.title,
    required this.isDarkMode,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
              
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }
}

class FooterLink extends StatefulWidget {
  final String text;
  final bool isDarkMode;
  final void Function()? onTap;

  FooterLink({required this.text, required this.isDarkMode, required this.onTap});

  @override
  _FooterLinkState createState() => _FooterLinkState();
}

class _FooterLinkState extends State<FooterLink> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          child: Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.translationValues(_isHovering ? -3 : 0, 0, 0),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 12.sp,
                  color: _isHovering 
                    ? AppColors.primary 
                    : AppColors.textSecondary(widget.isDarkMode),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                widget.text,
                style: TextStyle(
                 fontSize: AppTextStyles.medium,
                  color: _isHovering 
                    ? AppColors.primary 
                    : AppColors.textPrimary(widget.isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;

  ContactInfo({
    required this.icon,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 10.w),
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

class SocialIcon extends StatefulWidget {
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onTap;

  SocialIcon({required this.icon, required this.isDarkMode, required this.onTap});

  @override
  _SocialIconState createState() => _SocialIconState();
}

class _SocialIconState extends State<SocialIcon> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 34.w,
          height: 34.h,
          decoration: BoxDecoration(
            color: _isHovering 
              ? AppColors.primary 
              : AppColors.card(widget.isDarkMode).withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.1 : 0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 16.sp,
              color: _isHovering 
                ? Colors.white 
                : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}