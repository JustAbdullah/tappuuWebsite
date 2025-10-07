import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/FavoriteSellerController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:tappuu_website/core/data/model/AdResponse.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';
import 'package:tappuu_website/controllers/CurrencyController.dart';
import 'package:tappuu_website/core/localization/changelanguage.dart';
import 'package:tappuu_website/desktop/AdDetailsScreenDeskTop/AdDetailsScreen_desktop.dart';

import '../../app_routes.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/areaController.dart';
import '../../controllers/home_controller.dart';
import '../../customWidgets/custom_image_malt.dart';
import '../AdDetailsScreenDeskTop/DesktopConversationScreen.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';

class AdvertiserAdsScreenDesktop extends StatefulWidget {
  final Advertiser advertiser;
  final int idAdv;

  const AdvertiserAdsScreenDesktop({
    Key? key,
    required this.advertiser,
    required this.idAdv,
  }) : super(key: key);

  @override
  State<AdvertiserAdsScreenDesktop> createState() => _AdvertiserAdsScreenDesktopState();
}

class _AdvertiserAdsScreenDesktopState extends State<AdvertiserAdsScreenDesktop> {
  final FavoriteSellerController _controller = Get.put(FavoriteSellerController());
  final CurrencyController _currencyController = Get.find<CurrencyController>();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadInitialAds();
    _scrollController.addListener(_scrollListener);
  }

  void _loadInitialAds() {
    _controller.fetchAdvertiserAds(
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      advertiserProfileId: widget.idAdv,
      page: 1,
      perPage: 20,
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreAds();
    }
  }

  void _loadMoreAds() {
    if (_controller.advertiserAdsList.length % 20 == 0) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      _controller.fetchAdvertiserAds(
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
        advertiserProfileId: widget.idAdv,
        page: _currentPage,
        perPage: 20,
      ).then((_) {
        setState(() => _isLoadingMore = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final backgroundColor = AppColors.background(isDarkMode);
    final primaryColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final cardColor = AppColors.surface(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    // تحديد نوع الحساب والمظهر المناسب
    final accountType = widget.advertiser.accountType ?? 'individual';
    final accountTypeInfo = _getAccountTypeInfo(accountType);

    final HomeController _homeController = Get.find<HomeController>();

    return  Scaffold(     
       endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(isDarkMode),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
         SizedBox(height: 20.h,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  child: widget.advertiser.logo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.network(
                            widget.advertiser.logo,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.business, size: 24.w, color: primaryColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المعلن ونوع الحساب في نفس السطر
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.advertiser.name.toString(),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // شارة نوع الحساب
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: accountTypeInfo.color,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              accountTypeInfo.text,
                              style: TextStyle(
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.advertiser.description,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          ,
            SizedBox(height: 30.h),
            
            // Send Message Button (Smaller size)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 150.w,
                    child: ElevatedButton(
                      onPressed: () {
                        final userId = Get.find<LoadingController>().currentUser?.id;
                        if (userId == null) {
                          Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                          return;
                        } else {
                          Get.to(() => DesktopConversationScreen(advertiser: widget.advertiser, ad: null, idAdv: widget.idAdv));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonAndLinksColor,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.r),
                        ),
                      ),
                      child: Text(
                        'إرسال رسالة'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            
            // Portfolio Title
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 10.w),
              child: Row(
                children: [
                  Text(
                    'محفظتنا الاستثمارية'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode)
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  Obx(() => Text(
                    '${'إعلاناً'.tr} ${_controller.adsCount.value}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonAndLinksColor,
                    ),
                  )),
                ],
              ),
            ),
      
            SizedBox(height: 10.h),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'المناطق التي نعمل فيها'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Obx(() => Text(
                        _controller.areasText.value,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: AppTextStyles.medium,
                          color: AppColors.buttonAndLinksColor,
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
      
            Divider(
              height: 1.5,
              thickness: 1.5,
              color: dividerColor,
              indent: 16.w,
              endIndent: 16.w,
            ),
      
            SizedBox(height: 10.h),
      
            // ─── Quick Search Filters ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بحث سريع في محفظتنا'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() {
                    if (_controller.isLoadingAdvertiserAds.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    // استخراج عناوين الإعلانات الفريدة
                    final uniqueTitles = _controller.advertiserAdsList
                        .map((ad) => ad.title)
                        .toSet()
                        .toList();
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: uniqueTitles.map((title) {
                          return _buildFilterButton(
                            title,
                            _selectedFilter == title,
                            onTap: () {
                              // البحث عن الإعلان الأول بهذا العنوان
                              final ad = _controller.advertiserAdsList.firstWhere(
                                (a) => a.title == title,
                                orElse: () => _controller.advertiserAdsList.first
                              );
                              
                      
  if (ad == null) return;

  // الانتقال المباشر إلى شاشة التفاصيل مع تمرير كائن الإعلان
  Get.toNamed('/ad-details-direct', arguments: {'ad': ad});


                            },
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            
            // ─── Latest Ads Title ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أحدث منشوراتنا'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            
            // ─── Ads List ────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (_controller.isLoadingAdvertiserAds.value) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary,));
                }
                
                if (_controller.advertiserAdsList.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد إعلانات'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: textSecondary,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 16.h),
                  itemCount: _controller.advertiserAdsList.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _controller.advertiserAdsList.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child:               Center(child: CircularProgressIndicator(color: AppColors.primary,))

                        ),
                      );
                    }
                    
                    final ad = _controller.advertiserAdsList[index];
                    return Column(
                      children: [
                        SizedBox(
                          height: 150.h,
                          child: _buildAdItem(ad, isDarkMode, textPrimary, textSecondary)),
                        Divider(
                          height: 1,
                          thickness: 0.3,
                          color: dividerColor,
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة للحصول على معلومات نوع الحساب
  _AccountTypeInfo _getAccountTypeInfo(String accountType) {
    switch (accountType) {
      case 'company':
        return _AccountTypeInfo(
          text: 'شركة'.tr,
          color: Colors.blue[700]!,
        );
      case 'individual':
      default:
        return _AccountTypeInfo(
          text: 'فردي'.tr,
          color: Colors.green[700]!,
        );
    }
  }

  Widget _buildFilterButton(String label, bool isSelected, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
            side: BorderSide(color: AppColors.buttonAndLinksColor),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.buttonAndLinksColor,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
          ),
        ),
      ),
    );
  }

  Widget _buildAdItem(Ad ad, bool isDarkMode, Color textPrimary, Color textSecondary) {
  return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
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
            child: _buildImageSection(120.h, ad, isGrid: false),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 7.h),
                  Text(
                    ad.title,
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
                  if (ad.price != null)
                    Text(
                      _currencyController.formatPrice(ad.price!),
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
                                '${ad.city?.name??""}, ${ad.area?.name??""}',
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

  Widget _buildImageSection(double height,Ad ad,   {required bool isGrid}) 
  
  {
    
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
          if (ad.images.isNotEmpty && _imageProvider != null && _isImageLoaded)
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
          
            // تاريخ الإنشاء
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
                  _formatDate(ad.createdAt),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.small,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Premium badge
            if (ad.is_premium == true)
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
          if (ad.images.length > 1)
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
                  '${ad.images.length}',
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
}  bool _isImageLoaded = false;
  ImageProvider? _imageProvider;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${'قبل'.tr} ${difference.inDays} ${'يوم'.tr}';
    } else if (difference.inHours > 0) {
      return '${'قبل'.tr} ${difference.inHours} ${'ساعة'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${'قبل'.tr} ${difference.inMinutes} ${'دقيقة'.tr}';
    } else {
      return 'الآن'.tr;
    }
  }



// كلاس مساعد لتخزين معلومات نوع الحساب
class _AccountTypeInfo {
  final String text;
  final Color color;

  _AccountTypeInfo({required this.text, required this.color});
}