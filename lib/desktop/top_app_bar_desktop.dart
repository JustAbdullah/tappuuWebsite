import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/editable_text_controller.dart' show EditableTextController;
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/localization/changelanguage.dart';
import 'package:tappuu_website/core/services/appservices.dart';

import 'package:tappuu_website/controllers/LoadingController.dart';
import 'package:tappuu_website/core/data/model/user.dart';

import '../core/constant/images_path.dart';
import '../customWidgets/EditableTextWidget.dart';
import 'AuthScreenDeskTop/LoginDesktopScreen.dart';
import 'SettingsDeskTop/UserInfoPageDeskTop.dart';

class TopAppBarDeskTop extends StatefulWidget {
  @override
  _TopAppBarDeskTopState createState() => _TopAppBarDeskTopState();
}

class _TopAppBarDeskTopState extends State<TopAppBarDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final ChangeLanguageController languageController =
      Get.find<ChangeLanguageController>();

  // مراجع الخدمات والحالة
  final LoadingController _loadingC = Get.find<LoadingController>();
  final AppServices _appServices = Get.find<AppServices>();

  // 🔴 كنترولر النصوص المتغيّرة
  late final EditableTextController _editableCtrl;
  bool _requestedEditableOnce = false;

  @override
  void initState() {
    super.initState();

    // نحصل على الكنترولر أو ننشئه لو مش مسجل
    if (Get.isRegistered<EditableTextController>()) {
      _editableCtrl = Get.find<EditableTextController>();
    } else {
      _editableCtrl = Get.put(EditableTextController(), permanent: true);
    }

    // لو ما في ولا نص متغيّر، نطلبهم مرة واحدة في الخلفية
    if (_editableCtrl.items.isEmpty) {
      _requestedEditableOnce = true;
      _editableCtrl.fetchAll().then((_) {
        debugPrint(
          'TopAppBarDeskTop: editable texts loaded in initState '
          '(count=${_editableCtrl.items.length})',
        );
      }).catchError((e) {
        debugPrint('TopAppBarDeskTop: fetchAll error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⬅⬅ أهم تعديل: نلف كل الـ UI داخل Obx
    return Obx(() {
      final isDarkMode = themeC.isDarkMode.value;
      final logoUrl = _appServices.getStoredAppLogoUrl();

      // أمان إضافي: لو لسبب ما وصلنا هنا ولسا مافيه بيانات ولم نطلبها، نطلبها
      if (!_requestedEditableOnce && _editableCtrl.items.isEmpty) {
        _requestedEditableOnce = true;
        _editableCtrl.fetchAll().then((_) {
          debugPrint(
            'TopAppBarDeskTop(build): editable texts loaded '
            '(count=${_editableCtrl.items.length})',
          );
        }).catchError((e) {
          debugPrint('TopAppBarDeskTop(build): fetchAll error: $e');
        });
      }

      return Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0a0a0a) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? const Color(0xFF1a1a1a) : const Color(0xFFf0f0f0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ـــ الشعار + اسم الموقع ـــ
           
            Row(
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

                              SizedBox(width: 10.w,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   
                    EditableTextWidget(
                      keyName: isDarkMode ? 'mainTitle' : 'mainTitleWeb',
                      textAlign: TextAlign.start,
                      fontWeight: FontWeight.w800,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'منصة الإعلانات الرائدة v1.17'.tr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontFamily: AppTextStyles.appFontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ـــ أدوات يمين الشريط ـــ
            Row(
              children: [
                // تبديل الثيم - تصميم بسيط
                _SimpleThemeToggle(
                  isDarkMode: isDarkMode,
                  onTap: () {
                    themeC.toggleTheme();
                    HapticFeedback.lightImpact();
                  },
                ),
                SizedBox(width: 16.w),

                // منطقة الدخول/البريد
                Obx(() {
                  final User? u =
                      _loadingC.currentUserToFix.value ?? _loadingC.currentUser;
                  if (u == null) {
                    // غير مسجل دخول -> زر تسجيل الدخول
                    return _SimpleLoginButton(
                      onTap: () {
                        Get.to(
                          () => const LoginDesktopScreen(),
                          preventDuplicates: false,
                        );
                      },
                    );
                  } else {
                    // مسجل دخول -> شارة بريد
                    final email = (u.email ?? '').trim();
                    return _SimpleUserBadge(
                      email: email.isEmpty ? 'المستخدم' : email,
                      onProfile: () {
                        Get.to(() => UserInfoPageDeskTop());
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
    });
  }
}

// ======= عناصر مساعدة بتصميم بسيط وأنيق =======

class _SimpleThemeToggle extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SimpleThemeToggle({
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_SimpleThemeToggle> createState() => _SimpleThemeToggleState();
}

class _SimpleThemeToggleState extends State<_SimpleThemeToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withOpacity(0.05)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 20.w,
              color: widget.isDarkMode
                  ? Colors.amber
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleLoginButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SimpleLoginButton({required this.onTap});

  @override
  State<_SimpleLoginButton> createState() => _SimpleLoginButtonState();
}

class _SimpleLoginButtonState extends State<_SimpleLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withOpacity(0.9)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.login_rounded,
                size: 14.w,
                color: Colors.white,
              ),
              SizedBox(width: 6.w),
              Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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

class _SimpleUserBadge extends StatefulWidget {
  final String email;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final bool isDark;

  const _SimpleUserBadge({
    required this.email,
    required this.onProfile,
    required this.onLogout,
    required this.isDark,
  });

  @override
  State<_SimpleUserBadge> createState() => _SimpleUserBadgeState();
}

class _SimpleUserBadgeState extends State<_SimpleUserBadge> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _isHovered = false;

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return 'U';
    final part = email.split('@').first;
    if (part.isEmpty) return 'U';
    return part.characters.first.toUpperCase();
  }

  void _openMenu() {
    final RenderBox box =
        _anchorKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(
          box.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
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
            leading: Icon(Icons.person_outline, size: 18.w),
            title: Text(
              'الملف الشخصي',
              style: TextStyle(
                fontSize: 12.sp,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.logout, size: 18.w, color: Colors.red),
            title: Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ),
      ],
      elevation: 4,
      color: widget.isDark ? const Color(0xFF1a1a1a) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    ).then((value) {
      if (value == 0) widget.onProfile();
      if (value == 1) widget.onLogout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromEmail(widget.email);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: _anchorKey,
        onTap: _openMenu,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              // Avatar بسيط
              Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // البريد الإلكتروني
              Text(
                widget.email,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.sp,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: 4.w),

              // أيقونة السهم
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16.w,
                color: widget.isDark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
