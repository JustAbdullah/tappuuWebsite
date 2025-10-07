import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/PopularHistoryController.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import '../../../../core/data/model/PopularHistory.dart';
import '../../AdsSearchDeskTop/AdsScreenDesktop.dart';

class PopularTagsSectionDeskTop extends StatelessWidget {
  const PopularTagsSectionDeskTop({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeC = Get.find<ThemeController>();
    final isDarkMode = themeC.isDarkMode.value;
    final controller = Get.put(PopularHistoryController());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      color: AppColors.background(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Text(
            'أشهر مفاتيح البحث'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 20.0),
          
          // قائمة التاجات
          Obx(() {
            if (controller.isLoadingPopular.value) {
              return _buildShimmerTags(isDarkMode);
            }
            
            if (controller.popularList.isEmpty) {
              return Text(
                'لا توجد مفاتيح بحث شائعة حالياً'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 12.0.sp,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              );
            }
            
            return _buildTagsGrid(controller.popularList, isDarkMode);
          }),
        ],
      ),
    );
  }

  Widget _buildTagsGrid(List<PopularHistory> tags, bool isDarkMode) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: tags.map((tag) {
        final displayText = _getDisplayText(tag);
        
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _handleTagTap(tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: AppColors.tagBackground(isDarkMode),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.tagText(isDarkMode),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDisplayText(PopularHistory tag) {
    if (tag.subcatLv2 != null && tag.subcatLv2!.isNotEmpty) {
      return tag.subcatLv2!;
    }
    return tag.subcategory;
  }

  Widget _buildShimmerTags(bool isDarkMode) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: List.generate(10, (index) {
        return Container(
          width: 150,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(8.0),
          ),
        );
      }),
    );
  }

  void _handleTagTap(PopularHistory tag) {
    final controller = Get.find<PopularHistoryController>();
    
    controller.addOrIncrement(
      categoryId: tag.categoryId,
      subcat1Id: tag.subcat1Id,
      subcat2Id: tag.subcat2Id,
    );
    
   Get.to(() => AdsScreenDesktop(
      categoryId: tag.categoryId,
      subCategoryId: tag.subcat1Id,
      subTwoCategoryId: tag.subcat2Id,
      nameOfMain: tag.category,
      nameOFsub: tag.subcategory,
      nameOFsubTwo: tag.subcatLv2,
    ));
  }
}