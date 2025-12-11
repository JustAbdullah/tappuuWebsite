import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:tappuu_website/core/constant/app_text_styles.dart';
import '../../../controllers/AdsManageSearchController.dart';
import '../../../controllers/CurrencyController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AdResponse.dart';

class LatestAdsSectionDestop extends StatelessWidget {
  final AdsController adsController;

  // نجهز الكنترولرات مرّة واحدة
  final ThemeController _themeController = Get.find<ThemeController>();
  final CurrencyController _currencyController =
      Get.put(CurrencyController(), permanent: true);

  LatestAdsSectionDestop({super.key, required this.adsController});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = _themeController.isDarkMode.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================
        //      HEADER بسيط
        // =========================
        Padding(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 4.w,
            bottom: 6.h,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أيقونة داخل حاوية بسيطة
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.buttonAndLinksColor.withOpacity(
                    isDarkMode ? 0.22 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  size: 18.w,
                  color: AppColors.buttonAndLinksColor,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'أحدث الإعلانات'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),

        // =========================
        //         المحتوى
        // =========================
        Obx(() {
          if (adsController.isLoadingAdsLatest.value) {
            return _buildLatestShimmerDesktop(isDarkMode);
          }

          final adsList = adsController.adsListLatest;

          // لا توجد إعلانات حديثة / أو فشل في التحميل
          if (adsList.isEmpty) {
            return _buildLatestEmptyState(
              isDarkMode: isDarkMode,
              onRetry: () => adsController.fetchLatestAds(),
            );
          }

          return SizedBox(
            height: 155.h,
            child: ListView.builder(
              cacheExtent: 1000,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: adsList.length,
              itemBuilder: (context, index) {
                final ad = adsList[index];
                return LatestAdItem(
                  key: ValueKey(ad.id),
                  ad: ad,
                  isDarkMode: isDarkMode,
                  currencyController: _currencyController,
                );
              },
            ),
          );
        }),
      ],
    );
  }

  /// واجهة احترافية عند عدم وجود إعلانات / فشل التحميل
  Widget _buildLatestEmptyState({
    required bool isDarkMode,
    required VoidCallback onRetry,
  }) {
    return SizedBox(
      height: 155.h,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.grey.withOpacity(isDarkMode ? 0.35 : 0.22),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة احترافية
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.buttonAndLinksColor.withOpacity(
                    isDarkMode ? 0.15 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.history_toggle_off_rounded,
                  size: 24.w,
                  color: AppColors.buttonAndLinksColor,
                ),
              ),
              SizedBox(width: 12.w),

              // النص + زر إعادة المحاولة
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لا توجد إعلانات حديثة حالياً'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'قد لا توجد إعلانات جديدة في هذه اللحظة، أو قد يكون اتصالك بالإنترنت محدوداً.'
                          .tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onRetry,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 14.sp,
                        ),
                        label: Text(
                          'إعادة المحاولة'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.small,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.buttonAndLinksColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestShimmerDesktop(bool isDarkMode) {
    final base = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlight = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return SizedBox(
      height: 155.h,
      child: ListView.builder(
        cacheExtent: 1000,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: 7,
        itemBuilder: (_, __) {
          return Container(
            width: 145.w,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الصورة الوهمية
                  Container(
                    height: 78.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // عنوان
                  Container(
                    height: 10.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // سطر السعر
                  Container(
                    height: 10.h,
                    width: 65.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LatestAdItem extends StatefulWidget {
  final Ad ad;
  final bool isDarkMode;
  final CurrencyController currencyController;

  const LatestAdItem({
    Key? key,
    required this.ad,
    required this.isDarkMode,
    required this.currencyController,
  }) : super(key: key);

  @override
  State<LatestAdItem> createState() => _LatestAdItemState();
}

class _LatestAdItemState extends State<LatestAdItem>
    with AutomaticKeepAliveClientMixin {
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
      final file =
          await DefaultCacheManager().getSingleFile(widget.ad.images.first);
      if (!mounted) return;
      setState(() {
        _imageProvider = FileImage(file);
        _imageLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
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
        try {
          return DateTime.parse(v.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  bool get _isPremiumByPackage {
    try {
      if (widget.ad.packages == null || widget.ad.packages.isEmpty) {
        return false;
      }
      final now = DateTime.now();

      for (final dynamic p in widget.ad.packages) {
        try {
          bool isActive = false;
          DateTime? expiresAt;
          dynamic premiumPackage;

          if (p is AdPackage) {
            isActive = p.isActive;
            expiresAt = p.expiresAt;
            premiumPackage = p.premiumPackage;
          } else if (p is Map) {
            isActive = (p['is_active'] == true) ||
                (p['is_active'] == 1) ||
                (p['isActive'] == true) ||
                (p['isActive'] == 1);
            expiresAt = _parseDateSafe(p['expires_at'] ?? p['expiresAt']);
            premiumPackage = p['premium_package'] ?? p['premiumPackage'];
          } else {
            continue;
          }

          if (!isActive) continue;
          if (expiresAt == null) continue;
          if (!expiresAt.isAfter(now)) continue;

          int? typeId;

          if (premiumPackage == null) {
            continue;
          } else if (premiumPackage is PremiumPackage) {
            typeId = premiumPackage.packageTypeId ?? premiumPackage.type?.id;
          } else if (premiumPackage is Map) {
            final dynamic rawTypeId = premiumPackage['package_type_id'] ??
                premiumPackage['packageTypeId'] ??
                premiumPackage['type']?['id'];
            if (rawTypeId != null) {
              typeId = int.tryParse(rawTypeId.toString());
            }
          } else if (premiumPackage is int) {
            typeId = premiumPackage;
          }

          if (typeId != null && typeId == 1) {
            return true;
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // رجّع false لو صار أي خطأ عام
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isPremium = _isPremiumByPackage;
    final bool isDarkMode = widget.isDarkMode;
    final currency = widget.currencyController;

    return RepaintBoundary(
      child: SizedBox(
        height: 155.h,
        child: InkWell(
          onTap: () {
            final ad = widget.ad;
            Get.toNamed(
              '/ad-details-direct',
              arguments: {'ad': ad},
            );
          },
          child: Container(
            width: 145.w,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10.r),
                      ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
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
                              Icon(
                                Icons.location_on,
                                size: 9.sp,
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  '${widget.ad.city?.name ?? ""}, ${widget.ad.area?.name ?? ""}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: 10.5.sp,
                                    color:
                                        AppColors.textSecondary(isDarkMode),
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

                // تاريخ الإنشاء
                if (widget.ad.show_time == 1)
                  Positioned(
                    top: 4.w,
                    left: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.5.h,
                      ),
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
                  ),

                // Premium badge لو الإعلان نفسه مميز
                if (isPremium)
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 8.w,
                            color: Colors.white,
                          ),
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
