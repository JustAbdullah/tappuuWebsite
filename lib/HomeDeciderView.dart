import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import 'desktop/HomeScreenDeskTop/home_web_desktop_screen.dart';
import 'mobile/HomeScreen/home_screen.dart';

class HomeDeciderView extends StatelessWidget {
  const HomeDeciderView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeCtrl = Get.find<HomeController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // يتم تحديث القيم في كل إعادة بناء
        HomeCtrl.isDesktop.value = width >= 1024;
        HomeCtrl.isTablet.value = width >= 600 && width < 1024;
        HomeCtrl.isMobile.value = width < 600;

        return Obx(() {
          if (HomeCtrl.isDesktop.value || HomeCtrl.isTablet.value) {
            return  ScreenUtilInit(
              designSize:  Size(1440, 900),
              child:  HomeWebDeskTopScreen(),
            );
          } else {
            HomeCtrl.isMobile.value = true;
            return ScreenUtilInit(
              designSize:  Size(375, 812),
              minTextAdapt: true,
              child:  HomeScreen(),
            );
          }
        });
      },
    );
  }
}
