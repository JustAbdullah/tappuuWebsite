import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/AdvertiserController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AdvertiserProfile.dart';
import '../../AdvertiserManageDeskTop/AdvertiserDataScreenDesktop.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'EditAdvertiserScreenDeskTop.dart';

// سلوك التمرير بدون شريط تمرير
class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics();
  }
}

class AdvertiserProfilesScreenDeskTop extends StatefulWidget {
  const AdvertiserProfilesScreenDeskTop({Key? key}) : super(key: key);

  @override
  State<AdvertiserProfilesScreenDeskTop> createState() => _AdvertiserProfilesScreenDeskTopState();
}

class _AdvertiserProfilesScreenDeskTopState extends State<AdvertiserProfilesScreenDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final AdvertiserController advC = Get.put(AdvertiserController(), permanent: true);
  final LoadingController loadingC = Get.find<LoadingController>();

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  void _fetchProfiles() {
    final userId = loadingC.currentUser?.id ?? 0;
    if (userId > 0) {
      advC.fetchProfiles(userId).then((_) {
        advC.resetSelection();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final HomeController _homeController = Get.find<HomeController>();

    return Scaffold(     
      endDrawer: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _homeController.isServicesOrSettings.value
            ? SettingsDrawerDeskTop(key: const ValueKey(1))
            : DesktopServicesDrawer(key: const ValueKey(2)),
      ),
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
          Expanded(
            child: ScrollConfiguration(
              behavior: NoScrollbarScrollBehavior(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    GetBuilder<AdvertiserController>(
                      builder: (controller) {
                        if (controller.isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                    
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 800.w),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'ملفات المعلنين الخاصة بك'.tr,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.xlarge,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                    
                                  Center(
                                    child: Text(
                                      'اختر ملفًا لعرض تفاصيله أو قم بإنشاء ملف جديد'.tr,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.medium,
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: AppColors.textSecondary(isDarkMode),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: 32.h),
                    
                                  // القائمة المنسدلة
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(isDarkMode),
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                    child: _buildDropdown(controller, isDarkMode),
                                  ),
                                  SizedBox(height: 32.h),
                    
                                  if (controller.selected.value != null)
                                    _buildProfileCard(
                                      controller.selected.value!,
                                      isDarkMode,
                                    ),
                                  
                                  SizedBox(height: 32.h),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        controller.resetSelection();
                                        Get.to(() => AdvertiserDataScreenDeskTop());
                                      },
                                      icon: Icon(Icons.add, size: 20.w),
                                      label: Text(
                                        'إنشاء ملف جديد'.tr,
                                        style: TextStyle(
                                          color: AppColors.onPrimary,
                                          fontSize: AppTextStyles.medium,
                                          fontFamily: AppTextStyles.appFontFamily,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.onPrimary,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32.w, vertical: 14.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildDropdown(AdvertiserController controller, bool isDarkMode) {
    if (controller.profiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: Text(
            'لا توجد ملفات متاحة'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ),
      );
    }

    return DropdownButton<AdvertiserProfile>(
      isExpanded: true,
      value: controller.selected.value,
      underline: SizedBox(),
      dropdownColor: AppColors.surface(isDarkMode),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary(isDarkMode), size: 28.w),
      hint: Text(
        'اختر ملف المعلن'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.medium,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      items: controller.profiles.map((profile) {
        return DropdownMenuItem<AdvertiserProfile>(
          value: profile,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              profile.description ?? '${'ملف بدون وصف (ID:'.tr} ${profile.id})',
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDarkMode),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      onChanged: (AdvertiserProfile? newValue) {
        controller.selected.value = newValue;
        controller.update();
      },
    );
  }

  Widget _buildProfileCard(AdvertiserProfile profile, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile.logo != null && profile.logo!.isNotEmpty)
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    image: DecorationImage(
                      image: NetworkImage(profile.logo!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'ملف المعلن #'.tr}${profile.id}',
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    if (profile.name != null && profile.name!.isNotEmpty)
                      Text(
                        profile.name!,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (profile.description != null && profile.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Text(
                          profile.description!,
                          style: TextStyle(
                            fontSize: AppTextStyles.small,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          Divider(
            color: AppColors.divider(isDarkMode),
            thickness: 1,
            height: 1,
          ),
          SizedBox(height: 20.h),

          Text(
            'معلومات الاتصال'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          
          _buildInfoRow(
            icon: Icons.phone,
            label: 'رقم الاتصال'.tr,
            value: profile.contactPhone ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
          
          _buildInfoRow(
            icon: Icons.chat,
            label: 'واتساب'.tr,
            value: profile.whatsappPhone ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
           
          _buildInfoRow(
            icon: Icons.phone_android,
            label: 'رقم الاتصال واتساب'.tr,
            value: profile.whatsappCallNumber ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 24.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر التعديل
              ElevatedButton.icon(
                onPressed: () {
                  advC.loadProfileForEdit(profile);
                  Get.to(() => EditAdvertiserScreen());
                },
                icon: Icon(Icons.edit, size: 18.w),
                label: Text('تعديل'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // زر الحذف
              ElevatedButton.icon(
                onPressed: () {
                  if (profile.id != null) {
                    Get.defaultDialog(
                      title: "تأكيد الحذف".tr,
                      titleStyle: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold),
                      middleText: "هل أنت متأكد أنك تريد حذف هذا الملف؟".tr,
                      middleTextStyle: TextStyle(fontSize: 14.sp),
                      textConfirm: "نعم".tr,
                      textCancel: "إلغاء".tr,
                      confirmTextColor: Colors.white,
                      buttonColor: Colors.red[700],
                      onConfirm: () {
                        // advC.deleteProfile(profile.id!, profile.userId);
                        Get.back();
                      },
                    );
                  }
                },
                icon: Icon(Icons.delete, size: 18.w),
                label: Text('حذف'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
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
        ],
      ),
    );
  }
}