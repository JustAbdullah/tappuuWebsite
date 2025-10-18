import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/images_path.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/localization/changelanguage.dart';
import 'package:tappuu_website/core/services/appservices.dart';

import 'package:tappuu_website/controllers/LoadingController.dart';
import 'package:tappuu_website/core/data/model/user.dart';

import 'AuthScreenDeskTop/LoginDesktopScreen.dart';
import 'SettingsDeskTop/UserInfoPageDeskTop.dart';

class TopAppBarDeskTop extends StatefulWidget {
  @override
  _TopAppBarDeskTopState createState() => _TopAppBarDeskTopState();
}

class _TopAppBarDeskTopState extends State<TopAppBarDeskTop> with SingleTickerProviderStateMixin {
  final ThemeController themeC = Get.find<ThemeController>();
  final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // مراجع الخدمات والحالة
  final LoadingController _loadingC = Get.find<LoadingController>();
  final AppServices _appServices = Get.find<AppServices>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onThemeToggleHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final logoUrl = _appServices.getStoredAppLogoUrl();

    return Container(
      height: 85.h,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.onPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ـــ الشعار والاسم ـــ
          MouseRegion(
            onEnter: (_) => _animationController.forward(),
            onExit: (_) => _animationController.reverse(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Row(
                children: [
                  Container(
                    width: 65.w,
                    height: 65.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            key: ValueKey(logoUrl),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Image.asset(ImagesPath.logo, fit: BoxFit.contain),
                          )
                        : Image.asset(ImagesPath.logo, fit: BoxFit.contain),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'TaaPuu',
                    style: TextStyle(
                      fontSize: AppTextStyles.xxlarge,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ـــ أدوات يمين الشريط + منطقة الدخول/البريد ـــ
          Row(
            children: [
              // تبديل الثيم
              MouseRegion(
                onEnter: (_) => _onThemeToggleHover(true),
                onExit: (_) => _onThemeToggleHover(false),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 42.w,
                    height: 42.h,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: child),
                        child: isDarkMode
                            ? Icon(Icons.light_mode, key: const ValueKey('light'), color: Colors.yellow[600])
                            : Icon(Icons.dark_mode, key: const ValueKey('dark'), color: Colors.indigo),
                      ),
                      onPressed: () {
                        themeC.toggleTheme();
                        HapticFeedback.mediumImpact();
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // (مكان فارغ مستقبلي للأدوات الأخرى إن وجدت)
              // SizedBox(width: 16.w),

              // منطقة الدخول/البريد — تفاعلية ومُحدثة آليًا عبر Obx
              Obx(() {
                final User? u = _loadingC.currentUserToFix.value ?? _loadingC.currentUser;
                if (u == null) {
                  // غير مسجل دخول -> زر تسجيل الدخول
                  return _LoginButton(onTap: () {
                    Get.to(() => const LoginDesktopScreen(), preventDuplicates: false);
                  });
                } else {
                  // مسجل دخول -> شارة بريد + قائمة منبثقة
                  final email = (u.email ?? '').trim();
                  return _UserBadgeWithMenu(
                    email: email.isEmpty ? 'المستخدم' : email,
                    onProfile: () {
                      // TODO: انتقل لصفحة الملف الشخصي إن وُجدت
                      Get.snackbar('قريبًا', 'صفحة الملف الشخصي', snackPosition: SnackPosition.BOTTOM);
                    },
                    onLogout: () async {
                      await _loadingC.logout();
                    },
                    isDark: isDarkMode,
                  );
                }
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ======= عناصر مساعدة خاصة بالشريط =======

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: EdgeInsetsDirectional.only(start: 8.w),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.login, size: 18),
          label: Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonAndLinksColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class _UserBadgeWithMenu extends StatefulWidget {
  final String email;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final bool isDark;

  const _UserBadgeWithMenu({
    required this.email,
    required this.onProfile,
    required this.onLogout,
    required this.isDark,
  });

  @override
  State<_UserBadgeWithMenu> createState() => _UserBadgeWithMenuState();
}

class _UserBadgeWithMenuState extends State<_UserBadgeWithMenu> {
  final GlobalKey _anchorKey = GlobalKey();

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return 'U';
    final part = email.split('@').first;
    if (part.isEmpty) return 'U';
    final chunks = part.split(RegExp(r'[.\-_]')).where((e) => e.isNotEmpty).toList();
    if (chunks.isEmpty) return part.characters.first.toUpperCase();
    final first = chunks.first.characters.first.toUpperCase();
    final last = chunks.length > 1 ? chunks.last.characters.first.toUpperCase() : '';
    return (first + last).trim();
  }

  void _openMenu() {
    final RenderBox box = _anchorKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<int>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 0,
          child: ListTile(
            leading: const Icon(Icons.person),
            title: const Text('الملف الشخصي'),
            onTap: () => Get.to(() => UserInfoPageDeskTop()),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context, 1),
          ),
        ),
      ],
      elevation: 8,
      color: AppColors.card(widget.isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).then((value) async {
      if (value == 0) widget.onProfile();
      if (value == 1) widget.onLogout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromEmail(widget.email);

    return InkWell(
      key: _anchorKey,
      onTap: _openMenu,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 220.w),
              child: Text(
                widget.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTextStyles.small,
                  color: AppColors.textPrimary(widget.isDark),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary(widget.isDark)),
          ],
        ),
      ),
    );
  }
}
