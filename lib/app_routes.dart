// lib/app_routes.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/desktop/AdDetailsScreenDeskTop/AdDetailsScreen_desktop.dart';
import 'package:tappuu_website/mobile/viewAdsScreen/AdDetailsScreen.dart';
import 'package:tappuu_website/mobile/viewAdsScreen/AdsScreen.dart';

import 'HomeDeciderView.dart';
import 'core/data/model/AdResponse.dart';

// استيراد شاشة التحميل لتفاصيل الإعلان (عدّل المسار لو مختلف عندك)
import 'desktop/AdDetailsScreenDeskTop/AdDetailsLoadingScreen.dart';
import 'desktop/AdsSearchDeskTop/AdsLoadingScreen.dart';
import 'desktop/AdsSearchDeskTop/AdsScreenDesktop.dart';

class AppRoutes {
  static const String initial = '/Decider';
  static const String adsScreen = '/ads';
  static const String adsLoading = '/ads-loading';
  static const String adsScreenMobile = '/ads-mobile';
  static const String adDetailsMobile = '/ad-mobile';
  static const String adDetailsDirect = '/ad-details-direct';

  static bool get isDesktop {
    final context = Get.context;
    if (context == null) return false;
    return MediaQuery.of(context).size.width >= 600;
  }

  static final List<GetPage> pages = [
    GetPage(
      name: initial,
      page: () => const HomeDeciderView(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: adsScreen,
      page: () => isDesktop
          ? AdsScreenDesktop(
              categoryId: Get.arguments?['categoryId'],
              subCategoryId: Get.arguments?['subCategoryId'],
              subTwoCategoryId: Get.arguments?['subTwoCategoryId'],
              nameOfMain: Get.arguments?['nameOfMain'],
              nameOFsub: Get.arguments?['nameOFsub'],
              nameOFsubTwo: Get.arguments?['nameOFsubTwo'],
              currentTimeframe: Get.arguments?['currentTimeframe'],
              onlyFeatured: Get.arguments?['onlyFeatured'] ?? false,
              categorySlug: Get.arguments?['categorySlug'],
              subCategorySlug: Get.arguments?['subCategorySlug'],
              subTwoCategorySlug: Get.arguments?['subTwoCategorySlug'],
            )
          : AdsScreen(
              categoryId: Get.arguments?['categoryId'],
              subCategoryId: Get.arguments?['subCategoryId'],
              subTwoCategoryId: Get.arguments?['subTwoCategoryId'],
              nameOfMain: Get.arguments?['nameOfMain'],
              nameOFsub: Get.arguments?['nameOFsub'],
              nameOFsubTwo: Get.arguments?['nameOFsubTwo'],
              currentTimeframe: Get.arguments?['currentTimeframe'],
              onlyFeatured: Get.arguments?['onlyFeatured'] ?? false,
              categorySlug: Get.arguments?['categorySlug'],
              subCategorySlug: Get.arguments?['subCategorySlug'],
              subTwoCategorySlug: Get.arguments?['subTwoCategorySlug'],
              titleOfpage: Get.arguments?['titleOfpage'],
            ),
      transition: Transition.fadeIn,
    ),
  

    GetPage(
      name: adsLoading,
      page: () => AdsLoadingScreen(arguments: Get.arguments),
      transition: Transition.fadeIn,
    ),

    // مسار آمن ومرن: نأخذ كل ما بعد /ad/ كـ raw (مثال: "123" أو "123-my-slug" أو أي نص آخر)
    GetPage(
      name: '/ad/:raw',
      page: () {
        final raw = Get.parameters['raw'];
        if (raw == null || raw.isEmpty) {
          return const Scaffold(body: Center(child: Text('الإعلان غير موجود')));
        }
        // نمرر raw داخل arguments ليتعامل معها AdDetailsLoadingScreen
        return AdDetailsLoadingScreen(arguments: {'raw': raw});
      },
      transition: Transition.fadeIn,
    ),

    // مسارات الجوال القديمة
    GetPage(
      name: adsScreenMobile,
      page: () => AdsScreen(
        categoryId: Get.arguments?['categoryId'],
        subCategoryId: Get.arguments?['subCategoryId'],
        subTwoCategoryId: Get.arguments?['subTwoCategoryId'],
        nameOfMain: Get.arguments?['nameOfMain'],
        countofAds: Get.arguments?['countofAds'],
        nameOFsub: Get.arguments?['nameOFsub'],
        nameOFsubTwo: Get.arguments?['nameOFsubTwo'],
        currentTimeframe: Get.arguments?['currentTimeframe'],
        onlyFeatured: Get.arguments?['onlyFeatured'] ?? false,
        categorySlug: Get.arguments?['categorySlug'],
        subCategorySlug: Get.arguments?['subCategorySlug'],
        subTwoCategorySlug: Get.arguments?['subTwoCategorySlug'],
        titleOfpage: Get.arguments?['titleOfpage'],
      ),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: adDetailsMobile,
      page: () {
        final ad = Get.arguments?['ad'] as Ad?;
        if (ad == null) {
          return const Scaffold(body: Center(child: Text('الإعلان غير موجود')));
        }
        return AdDetailsScreen(ad: ad);
      },
      transition: Transition.fadeIn,
    ),


     GetPage(
      name: adDetailsDirect,
      page: () {
        final ad = Get.arguments?['ad'] as Ad?;
        if (ad == null) {
          return const Scaffold(body: Center(child: Text('الإعلان غير موجود')));
        }
        
        // استخدام الشاشة المناسبة حسب الجهاز
        return isDesktop 
            ? AdDetailsDesktop(ad: ad) 
            : AdDetailsScreen(ad: ad);
      },
      transition: Transition.fadeIn,
    ),

  ];
}
