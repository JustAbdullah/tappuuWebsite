import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/desktop/AdsManageDeskTop/AddAdScreenDeskTop.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../controllers/AuthController.dart';
import '../../controllers/LoadingController.dart';
import '../AdvertiserManageDeskTop/AdvertiserDataScreenDesktop.dart';
import '../AuthScreenDeskTop/ResetPasswordDesktopScreen.dart';
import 'AdvertiserProfilesScreenDeskTop/AdvertiserProfilesScreenDesktop.dart';
import 'CurrencySettingsPageDeskTop.dart';
import 'FavoriteGroupsDesktopPage/FavoriteGroupsDesktopPage.dart';
import 'FavoriteSellersUnifiedPageDesktop/FavoriteSellersUnifiedPageDesktop.dart';
import 'FavoritesScreenDeskTop/FavoritesScreenDeskTop.dart';
import 'LanguageSettingsPageDeskTop.dart';
import 'MyConversationsScreenDeskTop/DesktopConversationsListScreen.dart';
import 'MyReportsScreenDesktop/MyReportsScreenDeskTop.dart';
import 'SearchHistoryDesktopPage/SearchHistoryDesktopPage.dart';
import 'SearchHistoryScreenDeskTop/SearchHistoryScreenDeskTop.dart';
import 'TransferProofsDesktopPage/TransferProofsDesktopPage.dart';
import 'UserInfoPageDeskTop.dart';
import 'UserWalletsDesktopPage/UserWalletsDesktopPage.dart';
import 'UsersAdsDeskTop/UserAdsScreenDeskTop.dart';

class SettingsDrawerDeskTop extends StatefulWidget {
  const SettingsDrawerDeskTop({Key? key}) : super(key: key);

  @override
  _SettingsDrawerDeskTopState createState() => _SettingsDrawerDeskTopState();
}

class _SettingsDrawerDeskTopState extends State<SettingsDrawerDeskTop> {
  int _selectedCategory = 0;
  final ThemeController themeController = Get.find<ThemeController>();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'حسابي'.tr, 'icon': Icons.person_outline, 'color': Colors.blue},
    {'title': 'الإعلانات'.tr, 'icon': Icons.campaign_outlined, 'color': Colors.orange},
    {'title': 'المعلنين'.tr, 'icon': Icons.business_outlined, 'color': Colors.purple},
    {'title': 'المفضلات'.tr, 'icon': Icons.favorite_border, 'color': Colors.pink},
    {'title': 'المظهر'.tr, 'icon': Icons.palette_outlined, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeController.isDarkMode.value;
    final bgColor = AppColors.surface(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final primary = AppColors.primary;
    final textColor = AppColors.textPrimary(isDarkMode);
    final iconColor = AppColors.icon(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar - 25% width
              Container(
                width: MediaQuery.of(context).size.width * 0.25,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: dividerColor, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 12.w, bottom: 16.h, top: 8.h),
                      child: Text(
                        'الإعدادات',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: primary,
                          fontSize: AppTextStyles.xxlarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Categories List
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == index;
                          
                          return _buildCategoryItem(
                            title: category['title'],
                            icon: category['icon'],
                            color: category['color'],
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = index;
                              });
                            },
                            isDarkMode: isDarkMode,
                          );
                        },
                      ),
                    ),
                    
                    // Actions at the bottom
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Column(
                        children: [
                          _buildActionButton(
                            'تسجيل خروج'.tr,
                            Icons.logout,
                            AppColors.error,
                            () => _handleLogout(),
                            isDarkMode: isDarkMode,
                          ),
                          SizedBox(height: 8.h),
                          _buildActionButton(
                            'حذف الحساب'.tr,
                            Icons.delete_outline,
                            AppColors.error,
                            () => _handleDeleteAccount(),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content - 75% width
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: _buildContentForCategory(
                    _selectedCategory,
                    cardColor: cardColor,
                    textColor: textColor,
                    primary: primary,
                    iconColor: iconColor,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.w, color: isSelected ? color : AppColors.icon(isDarkMode)),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.arrow_back_ios, size: 14.w, color: color, textDirection: TextDirection.ltr),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap, {required bool isDarkMode}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        child: Row(
          children: [
            Icon(icon, size: 16.w, color: color),
            SizedBox(width: 10.w),
            Text(
              text,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: color,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForCategory(
    int categoryIndex, {
    required Color cardColor,
    required Color textColor,
    required Color primary,
    required Color iconColor,
    required bool isDarkMode,
  }) {
    switch (categoryIndex) {
      case 0: // حسابي
        return _buildAccountSettings(cardColor, textColor, primary, iconColor);
      case 1: // الإعلانات
        return _buildAdsSettings(cardColor, textColor, primary, iconColor);
      case 2: // المعلنين
        return _buildAdvertisersSettings(cardColor, textColor, primary, iconColor);
      case 3: // المفضلات
        return _buildFavoritesSettings(cardColor, textColor, primary, iconColor);
      case 4: // المظهر
        return _buildAppearanceSettings(cardColor, textColor, primary, iconColor, isDarkMode);
      default:
        return _buildAccountSettings(cardColor, textColor, primary, iconColor);
    }
  }

  Widget _buildAccountSettings(Color cardColor, Color textColor, Color primary, Color iconColor) {
    return ListView(
      children: [
        Text(
          'إعدادات الحساب'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            color: primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 16.h),
        
        _buildSettingCard(
          title: 'معلوماتي الشخصية'.tr,
          description: 'إدارة معلومات الحساب الأساسية'.tr,
          onTap: () => _handleMyInfo(),
          color: Colors.blue,
        ),  SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'محفظتي'.tr,
          description: 'إدارة محفظتي'.tr,
          onTap: () => _handlUserWallets(),
          color: Colors.brown,
        ),
        SizedBox(height: 12.h),
          _buildSettingCard(
          title: 'التحويلات البنكية'.tr,
          description: 'إدارة التحويلات البنكية'.tr,
          onTap: () => _handlTransferProofsDesktopPage(),
          color: Colors.pink,
        ),
        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'الأمان'.tr,
          description: 'تغيير كلمة المرور'.tr,
          onTap: () => _handleChangePassword(),
          color: Colors.orange,
        ),  SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'المحادثات'.tr,
          description: 'المحادثات والرسائل مع مختلف المعلنين'.tr,
          onTap: () => _handleConversation(),
          color: Colors.purple,
        ),
        SizedBox(height: 12.h),
        _buildSettingCard(
          title: 'بلاغاتي'.tr,
          description:'البلاغات'.tr,
          onTap: () => _handleReport(),
          color: Colors.purple,
        ),
        SizedBox(height: 12.h),
     
      ],
    );
  }

  Widget _buildAdsSettings(Color cardColor, Color textColor, Color primary, Color iconColor) {
    return ListView(
      children: [
        Text(
          'إعدادات الإعلانات'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            color: primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 16.h),
        
        _buildSettingCard(
          title: 'إضافة إعلان جديد'.tr,
          description: 'إضافة إعلان جديد إلى المنصة'.tr,
          onTap: () => _handleAddNewAd(),
          color: Colors.purple,
        ),
        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'إدارة الإعلانات'.tr,
          description: 'عرض وتعديل الإعلانات المنشورة'.tr,
          onTap: () => _handleManageAds(),
          color: Colors.blue,
        ),
        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'الإعلانات غير المنشورة'.tr,
          description: 'الإعلانات قيد المراجعة'.tr,
          onTap: () => _handleUnpublishedAds(),
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildAdvertisersSettings(Color cardColor, Color textColor, Color primary, Color iconColor) {
    return ListView(

      children: [
        Text(
          'إعدادات المعلنين'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            color: primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 16.h),
        
        _buildSettingCard(
          title: 'إدارة المعلنين'.tr,
          description: 'عرض وتعديل بيانات المعلنين'.tr,
          onTap: () => _handleManageAdvertisers(),
          color: Colors.teal,
        ),
        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'إضافة معلن جديد'.tr,
          description: 'إضافة معلن جديد إلى الحساب'.tr,
          onTap: () => _handleAddNewAdvertiser(),
          color: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildFavoritesSettings(Color cardColor, Color textColor, Color primary, Color iconColor) {
    return ListView(
      children: [
        Text(
          'المفضلات والتاريخ'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            color: primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 16.h),
        
        _buildSettingCard(
          title: 'مفضلاتي من الإعلانات'.tr,
          description: 'عرض الإعلانات المفضلة',
          onTap: () => _handleFavoriteAds(),
          color: Colors.red,
        ), 

        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'سجل المشاهدات الأخيرة'.tr,
          description: 'عرض الإعلانات التي شاهدتها مؤخرًا'.tr,
          onTap: () => _handleViewHistory(),
          color: Colors.indigo,
        ),_buildSettingCard(
          title: 'الباعة المفضلين'.tr,
          description: 'عرض الباعة المفضلين',
          onTap: () => _handleFavoriteSellers(),
          color: Colors.pink,
        ),
        _buildSettingCard(
          title: 'سجلات البحث'.tr,
          description: 'سجلات البحث المحفوظة ',
          onTap: () => _handleSearchHistory(),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings(Color cardColor, Color textColor, Color primary, Color iconColor, bool isDarkMode) {
    return ListView(
      children: [
        Text(
          'إعدادات المظهر'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.bold,
            color: primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 16.h),
        
     /*   _buildSettingCard(
          title: 'اللغة'.tr,
          description: 'تغيير لغة التطبيق'.tr,
          onTap: () => _handleLanguageSettings(),
          color: Colors.blueAccent,
        ),*/
        SizedBox(height: 12.h),
        
        _buildSettingCard(
          title: 'العملة'.tr,
          description: 'تغيير العملة المستخدمة'.tr,
          onTap: () => _handleCurrencySettings(),
          color: Colors.green,
        ),
        SizedBox(height: 12.h),
        
        // Theme Card
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.palette, size: 22.w, color: Colors.purple),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ثيم التطبيق'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'التغيير بين الوضع الفاتح والداكن'.tr,
                      style: TextStyle(
                       fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDarkMode,
                onChanged: (value) => themeController.toggleTheme(),
                activeColor: primary,
                activeTrackColor: primary.withOpacity(0.3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.card(isDarkMode),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
           
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkMode),
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                     fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(isDarkMode),
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.w, color: AppColors.icon(isDarkMode)),
          ],
        ),
      ),
    );
  }

  // ================== Event Handlers ================== //
  
  void _handleLanguageSettings() {
    Get.to(() => LanguageSettingsPageDeskTop());
  }

  void _handleCurrencySettings() {
 Get.to(() => CurrencySettingsPageDeskTop());
  }

  void _handleAddNewAd() {
  Get.to(() => AddAdScreenDesktop());
  }

  void _handleManageAds() {
  Get.to(() => UserAdsScreenDeskTop(statusAds: 'published'));
  }

  void _handleUnpublishedAds() {  Get.to(() => UserAdsScreenDeskTop(statusAds: 'under_review'));


  }

  void _handleMyInfo() {
    
     Get.to(() => UserInfoPageDeskTop());
  }  void _handlUserWallets() {
    
     Get.to(() => UserWalletsDesktopPage(userId:  Get.find<LoadingController>().currentUser?.id??0));
  }
  void _handlTransferProofsDesktopPage() {
    
     Get.to(() => TransferProofsDesktopPage(userId:  Get.find<LoadingController>().currentUser?.id??0));
  }

  void _handleChangePassword() {
           Get.to(() => ResetPasswordDesktopScreen());

  }
  void _handleConversation() {
        Get.to(() => DesktopConversationsListScreen());

  }  void _handleReport() {
        Get.to(() => MyReportsScreenDeskTop());

  }




  void _handleManageAdvertisers() {
   Get.to(() => AdvertiserProfilesScreenDeskTop());
  }

  void _handleAddNewAdvertiser() {
  Get.to(() => AdvertiserDataScreenDeskTop());
  }

  void _handleFavoriteAds() {
 Get.to(() => FavoriteGroupsDesktopPage());
  }
  void _handleFavoriteSellers() {
 Get.to(() => FavoriteSellersUnifiedPageDesktop());
  }
    void _handleSearchHistory() {
 Get.to(() => SearchHistoryDesktopPage());
  }
  

  void _handleViewHistory() {
   Get.to(() => SearchHistoryScreenDeskTop());
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        title: Text('تسجيل الخروج'.tr),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
               Get.find<LoadingController>().logout();
            },
            child: Text('تسجيل الخروج'.tr),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    Get.dialog(
      AlertDialog(
        title: Text('حذف الحساب'.tr),
        content: Text('هل أنت متأكد أنك تريد حذف حسابك؟ هذه العملية لا يمكن التراجع عنها.'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () {
                 Get.find<AuthController>().deleteUser(Get.find<LoadingController>().currentUser?.id??0);
              Get.back();
            },
            child: Text('حذف الحساب'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}