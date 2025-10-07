import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/data/model/AdResponse.dart';
import 'package:tappuu_website/controllers/AdsManageSearchController.dart';
import 'package:tappuu_website/controllers/CurrencyController.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';

class CategoryAdsSectionDeskTop extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  final AdsController adsController;

  const CategoryAdsSectionDeskTop({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    required this.adsController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with category badge
   Padding(
  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
  child: Wrap(
    spacing: 10.w,
    runSpacing: 6.h,
    children: [
      // Tag 1 – إعلانات (أوتلاين خفيف)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.buttonAndLinksColor.withOpacity(0.04)
              : AppColors.buttonAndLinksColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: AppColors.buttonAndLinksColor,
            width: 1.2,
          ),
        ),
        child: Text(
          'إعلانات'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
           fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      ),

      // Tag 2 – اسم القسم (مفعّل بجرادينت)
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.buttonAndLinksColor.withOpacity(0.8),
              AppColors.buttonAndLinksColor.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.buttonAndLinksColor.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          categoryName,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
           fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
),




        // Content
        Obx(() {
          final isLoading = adsController.isLoadingCategoryMap[categoryId] ?? false;
          final adsList = adsController.categoryAdsMap[categoryId] ?? [];

          if (isLoading) {
            return _buildShimmer(isDarkMode);
          }
          if (adsList.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Text(
                'لا توجد إعلانات في $categoryName',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            );
          }

          return SizedBox(
            height: 155.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              itemCount: adsList.length,
              itemBuilder: (ctx, i) => AdItem(
                ad: adsList[i],
                key: ValueKey(adsList[i].id),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShimmer(bool isDarkMode) {
    final base = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SizedBox(
      height: 155.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        itemCount: 7,
        itemBuilder: (_, __) {
          return Container(
            width: 145.w,
            margin: EdgeInsets.symmetric(horizontal: 7.w),
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 78.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                  )),
                  SizedBox(height: 6.h),
                  Container(height: 10.h, width: double.infinity, color: Colors.white),
                  SizedBox(height: 4.h),
                  Container(height: 10.h, width: 65.w, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdItem extends StatefulWidget {
  final Ad ad;
  const AdItem({Key? key, required this.ad}) : super(key: key);

  @override
  State<AdItem> createState() => _AdItemState();
}

class _AdItemState extends State<AdItem> with AutomaticKeepAliveClientMixin {
  ImageProvider? _imageProvider;
  bool _imageLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() async {
    if (widget.ad.images.isEmpty) return;
    
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.ad.images.first);
      setState(() {
        _imageProvider = FileImage(file);
        _imageLoaded = true;
      });
    } catch (e) {
      setState(() {
        _imageProvider = CachedNetworkImageProvider(widget.ad.images.first);
        _imageLoaded = true;
      });
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return 'قبل ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'قبل ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
  // Helper: parse possible date strings safely
  DateTime? _parseDateSafe(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v).toLocal();
      } catch (_) {
        // حاول تنسيقات بديلة أو تجاهل
        try {
          return DateTime.parse(v.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
  // ------------------------------
  // Core rule: "مميز" يعتمد حصراً على ad.packages
  // شرط أن يوجد سجل packages where:
  //  - is_active == true (أو 1)
  //  - expires_at in future
  //  - premium_package.package_type_id == 1
bool get _isPremiumByPackage {
  try {
    if (widget. ad.packages == null ||widget. ad.packages.isEmpty) return false;
    final now = DateTime.now();

    for (final dynamic p in widget. ad.packages) {
      try {
        // --- احصل على isActive و expiresAt و premiumPackage بأمان سواء p هو AdPackage أو Map ---
        bool isActive = false;
        DateTime? expiresAt;
        dynamic premiumPackage;

        if (p is AdPackage) {
          isActive = p.isActive;
          expiresAt = p.expiresAt;
          premiumPackage = p.premiumPackage;
        } else if (p is Map) {
          isActive = (p['is_active'] == true) || (p['is_active'] == 1) || (p['isActive'] == true) || (p['isActive'] == 1);
          expiresAt = _parseDateSafe(p['expires_at'] ?? p['expiresAt']);
          premiumPackage = p['premium_package'] ?? p['premiumPackage'];
        } else {
          // نوع غير متوقع -> نتجاهل
          continue;
        }

        if (!isActive) continue;
        if (expiresAt == null) continue;
        if (!expiresAt.isAfter(now)) continue;

        // --- اكتشاف نوع الباقة (package_type_id) بعدة طرق ---
        int? typeId;

        if (premiumPackage == null) {
          continue;
        } else if (premiumPackage is PremiumPackage) {
          typeId = premiumPackage.packageTypeId ?? premiumPackage.type?.id;
        } else if (premiumPackage is Map) {
          final dynamic rawTypeId = premiumPackage['package_type_id'] ?? premiumPackage['packageTypeId'] ?? premiumPackage['type']?['id'];
          if (rawTypeId != null) typeId = int.tryParse(rawTypeId.toString());
        } else if (premiumPackage is int) {
          typeId = premiumPackage;
        }

        // لو وجدنا typeId == 1 => إعلان مميز
        if (typeId != null && typeId == 1) {
          // debug: لاحظ أنه يمكنك تفعيل الطباعة أثناء الاختبار
          // print('Found premium package for ad ${ad.id}, package type: $typeId, expiresAt: $expiresAt');
          return true;
        }
      } catch (e) {
        // تجاهل هذا العنصر واستمر في الباقي
        continue;
      }
    }
  } catch (e) {
    // لو صار خطأ نلّف ونرجع false
  }
  return false;
}


  @override
  Widget build(BuildContext context) {
    super.build(context);
          final bool isPremium = _isPremiumByPackage;

    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final currency = Get.find<CurrencyController>();
    final city = widget.ad.city;

    return RepaintBoundary(
      child: SizedBox(
        height: 155.h,
        child: InkWell(
     onTap: (){
     final ad = widget.ad;
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});
},


          child: Container(
            width: 145.w,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppColors.surface(isDarkMode),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image + Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصورة
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                      child: Container(
                        height: 78.h,
                        width: double.infinity,
                        color: AppColors.grey.withOpacity(0.2),
                        child: _imageLoaded && _imageProvider != null
                            ? Image(
                                image: _imageProvider!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.buttonAndLinksColor,
                                ),
                              ),
                      ),
                    ),

                    // بيانات الإعلان
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                             fontSize: AppTextStyles.medium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkMode),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          if (widget.ad.price != null)
                            Text(
                              currency.formatPrice(widget.ad.price!),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                               fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 9.sp,
                                  color: AppColors.textSecondary(isDarkMode)),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                                                  '${widget.ad.city?.name??""}, ${widget.ad.area?.name??""}',

                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: 10.5.sp,
                                    color: AppColors.textSecondary(isDarkMode),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
 Visibility(
                              visible: widget. ad.show_time == 1,
                              child: 
                // تاريخ الإنشاء
                Positioned(
                  top: 4.w,
                  left: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _formatDate(widget.ad.createdAt),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                       fontSize: AppTextStyles.small,
                        color: Colors.white,
                      ),
                    ),
                  ),
  ) ),

              if (     isPremium  )   // Premium badge
                Positioned(
                  top: 4.w,
                  right: 4.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 8.w, color: Colors.white),
                        SizedBox(width: 1.5.w),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}