import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/AdsManageController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/areaController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AdResponse.dart';
import '../../../customWidgets/custom_image_malt.dart';
import '../../AdDetailsScreenDeskTop/AdDetailsScreen_desktop.dart';
import 'AdStatisticsScreenWeb.dart';
import 'EditAdScreenDeskTop.dart';

class UserAdItemDeskTop extends StatelessWidget {
  final Ad ad;
  final String viewMode;

  const UserAdItemDeskTop({
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
    final adsController = Get.find<ManageAdController>();

    return
    InkWell(
      onTap: () => Get.to(() => AdStatisticsScreenWeb(ad: ad)),
      child:
     Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: viewMode == 'grid'
          ? 
          _buildGridItem(isDarkMode, areaName, adsController)
          : _buildListItem(isDarkMode, areaName, adsController),
    ));
  }

  // تصميم البطاقة في وضع الشبكة
  Widget _buildGridItem(bool isDarkMode, String? areaName, ManageAdController adsController) {
      ThemeController themeController = Get.find<ThemeController>();

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // صورة الإعلان
      InkWell(
      onTap: () => Get.to(() => AdStatisticsScreenWeb(ad: ad)),
      child:  _buildImageSection(140.h, isGrid: true, isDarkMode: isDarkMode)),
        
        // تفاصيل الإعلان
        Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Text(
                ad.title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(isDarkMode),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 5.h),
              
              // السعر
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

              
              // الموقع
              Row(
                children: [
                  Icon(Icons.location_on_outlined, 
                      size: 13.sp,
                      color: AppColors.textSecondary(isDarkMode)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                                '${ad.city?.name??""}, ${ad.area?.name??""}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                       fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

                   SizedBox(height: 3.h),
             
                
                  
                        _buildStatItem(
                        icon: Icons.remove_red_eye_outlined,
                        value: ad.views,
                        label: 'مشاهدة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد الإضافات للمفضلة
                      _buildStatItem(
                        icon: Icons.favorite_border,
                        value: ad.favorites_count ?? 0,
                        label: 'مفضلة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد المتواصلين
                      _buildStatItem(
                        icon: Icons.chat_outlined,
                        value: ad.inquirers_count ?? 0,
                        label: 'تواصل',
                        isDarkMode: isDarkMode
                      ),
          
            
           
            ],
          ),
        ),
      ],
    );
  }

  // تصميم البطاقة في وضع القائمة
  Widget _buildListItem(bool isDarkMode, String? areaName, ManageAdController adsController) {
   ThemeController themeController = Get.find<ThemeController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة الإعلان
    InkWell(
      onTap: () => Get.to(() => AdStatisticsScreenWeb(ad: ad)),
      child:    Container(
          width: 200.w,
          height: 150.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              bottomLeft: Radius.circular(12.r)),
          ),
          child: _buildImageSection(140.h, isGrid: false, isDarkMode: isDarkMode),
    )),
        
        // تفاصيل الإعلان
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Text(
                  ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 5.h),
                
                // السعر والموقع
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
                    SizedBox(width: 8.w),
                    Text(
                                '${ad.city?.name??""}, ${ad.area?.name??""}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                       fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 3.h),
             
                
                  
                        _buildStatItem(
                        icon: Icons.remove_red_eye_outlined,
                        value: ad.views,
                        label: 'مشاهدة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد الإضافات للمفضلة
                      _buildStatItem(
                        icon: Icons.favorite_border,
                        value: ad.favorites_count ?? 0,
                        label: 'مفضلة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد المتواصلين
                      _buildStatItem(
                        icon: Icons.chat_outlined,
                        value: ad.inquirers_count ?? 0,
                        label: 'تواصل',
                        isDarkMode: isDarkMode
                      ),
                      
              ],
            ),
          ),
        ),
      ],
    );
  }

  // زر الإجراء
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,textStyle: TextStyle( color: AppColors.onPrimary,
         fontFamily: AppTextStyles.appFontFamily,
                           fontSize: AppTextStyles.medium,),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 14.w, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // بناء قسم الصورة
  Widget _buildImageSection(double height, {required bool isGrid, required bool isDarkMode}) {
    return ClipRRect(
      borderRadius: isGrid 
          ? BorderRadius.vertical(top: Radius.circular(12.r))
          : BorderRadius.horizontal(left: Radius.circular(12.r)),
      child: Stack(
        children: [
          // الصورة الرئيسية
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
                      size: 50.w,
                      color: AppColors.grey,
                    ),
                  ),
          ),
          
          // شارة الإعلان المميز
          if (ad.is_premium == true)
            Positioned(
              top: 4.w,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 18.w, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      'مميز'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
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

  // تأكيد الحذف
  Future<void> _confirmDelete(int adId, ManageAdController adsController) async {
    final confirmed = await Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف', style: TextStyle(fontSize: 20.sp)),
        content: Text('هل أنت متأكد أنك تريد حذف هذا الإعلان؟ سيتم حذفه نهائياً.', 
          style: TextStyle(fontSize: 16.sp)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: TextStyle(fontSize: 16.sp)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text('حذف', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      adsController.deleteAd(adId);
    }
  }

  // تعديل الإعلان
  void _editAd(Ad ad) {
   
   Get.to(()=> EditAdScreenDeskTop(adId:ad.id));
   
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'قبل ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
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
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h), // تصغير الحشوة
      decoration: BoxDecoration(
        color: AppColors.card(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
         fontSize: AppTextStyles.small, // تصغير حجم الخط
          color: AppColors.textSecondary(themeController.isDarkMode.value),
        ),
      ),
    );
  }
}
  // دالة لبناء عنصر إحصائية
  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required bool isDarkMode
  }) {
    return Row(
      children: [
        Icon(icon, size: 17.sp, color: AppColors.primary),
        SizedBox(width: 4.h),
        Text(
          _formatStatValue(value),
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
           fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(width: 2.h),
        Text(
          label.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
           fontSize: AppTextStyles.small,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    );
  }

  // دالة لتنسيق قيمة الإحصائية
  String _formatStatValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
