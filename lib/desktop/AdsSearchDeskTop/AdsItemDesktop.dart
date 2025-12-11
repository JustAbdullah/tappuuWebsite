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

class AdsItemDesktop extends StatefulWidget {
  final Ad ad;
  final String viewMode; // 'grid' أو 'list'

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
  bool _isHovered = false;

  ImageProvider? _imageProvider;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();

    _themeController = Get.find<ThemeController>();
    _areaController = Get.find<AreaController>();

    if (Get.isRegistered<CurrencyController>()) {
      _currencyController = Get.find<CurrencyController>();
    } else {
      _currencyController = Get.put(CurrencyController());
    }

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
        },
      );

      _imageStream!.addListener(_imageListener!);
    } catch (_) {
      if (mounted) {
        setState(() => _isImageLoaded = true);
      }
    }
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageProvider?.evict();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays > 0) {
      return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    }
    if (diff.inHours > 0) {
      return 'قبل ${diff.inHours} ساعة';
    }
    if (diff.inMinutes > 0) {
      return 'قبل ${diff.inMinutes} دقيقة';
    }
    return 'الآن';
  }

  void _openAdDetails() {
    Get.toNamed(
      '/ad-details-direct',
      arguments: {'ad': widget.ad},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = _themeController.isDarkMode.value;
    final bool isGrid = widget.viewMode == 'grid';

    final String cityName = widget.ad.city?.name ?? '';
    final String areaName = widget.ad.area?.name ?? '';
    final String locationText = (cityName.isNotEmpty && areaName.isNotEmpty)
        ? '$cityName، $areaName'
        : cityName.isNotEmpty
            ? cityName
            : areaName;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(bottom: isGrid ? 0 : 10.h),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _cardBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: _isPremiumByPackage
                ? AppColors.PremiumColor.withOpacity(_isHovered ? 0.9 : 0.7)
                : Colors.black.withOpacity(0.04),
            width: _isPremiumByPackage ? 1.2 : 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 12 : 5,
              spreadRadius: 0.5,
              offset: Offset(0, _isHovered ? 5 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAdDetails,
            child: isGrid
                ? _buildGridContent(isDarkMode, locationText)
                : _buildListContent(isDarkMode, locationText),
          ),
        ),
      ),
    );
  }

  Color _cardBackgroundColor(bool isDarkMode) {
    if (_isPremiumByPackage) {
      // كرت أصفر واضح للمميز
      return isDarkMode
          ? const Color(0xFF5A4A00) // أصفر غامق في الداكن
          : const Color(0xFFFFF4B3); // أصفر فاتح قوي في الفاتح
    }
    return AppColors.card(isDarkMode);
  }

  // ========================= GRID (شبكة – كرت عمودي) =========================
  Widget _buildGridContent(bool isDarkMode, String locationText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الصورة تأخذ جزء مرن من ارتفاع الكرت -> لا Overflow
        Expanded(
          flex: 5,
          child: _buildImageSection(
            isGrid: true,
            showTimeOverlay: true,
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // العنوان
                Text(
                  widget.ad.title,
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

                // السعر (لو موجود)
                if (widget.ad.price != null)
                  Text(
                    _currencyController.formatPrice(widget.ad.price!),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                // الموقع
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12.sp,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        locationText,
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
        ),
      ],
    );
  }

  // ========================= LIST (كرت أفقي) =========================
  Widget _buildListContent(bool isDarkMode, String locationText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الصورة يسار/يمين حسب الاتجاه
        SizedBox(
          width: 150.w,
          height: 130.h,
          child: _buildImageSection(
            isGrid: false,
            showTimeOverlay: false,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 10.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // العنوان
                Text(
                  widget.ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (widget.ad.price != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      _currencyController.formatPrice(widget.ad.price!),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.sp,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          locationText,
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
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.ad.show_time == 1) _buildTimeChip(isDarkMode),
                    
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.grey.withOpacity(isDarkMode ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 11.sp,
            color: AppColors.textSecondary(isDarkMode),
          ),
          SizedBox(width: 3.w),
          Text(
            _formatDate(widget.ad.createdAt),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.small,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= IMAGE SECTION =========================
  Widget _buildImageSection({
    required bool isGrid,
    required bool showTimeOverlay,
  }) {
    final bool isPremium = _isPremiumByPackage;

    return ClipRRect(
      borderRadius: isGrid
          ? BorderRadius.vertical(top: Radius.circular(10.r))
          : BorderRadius.horizontal(left: Radius.circular(10.r)),
      child: Container(
        color: AppColors.grey.withOpacity(0.08),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageProvider != null)
              AnimatedOpacity(
                opacity: _isImageLoaded ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Image(
                  image: _imageProvider!,
                  fit: BoxFit.cover,
                ),
              ),
            if (!_isImageLoaded)
              Center(
                child: SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                  ),
                ),
              )
            else if (_imageProvider == null)
              Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 30.w,
                  color: AppColors.grey,
                ),
              ),

            if (showTimeOverlay && widget.ad.show_time == 1)
              Positioned(
                top: 5.w,
                left: 5.w,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10.r),
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

            if (isPremium)
              Positioned(
                top: 5.w,
                right: 5.w,
                child: _buildPremiumBadge(),
              ),

         
          ],
        ),
      ),
    );
  }

  // ========================= PREMIUM LOGIC =========================
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

            expiresAt = _parseDateSafe(
              p['expires_at'] ?? p['expiresAt'],
            );

            premiumPackage =
                p['premium_package'] ?? p['premiumPackage'];
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
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
    return false;
  }

  Widget _buildPremiumBadge() {
    if (!_isPremiumByPackage) {
      return const SizedBox.shrink();
    }

    final bool isDark = _themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [const Color(0xFFFFD186), const Color(0xFFFFB74D)]
        : [
            AppColors.PremiumColor,
            const Color(0xFFFFE9A7),
          ];

    final Color textColor = isDark ? Colors.black87 : Colors.grey[800]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 11.sp,
            color: Colors.white,
          ),
          SizedBox(width: 3.w),
          Text(
            'مميز'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
