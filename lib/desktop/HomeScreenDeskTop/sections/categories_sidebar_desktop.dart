import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import 'package:tappuu_website/controllers/home_controller.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';

import '../../../app_routes.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/category.dart';
import '../../../core/data/model/subcategory_level_one.dart';
import '../../../core/data/model/subcategory_level_two.dart';
import '../../../core/localization/changelanguage.dart';

class CategoriesSidebarDesktop extends StatelessWidget {
  CategoriesSidebarDesktop({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final ChangeLanguageController languageController =
      Get.find<ChangeLanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  final List<Color> iconColors = const [
    Color.fromARGB(255, 255, 117, 75),
    Color.fromARGB(255, 59, 184, 200),
    Color.fromARGB(255, 133, 190, 68),
    Color.fromARGB(255, 236, 160, 47),
    Color(0xFFF48FB1),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFCE93D8),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Obx(() {
        final bool isDarkMode = themeController.isDarkMode.value;
        final bool isLoading = homeController.isLoadingCategories.value;
        final categories = homeController.categoriesList;
        final bool hasNoData = !isLoading && categories.isEmpty;
        final String langCode =
            languageController.currentLocale.value.languageCode;

        return Container(
          width: 230.w,
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.border(isDarkMode).withOpacity(0.6),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSidebarHeader(isDarkMode),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border(isDarkMode),
              ),
              SizedBox(height: 4.h),

              if (isLoading)
                _buildSidebarShimmer(isDarkMode)
              else if (hasNoData)
                _buildCategoriesErrorState(
                  isDarkMode: isDarkMode,
                  onRetry: () {
                    homeController.fetchCategories(langCode);
                  },
                )
              else
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      categories.length,
                      (index) => _buildMainCategoryItem(
                        context: context,
                        category: categories[index],
                        index: index,
                        isDarkMode: isDarkMode,
                        langCode: langCode,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ───── HEADER ───────────────────────────────────────────────────────

  Widget _buildSidebarHeader(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.buttonAndLinksColor.withOpacity(
                isDarkMode ? 0.16 : 0.10,
              ),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              size: 16.w,
              color: AppColors.buttonAndLinksColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'التصنيفات'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── حالة الخطأ / عدم توفر التصنيفات ─────────────────────────────

  Widget _buildCategoriesErrorState({
    required bool isDarkMode,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.buttonAndLinksColor.withOpacity(
                isDarkMode ? 0.16 : 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 22.w,
              color: AppColors.buttonAndLinksColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'تعذّر تحميل التصنيفات'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'قد يكون اتصالك بالإنترنت محدوداً أو حدث خطأ مؤقت في الخادم.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextStyles.small,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(height: 10.h),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh_rounded,
              size: 16.sp,
            ),
            label: Text(
              'إعادة المحاولة'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.small,
                fontWeight: FontWeight.w600,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 6.h,
              ),
              foregroundColor: Colors.white,
              backgroundColor: AppColors.buttonAndLinksColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── MAIN CATEGORY ITEM ──────────────────────────────────────────

  Widget _buildMainCategoryItem({
    required BuildContext context,
    required Category category,
    required int index,
    required bool isDarkMode,
    required String langCode,
  }) {
    final bool isExpanded = homeController.isCategoryExpanded(category.id);
    final String name = category.translations.first.name;
    final int adsCount = category.adsCount;

    final bool isLoadingSubcategories =
        homeController.isLoadingSubcategoriesMap[category.id] == true;

    final List<SubcategoryLevelOne> levelOneSubcategories =
        homeController.subCategoriesMap[category.id] ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // رأس التصنيف الرئيسي (كلّه clickable)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            homeController.clearDeif();
            Get.toNamed(
              AppRoutes.adsScreen,
              arguments: {
                'categoryId': category.id,
                'nameOfMain': category.name,
                'categorySlug': category.slug,
              },
              preventDuplicates: false,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
            decoration: BoxDecoration(
              color: isExpanded
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: iconColors[index % iconColors.length],
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      category.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 14.w,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // الإسم
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w700,
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.textPrimary(isDarkMode),
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),

                // عدد الإعلانات
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '$adsCount',
                    style: TextStyle(
                      fontSize: AppTextStyles.small,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(width: 6.w),

                // زر التوسيع/الطي
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    final wasExpanded =
                        homeController.isCategoryExpanded(category.id);
                    homeController.toggleCategory(category.id);

                    if (!wasExpanded) {
                      homeController.fetchSubcategories(
                        category.id,
                        langCode,
                      );
                    }
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18.w,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ),

        // التصنيفات الفرعية
        if (isExpanded) ...[
          Padding(
            padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
            child: isLoadingSubcategories
                ? _buildSubcategoryShimmer(isDarkMode)
                : _buildSubcategoriesLevelOne(
                    subcategories: levelOneSubcategories,
                    isDarkMode: isDarkMode,
                    langCode: langCode,
                  ),
          ),
          Divider(
            height: 10.h,
            thickness: 0.4,
            color: AppColors.border(isDarkMode),
            indent: 10.w,
            endIndent: 10.w,
          ),
        ],
      ],
    );
  }

  // ───── SUBCATEGORIES (LEVEL 1) ─────────────────────────────────────

  Widget _buildSubcategoriesLevelOne({
    required List<SubcategoryLevelOne> subcategories,
    required bool isDarkMode,
    required String langCode,
  }) {
    if (subcategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final subCategory in subcategories)
          _buildSubCategoryItemWithChildren(
            subCategory: subCategory,
            isDarkMode: isDarkMode,
            langCode: langCode,
          ),
      ],
    );
  }

  Widget _buildSubCategoryItemWithChildren({
    required SubcategoryLevelOne subCategory,
    required bool isDarkMode,
    required String langCode,
  }) {
    final bool isSubExpanded =
        homeController.isSubCategoryExpanded(subCategory.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5.h),

        // رأس التصنيف الفرعي (السهم + الاسم + العدد)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: [
              SizedBox(width: 16.w),

              // سهم التوسيع
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  final wasExpanded =
                      homeController.isSubCategoryExpanded(subCategory.id);
                  homeController.toggleSubCategory(subCategory.id);

                  if (!wasExpanded) {
                    homeController.fetchSubcategoriesLevelTwo(
                      subCategory.id,
                      langCode,
                    );
                  }
                },
                child: Icon(
                  isSubExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 18.w,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),

              SizedBox(width: 6.w),

              // الاسم + العدد (دخول للإعلانات)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.adsScreen,
                      arguments: {
                        'categoryId': subCategory.categoryId,
                        'subCategoryId': subCategory.id,
                        'nameOfMain': subCategory.categoryName,
                        'nameOFsub': subCategory.translations.first.name,
                        'categorySlug': subCategory.slugCategoryMain,
                        'subCategorySlug': subCategory.slug,
                      },
                      preventDuplicates: false,
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          subCategory.translations.first.name,
                          style: TextStyle(
                            fontSize: AppTextStyles.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDarkMode),
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          '${subCategory.adsCount}',
                          style: TextStyle(
                            fontSize: AppTextStyles.small,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (isSubExpanded)
          _buildThirdLevelSection(
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  // ───── SUBCATEGORIES (LEVEL 2) ─────────────────────────────────────

  Widget _buildThirdLevelSection({
    required bool isDarkMode,
  }) {
    final bool isLoadingLevelTwo =
        homeController.isLoadingSubcategoryLevelTwo.value;
    final List<SubcategoryLevelTwo> levelTwoList =
        homeController.subCategoriesLevelTwo;

    if (isLoadingLevelTwo) {
      return _buildThirdLevelShimmer(isDarkMode);
    }

    if (levelTwoList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(left: 40.w, top: 5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final thirdCategory in levelTwoList)
            _buildThirdLevelCategoryItem(
              thirdCategory: thirdCategory,
              isDarkMode: isDarkMode,
            ),
        ],
      ),
    );
  }

  Widget _buildThirdLevelCategoryItem({
    required SubcategoryLevelTwo thirdCategory,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Get.toNamed(
            AppRoutes.adsScreen,
            arguments: {
              'categoryId': thirdCategory.parentCategoryId,
              'subCategoryId': thirdCategory.parent1Id,
              'subTwoCategoryId': thirdCategory.id,
              'nameOfMain': thirdCategory.parentCategoryName,
              'nameOFsub': thirdCategory.parent1Name,
              'nameOFsubTwo': thirdCategory.translations.first.name,
              'categorySlug': thirdCategory.slugParentCategory,
              'subCategorySlug': thirdCategory.slugParent1,
              'subTwoCategorySlug': thirdCategory.slug,
            },
            preventDuplicates: false,
          );
        },
        child: Row(
          children: [
            SizedBox(width: 8.w),
            Container(
              width: 4.w,
              height: 4.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                thirdCategory.translations.first.name,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '${thirdCategory.adsCount}',
                style: TextStyle(
                  fontSize: AppTextStyles.small,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── SHIMMER WIDGETS ─────────────────────────────────────────────

  Widget _buildThirdLevelShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Padding(
      padding: EdgeInsets.only(left: 40.w, top: 5.h),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  Container(
                    width: 4.w,
                    height: 4.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 100.w,
                    height: 12.h,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Container(
                    width: 20.w,
                    height: 12.h,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Padding(
      padding: EdgeInsets.only(top: 6.h, left: 16.w),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  const Icon(Icons.arrow_right, size: 18),
                  SizedBox(width: 6.w),
                  Container(
                    width: 120.w,
                    height: 14.h,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  Container(
                    width: 25.w,
                    height: 14.h,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor =
        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      width: 100.w,
                      height: 14.h,
                      color: baseColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 30.w,
                    height: 16.h,
                    color: baseColor,
                  ),
                  SizedBox(width: 6.w),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
