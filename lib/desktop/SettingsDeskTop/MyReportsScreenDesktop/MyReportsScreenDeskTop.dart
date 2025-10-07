import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_website/controllers/LoadingController.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/ad_report_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/ad_report_model.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class MyReportsScreenDeskTop extends StatefulWidget {
  const MyReportsScreenDeskTop({Key? key}) : super(key: key);

  @override
  State<MyReportsScreenDeskTop> createState() => _MyReportsScreenDeskTopState();
}

class _MyReportsScreenDeskTopState extends State<MyReportsScreenDeskTop> {
  final AdReportController reportController = Get.put(AdReportController());
  final ThemeController themeController = Get.find<ThemeController>();
  final LoadingController loadingController = Get.find<LoadingController>();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null);
    // جلب بلاغات المستخدم عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportController.fetchUserReports(
        userId: loadingController.currentUser?.id ?? 0,
        direction: 'both',
        lang: 'ar',
      );
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'in_review':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_review':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeController.isDarkMode.value;
  final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
          SizedBox(height: 20.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Obx(() {
                if (reportController.isLoadingReports.value) {
                  return _buildShimmerLoader(isDarkMode);
                }

                if (reportController.reports.isEmpty) {
                  return _emptyState(isDarkMode);
                }

                return Column(
                  children: [
                    // شريط التحكم العلوي
                    _buildTopControls(isDarkMode),
                    SizedBox(height: 16.h),
                    
                    // قائمة البلاغات
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: reportController.reports.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.grey.withOpacity(0.5),
                        ),
                        itemBuilder: (context, index) {
                          final report = reportController.reports[index];
                          return _buildReportTile(
                            report,
                            isDarkMode,
                            _getStatusText(report.status),
                            _getStatusColor(report.status),
                            _formatDate(report.date),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // شريط التحكم العلوي
  Widget _buildTopControls(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // عدد البلاغات
          Obx(() {
            final count = reportController.reports.length;
            return Row(
              children: [
                Icon(Icons.report_problem, size: 24.w, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text(
                  "عرض $count بلاغ",
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            );
          }),

          // زر التحديث
          IconButton(
            onPressed: () {
              reportController.fetchUserReports(
                userId: loadingController.currentUser?.id ?? 0,
                direction: 'both',
                lang: 'ar',
              );
            },
            icon: Icon(Icons.refresh, size: 24.w, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_problem_outlined,
            size: 80.w,
            color: AppColors.primary.withOpacity(0.7),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد بلاغات'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لم تقم بتقديم أي بلاغات حتى الآن'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(bool isDarkMode) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 6,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.grey.withOpacity(0.5),
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // صورة الشيمر
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(isDarkMode).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان الشيمر
                    Container(
                      height: 20.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary(isDarkMode).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // حالة الشيمر
                    Container(
                      height: 16.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary(isDarkMode).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // تاريخ الشيمر
                    Container(
                      height: 14.h,
                      width: 120.w,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary(isDarkMode).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTile(
    AdReportModel report,
    bool isDarkMode,
    String statusText,
    Color statusColor,
    String formattedDate,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      leading: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.report_problem,
          color: AppColors.primary,
          size: 24.w,
        ),
      ),
      title: Text(
        report.ad?.title ?? 'إعلان بدون عنوان',
        style: TextStyle(
          fontSize: AppTextStyles.medium,
          fontWeight: FontWeight.w600,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textPrimary(isDarkMode),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                   fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.calendar_today, size: 14.w, color: AppColors.textSecondary(isDarkMode)),
              SizedBox(width: 4.w),
              Text(
                formattedDate,
                style: TextStyle(
                 fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
          if (report.reason != null && report.reason!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              'سبب البلاغ: ${report.reason!}',
              style: TextStyle(
               fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDarkMode), size: 22.w),
        onPressed: () => _showReportOptions(report, isDarkMode),
      ),
      onTap: () => _showReportDetails(report, isDarkMode),
    );
  }

  void _showReportOptions(AdReportModel report, bool isDarkMode) {
    showDialog(
      context: Get.context!,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.card(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Container(
            width: 300.w,
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: AppColors.primary, size: 24.w),
                  title: Text(
                    'عرض التفاصيل'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _showReportDetails(report, isDarkMode);
                  },
                ),
                Divider(height: 1, color: AppColors.divider(isDarkMode)),
                ListTile(
                  leading: Icon(Icons.open_in_new, color: AppColors.primary, size: 24.w),
                  title: Text(
                    'عرض الإعلان'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    // TODO: تنفيذ عرض الإعلان
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDetails(AdReportModel report, bool isDarkMode) {
    showDialog(
      context: Get.context!,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.card(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            width: 500.w,
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل البلاغ'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.xlarge,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 16.h),
                
                // معلومات الإعلان
                Text(
                  report.ad?.title ?? 'إعلان بدون عنوان',
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // حالة البلاغ
                Row(
                  children: [
                    Text(
                      'الحالة: ',
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(report.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _getStatusText(report.status),
                        style: TextStyle(
                          color: _getStatusColor(report.status),
                          fontWeight: FontWeight.w700,
                         fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // تاريخ البلاغ
                Text(
                  'التاريخ: ${_formatDate(report.date)}',
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // سبب البلاغ
                if (report.reason != null && report.reason!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سبب البلاغ:',
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        report.reason!,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                
                SizedBox(height: 24.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('موافق'.tr),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}