import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/desktop/AdvertiserAdsScreenDesktop/AdvertiserAdsScreenDesktop.dart';

import '../../../controllers/FavoriteSellerController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/FavoriteSeller.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class FavoriteSellersUnifiedPageDesktop extends StatefulWidget {
  const FavoriteSellersUnifiedPageDesktop({Key? key}) : super(key: key);

  @override
  State<FavoriteSellersUnifiedPageDesktop> createState() => _FavoriteSellersUnifiedPageDesktopState();
}

class _FavoriteSellersUnifiedPageDesktopState extends State<FavoriteSellersUnifiedPageDesktop> {
  final FavoriteSellerController favCtrl = Get.put(FavoriteSellerController());
  final ThemeController themeController = Get.find<ThemeController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFetch());
  }

  void _initFetch() {
    if (_initialized) return;
    final user = loadingController.currentUser;
    if (user != null) {
      _initialized = true;
      favCtrl.fetchFavorites(userId: user?.id??0);
    }
  }

  String _relativeFrom(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return '${'قبل'.tr} ${diff.inHours} ${'ساعة'.tr}';
    if (diff.inMinutes > 0) return '${'قبل'.tr} ${diff.inMinutes} ${'دقيقة'.tr}';
    return 'الآن'.tr;
  }

  Future<void> _refresh() async {
    final user = loadingController.currentUser;
    if (user != null) {
      await favCtrl.fetchFavorites(userId: user?.id??0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
           final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
      key: _scaffoldKey,
    endDrawer: Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _homeController.drawerType.value == DrawerType.settings
            ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
            : const DesktopServicesDrawer(key: ValueKey('services')),
      ),
    ),
        backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [           
           TopAppBarDeskTop(),
              SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey,),
             SizedBox(height: 20.h,), Expanded(
               child: Container(
                       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                       child: Obx(() {
                         if (favCtrl.isLoadingFavorites.value && !_initialized) {
                           return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
                           );
                         }
               
                         if (favCtrl.favoriteList.isEmpty) {
                           return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 120.h),
                    Center(
                      child: Text(
                        'لا توجد بائعين مفضّلين'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                           );
                         }
               
                         return RefreshIndicator(
                           onRefresh: _refresh,
                           child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: favCtrl.favoriteList.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.grey.withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final FavoriteSeller s = favCtrl.favoriteList[index];
                  final subtitle = '${'متابع منذ'.tr} ${_relativeFrom(s.followedAt)}';
                  return _buildSellerTile(s, subtitle, isDark);
                },
                           ),
                         );
                       }),
                     ),
             ),
   ]) );
  }

  Widget _buildSellerTile(FavoriteSeller seller, String subtitle, bool isDark) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          leading: seller.advertiser.logo != null && seller.advertiser.logo!.isNotEmpty
              ? CircleAvatar(
                  radius: 22.r,
                  backgroundImage: NetworkImage(seller.advertiser.logo!),
                )
              : CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.grey,
                  child: Icon(Icons.store, color: Colors.white, size: 18.w),
                ),
          title: Text(
            seller.advertiser.name.toString(),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
             fontSize: AppTextStyles.medium,
              color: Colors.green.shade700,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDark), size: 22.w),
            onPressed: () => _showOptionsForSeller(seller, isDark),
          ),
          onTap: () => _openSellerAds(seller),
        ),
      ],
    );
  }

  void _showOptionsForSeller(FavoriteSeller seller, bool isDark) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.card(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Container(
            width: 300.w,
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.store, color: AppColors.primary, size: 24.w),
                  title: Text(
                    'عرض إعلانات البائع'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _openSellerAds(seller);
                  },
                ),
                Divider(height: 1, color: AppColors.divider(isDark)),
                ListTile(
                  leading: Icon(Icons.favorite_border, color: AppColors.primary, size: 24.w),
                  title: Text(
                    'إلغاء المتابعة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  onTap: () async {
                    Get.back();
                    final userId = loadingController.currentUser?.id ?? 0;
                    final success = await favCtrl.toggleFavoriteByIds(
                      userId: userId,
                      advertiserProfileId: seller.advertiserProfileId,
                    );
                    if (success) {
                      Get.snackbar('نجاح'.tr, 'تم إلغاء المتابعة'.tr,
                        backgroundColor: Colors.green.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else {
                      Get.snackbar('فشل'.tr, 'حدث خطأ، حاول لاحقاً'.tr,
                        backgroundColor: Colors.red.withOpacity(0.9),
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
                Divider(height: 1, color: AppColors.divider(isDark)),
                ListTile(
                  leading: Icon(Icons.share, color: AppColors.primary, size: 24.w),
                  title: Text(
                    'مشاركة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                  onTap: () {
                    // TODO: مشاركة رابط البائع
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSellerAds(FavoriteSeller seller) async {
    try {
      await favCtrl.fetchAdvertiserAds(advertiserProfileId: seller.advertiserProfileId);
      Get.to(() => AdvertiserAdsScreenDesktop(
        advertiser: seller.advertiser,
        idAdv: seller.advertiserProfileId,
      ));
    } catch (e) {
      debugPrint('Failed open seller ads: $e');
    }
  }
}