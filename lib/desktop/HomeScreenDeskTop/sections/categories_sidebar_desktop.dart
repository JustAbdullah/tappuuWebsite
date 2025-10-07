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
import '../../AdsSearchDeskTop/AdsScreenDesktop.dart';

class CategoriesSidebarDesktop extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();
  final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
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

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Container(
        width: 230.w,
        decoration: BoxDecoration(
          color: AppColors.background(isDarkMode),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Obx(() {
          if (homeController.isLoadingCategories.value) {
            return _buildSidebarShimmer(isDarkMode);
          }
          
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: homeController.categoriesList.length,
            itemBuilder: (context, index) {
              final category = homeController.categoriesList[index];
              return _buildMainCategoryItem(
                category,
                category.translations.first.name,
                category.adsCount,
                isDarkMode,
                index,
                context
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildMainCategoryItem(Category category, String name, int adsCount, bool isDarkMode, int index, BuildContext context) {
    return Obx(() {
      final isExpanded = homeController.isCategoryExpanded(category.id);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main category header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 15.w),
            decoration: BoxDecoration(
              color: isExpanded 
                ? AppColors.primary.withOpacity(0.05) 
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                // Category icon and name - Tappable for navigation
                Expanded(
                  child: InkWell(
                    onTap: () {
                      print( category.id);
                      print(name);
                      homeController.clearDeif();
                        Get.toNamed(
  AppRoutes.adsScreen,
  arguments: {
    'categoryId': category.id,
    'nameOfMain': category.name,
    'categorySlug': category.slug,
    // يمكنك إضافة أي معلمات أخرى تحتاجها
  },
);
                    },
                    child: Row(
                      children: [
                        // Category icon
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
                        
                        SizedBox(width: 12.w),
                        
                        // Category name
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
                      ],
                    ),
                  ),
                ),
                
                // Ads count
                InkWell(
                  onTap: () {
                    homeController.clearDeif();
                    Get.toNamed(
  AppRoutes.adsScreen,
  arguments: {
    'categoryId': category.id,
    'nameOfMain': category.name,
    'categorySlug': category.slug,
    // يمكنك إضافة أي معلمات أخرى تحتاجها
  },
);

                  
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
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
                ),
                
                // Expand icon - Separate tap for expansion
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () {
                    homeController.toggleCategory(category.id);
                    if (homeController.isCategoryExpanded(category.id)) {
                      homeController.fetchSubcategories(
                        category.id,
                        languageController.currentLocale.value.languageCode
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
          
          // Subcategories
          if (isExpanded) ...[
            Padding(
              padding: EdgeInsets.only(left: 15.w),
              child: _buildSubcategories(category, isDarkMode),
            ),
            SizedBox(height: 8.h),
            Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.border(isDarkMode),
              indent: 15.w,
              endIndent: 15.w,
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSubcategories(Category category, bool isDarkMode) {
    return Obx(() {
      if (homeController.isLoadingSubcategoriesMap[category.id] == true) {
        return _buildSubcategoryShimmer(isDarkMode);
      }
      
      if (homeController.subCategoriesMap[category.id] == null) {
        return SizedBox();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var subCategory in homeController.subCategoriesMap[category.id]!)
            _buildSubCategoryItemWithChildren(subCategory, isDarkMode),
        ],
      );
    });
  }

  Widget _buildSubCategoryItemWithChildren(SubcategoryLevelOne subCategory, bool isDarkMode) {
    return Obx(() {
      final isSubExpanded = homeController.isSubCategoryExpanded(subCategory.id);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5.h),
          
          // Subcategory header
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              children: [
                SizedBox(width: 20.w),
                
                // Arrow icon - Separate tap for expansion
                InkWell(
                  onTap: () {
                    homeController.toggleSubCategory(subCategory.id);
                    if (isSubExpanded) {
                      homeController.fetchSubcategoriesLevelTwo(
                        subCategory.id,
                        languageController.currentLocale.value.languageCode
                      );
                    }
                  },
                  child: Icon(
                    isSubExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 18.w,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // Subcategory name and ads count - Tappable for navigation
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      
                      Get.toNamed(
  AppRoutes.adsScreen,
  arguments: {
    'categoryId':subCategory.categoryId,
    'subCategoryId': subCategory.id,
    'nameOfMain': subCategory.categoryName,
    'nameOFsub': subCategory.translations.first.name,
    'categorySlug': subCategory.slugCategoryMain,
    'subCategorySlug': subCategory.slug,
  },
);
                   
                    },
                    child: Row(
                      children: [
                        // Subcategory name
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
                        
                        // Ads count
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
          
          // Third level categories
          if (isSubExpanded) ...[
            if (homeController.isLoadingSubcategoryLevelTwo.value)
              _buildThirdLevelShimmer(isDarkMode)
            else if (homeController.subCategoriesLevelTwo.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: 45.w, top: 5.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var thirdCategory in homeController.subCategoriesLevelTwo)
                      _buildThirdLevelCategoryItem(thirdCategory, isDarkMode),
                  ],
                ),
              ),
          ],
        ],
      );
    });
  }

  Widget _buildThirdLevelCategoryItem(SubcategoryLevelTwo thirdCategory, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () async {
      Get.toNamed(
  AppRoutes.adsScreen,
  arguments: {
    'categoryId': thirdCategory.parentCategoryId,
    'subCategoryId':thirdCategory.parent1Id,
    'subTwoCategoryId':  thirdCategory.id,
    'nameOfMain':  thirdCategory.parentCategoryName,
    'nameOFsub':thirdCategory.parent1Name,
    'nameOFsubTwo': thirdCategory.translations.first.name,
    'categorySlug':  thirdCategory.slugParentCategory,
    'subCategorySlug': thirdCategory.slugParent1,
    'subTwoCategorySlug': thirdCategory.slug,
  },
);
         
        },
        child: Row(
          children: [
            SizedBox(width: 10.w),
            
            // Dot indicator
            Container(
              width: 4.w,
              height: 4.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Third level name
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
            
            // Ads count
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

  // باقي الدوال (Shimmer) تبقى كما هي بدون تغيير
  Widget _buildThirdLevelShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Padding(
      padding: EdgeInsets.only(left: 45.w, top: 5.h),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: List.generate(3, (index) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                SizedBox(width: 10.w),
                Container(
                  width: 4.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 100.w,
                  height: 12.h,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 20.w,
                  height: 12.h,
                  color: Colors.white,
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildSubcategoryShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Padding(
      padding: EdgeInsets.only(top: 10.h, left: 15.w),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: List.generate(4, (index) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              children: [
                SizedBox(width: 20.w),
                Icon(Icons.arrow_right, size: 18.w),
                SizedBox(width: 8.w),
                Container(
                  width: 120.w,
                  height: 14.h,
                  color: Colors.white,
                ),
                Spacer(),
                Container(
                  width: 25.w,
                  height: 14.h,
                  color: Colors.white,
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildSidebarShimmer(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 14.h,
                          color: baseColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 30.w,
                    height: 16.h,
                    color: baseColor,
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.expand_more, size: 18.w),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
} 

