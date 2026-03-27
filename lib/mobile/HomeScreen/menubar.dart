import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/LoadingController.dart';

import '../../controllers/ThemeController.dart';
import '../../controllers/home_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/images_path.dart';
import '../../core/localization/changelanguage.dart';
import '../AddAds/AddAdScreen.dart';
import '../ServicesDrawer/ServicesDrawer.dart';
import '../UserSettings/SettingsDrawer.dart';
import '../UserSettings/itemsUserSettings/UserInfoPage.dart';
import 'homeItems/LoginPopup.dart';
import 'homeItems/SubCategories/subCategoriesScreen.dart';
import 'home_screen.dart';

class Menubar extends StatelessWidget {
  const Menubar({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final LoadingController loadingController = Get.find<LoadingController>();
    final List<Color> iconColors = [
      const Color.fromARGB(255, 255, 117, 75),
      const Color.fromARGB(255, 59, 184, 200),
      const Color.fromARGB(255, 133, 190, 68),
      const Color.fromARGB(255, 236, 160, 47),
      const Color(0xFFF48FB1),
      const Color(0xFF90CAF9),
      const Color(0xFFA5D6A7),
      const Color(0xFFCE93D8),
    ];

    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Drawer(
          backgroundColor: AppColors.surface(isDarkMode),
          width: MediaQuery.of(context).size.width * 0.78,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(18.r),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(
                  context: context,
                  isDarkMode: isDarkMode,
                  loadingController: loadingController,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context: context,
                        title: 'الرئيسية'.tr,
                        icon: Icons.home_outlined,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Get.offAll(HomeScreen());
                        },
                      ),
                      SizedBox(height: 8.h),
                      _buildMenuItem(
                        context: context,
                        title: 'الملف الشخصي'.tr,
                        icon: Icons.person_outline,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          if (loadingController.currentUser != null) {
                            Get.to(() => UserInfoPage());
                          } else {
                            Get.dialog(
                              LoginPopup(),
                              barrierDismissible: true,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      _buildMenuItem(
                        context: context,
                        title: 'الاعدادت'.tr,
                        icon: Icons.settings_outlined,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          if (loadingController.currentUser != null) {
                            _openSlideDrawer(context, SettingsDrawer());
                          } else {
                            Get.dialog(
                              LoginPopup(),
                              barrierDismissible: true,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 8.h),
                      _buildMenuItem(
                        context: context,
                        title: 'اضف اعلان'.tr,
                        icon: Icons.add_circle_outline,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          if (Get.find<LoadingController>().currentUser == null) {
                            Get.snackbar(
                              'تنبيه'.tr,
                              'يجب تسجيل الدخول'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          Get.to(() => AddAdScreen());
                        },
                      ),
                      SizedBox(height: 8.h),
                      _buildMenuItem(
                        context: context,
                        title: 'خدماتنا'.tr,
                        icon: Icons.support_agent_outlined,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _openSlideDrawer(context, ServicesDrawer());
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 22.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'التصنيفات الرئيسية'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (controller.isLoadingCategories.value) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return Column(
                    children: controller.categoriesList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                      final translation = category.translations.firstWhere(
                        (t) => t.language == langCode,
                        orElse: () => category.translations.first,
                      );

                      return _buildSmallCategoryItem(
                        id: category.id,
                        image: category.image,
                        name: translation.name,
                        color: iconColors[index % iconColors.length],
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Navigator.pop(context);
                          Get.to(() => SubCategoriesScreen(
                            categoryId: category.id,
                            categoryName: translation.name,
                            countOfAdsInCategory: category.adsCount,
                          ));
                        },
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _openSlideDrawer(BuildContext context, Widget drawer) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: drawer,
        );
      },
    );
  }

  Widget _buildDrawerHeader({
    required BuildContext context,
    required bool isDarkMode,
    required LoadingController loadingController,
  }) {
    final isLoggedIn = loadingController.currentUser != null;
    final email = loadingController.currentUser?.email ?? 'ضيف'.tr;
    final logo = ImagesPath.logo;
    final uri = Uri.tryParse(logo);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primarySecond],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54.w,
                height: 54.w,
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: isNetwork
                      ? Image.network(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            ImagesPath.logo,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          logo,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? 'مرحباً بك'.tr : 'أهلاً بك'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.large,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isLoggedIn
                          ? email
                          : 'سجّل الدخول لاستكشاف كل المزايا'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildHeaderAction(
                  label: isLoggedIn ? 'الملف الشخصي'.tr : 'تسجيل الدخول'.tr,
                  icon: Icons.person_outline,
                  onTap: () {
                    Navigator.pop(context);
                    if (loadingController.currentUser != null) {
                      Get.to(() => UserInfoPage());
                    } else {
                      Get.dialog(
                        LoginPopup(),
                        barrierDismissible: true,
                      );
                    }
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildHeaderAction(
                  label: 'أضف إعلان'.tr,
                  icon: Icons.add_circle_outline,
                  onTap: () {
                    Navigator.pop(context);
                    if (Get.find<LoadingController>().currentUser == null) {
                      Get.snackbar(
                        'تنبيه'.tr,
                        'يجب تسجيل الدخول'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    Get.to(() => AddAdScreen());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.w,
                color: Colors.white,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card(isDarkMode),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 18.w,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.w,
                color: AppColors.grey.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCategoryItem({
    required int id,
    required String image,
    required String name,
    required Color color,
    
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Material(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      width: 24.w,
                      height: 24.h,
                      placeholder: (context, url) => SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.category,
                        size: 18.w,
                        color: color,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.w,
                  color: AppColors.grey.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
