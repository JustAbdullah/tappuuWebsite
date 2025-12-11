import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_website/desktop/SettingsDeskTop/UsersAdsDeskTop/EditAdScreenDeskTop.dart';
import 'package:tappuu_website/core/data/model/PremiumPackage.dart' as prm;

import '../../../controllers/AdsManageController.dart';
import '../../../controllers/CardPaymentController.dart';
import '../../../controllers/PremiumPackageController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AdResponse.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/data/model/UserWallet.dart';

class AdStatisticsScreenWeb extends StatefulWidget {
  final Ad ad;

  const AdStatisticsScreenWeb({super.key, required this.ad});

  @override
  State<AdStatisticsScreenWeb> createState() => _AdStatisticsScreenWebState();
}

class _AdStatisticsScreenWebState extends State<AdStatisticsScreenWeb> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null);
  }

  // ---------- Helpers: parsing & formatting ----------
  DateTime? _parseDateSafe(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
      } catch (_) {
        return null;
      }
    }
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

  String _formatDetailedDateFromDynamic(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    String formattedDate = dateFormat.format(dt);
    String formattedTime = timeFormat.format(dt).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    return '$formattedDate - $formattedTime';
  }

  String _formatShortDateFromDynamic(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final df = DateFormat.yMd('ar');
    return df.format(dt);
  }

  String _formatRelative(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays >= 1) return 'ينتهي بعد ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'ينتهي بعد ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'ينتهي بعد ${diff.inMinutes} دقيقة';
    return 'قريبًا';
  }

  // ---------- defensive read helpers ----------
  List<dynamic> _rawPackages() {
    try {
      final pk = widget.ad.packages;
      if (pk == null) return [];
      if (pk is List) return pk;
      if (pk is String) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _getAllPackages() {
    final raw = _rawPackages();
    final List<Map<String, dynamic>> out = [];
    for (final e in raw) {
      if (e == null) continue;
      if (e is Map<String, dynamic>) out.add(e);
      else if (e is Map) out.add(Map<String, dynamic>.from(e));
      else {
        try {
          final json = (e as dynamic).toJson();
          if (json is Map) out.add(Map<String, dynamic>.from(json));
        } catch (_) {}
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _getActivePackages() {
    final now = DateTime.now();
    return _getAllPackages().where((p) {
      try {
        final isActiveRaw = p['is_active'];
        final isActive = (isActiveRaw == true) || (isActiveRaw == 1) || (isActiveRaw == '1') || (isActiveRaw == 'true');
        if (!isActive) return false;
        final expires = _parseDateSafe(p['expires_at']);
        if (expires == null) return false;
        return expires.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  bool get _hasPremiumType1 {
    final active = _getActivePackages();
    for (final p in active) {
      final premium = p['premium_package'] ?? p['premiumPackage'];
      if (premium == null) continue;
      final typeId = premium['package_type_id'] ?? (premium['type']?['id']);
      final parsed = int.tryParse(typeId?.toString() ?? '');
      if (parsed != null && parsed == 1) return true;
    }
    return false;
  }

  String _packageTypeLabel(dynamic packageTypeId) {
    final id = int.tryParse(packageTypeId?.toString() ?? '') ?? 0;
    switch (id) {
      case 1:
        return 'مميز';
      case 2:
        return 'عرض مميز';
      case 3:
        return 'متجدد';
      default:
        return 'باقه';
    }
  }

  Color _packageTypeColor(dynamic packageTypeId) {
    final id = int.tryParse(packageTypeId?.toString() ?? '') ?? 0;
    switch (id) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.deepPurple;
      case 3:
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    final HomeController _homeController = Get.find<HomeController>();

    final allPackages = _getAllPackages();
    final activePackages = _getActivePackages();
    final hasAny = allPackages.isNotEmpty;
    final hasActive = activePackages.isNotEmpty;

    return Scaffold(     
        key: _scaffoldKey,
    endDrawer: Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _homeController.drawerType.value == DrawerType.settings
            ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
            : const DesktopServicesDrawer(key: ValueKey('services')),
      ),
    ),
        backgroundColor: AppColors.background(themeController.isDarkMode.value),
      body: Column(
        children: [  
            TopAppBarDeskTop(),
      SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey,),
         SizedBox(height: 20.h,),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1200.w, minHeight: 800.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // بطاقة معلومات الإعلان
                      _buildAdInfoCard(isDarkMode),
                      
                      SizedBox(height: 20.h),
                      
                      // بطاقة حالة النشر
                      _buildPublishStatusCard(isDarkMode),
                      
                      SizedBox(height: 20.h),
                      
                      // بطاقة الإحصائيات
                      _buildStatisticsCard(isDarkMode),
                      
                      SizedBox(height: 20.h),
                      
                      // بطاقة حالة البريميوم
                      _buildPremiumCard(isDarkMode, allPackages, activePackages, hasAny, hasActive),
                      
                      SizedBox(height: 20.h),
                      
                      // بطاقة الأزرار
                      _buildActionsCard(isDarkMode),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة معلومات الإعلان
  Widget _buildAdInfoCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الإعلان'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 16.h),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الجزء الأيسر: المعلومات النصية
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Text(
                      widget.ad.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    // الوصف
                    if (widget.ad.description.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ad.description,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                             fontSize: AppTextStyles.medium,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    
                    // السعر
                    if (widget.ad.price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: _formatPrice(widget.ad.price!),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              children: [
                                TextSpan(
                                  text: ' ليرة سورية'.tr,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.medium,
                                    fontWeight: FontWeight.normal,
                                    color: AppColors.textSecondary(isDarkMode),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    
                    // تاريخ الإنشاء
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16.sp, color: AppColors.grey),
                        SizedBox(width: 8.w),
                        Text(
                          'نشر في ${_formatDetailedDate(widget.ad.createdAt)}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                           fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // الجزء الأيمن: صورة الإعلان
              if (widget.ad.images.isNotEmpty)
                Container(
                  width: 250.w,
                  height: 250.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(
                      widget.ad.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.grey.withOpacity(0.2),
                        child: Icon(Icons.image_not_supported, size: 32.sp, color: AppColors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // بطاقة حالة النشر
  Widget _buildPublishStatusCard(bool isDarkMode) {
    // تحديد لون ورمز حالة النشر
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (widget.ad.status) {
      case 'published':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'منشور';
        break;
      case 'under_review':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'تحت المراجعة';
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'منتهي الصلاحية';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'غير معروف';
    }
    
    return Container(
      alignment: Alignment.center,
      width: 700.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 20.sp,
              color: statusColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة النشر'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusText.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.ad.status == 'under_review') ...[
            Icon(
              Icons.info,
              size: 14.sp,
              color: AppColors.textSecondary(isDarkMode),
            ),
            SizedBox(width: 8.w),
            Text(
              'جاري المراجعة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
               fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // بطاقة الإحصائيات
  Widget _buildStatisticsCard(bool isDarkMode) {
    return Container(
      width:300.w,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات الإعلان'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.remove_red_eye,
                value: widget.ad.views,
                label: 'مشاهدة',
                isDarkMode: isDarkMode
              ),
              
              _buildStatCard(
                icon: Icons.favorite,
                value: widget.ad.favorites_count ?? 0,
                label: 'مفضلة',
                isDarkMode: isDarkMode
              ),
              
              _buildStatCard(
                icon: Icons.chat,
                value: widget.ad.inquirers_count ?? 0,
                label: 'تواصل',
                isDarkMode: isDarkMode
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بطاقة إحصائية
  Widget _buildStatCard({
    required IconData icon,
    required int value,
    required String label,
    required bool isDarkMode
  }) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 5.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: AppColors.primary),
          SizedBox(height: 8.h),
          Text(
            _formatStatValue(value),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label.tr,
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

  // بطاقة حالة البريميوم
  Widget _buildPremiumCard(bool isDarkMode, List<Map<String, dynamic>> allPackages, List<Map<String, dynamic>> activePackages, bool hasAny, bool hasActive) {
    final borderColor = hasActive ? Colors.amber : (hasAny ? AppColors.primary : AppColors.grey.withOpacity(0.3));

    return Container(
      alignment: Alignment.center,
      width: 700.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: hasActive ? Colors.amber.withOpacity(0.2) : AppColors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasActive ? Icons.star : Icons.star_outline,
                  size: 20.sp,
                  color: hasActive ? Colors.amber : AppColors.grey,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                hasActive ? 'باقات نشطة' : (hasAny ? 'باقات مسجلة' : 'لا توجد باقات'),
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: hasActive ? Colors.amber : AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          Text(
            'هنا تظهر الباقات المسجلة للإعلان، الحالة وتاريخ الانتهاء.'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
             fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          SizedBox(height: 12.h),

          if (!hasAny) ...[
            Center(
              child: Text(
                'لا توجد باقات مسجلة لهذا الإعلان'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                Get.to(() => PremiumPackagesScreenWeb(adTitle: widget.ad.title, adId: widget.ad.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                minimumSize: Size(double.infinity, 44.h),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('إنشاء/شراء باقة لهذا الإعلان'.tr,
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp)),
                ],
              ),
            ),
          ] else ...[
            // القائمة: كل الباقات (تفصيل فقط، بلا أزرار خاصة لكل باقة)
            Column(
              children: [
                ...allPackages.map((p) {
                  final premium = (p['premium_package'] ?? p['premiumPackage']) as dynamic;
                  final packageName = (premium != null ? (premium['name'] ?? premium['title'] ?? premium['type']?['name']) : null) ?? 'باقه';
                  final packagePrice = (premium != null ? (premium['price'] ?? '') : '');
                  final duration = premium != null ? (premium['duration_days'] ?? '-') : '-';
                  final packageTypeId = premium != null ? (premium['package_type_id'] ?? (premium['type']?['id'])) : null;
                  final typeLabel = _packageTypeLabel(packageTypeId);
                  final typeColor = _packageTypeColor(packageTypeId);
                  final isActiveRaw = p['is_active'];
                  final isActive = (isActiveRaw == true) || (isActiveRaw == 1) || (isActiveRaw == '1') || (isActiveRaw == 'true');
                  final startedAt = p['started_at'];
                  final expiresAt = p['expires_at'];
                  final expiresDt = _parseDateSafe(expiresAt);
                  final isExpired = expiresDt == null ? true : !expiresDt.isAfter(DateTime.now());

                  return Container(
                    key: ValueKey(p['id'] ?? p.hashCode),
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface(isDarkMode),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: isActive ? typeColor.withOpacity(0.12) : AppColors.grey.withOpacity(0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: details (expandable)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: typeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      packageName.toString(),
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // price + duration in vertical layout to avoid horizontal overflow
                              Wrap(
                                spacing: 12.w,
                                runSpacing: 6.h,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'السعر: '.tr,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          color: AppColors.textSecondary(isDarkMode),
                                        ),
                                      ),
                                      Text(
                                        '${packagePrice ?? '-'}',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'المدة: '.tr,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          color: AppColors.textSecondary(isDarkMode),
                                        ),
                                      ),
                                      Text(
                                        '$duration يوم',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14.sp, color: AppColors.textSecondary(isDarkMode)),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      'من: ${startedAt != null ? _formatShortDateFromDynamic(startedAt) : '-'}',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: AppColors.textSecondary(isDarkMode),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Flexible(
                                    child: Text(
                                      'حتى: ${expiresAt != null ? _formatShortDateFromDynamic(expiresAt) : '-'}',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: isExpired ? Colors.red : AppColors.textSecondary(isDarkMode),
                                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right: status (compact)
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: isActive ? typeColor.withOpacity(0.12) : AppColors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                isActive ? 'نشطة' : (isExpired ? 'منتهية' : 'غير نشطة'),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: isActive ? typeColor : AppColors.textSecondary(isDarkMode),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _formatRelative(expiresAt),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),

                SizedBox(height: 12.h),

                // common actions (single renew/manage buttons)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(() => PremiumPackagesScreenWeb(adTitle: widget.ad.title, adId: widget.ad.id));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasActive ? Colors.amber : AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          minimumSize: Size(double.infinity, 44.h),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(hasActive ? Icons.autorenew : Icons.add, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(hasActive ? 'تجديد الباقات'.tr : 'ترقية/شراء باقات'.tr,
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // بطاقة أزرار التحكم
  Widget _buildActionsCard(bool isDarkMode) {
    ManageAdController _manage = Get.find<ManageAdController>();

    return Container(
      alignment: Alignment.center,
      width: 400.w,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.ad.status == 'published')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit, size: 20.sp),
                label: Text('تعديل الإعلان'.tr,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 15.sp)),
                onPressed: () {
                  Get.to(() => EditAdScreenDeskTop(adId: widget.ad.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonAndLinksColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          
          SizedBox(height: 12.h),
          
          // زر الحذف
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.delete, size: 20.sp),
              label: Text('حذف الإعلان'.tr,
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 15.sp)),
              onPressed: () async {
                final confirmed = await Get.dialog(
                  Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDarkMode),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, size: 40.sp, color: Colors.orange),
                          SizedBox(height: 16.h),
                          Text(
                            'تأكيد الحذف'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.xlarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'هل أنت متأكد من حذف هذا الإعلان؟'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Get.back(result: false),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text('إلغاء'.tr),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {

                                    Get.back(result: true);
                                  
                                  } ,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text('حذف'.tr),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                
                if (confirmed == true) {
                   _manage.deleteAd(widget.ad.id);
                  Get.back(); // العودة للشاشة السابقة بعد الحذف
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // زر عرض الإعلان (يظهر فقط إذا كان الإعلان منشوراً)
          if (widget.ad.status == 'published')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.visibility, size: 20.sp),
                label: Text('عرض الإعلان'.tr,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 15.sp)),
                onPressed: () {
                  final ad = widget.ad;
                  if (ad == null) return;

                  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
                  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // دالة لتنسيق السعر
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} ${'مليون'.tr}';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ${'ألف'.tr}';
    }
    return price.toStringAsFixed(0);
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

  // دالة لتنسيق التاريخ بشكل مفصل (12 ساعة)
  String _formatDetailedDate(DateTime date) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    
    String formattedDate = dateFormat.format(date);
    String formattedTime = timeFormat.format(date);
    
    // تحويل AM/PM إلى صباحاً/مساءً
    formattedTime = formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');
    
    return '$formattedDate - $formattedTime';
  }
}


class PremiumPackagesScreenWeb extends StatefulWidget {
  final String adTitle;
  final int adId;

  const PremiumPackagesScreenWeb({
    Key? key,
    required this.adTitle,
    required this.adId,
  }) : super(key: key);

  @override
  State<PremiumPackagesScreenWeb> createState() => _PremiumPackagesScreenWebState();
}

class _PremiumPackagesScreenWebState extends State<PremiumPackagesScreenWeb> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');
  
  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
  }

  // ------------------ Helpers ------------------
  int _extractDaysFromName(String name) {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  Map<String, List<prm. PremiumPackage>> _groupPackagesByType(List<prm.PremiumPackage> packages) {
    Map<String, List<prm.PremiumPackage>> groupedPackages = {};
    for (var package in packages) {
      if (package.isActive == true) {
        String typeName = package.type?.name ?? 'باقات أخرى';
        groupedPackages.putIfAbsent(typeName, () => []);
        groupedPackages[typeName]!.add(package);
      }
    }
    groupedPackages.forEach((key, value) {
      value.sort((a, b) {
        int aDays = _extractDaysFromName(a.name ?? '');
        int bDays = _extractDaysFromName(b.name ?? '');
        if (aDays != bDays) return aDays.compareTo(bDays);
        final da = (a.price ?? 0).compareTo((b.price ?? 0));
        if (da != 0) return da;
        return (a.name ?? '').compareTo((b.name ?? ''));
      });
    });
    return groupedPackages;
  }

  void _togglePackageSelection(String typeName, int packageId) {
    setState(() {
      if (selectedPackagesByType[typeName] == packageId) {
        selectedPackagesByType.remove(typeName);
      } else {
        selectedPackagesByType[typeName] = packageId;
      }
    });
  }

  Set<int> get selectedPackageIds => selectedPackagesByType.values.toSet();

  List<prm.PremiumPackage> get _selectedPackages {
    return controller.packagesList.where((p) => selectedPackageIds.contains(p.id)).toList();
  }

  String _buildSelectedSummary() {
    final selected = _selectedPackages;
    if (selected.isEmpty) return 'لم يتم اختيار باقات بعد';
    final total = selected.fold<double>(0.0, (prev, el) => prev + (el.price ?? 0));
    final types = selected.map((e) => e.type?.name ?? '').toSet().join(' • ');
    final names = selected.map((e) => e.name ?? '').join(' • ');
    return '$names · $types · ${_fmt.format(total)} ل.س';
  }

  void _onProceedToPayment() {
    final selectedIds = selectedPackageIds;
    if (selectedIds.isEmpty) {
      Get.snackbar('خطأ', 'يرجى اختيار باقة واحدة على الأقل', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final selectedPackages = _selectedPackages;

    Get.to(() => PaymentScreenWeb(
          packageList: selectedPackages,
          adTitle: widget.adTitle,
          adId: widget.adId,
        ));
  }

  void _showPackageDetailsDialog(prm.PremiumPackage pkg, String typeName) {
    final currentlySelected = _selectedPackages;
    final currentTotal = currentlySelected.fold<double>(0.0, (p, e) => p + (e.price ?? 0));
    final willAdd = selectedPackagesByType[typeName] != pkg.id;
    final predictedTotal = currentTotal + (willAdd ? (pkg.price ?? 0) : 0);

    showDialog(
      context: context,
      builder: (ctx) {
        return SizedBox(
          width:400.w,
          child: Dialog(
            backgroundColor: themeController.isDarkMode.value ? Color(0xFF0b1220) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, fontFamily: AppTextStyles.appFontFamily)),
                  SizedBox(height: 8),
                  Text('${_fmt.format(pkg.price ?? 0)} ل.س • ${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                  SizedBox(height: 10),
                  if ((pkg.description ?? '').isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(pkg.description!, style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value)), textAlign: TextAlign.center),
                    ),
                  SizedBox(height: 16),
          
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع بعد الاختيار', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_fmt.format(predictedTotal)} ل.س', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.medium)),
                    ],
                  ),
                  SizedBox(height: 12),
          
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _togglePackageSelection(typeName, pkg.id!);
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedPackagesByType[typeName] == pkg.id) ? Colors.grey : AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text((selectedPackagesByType[typeName] == pkg.id) ? 'إلغاء الاختيار' : 'اختيار هذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedPackagesByType[typeName] != pkg.id) _togglePackageSelection(typeName, pkg.id!);
                            Navigator.of(ctx).pop();
                            _onProceedToPayment();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('الدفع الآن لهذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final bg = AppColors.background(isDark);
      final cardColor = AppColors.card(isDark);

      final activePackages = controller.packagesList.where((pkg) => pkg.isActive == true).toList();
      final groupedPackages = _groupPackagesByType(activePackages);

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          title: Text('الباقات المميزة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: Colors.white,
                fontSize: AppTextStyles.xxlarge,
                fontWeight: FontWeight.w700,
              )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    Container(width: 6.w, height: 48.h, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6.r))),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ارتقِ بإعلاناتك — اجذب الزبائن الآن'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                          SizedBox(height: 6.h),
                          Text(
                            'اختر الباقات المناسبة لإبراز إعلانك',
                            style: TextStyle(
                             fontSize: AppTextStyles.medium,
                              color: AppColors.textSecondary(isDark),
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Expanded(
                child: controller.isLoadingPackages.value
                    ? Center(child: CircularProgressIndicator())
                    : activePackages.isEmpty
                        ? _noActivePackagesState(cardColor, isDark)
                        : ListView(
                            padding: EdgeInsets.only(bottom: 120),
                            children: [
                              ...groupedPackages.entries.map((entry) {
                                final typeName = entry.key;
                                final typePackages = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(typeName, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                          if (typePackages.isNotEmpty && (typePackages.first.type?.description ?? '').isNotEmpty)
                                            IconButton(
                                              onPressed: () {
                                                Get.defaultDialog(title: typeName, content: Text(typePackages.first.type!.description ?? ''));
                                              },
                                              icon: Icon(Icons.info_outline, color: AppColors.textSecondary(isDark)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 190,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: typePackages.length,
                                        separatorBuilder: (_, __) => SizedBox(width: 14),
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        itemBuilder: (context, idx) {
                                          final pkg = typePackages[idx];
                                          final isSelected = selectedPackagesByType[typeName] == pkg.id;
                                          return HorizontalPackageCardWeb(
                                            pkg: pkg,
                                            isDark: isDark,
                                            priceText: '${_fmt.format(pkg.price ?? 0)} ل.س',
                                            isSelected: isSelected,
                                            onSelect: () => _showPackageDetailsDialog(pkg, typeName),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 22),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: selectedPackageIds.isNotEmpty
            ? Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF0b1220) : Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${selectedPackageIds.length} ${'باقات مختارة'.tr}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.medium)),
                          SizedBox(height: 6),
                          Text(_buildSelectedSummary(), style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _onProceedToPayment,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text('الدفع الآن'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.medium)),
                    ),
                  ],
                ),
              )
            : null,
      );
    });
  }

  Widget _noActivePackagesState(Color cardColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64.w, color: AppColors.primary.withOpacity(0.9)),
          SizedBox(height: 12.h),
          Text('لا توجد باقات نشطة حاليًا'.tr, style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
          SizedBox(height: 8.h),
          Text('يرجى التحقق لاحقًا أو التواصل مع الدعم'.tr,
              textAlign: TextAlign.center, style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textSecondary(isDark))),
        ],
      ),
    );
  }
}

class HorizontalPackageCardWeb extends StatelessWidget {
  final prm.PremiumPackage pkg;
  final bool isDark;
  final String priceText;
  final bool isSelected;
  final VoidCallback onSelect;

  const HorizontalPackageCardWeb({
    Key? key,
    required this.pkg,
    required this.isDark,
    required this.priceText,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25);
    final bg = isSelected ? AppColors.primary.withOpacity(0.06) : (isDark ? Color(0xFF141722) : Colors.white);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800, fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 6),
              InkWell(onTap: onSelect, child: Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary(isDark))),
            ]),
            SizedBox(height: 10),
            Text(priceText, style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, color: AppColors.primary)),
            SizedBox(height: 6),
            Text('${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark))),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSelect,
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Text(isSelected ? 'محدد' : 'عرض التفاصيل', style: TextStyle(fontSize: AppTextStyles.small, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.buttonAndLinksColor)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/////
///
class PaymentScreenWeb extends StatefulWidget {
  final List<prm.PremiumPackage> packageList;
  final int adId;
  final String adTitle;

  const PaymentScreenWeb({
    Key? key,
    required this.packageList,
    required this.adId,
    required this.adTitle,
  }) : super(key: key);

  @override
  State<PaymentScreenWeb> createState() => _PaymentScreenWebState();
}

class _PaymentScreenWebState extends State<PaymentScreenWeb> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.put(UserWalletController());
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController());

  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'wallet';
  }
  
  String selectedPaymentMethod = 'wallet';
  bool isProcessing = false;
  UserWallet? selectedWallet;
  final fmt = NumberFormat('#,##0', 'en_US');

  // متحكمات نموذج البطاقة
  final _formKey = GlobalKey<FormState>();
  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserWallets();
    
    // تعيين طريقة الدفع الافتراضية بناءً على حالة البطاقة
    selectedPaymentMethod = initialPaymentMethod;
    
    // التأكد من جلب أحدث إعدادات البطاقة
    _cardPaymentController.fetchSetting();
  }

  Future<void> _fetchUserWallets() async {
    final userId = loadingController.currentUser?.id;
    if (userId != null) await walletController.fetchUserWallets(userId);
  }

  double _totalPrice() => widget.packageList.fold(0.0, (p, e) => p + (e.price ?? 0));
  String _namesOfSelected() => widget.packageList.map((e) => e.name ?? '-').join(' • ');
  String _typesOfSelected() => widget.packageList.map((e) => e.type?.name ?? '-').toSet().join(' • ');
  String _durationText() {
    if (widget.packageList.isEmpty) return '-';
    if (widget.packageList.length == 1) return '${widget.packageList.first.durationDays ?? '-'} يوم';
    final durations = widget.packageList.map((e) => e.durationDays ?? 0).toSet();
    if (durations.length == 1) return '${durations.first} يوم';
    return 'متعددة';
  }

  String _getWalletStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشطة'.tr;
      case 'frozen':
        return 'مجمدة'.tr;
      case 'closed':
        return 'مغلقة'.tr;
      default:
        return status;
    }
  }

  Color _getWalletStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'frozen':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    if (selectedPaymentMethod == 'wallet') {
      if (selectedWallet == null) {
        Get.snackbar('خطأ', 'يرجى اختيار محفظة للدفع', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      final st = (selectedWallet!.status ?? '').toString().toLowerCase();
      if (st != 'active') {
        Get.snackbar('غير مسموح', 'لا يمكن استخدام هذه المحفظة لأنها ليست نشطة', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final total = _totalPrice();
      final balance = (selectedWallet!.balance ?? 0).toDouble();
      if (balance < total) {
        Get.snackbar('رصيد غير كافٍ', 'رصيد المحفظة أقل من سعر الباقات المختارة', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    setState(() => isProcessing = true);
    _showLoadingDialog();

    try {
      if (selectedPaymentMethod == 'wallet') {
        final packageIds = widget.packageList.map((e) => e.id ?? 0).where((id) => id > 0).toList();
        final res = await walletController.purchasePremium(walletUuid: selectedWallet!.uuid, adId: widget.adId, packageIds: packageIds);

        if (res != null && res['success'] == true) {
          Get.back();
          Get.snackbar('نجاح', res['message'] ?? 'تم شراء/تجديد الباقات بنجاح', backgroundColor: Colors.green, colorText: Colors.white);

          await walletController.fetchUserWallets(Get.find<LoadingController>().currentUser?.id ?? 0);

          Future.delayed(Duration(milliseconds: 300), () {
            if (Navigator.canPop(context)) Navigator.pop(context);
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
        } else {
          Get.back();
          final body = res != null ? (res['body'] ?? res) : null;
          final msg = body != null && body['message'] != null ? body['message'] : 'فشل شراء/تجديد الباقات';
          Get.snackbar('خطأ', msg, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else if (selectedPaymentMethod == 'card') {
        // محاكاة عملية الدفع بالبطاقة
        await Future.delayed(Duration(seconds: 2));
        
        Get.back();
        Get.snackbar(
          'نجاح', 
          'تمت عملية الدفع بالبطاقة بنجاح. سيتم تفعيل الباقات المميزة على إعلانك قريباً.', 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          duration: Duration(seconds: 5)
        );

        // محاكاة نجاح العملية والعودة للشاشة السابقة
        Future.delayed(Duration(milliseconds: 500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      }
    } catch (e, st) {
      Get.back();
      print('_processPayment exception: $e\n$st');
      Get.snackbar('خطأ', 'حدث خطأ أثناء الدفع: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('جاري معالجة الدفع...', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value))),
                  SizedBox(height: 8),
                  Text('يرجى الانتظار قليلاً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 13, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditCardSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'الدفع الآمن بالبطاقة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // تصميم متجاوب للشاشات الكبيرة
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: _onCardNumberChanged,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
                      decoration: InputDecoration(
                        labelText: 'رقم البطاقة'.tr, 
                        hintText: 'xxxx xxxx xxxx xxxx', 
                        filled: true, 
                        fillColor: AppColors.card(isDark), 
                        prefixIcon: Icon(Icons.credit_card, color: AppColors.primary), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      validator: (v) {
                        final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                        if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة'.tr;
                        if (digits.length < 12) return 'رقم البطاقة غير صحيح'.tr;
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    
                    TextFormField(
                      controller: nameCtrl, 
                      keyboardType: TextInputType.name, 
                      decoration: InputDecoration(
                        labelText: 'اسم صاحب البطاقة'.tr, 
                        filled: true, 
                        fillColor: AppColors.card(isDark), 
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ), 
                      validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryCtrl, 
                            keyboardType: TextInputType.number, 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                            decoration: InputDecoration(
                              labelText: 'انتهاء الصلاحية (MMYY)'.tr, 
                              filled: true, 
                              fillColor: AppColors.card(isDark), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                            ), 
                            validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 120, 
                          child: TextFormField(
                            controller: cvvCtrl, 
                            keyboardType: TextInputType.number, 
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                            decoration: InputDecoration(
                              labelText: 'CVV'.tr, 
                              filled: true, 
                              fillColor: AppColors.card(isDark), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                            ), 
                            obscureText: true, 
                            validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null
                          ),
                        ),
                      ]
                    ),
                    SizedBox(height: 12),
                    
                    // صورة بطاقة افتراضية للعرض (اختياري)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade700, Colors.purple.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Text(
                              '•••• •••• •••• ${cardNumberCtrl.text.length > 15 ? cardNumberCtrl.text.substring(cardNumberCtrl.text.length - 4) : '••••'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Text(
                              nameCtrl.text.isEmpty ? 'اسم صاحب البطاقة' : nameCtrl.text,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Text(
                              expiryCtrl.text.isEmpty ? 'MM/YY' : '${expiryCtrl.text.substring(0, 2)}/${expiryCtrl.text.substring(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildWalletSection(bool isDark) {
    return Obx(() {
      if (walletController.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (walletController.userWallets.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'لا توجد محافظ متاحة'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر المحفظة:'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 12),
          
          // تصميم متجاوب للمحافظ
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
            ),
            child: Column(
              children: walletController.userWallets.map((wallet) {
                final statusColor = _getWalletStatusColor(wallet.status ?? '');
                final statusText = _getWalletStatusText(wallet.status ?? '');
                final isSelected = selectedWallet?.uuid == wallet.uuid;
                
                return InkWell(
                  onTap: () {
                    final st = (wallet.status ?? '').toString().toLowerCase();
                    if (st != 'active') {
                      Get.snackbar('غير مسموح', 'هذه المحفظة ليست نشطة ولا يمكن استخدامها للدفع', backgroundColor: Colors.orange, colorText: Colors.white);
                      return;
                    }
                    setState(() => selectedWallet = wallet);
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary(isDark),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المحفظة ${wallet.currency}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary(isDark),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                wallet.uuid,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 12,
                                  color: AppColors.textSecondary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${wallet.balance} ${wallet.currency}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary(isDark),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12),
                        Radio(
                          value: wallet,
                          groupValue: selectedWallet,
                          onChanged: (value) {
                            final st = (value?.status ?? '').toString().toLowerCase();
                            if (st != 'active') {
                              Get.snackbar('غير مسموح', 'هذه المحفظة ليست نشطة ولا يمكن استخدامها للدفع', backgroundColor: Colors.orange, colorText: Colors.white);
                              return;
                            }
                            setState(() => selectedWallet = value);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: 16),
          if (selectedWallet != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المحفظة المحددة:'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'معرف المحفظة:'.tr}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                            Text(
                              selectedWallet!.uuid,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'الرصيد:'.tr}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                            Text(
                              '${selectedWallet!.balance} ${selectedWallet!.currency}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'الحالة:'.tr}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                            Text(
                              '${_getWalletStatusText(selectedWallet!.status ?? '')}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.bold,
                                color: _getWalletStatusColor(selectedWallet!.status ?? ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
    final totalPrice = _totalPrice();
    final namesText = _namesOfSelected();
    final typesText = _typesOfSelected();
    final durationText = _durationText();
    final priceText = '${fmt.format(totalPrice)} ل.س';

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text('إتمام الشراء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.white)),
        leading: IconButton(
          onPressed: () => Get.back(), 
          icon: Icon(Icons.arrow_back, color: Colors.white)
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1000),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العمود الأيسر: ملخص الطلب
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'ملخص طلبك'.tr, 
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily, 
                                fontSize: 24, 
                                fontWeight: FontWeight.w800
                              )
                            ),
                          ),
                          SizedBox(height: 20),
                          Divider(),
                          SizedBox(height: 20),
                          
                          _buildSummaryRow('الباقات المختارة:'.tr, namesText, isDark),
                          SizedBox(height: 16),
                          _buildSummaryRow('النوع:'.tr, typesText, isDark),
                          SizedBox(height: 16),
                          _buildSummaryRow('المدة:'.tr, durationText, isDark),
                          SizedBox(height: 16),
                          _buildSummaryRow('عنوان الإعلان:'.tr, widget.adTitle, isDark),
                          
                          SizedBox(height: 20),
                          Divider(),
                          SizedBox(height: 20),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الإجمالي:'.tr, 
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily, 
                                  fontSize: 20, 
                                  fontWeight: FontWeight.w800
                                )
                              ),
                              Text(
                                priceText, 
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily, 
                                  fontSize: 28, 
                                  fontWeight: FontWeight.w900, 
                                  color: AppColors.primary
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 24),
                  
                  // العمود الأيمن: طرق الدفع
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر طريقة الدفع'.tr, 
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.w700, 
                            fontFamily: AppTextStyles.appFontFamily
                          )
                        ),
                        SizedBox(height: 20),

                        // طرق الدفع
                        Obx(() {
                          final isCardEnabled = _cardPaymentController.isEnabled.value;
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card(isDark), 
                              borderRadius: BorderRadius.circular(16)
                            ),
                            child: Column(
                              children: [
                                if (isCardEnabled)
                                ListTile(
                                  leading: Icon(Icons.credit_card, color: AppColors.primary, size: 28),
                                  title: Text(
                                    'بطاقة ائتمان'.tr, 
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    )
                                  ),
                                  subtitle: Text(
                                    'دفع آمن عبر البطاقة الائتمانية'.tr,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 14,
                                      color: AppColors.textSecondary(isDark),
                                    )
                                  ),
                                  trailing: Radio(
                                    value: 'card', 
                                    groupValue: selectedPaymentMethod, 
                                    onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                                    activeColor: AppColors.primary
                                  ),
                                  onTap: () => setState(() => selectedPaymentMethod = 'card'),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                
                                ListTile(
                                  leading: Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                                  title: Text(
                                    'المحفظة الإلكترونية'.tr, 
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    )
                                  ),
                                  subtitle: Text(
                                    'استخدام رصيد المحفظة المتاح'.tr,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 14,
                                      color: AppColors.textSecondary(isDark),
                                    )
                                  ),
                                  trailing: Radio(
                                    value: 'wallet', 
                                    groupValue: selectedPaymentMethod, 
                                    onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                                    activeColor: AppColors.primary
                                  ),
                                  onTap: () => setState(() => selectedPaymentMethod = 'wallet'),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),

                                if (!isCardEnabled)
                                ListTile(
                                  leading: Icon(Icons.credit_card_off, color: Colors.grey, size: 28),
                                  title: Text(
                                    'الدفع بالبطاقة غير متاح حالياً'.tr, 
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily, 
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    )
                                  ),
                                  subtitle: Text(
                                    'يرجى استخدام المحفظة الإلكترونية للدفع'.tr,
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 14,
                                      color: Colors.grey,
                                    )
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        SizedBox(height: 24),

                        // عرض القسم المناسب بناءً على طريقة الدفع المختارة
                        if (selectedPaymentMethod == 'card') 
                          _buildCreditCardSection(isDark),

                        if (selectedPaymentMethod == 'wallet') 
                          _buildWalletSection(isDark),

                        SizedBox(height: 24),

                        // زر الدفع النهائي
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: isProcessing
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'إتمام الدفع'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: AppTextStyles.appFontFamily,
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
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
            fontSize: 16,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}