import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/images_path.dart';
import '../core/constant/appcolors.dart';
import '../core/localization/changelanguage.dart';
import '../core/services/appservices.dart';
import 'HomeScreenDeskTop/sections/home_common_widgets.dart';

class TopAppBarDeskTop extends StatefulWidget {
  @override
  _TopAppBarDeskTopState createState() => _TopAppBarDeskTopState();
}

class _TopAppBarDeskTopState extends State<TopAppBarDeskTop> with SingleTickerProviderStateMixin {
  final ThemeController themeC = Get.find<ThemeController>();
  final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
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
 final appServices = Get.find<AppServices>();
  final logoUrl = appServices.getStoredAppLogoUrl();
  return Container(
    height:85.h,
    padding: EdgeInsets.symmetric(horizontal: 30.w),
    decoration: BoxDecoration(
      color: isDarkMode ? Color(0xFF1E1E1E) : AppColors.onPrimary,
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
    // ✅ الشعار
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      // إضافة key فريد بناءً على الرابط لإجبار إعادة التحميل
                      key: ValueKey(logoUrl),
                      // إضافة options لتجنب cache
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
  


        // ✅ الأدوات
        Row(
          children: [
            // 🌓 تغيير الثيم
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
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(turns: animation, child: child);
                      },
                      child: isDarkMode
                          ? Icon(Icons.light_mode, key: ValueKey('light'), color: Colors.yellow[600])
                          : Icon(Icons.dark_mode, key: ValueKey('dark'), color: Colors.indigo),
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

          
            SizedBox(width: 16.w),

            // 🙍‍♂️ المستخدم
            UserIcon(),
          ],
        )
      ],
    ),
  );
}
}