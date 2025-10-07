import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../controllers/FavoritesController.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/ThemeController.dart';
import '../../../../controllers/areaController.dart';
import '../../../../core/constant/app_text_styles.dart';
import '../../../../core/constant/appcolors.dart';
import '../../../../core/data/model/AdResponse.dart';
import '../../../../customWidgets/custom_image_malt.dart';
import '../../../app_routes.dart';
import '../../AdDetailsScreenDeskTop/AdDetailsScreen_desktop.dart';

class FavoritesAdItemDeskTop extends StatelessWidget {
  final Ad ad;
  final String viewMode;

  const FavoritesAdItemDeskTop({
    super.key, 
    required this.ad, 
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    final AreaController areaController = Get.put(AreaController());
    final areaName = areaController.getAreaNameById(ad.areaId);
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final favoritesController = Get.find<FavoritesController>();
    final LoadingController loadingC = Get.find<LoadingController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: viewMode == 'grid'
          ? _buildGridItem(isDarkMode, areaName, favoritesController, loadingC)
          : _buildListItem(isDarkMode, areaName, favoritesController, loadingC),
    );
  }

  Widget _buildGridItem(
    bool isDarkMode, 
    String? areaName,
    FavoritesController favoritesController,
    LoadingController loadingC
  ) {
    return    InkWell(
           onTap: (){
               
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});

},
                   
        child:  Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
       InkWell(
           onTap: (){
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});

},
                   
        child:  _buildImageSection(110.h, isGrid: true, isDarkMode: isDarkMode)),
          
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 3.h),
                
                if (ad.price != null)
                  Text(
                    _formatPrice(ad.price!),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                     fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  
                SizedBox(height: 6.h),
                
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, 
                        size: 13.sp,
                        color: AppColors.textSecondary(isDarkMode)),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                                                        '${ad.city?.name??""}, ${ad.area?.name??""}',
      
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.small,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 3.h),
              
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite,
                      color: Colors.red,
                      tooltip: 'إزالة من المفضلة',
                      onPressed: () => _removeFromFavorites(ad.id, favoritesController, loadingC),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    bool isDarkMode, 
    String? areaName,
    FavoritesController favoritesController,
    LoadingController loadingC
  ) {
    ThemeController themeController = Get.find<ThemeController>();
    return    InkWell(
           onTap: (){
                 
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});

},
                   
        child:  Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         InkWell(
           onTap: (){
                 
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});

},
                   
        child:  Container(
              width: 150.w,
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  bottomLeft: Radius.circular(10.r)),
              ),
              child: _buildImageSection(140.h, isGrid: false, isDarkMode: isDarkMode),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child:  InkWell(
           onTap: (){
            
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});

},
                   
        child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 6.h),
                    
                    if (ad.price != null)
                      Text(
                        _formatPrice(ad.price!),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    
                    SizedBox(height: 3.h),
                    
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, 
                            size: 13.sp,
                            color: AppColors.textSecondary(isDarkMode)),
                        SizedBox(width: 6.w),
                        Text(
                                  '${ad.city?.name??""}, ${ad.area?.name??""}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                           fontSize: AppTextStyles.small,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                        Spacer(),
                        _buildActionButton(
                          icon: Icons.favorite,
                          color: Colors.red,
                          tooltip: 'إزالة من المفضلة',
                          onPressed: () => _removeFromFavorites(ad.id, favoritesController, loadingC),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    if (ad.category != null) 
                      Wrap(
                        spacing: 6.w,
                        children: [
                          _buildTag(ad.category.name, themeController),
                          if (ad.subCategoryLevelOne != null) 
                            _buildTag(ad.subCategoryLevelOne.name, themeController),
                          if (ad.subCategoryLevelTwo != null) 
                            _buildTag(ad.subCategoryLevelTwo!.name, themeController),
                        ],
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      textStyle: TextStyle( 
        color: AppColors.onPrimary,
        fontFamily: AppTextStyles.appFontFamily,
       fontSize: AppTextStyles.small,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 16.sp, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildImageSection(double height, {required bool isGrid, required bool isDarkMode}) {
    return ClipRRect(
      borderRadius: isGrid 
          ? BorderRadius.vertical(top: Radius.circular(10.r))
          : BorderRadius.horizontal(left: Radius.circular(10.r)),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            color: AppColors.grey.withOpacity(0.1),
            child: ad.images.isNotEmpty
                ? ImagesViewer(
                    images: ad.images,
                    width: double.infinity,
                    height: height,
                    isCompactMode: true,
                    enableZoom: true,
                    showPageIndicator: ad.images.length > 1,
                    imageQuality: ImageQuality.high,
                  )
                : Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40.w,
                      color: AppColors.grey,
                    ),
                  ),
          ),
          
          if (ad.is_premium == true)
            Positioned(
              top: 6.w,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                   colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14.sp, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      'مميز'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                       fontSize: AppTextStyles.small,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
            Visibility(
                              visible: ad.show_time == 1,
                              child: Positioned(
                                top: 6.w,
                                left: 6.w,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    _formatDate(ad.createdAt),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 11.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
        ],
      ),
    );
  }

  Future<void> _removeFromFavorites(int adId, FavoritesController favoritesController, LoadingController loadingC) async {
    if (loadingC.currentUser != null) {
      await favoritesController.removeFavorite(
        userId: loadingC.currentUser?.id??0,
        adId: adId,
      );
      
      Get.snackbar(
        'تمت الإزالة'.tr,
        'تمت إزالة الإعلان من المفضلة'.tr,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${'قبل'.tr} ${difference.inDays} ${'يوم'.tr}';
    } else if (difference.inHours > 0) {
      return '${'قبل'.tr} ${difference.inHours} ${'ساعة'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${'قبل'.tr} ${difference.inMinutes} ${'دقيقة'.tr}';
    } else {
      return 'الآن'.tr;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون ل.س';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف ل.س';
    }
    return '${price.toStringAsFixed(0)} ل.س';
  }

  Widget _buildTag(String text, ThemeController themeController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.card(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
         fontSize: AppTextStyles.small,
          color: AppColors.textSecondary(themeController.isDarkMode.value),
        ),
      ),
    );
  }
}