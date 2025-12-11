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
import '../../../customWidgets/EditableTextWidget.dart';
import '../../ServicesDrawerWeb/servicesItemsDesktop/AboutUsScreenDeskTop.dart';
import '../../ServicesDrawerWeb/servicesItemsDesktop/TermsAndConditionsScreenDesktop.dart';

class Footer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  final AboutUsController aboutUsController = Get.put(AboutUsController());

  Footer({
    Key? key,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final appServices = Get.find<AppServices>();
    final logoUrl = appServices.getStoredAppLogoUrl();

    return Obx(() {
      final aboutUs = aboutUsController.aboutUs.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          border: Border(
            top: BorderSide(
              color: AppColors.border(isDarkMode).withOpacity(0.25),
              width: 1.0,
            ),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------- الصف الرئيسي -------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عن الشركة
                    Expanded(
                      flex: 4,
                      child: FooterColumn(
                        title: 'عن المنصة'.tr,
                        isDarkMode: isDarkMode,
                        children: [
                          SizedBox(height: 10.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46.w,
                                height: 46.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.r),
                                  color: AppColors.card(isDarkMode),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: logoUrl != null &&
                                          logoUrl.isNotEmpty
                                      ? Image.network(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          key: ValueKey(logoUrl),
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: SizedBox(
                                                width: 16.w,
                                                height: 16.w,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.6,
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  Image.asset(
                                            ImagesPath.logo,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Image.asset(
                                          ImagesPath.logo,
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    
                                  EditableTextWidget(
                keyName: 'mainTitleWeb',
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w800,
              
              ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      aboutUs?.description ??
                                          "منصة للإعلانات المبوبة في سوريا، مع تركيز خاص على إعلانات المركبات والعقارات."
                                              .tr,
                                      style: TextStyle(
                                        fontFamily:
                                            AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.small,
                                        height: 1.5,
                                        color: AppColors.textSecondary(
                                            isDarkMode),
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 18.h),
                          Row(
                            children: [
                              if (aboutUs?.facebook != null &&
                                  aboutUs!.facebook!.isNotEmpty)
                                SocialIcon(
                                  icon: Icons.facebook,
                                  isDarkMode: isDarkMode,
                                  onTap: () =>
                                      _launchURL(aboutUs.facebook!),
                                ),
                              if (aboutUs?.instagram != null &&
                                  aboutUs!.instagram!.isNotEmpty) ...[
                                SizedBox(width: 10.w),
                                SocialIcon(
                                  icon: Icons.camera_alt,
                                  isDarkMode: isDarkMode,
                                  onTap: () =>
                                      _launchURL(aboutUs.instagram!),
                                ),
                              ],
                              if (aboutUs?.twitter != null &&
                                  aboutUs!.twitter!.isNotEmpty) ...[
                                SizedBox(width: 10.w),
                                SocialIcon(
                                  icon: Icons.language,
                                  isDarkMode: isDarkMode,
                                  onTap: () =>
                                      _launchURL(aboutUs.twitter!),
                                ),
                              ],
                              if (aboutUs?.youtube != null &&
                                  aboutUs!.youtube!.isNotEmpty) ...[
                                SizedBox(width: 10.w),
                                SocialIcon(
                                  icon: Icons.play_circle_fill,
                                  isDarkMode: isDarkMode,
                                  onTap: () =>
                                      _launchURL(aboutUs.youtube!),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 26.w),

                    // روابط سريعة
                    Expanded(
                      flex: 3,
                      child: FooterColumn(
                        title: 'روابط سريعة'.tr,
                        isDarkMode: isDarkMode,
                        children: [
                          SizedBox(height: 6.h),
                          FooterLink(
                            text: 'الرئيسية'.tr,
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Get.offAll(HomeWebDeskTopScreen());
                            },
                          ),
                          FooterLink(
                            text: 'خدماتنا'.tr,
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Get.find<HomeController>()
                                  .openServicesDrawer(scaffoldKey);
                            },
                          ),
                          FooterLink(
                            text: 'من نحن'.tr,
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Get.to(() => AboutUsScreenDesktop());
                            },
                          ),
                          FooterLink(
                            text: 'الشروط والأحكام'.tr,
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Get.to(() =>
                                  TermsAndConditionsScreenDesktop());
                            },
                          ),
                          FooterLink(
                            text: 'المدونة'.tr,
                            isDarkMode: isDarkMode,
                            onTap: () async {
                              final Uri url = Uri.parse(
                                  "http://testing.arabiagroup.net/blog");
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                Get.snackbar(
                                  "خطأ".tr,
                                  "تعذر فتح الرابط".tr,
                                  snackPosition:
                                      SnackPosition.BOTTOM,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 26.w),

                    // اتصل بنا
                    Expanded(
                      flex: 3,
                      child: FooterColumn(
                        title: 'اتصل بنا'.tr,
                        isDarkMode: isDarkMode,
                        children: [
                          SizedBox(height: 6.h),
                          if (aboutUs?.contactNumber != null &&
                              aboutUs!.contactNumber!.isNotEmpty)
                            ContactInfo(
                              icon: Icons.phone,
                              text: aboutUs.contactNumber!,
                              isDarkMode: isDarkMode,
                            ),
                          if (aboutUs?.contactEmail != null &&
                              aboutUs!.contactEmail!.isNotEmpty)
                            ContactInfo(
                              icon: Icons.email,
                              text: aboutUs.contactEmail!,
                              isDarkMode: isDarkMode,
                            ),
                          ContactInfo(
                            icon: Icons.access_time,
                            text: 'خدمة عملاء متاحة 24/7'.tr,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 22.h),
                Divider(
                  color: AppColors.border(isDarkMode).withOpacity(0.35),
                  thickness: 1,
                ),
                SizedBox(height: 10.h),

                // ------------------- الشريط السفلي -------------------
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        'جميع الحقوق محفوظة لـدى'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: AppColors
                              .textPrimary(isDarkMode)
                              .withOpacity(0.95),
                        ),
                      ),   EditableTextWidget(
                keyName: 'mainTitleWeb',
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w800,
              
              ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'خطأ'.tr,
        'لا يمكن فتح الرابط'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
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
          ),
          SizedBox(height: 4.h),
          Container(
            width: 32.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: AppColors.buttonAndLinksColor.withOpacity(
                isDarkMode ? 0.9 : 0.8,
              ),
              borderRadius: BorderRadius.circular(999.r),
            ),
          ),
          SizedBox(height: 14.h),
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

  FooterLink({
    required this.text,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  _FooterLinkState createState() => _FooterLinkState();
}

class _FooterLinkState extends State<FooterLink> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        AppColors.textPrimary(widget.isDarkMode);
    final hoverColor = AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                transform: Matrix4.translationValues(
                    _isHovering ? -3 : 0, 0, 0),
                child: Icon(
                  Icons.chevron_left,
                  size: 16.sp,
                  color: _isHovering ? hoverColor : baseColor.withOpacity(0.6),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: _isHovering ? hoverColor : baseColor,
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
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: AppColors.buttonAndLinksColor.withOpacity(
                isDarkMode ? 0.25 : 0.12,
              ),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              size: 13.sp,
              color: AppColors.primary,
            ),
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

  SocialIcon({
    required this.icon,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  _SocialIconState createState() => _SocialIconState();
}

class _SocialIconState extends State<SocialIcon> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseBg =
        AppColors.card(widget.isDarkMode).withOpacity(0.95);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovering
                ? AppColors.primary
                : baseBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    _isHovering ? 0.15 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 16.sp,
            color: _isHovering ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
