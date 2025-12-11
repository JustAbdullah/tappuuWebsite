import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_website/controllers/PopularHistoryController.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';

import '../../../../core/data/model/PopularHistory.dart';
import '../../../app_routes.dart';

class PopularTagsSectionDeskTop extends StatelessWidget {
  const PopularTagsSectionDeskTop({Key? key}) : super(key: key);

  // نحول النص لـ "slug" بسيط (استبدال المسافات بشرطة فقط)
  String? _slugify(String? text) {
    if (text == null) return null;
    return text.trim().replaceAll(' ', '-');
  }

  @override
  Widget build(BuildContext context) {
    final themeC = Get.find<ThemeController>();
    final isDarkMode = themeC.isDarkMode.value;
    final controller = Get.put(PopularHistoryController());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------- العنوان -----------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.buttonAndLinksColor.withOpacity(
                      isDarkMode ? 0.22 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 18.w,
                    color: AppColors.buttonAndLinksColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'عمليات بحث شائعة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'استكشف ما يبحث عنه المستخدمون واضغط لعرض الإعلانات المتطابقة.'
                  .tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            SizedBox(height: 14.h),

            // ----------------- المحتوى -----------------
            Obx(() {
              if (controller.isLoadingPopular.value) {
                return _buildShimmerTags(isDarkMode);
              }

              if (controller.popularList.isEmpty) {
                return Text(
                  'لا توجد عمليات بحث شائعة حالياً'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                );
              }

              return _buildTagsGrid(controller.popularList, isDarkMode);
            }),
          ],
        ),
      ),
    );
  }

  // ----------------- GRID / WRAP للتاقات -----------------
  Widget _buildTagsGrid(List<PopularHistory> tags, bool isDarkMode) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: List.generate(tags.length, (index) {
        final tag = tags[index];
        final displayText = _getDisplayText(tag);
        final isHot = index < 3; // أول 3 عناصر "رائجة" أكثر

        return _PopularTagChip(
          tag: tag,
          label: displayText,
          isDarkMode: isDarkMode,
          isHot: isHot,
          onTap: () => _handleTagTap(tag),
        );
      }),
    );
  }

  String _getDisplayText(PopularHistory tag) {
    // لو فيه مستوى ثاني استخدمه، وإلا استخدم الفرعي
    if (tag.subcatLv2 != null && tag.subcatLv2!.isNotEmpty) {
      return tag.subcatLv2!;
    }
    return tag.subcategory;
  }

  // ----------------- Shimmer بسيط للتاقات -----------------
  Widget _buildShimmerTags(bool isDarkMode) {
    final base = AppColors.surface(isDarkMode);
    final highlight = AppColors.surface(isDarkMode).withOpacity(0.6);

    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: List.generate(8, (index) {
        return Container(
          width: 130.w,
          height: 38.h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: highlight,
              width: 0.7,
            ),
          ),
        );
      }),
    );
  }

  void _handleTagTap(PopularHistory tag) {
    final controller = Get.find<PopularHistoryController>();

    // زيادة عدّاد الشعبية
    controller.addOrIncrement(
      categoryId: tag.categoryId,
      subcat1Id: tag.subcat1Id,
      subcat2Id: tag.subcat2Id,
    );

    // نولّد Slugs من الأسماء (نفس مفاتيح التصنيفات)
    final categorySlug = _slugify(tag.category);
    final subCategorySlug = _slugify(tag.subcategory);
    final subTwoCategorySlug = _slugify(tag.subcatLv2);

    // الدخول لواجهة الإعلانات مع تمرير كل شيء (IDs + أسماء + Slugs)
    Get.toNamed(
      AppRoutes.adsScreen,
      arguments: {
        'categoryId': tag.categoryId,
        'subCategoryId': tag.subcat1Id,
        'subTwoCategoryId': tag.subcat2Id,
        'nameOfMain': tag.category,
        'nameOFsub': tag.subcategory,
        'nameOFsubTwo': tag.subcatLv2,
        'categorySlug': categorySlug,
        'subCategorySlug': subCategorySlug,
        'subTwoCategorySlug': subTwoCategorySlug,
      },
      preventDuplicates: false,
    );
  }
}

/// Chip منفصلة عشان نحط فيها تأثير الهوفر والحركة
class _PopularTagChip extends StatefulWidget {
  final PopularHistory tag;
  final String label;
  final bool isDarkMode;
  final bool isHot;
  final VoidCallback onTap;

  const _PopularTagChip({
    Key? key,
    required this.tag,
    required this.label,
    required this.isDarkMode,
    required this.isHot,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_PopularTagChip> createState() => _PopularTagChipState();
}

class _PopularTagChipState extends State<_PopularTagChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bgBase = AppColors.tagBackground(widget.isDarkMode);
    final textColor = AppColors.tagText(widget.isDarkMode);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.buttonAndLinksColor.withOpacity(
                    widget.isDarkMode ? 0.22 : 0.12,
                  )
                : bgBase,
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: _hovering
                  ? AppColors.buttonAndLinksColor
                  : bgBase.withOpacity(0.4),
              width: 0.9,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color:
                          AppColors.buttonAndLinksColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 14.w,
                color: textColor.withOpacity(0.9),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isHot) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(
                        widget.isDarkMode ? 0.9 : 0.85),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 11.w,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'رائج'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
