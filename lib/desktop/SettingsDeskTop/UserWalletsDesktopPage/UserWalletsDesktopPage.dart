import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'WalletDetailsDesktopPage.dart';

class UserWalletsDesktopPage extends StatelessWidget {
  final int userId;
  final UserWalletController walletController = Get.put(UserWalletController());

  UserWalletsDesktopPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    // جلب المحافظ عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletController.fetchUserWallets(userId);
    });

    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final HomeController _homeController = Get.find<HomeController>();

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
          SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey),
          SizedBox(height: 20.h),
          Expanded(
            child: Center(
              child: Container(
                width: 0.8.sw,
                constraints: BoxConstraints(
                  maxWidth: 1100.w,
                  minHeight: 0.6.sh,
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان والوصف
                    Text(
                      'إدارة المحافظ المالية'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.xxlarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'يمكنك إدارة محافظك المالية ومتابعة أرصدتها ومعاملاتها'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // المحتوى الرئيسي
                    Expanded(
                      child: Obx(() {
                        if (walletController.isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        }

                        if (walletController.userWallets.isEmpty) {
                          return _buildEmptyState(context, isDarkMode);
                        }

                        return GridView.builder(
                          padding: EdgeInsets.only(bottom: 16.h),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 24.w,
                            mainAxisSpacing: 24.h,
                            childAspectRatio: 3.2,
                          ),
                          itemCount: walletController.userWallets.length,
                          itemBuilder: (context, index) {
                            final wallet = walletController.userWallets[index];
                            return _buildWalletCard(
                              context,
                              wallet,
                              isDarkMode,
                              index,
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreateWalletDialog(context, userId, isDarkMode),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'إنشاء محفظة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: Colors.white,
          ),
        ),
        tooltip: 'إنشاء محفظة جديدة'.tr,
      ),
    );
  }

  // =============== حالة عدم وجود محافظ ===============
  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
        ),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.card(isDarkMode),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 8.h),
                blurRadius: 20.r,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80.w,
              color: AppColors.textSecondary(isDarkMode),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد محافظ'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.large,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'انقر على زر "إنشاء محفظة" لإضافة محفظة جديدة وربطها بحسابك'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _showCreateWalletDialog(
                context,
                userId,
                isDarkMode,
              ),
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              label: Text(
                'إنشاء محفظة جديدة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============== كرت المحفظة ===============
  Widget _buildWalletCard(
    BuildContext context,
    UserWallet wallet,
    bool isDarkMode,
    int index,
  ) {
    final currencyLabel = _getCurrencyLabel(wallet.currency);
    final balanceText = '${wallet.balance} $currencyLabel';

    return Card(
      color: AppColors.card(isDarkMode),
      elevation: isDarkMode ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () => Get.to(() => WalletChargeDesktopScreen(wallet: wallet)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المحفظة ${index + 1}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.large,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(wallet.status, isDarkMode),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      _getStatusText(wallet.status),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(wallet.status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // الرصيد
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 22.w,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرصيد المتاح'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        balanceText,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // معرف المحفظة
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 18.w,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      wallet.uuid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // تاريخ آخر تحديث
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18.w,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'آخر تحديث: '.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  Text(
                    _formatDate(wallet.lastChangedAt),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============== النصوص المساعدة ===============
  String _getStatusText(String status) {
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

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'active':
        return Colors.green.withOpacity(0.15);
      case 'frozen':
        return Colors.orange.withOpacity(0.15);
      case 'closed':
        return Colors.red.withOpacity(0.15);
      default:
        return AppColors.card(isDarkMode);
    }
  }

  Color _getStatusTextColor(String status) {
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

  String _getCurrencyLabel(String? currency) {
    switch (currency) {
      case 'SYP':
        return 'ليرة سورية';
      case 'USD':
        return 'دولار أمريكي';
      default:
        return currency ?? '';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد'.tr;
    final d = date;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // =============== نافذة إنشاء محفظة ===============
  void _showCreateWalletDialog(
      BuildContext context, int userId, bool isDarkMode) {
    final currencyController = TextEditingController(text: 'SYP');

    final currencies = <String, String>{
      'SYP': 'ليرة سورية',
      'USD': 'دولار أمريكي',
    };

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            width: 420.w,
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء محفظة جديدة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'اختر العملة التي ترغب باستخدامها في هذه المحفظة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 24.h),

                // اختيار العملة
                Text(
                  'العملة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: 'SYP',
                  items: currencies.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        '${entry.value} (${entry.key})',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: AppColors.buttonAndLinksColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => currencyController.text = value!,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.buttonAndLinksColor,
                  ),
                ),
                SizedBox(height: 32.h),

                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'إلغاء'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      onPressed: () {
                        final currency = currencyController.text;
                        walletController.createWallet(
                          userId,
                          currency: currency,
                          initialBalance: 0.0,
                        );
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'إنشاء'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
