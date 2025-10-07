import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_website/controllers/home_controller.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/localization/changelanguage.dart';

import '../../../../app_routes.dart';
import '../../../../controllers/AdsManageSearchController.dart';
import '../../../../controllers/BrowsingHistoryController.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/PopularHistoryController.dart';
import '../../menubar.dart';

class SubCategoriesScreenLeveLTwo extends StatefulWidget {
  final int SubCateId;
  final String subCateName;
  final String subCateSlug;
  final String nameMainCate;
  final String slugMainCate;
  final int MainId;
  final int allSubOnecount;
  final HomeController controller = Get.find<HomeController>();

  SubCategoriesScreenLeveLTwo({
    super.key,
    required this.SubCateId,
    required this.subCateName,
    required this.nameMainCate,
    required this.MainId,
    required this.allSubOnecount,
    required this.slugMainCate,
    required this.subCateSlug
  });

  @override
  State<SubCategoriesScreenLeveLTwo> createState() => _SubCategoriesScreenLeveLTwoState();
}

class _SubCategoriesScreenLeveLTwoState extends State<SubCategoriesScreenLeveLTwo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
    widget.controller.fetchSubcategoriesLevelTwo(widget.SubCateId, langCode);
    _updateBrowserUrl();
  }

  void _updateBrowserUrl() {
    String urlPath = '';
    
    if (widget.slugMainCate != null && widget.slugMainCate.isNotEmpty) {
      urlPath += '/${widget.slugMainCate}';
    }
    
    if (widget.subCateSlug != null && widget.subCateSlug.isNotEmpty) {
      urlPath += '/${widget.subCateSlug}';
    }
    
    html.window.history.replaceState({}, '', urlPath);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final bgColor = AppColors.background(isDarkMode);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: Menubar(),
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, _scaffoldKey),
      body: _buildBody(bgColor),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    return AppBar(
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.w,
          color: AppColors.onSurfaceDark,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        InkWell(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Icon(
            Icons.menu,
            size: 30.w,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 8.w),
      ],
      centerTitle: true,
      title: Text(
        widget.subCateName,
        style: TextStyle(
          fontSize: AppTextStyles.xlarge,
          fontWeight: FontWeight.w700,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.onSurfaceDark,
        ),
      ),
      elevation: 0,
    );
  }

  Widget _buildFilterIcon() {
    return SizedBox(
      width: 40.w,
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.filter_list,
            size: 22.w,
            color: AppColors.onSurfaceDark,
          ),
          Positioned(
            right: 6.w,
            bottom: 8.h,
            child: Transform.rotate(
              angle: 0.0,
              child: Icon(
                Icons.refresh,
                size: 12.w,
                color: AppColors.onSurfaceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            title: Center(
              child: Text(
                'بحثي الأخير عن ${name.toString()}',
                style: TextStyle(
                  fontSize: AppTextStyles.xxlarge,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 4.h),
                Text(
                  'هل ترغب في تكرار بحثك الاخير ؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      print('مسح بحثي الأخير تم الضغط');
                      Get.back();
                    },
                    child: Text(
                      'مسح بحـثي الأخير',
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontFamily: AppTextStyles.appFontFamily,
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 7.h),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100.w,
                    height: 44.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.r),
                        ),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        'تراجع',
                        style: TextStyle(
                         fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.buttonAndLinksColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SizedBox(
                    width: 100.w,
                    height: 44.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonAndLinksColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.r),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 2,
                      ),
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        'إتمام',
                        style: TextStyle(
                         fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(Color bgColor) {
    return Obx(() {
      if (widget.controller.isLoadingSubcategoryLevelTwo.value) {
        return _buildShimmerLoader(bgColor);
      }

      if (widget.controller.subCategoriesLevelTwo.isEmpty) {
        return Center(
          child: Text(
            'لا توجد تصنيفات فرعية'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: Get.find<ThemeController>().isDarkMode.value
                  ? AppColors.textPrimary(true)
                  : AppColors.textPrimary(false),
            ),
          ),
        );
      }

      return Column(
        children: [
          _buildViewAllAdsLink(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              itemCount: widget.controller.subCategoriesLevelTwo.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Get.find<ThemeController>().isDarkMode.value
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final subCategory = widget.controller.subCategoriesLevelTwo[index];
                final translation = subCategory.translations.firstWhere(
                  (t) => t.language == Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
                  orElse: () => subCategory.translations.first,
                );

                return _buildSubCategoryItem(
                  idOfSubTwo: subCategory.id,
                  name: translation.name,
                  adsCount: subCategory.adsCount,
                  slugSubTwo: subCategory.slug,
                  imageUrl: subCategory.image,
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildViewAllAdsLink() {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
          child: InkWell(
            onTap: () {
              Get.find<AdsController>().viewMode.value = 'vertical_simple';
              Get.toNamed(
                AppRoutes.adsScreenMobile,
                arguments: {
                  'categoryId': widget.MainId,
                  'subCategoryId': widget.SubCateId,
                  'nameOfMain': widget.nameMainCate,
                  'nameOFsub': widget.subCateName,
                  'categorySlug': widget.slugMainCate,
                  'subCategorySlug': widget.subCateSlug,
                  'titleOfpage': widget.subCateName,
                  'countofAds': 0,
                },
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عرض جميع الإعلانات'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.buttonAndLinksColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "(${widget.allSubOnecount})",
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.buttonAndLinksColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          size: 20.w, color: AppColors.buttonAndLinksColor),
                      onPressed: () {
                        Get.find<AdsController>().viewMode.value = 'vertical_simple';
                        Get.toNamed(
                          AppRoutes.adsScreenMobile,
                          arguments: {
                            'categoryId': widget.MainId,
                            'subCategoryId': widget.SubCateId,
                            'nameOfMain': widget.nameMainCate,
                            'nameOFsub': widget.subCateName,
                            'categorySlug': widget.slugMainCate,
                            'subCategorySlug': widget.subCateSlug,
                            'titleOfpage': widget.subCateName,
                            'countofAds': 0,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Divider(
          height: 1,
          thickness: 1.5,
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildShimmerLoader(Color bgColor) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: Duration(milliseconds: 1500),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 150.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: ListView.separated(
                itemCount: 7,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1.5,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.w,
                              height: 40.h,
                              margin: EdgeInsets.only(left: 8.w),
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: 18.h,
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 30.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSubCategoryItem({
    required int idOfSubTwo,
    required String name,
    required int adsCount,
    required String slugSubTwo,
    required String? imageUrl, 
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return InkWell(
      onTap: () {
        BrowsingHistoryController _browsing = Get.put(BrowsingHistoryController());
        Get.find<LoadingController>().currentUser != null
            ? _browsing.addHistory(
                categoryId: widget.MainId,
                subcat1Id: widget.SubCateId,
                subcat2Id: idOfSubTwo,
                userId: Get.find<LoadingController>().currentUser?.id ?? 0)
            : null;
        Get.find<PopularHistoryController>().addOrIncrement(
            categoryId: widget.MainId, subcat1Id: widget.SubCateId, subcat2Id: idOfSubTwo);
        Get.find<AdsController>().viewMode.value = 'vertical_simple';
     
        Get.toNamed(
          AppRoutes.adsScreenMobile,
          arguments: {
            'categoryId': widget.MainId,
            'subCategoryId': widget.SubCateId,
            'subTwoCategoryId': idOfSubTwo,
            'nameOfMain': widget.nameMainCate,
            'nameOFsub': widget.subCateName,
            'nameOFsubTwo': name,
            'categorySlug': widget.slugMainCate,
            'subCategorySlug': widget.subCateSlug,
            'subTwoCategorySlug': slugSubTwo,
            'titleOfpage': name,
            'countofAds': adsCount,
          }
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  _buildImageWidget(imageUrl),
                SizedBox(width: 8.w),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '($adsCount)',
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.w,
                  color: AppColors.grey.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return Container(
        width: 30.w,
        height: 30.h,
        margin: EdgeInsets.only(left: 8.w),
        child: SvgPicture.network(
          imageUrl,
          fit: BoxFit.cover,
          placeholderBuilder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 20.w,
        height: 20.h,
        margin: EdgeInsets.only(left: 8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}