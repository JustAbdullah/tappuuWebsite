import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import '../../../mobile/UserSettings/UserWalletsPage/WalletDetailsPage.dart';
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

     
    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer:  _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        
        backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [            TopAppBarDeskTop(),
              SecondaryAppBarDeskTop(),
             SizedBox(height: 20.h,),
         Text(
           'إدارة المحافظ المالية'.tr,
           style: TextStyle(
             fontFamily: AppTextStyles.appFontFamily,
             fontSize: AppTextStyles.medium,
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
         SizedBox(height: 40.h),
         Expanded(
           child: Obx(() {
             if (walletController.isLoading.value) {
               return Center(
                 child: CircularProgressIndicator(
                   valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                 ),
               );
             }
                   
             if (walletController.userWallets.isEmpty) {
               return Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
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
                         fontSize: AppTextStyles.medium,
                         color: AppColors.textPrimary(isDarkMode),
                       ),
                     ),
                     SizedBox(height: 12.h),
                     Text(
                       'انقر على زر + لإنشاء محفظة جديدة'.tr,
                       style: TextStyle(
                         fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.medium,
                         color: AppColors.textSecondary(isDarkMode),
                       ),
                     ),
                   ],
                 ),
               );
             }
                   
             return GridView.builder(
               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2,
                 crossAxisSpacing: 24.w,
                 mainAxisSpacing: 24.h,
                 childAspectRatio: 3,
               ),
               itemCount: walletController.userWallets.length,
               itemBuilder: (context, index) {
                 final wallet = walletController.userWallets[index];
                 return _buildWalletCard(wallet, isDarkMode);
               },
             );
           }),
         ),
    
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateWalletDialog(context, userId, isDarkMode),
        backgroundColor: AppColors.primary,
        child:  Text(
                        'إنشاء محفظة'.tr,
                       style: TextStyle(
                         fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.medium,
                         color: AppColors.textSecondary(isDarkMode),
                       ),
                     ),
        
      
        tooltip: 'إنشاء محفظة جديدة'.tr,
      ),
    );
  }

  Widget _buildWalletCard(UserWallet wallet, bool isDarkMode) {
    return Card(
      color: AppColors.card(isDarkMode),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: () => Get.to(() => WalletChargeDesktopScreen(wallet: wallet)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // رأس البطاقة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المحفظة ${walletController.userWallets.indexOf(wallet) + 1}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(wallet.status, isDarkMode),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      _getStatusText(wallet.status),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(wallet.status),
                      ),
                    ),
                  ),
                ],
              ),
              
              // معلومات المحفظة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // الرصيد
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 24.w,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'الرصيد:',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${wallet.balance} ${wallet.currency}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // المعرف
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 24.w,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            wallet.uuid,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // تاريخ التحديث
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 24.w,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'آخر تحديث:',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatDate(wallet.lastChangedAt),
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
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'نشطة'.tr;
      case 'frozen': return 'مجمدة'.tr;
      case 'closed': return 'مغلقة'.tr;
      default: return status;
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'active': return Colors.green.withOpacity(0.2);
      case 'frozen': return Colors.orange.withOpacity(0.2);
      case 'closed': return Colors.red.withOpacity(0.2);
      default: return AppColors.card(isDarkMode);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'frozen': return Colors.orange;
      case 'closed': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد'.tr;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateWalletDialog(BuildContext context, int userId, bool isDarkMode) {
    final currencyController = TextEditingController(text: 'SYP');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            width: 200.w,
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إنشاء محفظة جديدة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xxlarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
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
                  items: ['SYP', 'USD'].map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(
                        currency,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,               
                               color: AppColors.buttonAndLinksColor

                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => currencyController.text = value!,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  ),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.buttonAndLinksColor
                  ),
                ),
                SizedBox(height: 32.h),
                
                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    ElevatedButton(
                      onPressed: () {
                        final currency = currencyController.text;
                        walletController.createWallet(userId, currency: currency, initialBalance: 0.0);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
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