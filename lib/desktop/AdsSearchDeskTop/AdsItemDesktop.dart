import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tappuu_website/controllers/CurrencyController.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/areaController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/data/model/AdResponse.dart';

import '../AdDetailsScreenDeskTop/AdDetailsScreen_desktop.dart';

class AdsItemDesktop extends StatefulWidget {
  final Ad ad;
  final String viewMode;

  const AdsItemDesktop({
    super.key,
    required this.ad,
    required this.viewMode,
  });

  @override
  State<AdsItemDesktop> createState() => _AdsItemDesktopState();
}

class _AdsItemDesktopState extends State<AdsItemDesktop> {
  late final ThemeController _themeController;
  late final CurrencyController _currencyController;
  late final AreaController _areaController;
  bool _isImageLoaded = false;
  ImageProvider? _imageProvider;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _themeController = Get.find<ThemeController>();
    _currencyController = Get.put(CurrencyController());
    _areaController = Get.find<AreaController>();
    _loadImage();
  }

  void _loadImage() {
    if (widget.ad.images.isEmpty) {
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
      return;
    }
    
    try {
      final imageUrl = widget.ad.images.first;
      _imageProvider = CachedNetworkImageProvider(
        imageUrl,
        cacheKey: '${widget.ad.id}_thumbnail',
        maxWidth: widget.viewMode == 'grid' ? 300 : 400,
      );
      
      final config = ImageConfiguration.empty;
      _imageStream = _imageProvider!.resolve(config);
      
      _imageListener = ImageStreamListener(
        (ImageInfo info, bool syncCall) {
          if (mounted) {
            setState(() => _isImageLoaded = true);
          }
        },
        onError: (Object exception, StackTrace? stackTrace) {
          if (mounted) {
            setState(() => _isImageLoaded = true);
          }
        }
      );
      
      _imageStream!.addListener(_imageListener!);
    } catch (e) {
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    // إلغاء أي عمليات جارية عند التخلص من العنصر
    _imageStream?.removeListener(_imageListener!);
    _imageProvider?.evict();
    
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return 'قبل ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'قبل ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  void _openAdDetails() {
     final ad = widget.ad;
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});



  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final areaName = _areaController.getAreaNameById(widget.ad.areaId);
    final cityName = widget.ad.city?.name ?? 'دمشق';
    


    
    return InkWell(
      onTap: _openAdDetails,
      child: widget.viewMode == 'grid' 
          ? _buildGridItem(isDarkMode, areaName, cityName)
          : _buildListItem(isDarkMode, areaName, cityName),
    );
  }


  Widget _buildGridItem(bool isDarkMode, String? areaName, String cityName) {
          final bool isPremium = _isPremiumByPackage;

   
    return Container(
      decoration: BoxDecoration(
        color:isPremium?const Color.fromARGB(255, 237, 202, 24).withOpacity(0.2)
:        
     
         AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(100.h, isGrid: true),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
               if (widget.ad.price != null)
                    Text(
                      _currencyController.formatPrice(widget.ad.price!),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, 
                        size: 12.sp,
                        color: AppColors.textSecondary(isDarkMode)),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                                '${widget.ad.city?.name??""}, ${widget.ad.area?.name??""}',
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
              ],
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildListItem(bool isDarkMode, String? areaName, String cityName) {
       final bool isPremium = _isPremiumByPackage;

   
   
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isPremium?const Color.fromARGB(255, 237, 202, 24).withOpacity(0.2)
:        
     
         AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                bottomLeft: Radius.circular(8.r)),
              color: AppColors.grey.withOpacity(0.1),
            ),
            child: _buildImageSection(120.h, isGrid: false),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 7.h),
                  Text(
                    widget.ad.title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                     fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  if (widget.ad.price != null)
                    Text(
                      _currencyController.formatPrice(widget.ad.price!),
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
                          size: 12.sp,
                          color: AppColors.textSecondary(isDarkMode)),
                      SizedBox(width: 4.w),
                      Text(
                                '${widget.ad.city?.name??""}, ${widget.ad.area?.name??""}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.small,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  // ------------------------------
  // PREMIUM BADGE — يدعم الوضع الداكن بخيارات ألوان مناسبة
  Widget _buildPremiumBadge() {
    if (! _isPremiumByPackage) {
      return Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h));
    }

    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [Color(0xFFFFD186), Color(0xFFFFB74D)]
        : [
            AppColors.PremiumColor,
            const Color.fromARGB(246, 235, 235, 225).withOpacity(0.1),
            AppColors.PremiumColor,
          ];

    final textColor = isDark ? Colors.black87 : Colors.grey[700];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        'Premium offer',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: 9.2.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }


  Widget _buildImageSection(double height, {required bool isGrid}) {
   
          final bool isPremium = _isPremiumByPackage;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: isGrid 
            ? BorderRadius.vertical(top: Radius.circular(8.r))
            : BorderRadius.horizontal(left: Radius.circular(8.r)),
        color: AppColors.grey.withOpacity(0.1),
      ),
      child: Stack(
        children: [
          if (widget.ad.images.isNotEmpty && _imageProvider != null && _isImageLoaded)
            Image(
              image: _imageProvider!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
            )
          else if (!_isImageLoaded)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 1.5,
              ),
            )
          else
            Center(
              child: Icon(
                Icons.image_not_supported,
                size: 30.w,
                color: AppColors.grey,
              ),
            ),
          
           Visibility(
                              visible:widget. ad.show_time == 1,
                              child:  // تاريخ الإنشاء
            Positioned(
              top: 4.w,
              left: 4.w,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
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
           )),

            // Premium badge
            if (     isPremium  )

              Positioned(
                top: 4.w,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 4.w, vertical: 0.8.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 3)
                    ],
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
          if (widget.ad.images.length > 1)
            Positioned(
              bottom: 4.w,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${widget.ad.images.length}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.small,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

