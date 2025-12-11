import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/TransferProofController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/TransferProofModel.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class TransferProofsDesktopPage extends StatelessWidget {
  final int userId;
  final TransferProofController proofController = Get.put(TransferProofController());

  TransferProofsDesktopPage({required this.userId});

  @override
  Widget build(BuildContext context) {
           final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final HomeController _homeController = Get.find<HomeController>();

    // جلب الإثباتات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      proofController.fetchProofsByUser(userId: userId);
    });

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
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey,),
          SizedBox(height: 20.h),
          
          // العنوان والوصف
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إثباتات التحويل'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'عرض ومتابعة جميع إثباتات التحويل البنكي الخاصة بك'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 16.sp,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),

          // محتوى الصفحة
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Obx(() {
                if (proofController.isLoading.value) {
                  return _buildShimmerLoader(isDarkMode);
                }

                if (proofController.proofs.isEmpty) {
                  return _emptyState(isDarkMode);
                }

                return Column(
                  children: [
                    // شريط التحكم العلوي
                    _buildTopControls(isDarkMode),
                    SizedBox(height: 16.h),
                    
                    // قائمة الإثباتات
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: proofController.proofs.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.grey.withOpacity(0.5),
                        ),
                        itemBuilder: (context, index) {
                          final proof = proofController.proofs[index];
                          return _buildProofTile(
                            proof,
                            isDarkMode,
                            _getStatusText(proof.status),
                            _getStatusColor(proof.status),
                            _formatDate(proof.createdAt),
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
          // عدد الإثباتات
          Obx(() {
            final count = proofController.proofs.length;
            return Row(
              children: [
                Icon(Icons.receipt_long, size: 24.w, color: AppColors.primary),
                SizedBox(width: 12.w),
                Text(
                  "عرض $count إثبات تحويل",
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 16.sp,
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
              proofController.fetchProofsByUser(userId: userId);
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
            Icons.receipt_long_outlined,
            size: 80.w,
            color: AppColors.primary.withOpacity(0.7),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد إثباتات تحويل'.tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لم تقم بإضافة أي إثباتات تحويل حتى الآن'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
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

  Widget _buildProofTile(
    TransferProofModel proof,
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
          Icons.receipt_long,
          color: AppColors.primary,
          size: 24.w,
        ),
      ),
      title: Text(
        'مبلغ: ${proof.amount} ل.س',
        style: TextStyle(
          fontSize: 16.sp,
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
                    fontSize: 14.sp,
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
                  fontSize: 14.sp,
                  color: AppColors.textSecondary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
          if (proof.bankAccount != null) ...[
            SizedBox(height: 8.h),
            Text(
              'الحساب: ${proof.bankAccount!.accountNumber}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDarkMode), size: 22.w),
        onPressed: () => _showProofOptions(proof, isDarkMode),
      ),
      onTap: () => _showProofDetails(proof, isDarkMode),
    );
  }

  void _showProofOptions(TransferProofModel proof, bool isDarkMode) {
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
                      fontSize: 16.sp,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    _showProofDetails(proof, isDarkMode);
                  },
                ),
                if (proof.proofImage != null && proof.proofImage!.isNotEmpty) ...[
                  Divider(height: 1, color: AppColors.divider(isDarkMode)),
                  ListTile(
                    leading: Icon(Icons.image, color: AppColors.primary, size: 24.w),
                    title: Text(
                      'عرض صورة الإثبات'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 16.sp,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      _showImageDialog(proof.proofImage!, isDarkMode);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProofDetails(TransferProofModel proof, bool isDarkMode) {
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
                  'تفاصيل إثبات التحويل'.tr,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 16.h),
                
                // المبلغ
                _buildDetailRow('المبلغ', '${proof.amount} ل.س', isDarkMode),
                SizedBox(height: 12.h),
                
                // حالة الإثبات
                Row(
                  children: [
                    Text(
                      'الحالة: ',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(proof.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _getStatusText(proof.status),
                        style: TextStyle(
                          color: _getStatusColor(proof.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // الحساب البنكي
                if (proof.bankAccount != null)
                  _buildDetailRow('الحساب البنكي', proof.bankAccount!.accountNumber, isDarkMode),
                
                // رقم الحساب المحول منه
                if (proof.sourceAccountNumber != null && proof.sourceAccountNumber!.isNotEmpty)
                  _buildDetailRow('رقم الحساب المحول منه', proof.sourceAccountNumber!, isDarkMode),
                
                // التاريخ
                _buildDetailRow('تاريخ الإنشاء', _formatDate(proof.createdAt), isDarkMode),
                
                if (proof.approvedAt != null)
                  _buildDetailRow('تاريخ المراجعة', _formatDate(proof.approvedAt), isDarkMode),
                
                // التعليق
                if (proof.comment != null && proof.comment!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'التعليق:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background(isDarkMode),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      proof.comment!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                ],
                
                // صورة الإثبات
                if (proof.proofImage != null && proof.proofImage!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Text(
                    'صورة الإثبات:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () => _showImageDialog(proof.proofImage!, isDarkMode),
                    child: Container(
                      width: double.infinity,
                      height: 200.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CachedNetworkImage(
                          imageUrl: proof.proofImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.background(isDarkMode),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.background(isDarkMode),
                            child: Center(
                              child: Icon(
                                Icons.error_outline,
                                color: AppColors.textSecondary(isDarkMode),
                                size: 40.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
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

  Widget _buildDetailRow(String title, String value, bool isDarkMode) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(String imageUrl, bool isDarkMode) {
    showDialog(
      context: Get.context!,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: 600.w,
                height: 500.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: AppColors.background(isDarkMode),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background(isDarkMode),
                      child: Center(
                        child: Icon(
                          Icons.error_outline,
                          color: AppColors.textSecondary(isDarkMode),
                          size: 40.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 24.w),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'في الانتظار'.tr;
      case 'approved': return 'مقبولة'.tr;
      case 'rejected': return 'مرفوضة'.tr;
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد'.tr;
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}