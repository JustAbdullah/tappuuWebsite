import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_website/controllers/LoadingController.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// تجاهل التحذير لأن هذا مشروع ويب
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../app_routes.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/CurrencyController.dart';
import '../../controllers/FavoriteSellerController.dart';
import '../../controllers/FavoritesController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/ad_report_controller.dart';
import '../../controllers/areaController.dart';
import '../../controllers/favorite_groups_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/AdResponse.dart';
import '../../core/data/model/favorite.dart';
import '../../customWidgets/EditableTextWidget.dart';
import '../AdvertiserAdsScreenDesktop/AdvertiserAdsScreenDesktop.dart';
import '../HomeScreenDeskTop/sections/footer_desktop.dart';
import '../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../SettingsDeskTop/SettingsDrawerDeskTop.dart';
import '../secondary_app_bar_desktop.dart';
import '../top_app_bar_desktop.dart';
import 'DesktopConversationScreen.dart';

class AdDetailsDesktop extends StatefulWidget {
  final Ad? ad;

  const AdDetailsDesktop({super.key, this.ad});

  @override
  State<AdDetailsDesktop> createState() => _AdDetailsDesktopState();
}

class _AdDetailsDesktopState extends State<AdDetailsDesktop> {
  Ad? _ad;

  final AdsController _adsController = Get.find<AdsController>();

  final LoadingController _loadingController =
      Get.isRegistered<LoadingController>()
          ? Get.find<LoadingController>()
          : Get.put(LoadingController());

  final AreaController _areaController =
      Get.isRegistered<AreaController>()
          ? Get.find<AreaController>()
          : Get.put(AreaController());

  // ✅ لا تسوي Get.put داخل build
  late final CurrencyController _currencyController;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedBottomTab = 0;
  bool _isFavorite = false;

  bool _isSeoDataLoading = false;

  // ✅ Lazy controllers (ما ننشئهم إلا عند الضغط على زر المفضلة / المتابعة)
  FavoritesController? _favoritesControllerLazy;
  FavoriteGroupsController? _favoriteGroupsControllerLazy;
  FavoriteSellerController? _favoriteSellerControllerLazy;

  FavoritesController _ensureFavoritesController() {
    if (_favoritesControllerLazy != null) return _favoritesControllerLazy!;
    if (Get.isRegistered<FavoritesController>()) {
      _favoritesControllerLazy = Get.find<FavoritesController>();
    } else {
      _favoritesControllerLazy = Get.put(FavoritesController());
    }
    return _favoritesControllerLazy!;
  }

  FavoriteGroupsController _ensureFavoriteGroupsController() {
    if (_favoriteGroupsControllerLazy != null) {
      return _favoriteGroupsControllerLazy!;
    }
    if (Get.isRegistered<FavoriteGroupsController>()) {
      _favoriteGroupsControllerLazy = Get.find<FavoriteGroupsController>();
    } else {
      _favoriteGroupsControllerLazy = Get.put(FavoriteGroupsController());
    }
    return _favoriteGroupsControllerLazy!;
  }

  FavoriteSellerController _ensureFavoriteSellerController() {
    if (_favoriteSellerControllerLazy != null) {
      return _favoriteSellerControllerLazy!;
    }
    if (Get.isRegistered<FavoriteSellerController>()) {
      _favoriteSellerControllerLazy = Get.find<FavoriteSellerController>();
    } else {
      _favoriteSellerControllerLazy = Get.put(FavoriteSellerController());
    }
    return _favoriteSellerControllerLazy!;
  }

  @override
  void initState() {
    super.initState();

    _currencyController = Get.isRegistered<CurrencyController>()
        ? Get.find<CurrencyController>()
        : Get.put(CurrencyController());

    _ad = widget.ad ?? Get.arguments?['ad'];
    if (_ad == null) {
      Get.back();
      Get.snackbar('خطأ', 'لم يتم العثور على تفاصيل الإعلان');
      return;
    }

    _updateBrowserUrl();
    _loadSeoData();

    // ❌ مهم: لا تستدعي أي فحص للمفضلة هنا
    // لأن هذا بالضبط اللي يطلع Snackbar بدون ضغط المستخدم.
  }

  Future<void> _loadSeoData() async {
    setState(() => _isSeoDataLoading = true);

    try {
      final seoData = await _adsController.fetchSeoData(_ad!.id);
      if (seoData.isNotEmpty && seoData['metaTitle'] != null) {
        _adsController.updateDocumentHead(seoData);
      } else {
        _adsController.handleMissingSeoData();
      }
    } catch (e) {
      debugPrint('Error loading SEO data: $e');
      _adsController.handleMissingSeoData();
    } finally {
      if (mounted) {
        setState(() => _isSeoDataLoading = false);
      }
    }
  }

  void _updateBrowserUrl() {
    if (_ad == null) return;

    final newUrl = '/ad/${_ad!.id}-${_ad!.slug}';
    final currentPath = html.window.location.pathname;

    if (currentPath != newUrl) {
      html.window.history.replaceState({}, '', newUrl);
    }
  }

  String get shareableUrl {
    if (_ad == null) return '';
    final baseUrl = html.window.location.origin;
    return '$baseUrl/ad/${_ad!.id}-${_ad!.slug}';
  }

  Widget _buildShareButton(bool isDarkMode) {
    return IconButton(
      icon: Icon(Icons.share, size: 22.w),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: shareableUrl));
        Get.snackbar('تم النسخ', 'تم نسخ رابط الإعلان إلى الحافظة');
      },
      tooltip: 'مشاركة الرابط',
    );
  }

  // ---------- مساعدات محسّنة ----------
  double? _parsePriceDynamic(dynamic price) {
    if (price == null) return null;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return null;
      try {
        return double.parse(cleaned);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _sanitizePhone(String? phone) {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return '';
    // خفيفة: نشيل المسافات والرموز الغريبة
    return p.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  // ---------- المفضلة (بدون أي Snackbar عند فتح الصفحة) ----------
  void _toggleFavorite() async {
    final userId = _loadingController.currentUser?.id;

    // ✅ Snackbar فقط عند الضغط
    if (userId == null) {
      Get.snackbar(
        'تنبيه'.tr,
        'يجب تسجيل الدخول لإضافة إلى المفضلة'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final favCtrl = _ensureFavoritesController();

    if (_isFavorite) {
      setState(() => _isFavorite = false);

      try {
        await favCtrl.removeFavorite(userId: userId, adId: _ad!.id);
        await _loadingController.unsubscribeFromTopicPublic('AdId_${_ad!.id}');
        Get.rawSnackbar(
          title: 'نجاح',
          message: 'تمت الإزالة من المفضلة',
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        setState(() => _isFavorite = true);
        Get.rawSnackbar(
          title: 'خطأ',
          message: 'فشل إزالة الإعلان من المفضلة',
          duration: const Duration(seconds: 2),
        );
        debugPrint('removeFavorite error: $e');
      }
    } else {
      _showFavoriteGroups();
    }
  }

  void _showFavoriteGroups() async {
    final userId = _loadingController.currentUser?.id;
    if (userId == null) return;

    final groupsCtrl = _ensureFavoriteGroupsController();
    await groupsCtrl.fetchGroups(userId: userId);

    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final cardColor = AppColors.surface(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    Get.dialog(
      Builder(builder: (ctx) {
        return Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.30,
            padding: EdgeInsets.all(20.w),
            margin: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close, size: 24.w),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    child: Center(
                      child: Text(
                        'احفظ في قائمة المفضلة',
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1.h, thickness: 0.8, color: dividerColor),
                  SizedBox(height: 16.h),
                  Obx(() {
                    if (groupsCtrl.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (groupsCtrl.groups.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                          'لا توجد مجموعات مفضلة',
                          style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily),
                        ),
                      );
                    }

                    return Container(
                      constraints: BoxConstraints(maxHeight: 200.h),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: groupsCtrl.groups.length,
                        itemBuilder: (context, index) {
                          final group = groupsCtrl.groups[index];
                          return ListTile(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8.w),
                            title: Center(
                              child: Text(
                                group.name,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              final double? currentPrice =
                                  _parsePriceDynamic(_ad!.price);
                              _showPriceNotificationDialog(
                                userId,
                                group.id,
                                currentPrice: currentPrice,
                              );
                            },
                          );
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 24.h),
                  InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _createNewGroup(userId, ctx);
                    },
                    child: Text(
                      'إنشاء قائمة جديدة',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.buttonAndLinksColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      barrierDismissible: true,
    );
  }

  Future<void> _createNewGroup(int userId, BuildContext ctx) async {
    final groupsCtrl = _ensureFavoriteGroupsController();

    final nameController = TextEditingController();
    final isDark = Get.find<ThemeController>().isDarkMode.value;
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);

    await Get.dialog(
      Dialog(
        backgroundColor: cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(ctx).size.width * 0.3,
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إنشاء مجموعة جديدة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xlarge,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المجموعة'.tr,
                    labelStyle: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDark),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'إلغاء'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          Get.snackbar('', 'من فضلك أدخل اسم المجموعة'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2));
                          return;
                        }

                        Get.back();

                        try {
                          final newGroup = await groupsCtrl.createGroup(
                            userId: userId,
                            name: name,
                          );

                          if (newGroup != null) {
                            Get.snackbar('نجاح'.tr, 'تم إنشاء مجموعة جديدة'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2));

                            await groupsCtrl.fetchGroups(userId: userId);
                            _showFavoriteGroups();
                          } else {
                            Get.snackbar('خطأ'.tr, 'فشل إنشاء المجموعة'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2));
                          }
                        } catch (e, st) {
                          debugPrint('createGroup error: $e\n$st');
                          Get.snackbar('خطأ'.tr, 'حدث خطأ أثناء الإنشاء'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'إنشاء'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _showPriceNotificationDialog(int userId, int groupId,
      {double? currentPrice}) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final cardColor = AppColors.surface(isDarkMode);
    final textColor = AppColors.textPrimary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    Get.dialog(
      Builder(builder: (ctx) {
        return Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.30,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      'اختر إعدادات الإشعار والإضافة للمفضلة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Divider(height: 1.h, thickness: 0.9, color: dividerColor),
                  SizedBox(height: 12.h),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showSetPriceDialog(userId, groupId,
                            currentPrice: currentPrice);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: AppColors.primary, width: 1.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'أعلمني عندما ينخفض السعر إلى ما دون السعر المحدد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();

                        final favCtrl = _ensureFavoritesController();

                        final notif = NotificationSettings(
                          notifyEmail: true,
                          notifyPush: true,
                          notifyOnAnyChange: true,
                          minPrice: null,
                          lastNotifiedPrice: null,
                        );

                        final success = await favCtrl.addFavorite(
                          userId: userId,
                          adId: _ad!.id,
                          favoriteGroupId: groupId,
                          notificationSettings: notif,
                        );

                        final topic = 'AdId_${_ad!.id}';

                        if (success) {
                          await _loadingController.subscribeToTopicPublic(topic);
                          setState(() => _isFavorite = true);
                          Get.rawSnackbar(
                            title: 'تم التفعيل',
                            message: 'تمت الإضافة للمفضلة وتفعيل الإشعارات',
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Get.rawSnackbar(
                            title: 'خطأ',
                            message: 'فشل حفظ التفضيلات',
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        backgroundColor: AppColors.buttonAndLinksColor,
                      ),
                      child: Text(
                        'اعلام دائماً',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
        );
      }),
      barrierDismissible: true,
    );
  }

  void _showSetPriceDialog(int userId, int groupId, {double? currentPrice}) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final cardColor = AppColors.surface(isDarkMode);
    final textColor = AppColors.textPrimary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    final priceController = TextEditingController();
    if (currentPrice != null) {
      priceController.text = NumberFormat('#,###', 'en_US').format(currentPrice);
    }

    Get.dialog(
      Builder(builder: (ctx) {
        int selectedRadio = 2;
        bool notifyEmail = true;
        bool notifyMobile = true;

        bool showTargetInput() => selectedRadio == 2;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.46,
              height: MediaQuery.of(ctx).size.height * 0.72,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: StatefulBuilder(builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'إشعارات الأسعار',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.xxlarge,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Padding(
                            padding: EdgeInsets.all(6.w),
                            child: Icon(Icons.close,
                                size: 22.w, color: textColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(height: 8.h, color: dividerColor.withOpacity(0.25)),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'نوع الإشعار',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            InkWell(
                              onTap: () => setState(() => selectedRadio = 1),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 1,
                                    groupValue: selectedRadio,
                                    onChanged: (v) => setState(() =>
                                        selectedRadio = v ?? selectedRadio),
                                    activeColor: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'أعلمني في كل مرة يتغير فيها السعر',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => selectedRadio = 2),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 2,
                                    groupValue: selectedRadio,
                                    onChanged: (v) => setState(() =>
                                        selectedRadio = v ?? selectedRadio),
                                    activeColor: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'أعلمني عندما ينخفض السعر إلى ما دون السعر المحدد',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'السعر الحالي (ل.س)',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              enabled: false,
                              decoration: InputDecoration(
                                hintText: currentPrice != null
                                    ? NumberFormat('#,###', 'en_US')
                                        .format(currentPrice)
                                    : (_ad!.price?.toString() ?? '-'),
                                filled: true,
                                fillColor:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.03)
                                        : Colors.grey.shade100,
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            if (showTargetInput()) ...[
                              Text(
                                'السعر الذي حددته (ل.س)',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: AppTextStyles.medium,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              TextField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                                ],
                                decoration: InputDecoration(
                                  hintText: 'أدخل السعر الذي حددته',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6.r)),
                                ),
                              ),
                              SizedBox(height: 12.h),
                            ],
                            InkWell(
                              onTap: () => setState(() => selectedRadio = 3),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: 3,
                                    groupValue: selectedRadio,
                                    onChanged: (v) => setState(() =>
                                        selectedRadio = v ?? selectedRadio),
                                    activeColor: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'كتم إشعارات الأسعار',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Divider(height: 1.h, thickness: 0.8, color: dividerColor),
                            SizedBox(height: 12.h),
                            Text(
                              'قناة الإشعارات',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => notifyEmail = !notifyEmail),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28.w,
                                    height: 28.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: AppColors.textSecondary(isDarkMode),
                                        width: 1.2,
                                      ),
                                      color: notifyEmail
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                    child: notifyEmail
                                        ? Icon(Icons.check,
                                            size: 18.w, color: Colors.white)
                                        : const SizedBox.shrink(),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'إشعار البريد الإلكتروني',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: AppTextStyles.medium,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => notifyMobile = !notifyMobile),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28.w,
                                    height: 28.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                          color: AppColors.buttonAndLinksColor,
                                          width: 1.2),
                                      color: notifyMobile
                                          ? AppColors.buttonAndLinksColor
                                          : Colors.transparent,
                                    ),
                                    child: notifyMobile
                                        ? Icon(Icons.check,
                                            size: 18.w, color: Colors.white)
                                        : const SizedBox.shrink(),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'إشعارات الهاتف المحمول',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: AppTextStyles.medium,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: AppColors.buttonAndLinksColor, width: 1.4),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                color: AppColors.buttonAndLinksColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedRadio == 2 &&
                                  priceController.text.trim().isEmpty) {
                                Get.snackbar(
                                  '',
                                  'من فضلك أدخل السعر الذي تريده',
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 12.h),
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                                return;
                              }

                              double? targetPrice;
                              if (priceController.text.trim().isNotEmpty) {
                                final normalized = priceController.text
                                    .replaceAll('.', '')
                                    .replaceAll(',', '')
                                    .trim();
                                try {
                                  targetPrice = double.parse(normalized);
                                } catch (_) {
                                  targetPrice = null;
                                }
                              }

                              final mode = selectedRadio;

                              bool passNotifyEmail;
                              bool passNotifyMobile;

                              if (mode == 3) {
                                passNotifyEmail = false;
                                passNotifyMobile = false;
                              } else if (mode == 1) {
                                passNotifyEmail = true;
                                passNotifyMobile = true;
                              } else {
                                passNotifyEmail = notifyEmail;
                                passNotifyMobile = notifyMobile;
                              }

                              final ok = await _setNotificationPreference(
                                userId,
                                groupId,
                                targetPrice,
                                mode: mode,
                                notifyEmail: passNotifyEmail,
                                notifyMobile: passNotifyMobile,
                              );

                              if (ok) {
                                Navigator.of(ctx).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonAndLinksColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'حفظ',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      }),
      barrierDismissible: true,
    );
  }

  Future<bool> _setNotificationPreference(
    int userId,
    int groupId,
    double? targetPrice, {
    required int mode,
    required bool notifyEmail,
    required bool notifyMobile,
  }) async {
    final favCtrl = _ensureFavoritesController();

    final notif = NotificationSettings(
      notifyEmail: notifyEmail,
      notifyPush: notifyMobile,
      notifyOnAnyChange: mode == 1,
      minPrice: mode == 2 ? targetPrice : null,
      lastNotifiedPrice: null,
    );

    try {
      final success = await favCtrl.addFavorite(
        userId: userId,
        adId: _ad!.id,
        favoriteGroupId: groupId,
        notificationSettings: notif,
      );

      final topic = 'AdId_${_ad!.id}';

      if (!success) {
        Get.rawSnackbar(
          title: 'خطأ',
          message: 'فشل حفظ تفضيلات الإشعارات',
          duration: const Duration(seconds: 2),
        );
        return false;
      }

      if (mode == 3) {
        await _loadingController.unsubscribeFromTopicPublic(topic);
      } else {
        if (notifyMobile) {
          await _loadingController.subscribeToTopicPublic(topic);
        } else {
          await _loadingController.unsubscribeFromTopicPublic(topic);
        }
      }

      setState(() => _isFavorite = true);
      Get.rawSnackbar(
        title: 'تم الحفظ',
        message: 'تم تعيين تفضيلات الإشعارات بنجاح',
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e, st) {
      debugPrint('Exception in _setNotificationPreference: $e\n$st');
      Get.rawSnackbar(
        title: 'خطأ',
        message: 'حدث خطأ أثناء حفظ التفضيلات',
        duration: const Duration(seconds: 2),
      );
      return false;
    }
  }

  void _handleReportAd() {
    final user = _loadingController.currentUser;
    if (user == null) {
      Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول لتقديم بلاغ'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));
      return;
    }
    _showReportDialog();
  }

  void _showReportDialog() {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final cardColor = AppColors.surface(isDarkMode);
    final textColor = AppColors.textPrimary(isDarkMode);
    const successColor = Colors.green;
    const errorColor = Colors.red;
    final AdReportController _reportController = Get.put(AdReportController());

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          String selectedReason = 'إعلان مخالف';
          TextEditingController detailsController = TextEditingController();
          bool isLoading = false;
          String? message;
          bool isSuccess = false;

          Future<void> submitReport() async {
            setState(() {
              isLoading = true;
              message = null;
            });

            try {
              final Map<String, dynamic> reportData = {
                'ad_id': _ad?.id ?? 0,
                'reason': selectedReason,
                'details': detailsController.text,
                'reporter_id': _loadingController.currentUser?.id,
              };

              final success = await _reportController.createReport(reportData);

              setState(() {
                isLoading = false;
                isSuccess = success;
                message = success
                    ? 'تم استلام بلاغك وسيتم مراجعته'.tr
                    : 'فشل في إرسال البلاغ'.tr;
              });

              if (success) {
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted) {
                  Get.back();
                  Get.snackbar(
                    'شكراً لك'.tr,
                    'تم استلام بلاغك وسيتم مراجعته'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: successColor,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              }
            } catch (e) {
              setState(() {
                isLoading = false;
                isSuccess = false;
                message = 'حدث خطأ أثناء إرسال البلاغ'.tr;
              });
            }
          }

          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            elevation: 5,
            child: Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'الإبلاغ عن إعلان مخالف'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xxlarge,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'سبب الإبلاغ'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: textColor.withOpacity(0.7)),
                        items: [
                          'إعلان مخالف',
                          'إعلان مكرر',
                          'معلومات خاطئة',
                          'احتيال',
                          'محتوى غير لائق',
                          'أخرى'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.medium,
                                fontFamily: AppTextStyles.appFontFamily,
                                color: textColor,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (newValue) {
                                setState(() {
                                  selectedReason = newValue!;
                                });
                              },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'تفاصيل الإبلاغ (اختياري)'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: detailsController,
                    maxLines: 4,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'يرجى توضيح سبب الإبلاغ'.tr,
                      hintStyle: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: textColor.withOpacity(0.5),
                      ),
                      contentPadding: EdgeInsets.all(16.w),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (message != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? successColor.withOpacity(0.15)
                            : errorColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSuccess ? successColor : errorColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.error,
                            color: isSuccess ? successColor : errorColor,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              message!,
                              style: TextStyle(
                                color: isSuccess ? successColor : errorColor,
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message != null) SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: BorderSide(
                                color: AppColors.buttonAndLinksColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'إلغاء'.tr,
                            style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonAndLinksColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'إرسال البلاغ'.tr,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    color: Colors.white,
                                  ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final HomeController _homeController = Get.find<HomeController>();

    return Obx(() {
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _ad!.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(isDarkMode),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _toggleFavorite,
                                child: Text(
                                  _isFavorite
                                      ? "ازل من المفضلة"
                                      : "اضف إلى مفضلتي".tr,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.medium,
                                    fontWeight: FontWeight.bold,
                                    color: _isFavorite
                                        ? Colors.red
                                        : AppColors.buttonAndLinksColor,
                                  ),
                                ),
                              ),
                              Icon(
                                _isFavorite ? Icons.favorite : Icons.star,
                                color: AppColors.textSecondary(isDarkMode),
                                size: 12.sp,
                              ),
                              SizedBox(width: 10.w),
                              SizedBox(
                                width: 150.w,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final userId =
                                        _loadingController.currentUser?.id;
                                    if (userId == null) {
                                      Get.snackbar('تنبيه'.tr,
                                          'يجب تسجيل الدخول للبلاغ '.tr);
                                      return;
                                    }
                                    _handleReportAd();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.buttonAndLinksColor,
                                    foregroundColor: Colors.white,
                                    padding:
                                        EdgeInsets.symmetric(vertical: 14.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  child: Text(
                                    'بلاغ'.tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.medium,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: AppColors.divider(isDarkMode)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildMediaGallery(isDarkMode, _ad!),
                        ),
                        SizedBox(width: 40.w),
                        Expanded(
                          flex: 3,
                          child: _buildAdProperties(isDarkMode, _ad!),
                        ),
                        SizedBox(width: 40.w),
                        Expanded(
                          flex: 3,
                          child: _buildAdvertiserInfo(isDarkMode, _ad!),
                        ),
                      ],
                    ),
                    SizedBox(height: 50.h),
                    _buildBottomTabs(isDarkMode),
                    SizedBox(height: 40.h),
                    Footer(scaffoldKey: _scaffoldKey),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMediaGallery(bool isDarkMode, Ad ad) {
    return _MediaGallery(ad: ad, isDarkMode: isDarkMode);
  }

  Widget _buildAdProperties(bool isDarkMode, Ad ad) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ad.price != null)
            Row(
              children: [
                Text(
                  'السعر:'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _currencyController.formatPrice(ad.price!),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          Divider(color: AppColors.divider(isDarkMode)),
          Row(
            children: [
              Text(
                'رقم الإعلان:'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.small,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                ad.ad_number,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redId,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.divider(isDarkMode)),
          _buildCategoryHierarchy(isDarkMode, ad),
          Divider(color: AppColors.divider(isDarkMode)),
          _buildAttributesList(ad.attributes, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCategoryHierarchy(bool isDarkMode, Ad ad) {
    final mainCategory = ad.category;
    final subCategory = ad.subCategoryLevelOne;
    final subTwoCategory = ad.subCategoryLevelTwo;

    List<Widget> categoriesWidgets = [];

    categoriesWidgets.add(
      GestureDetector(
        onTap: () {
          Get.toNamed(
            AppRoutes.adsScreen,
            arguments: {
              'categoryId': mainCategory.id,
              'nameOfMain': mainCategory.name,
            },
          );
        },
        child: Text(
          mainCategory.name,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: AppColors.buttonAndLinksColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (subCategory != null) {
      categoriesWidgets.add(Text(" / ",
          style: TextStyle(color: AppColors.textSecondary(isDarkMode))));
      categoriesWidgets.add(
        GestureDetector(
          onTap: () {
            Get.toNamed(
              AppRoutes.adsScreen,
              arguments: {
                'categoryId': mainCategory.id,
                'subCategoryId': subCategory.id,
                'nameOfMain': mainCategory.name,
                'nameOFsub': subCategory.name,
              },
            );
          },
          child: Text(
            subCategory.name,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.buttonAndLinksColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (subTwoCategory != null) {
      categoriesWidgets.add(Text(" / ",
          style: TextStyle(color: AppColors.textSecondary(isDarkMode))));
      categoriesWidgets.add(
        GestureDetector(
          onTap: () {
            Get.toNamed(
              AppRoutes.adsScreen,
              arguments: {
                'categoryId': mainCategory.id,
                'subCategoryId': subCategory?.id,
                'subTwoCategoryId': subTwoCategory.id,
                'nameOfMain': mainCategory.name,
                'nameOFsub': subTwoCategory.name,
                'nameOFsubTwo': subTwoCategory.name,
              },
            );
          },
          child: Text(
            subTwoCategory.name,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.buttonAndLinksColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: categoriesWidgets,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvertiserInfo(bool isDarkMode, Ad ad) {
    final advertiser = ad.advertiser;

    final logo = (advertiser.logo ?? '').trim();
    final desc = (advertiser.description ?? '').trim();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات المعلن'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background(isDarkMode),
                ),
                child: logo.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          logo,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40.w);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40.w),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Dismiss',
                          barrierColor: Colors.black.withOpacity(0.5),
                          transitionDuration:
                              const Duration(milliseconds: 200),
                          pageBuilder: (_, __, ___) {
                            return Center(
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.40,
                                  padding: EdgeInsets.all(20.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: const Icon(Icons.close, size: 24),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'المعاملات'.tr,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.appFontFamily,
                                            fontSize: AppTextStyles.medium,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: InkWell(
                                          onTap: () {
                                            final userId =
                                                _loadingController
                                                    .currentUser?.id;
                                            if (userId == null) {
                                              Get.snackbar(
                                                'تنبيه'.tr,
                                                'يجب تسجيل الدخول لإضافة إلى المفضلة'.tr,
                                              );
                                              return;
                                            }
                                            _ensureFavoriteSellerController()
                                                .toggleFavoriteByIds(
                                              userId: userId,
                                              advertiserProfileId: ad.idAdvertiser,
                                            );
                                          },
                                          child: Text(
                                            'متابعة مالك الإعلان'.tr,
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTextStyles.appFontFamily,
                                              fontSize: AppTextStyles.medium,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Divider(height: 1, color: Colors.grey[300]),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () {
                                          Get.to(() => AdvertiserAdsScreenDesktop(
                                                advertiser: ad.advertiser,
                                                idAdv: ad.idAdvertiser,
                                              ));
                                        },
                                        child: Text(
                                          '${'جميع إعلانات '.tr}${advertiser.name.toString()}',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.appFontFamily,
                                            fontSize: AppTextStyles.medium,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Text(
                        advertiser.name ?? 'معلن'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      desc,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.phone, size: 20.w),
                  label: Text(
                    'اتصال'.tr,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () => _makePhoneCall(advertiser.contactPhone),
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.wallet, size: 20.w),
                  label: Text(
                    'واتساب'.tr,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () => _launchWhatsApp(advertiser.whatsappPhone),
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          ElevatedButton.icon(
            icon: Icon(Icons.message, size: 20.w),
            label: Text(
              'إرسال رسالة'.tr,
              style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              final userId = _loadingController.currentUser?.id;
              if (userId == null) {
                Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                return;
              }
              Get.to(() => DesktopConversationScreen(
                    ad: ad,
                    advertiser: advertiser,
                    idAdv: ad.idAdvertiser,
                  ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabs(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBottomTab(0, 'tabTitle_info'.tr),
            _buildBottomTab(1, 'tabTitle_location'.tr),
            _buildBottomTab(2, 'tabTitle_desc'.tr),
          ],
        ),
        SizedBox(height: 30.h),
        if (_selectedBottomTab == 0) _buildAdDescription(isDarkMode, _ad!),
        if (_selectedBottomTab == 1) _buildLocationMap(isDarkMode, _ad!),
        if (_selectedBottomTab == 2)
          _buildAdditionalAdvertiserInfo(isDarkMode, _ad!),
      ],
    );
  }

  Widget _buildBottomTab(int index, String title) {
    final isSelected = _selectedBottomTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBottomTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: EditableTextWidget(
              keyName: title,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdDescription(bool isDarkMode, Ad ad) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الإعلان'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 15.h),
          Text(
            ad.description,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDarkMode),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(bool isDarkMode, Ad ad) {
    if (ad.latitude == null || ad.longitude == null) {
      return Center(
        child: Text(
          'لا يتوفر موقع جغرافي'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 12.sp,
          ),
        ),
      );
    }

    return Container(
      height: 400.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: AppColors.card(isDarkMode),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(ad.latitude!, ad.longitude!),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(ad.latitude!, ad.longitude!),
                  child: Icon(Icons.location_on,
                      size: 40.w, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalAdvertiserInfo(bool isDarkMode, Ad ad) {
    final advertiser = ad.advertiser;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات إضافية عن المعلن'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          SizedBox(height: 20.h),
          _buildInfoRow('رقم الجوال'.tr, advertiser.contactPhone),
          _buildInfoRow('واتساب'.tr, advertiser.whatsappPhone),
          if (advertiser.name != null)
            _buildInfoRow('اسم المعلن'.tr, advertiser.name!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              (value).isEmpty ? '—' : value,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesList(List<AttributeValue> attributes, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attributes.length,
      itemBuilder: (context, index) {
        final attr = attributes[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.5.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      attr.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                  Text(
                    attr.value,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: _getValueColor(attr.value, isDarkMode: isDarkMode),
                    ),
                  ),
                ],
              ),
              Divider(color: AppColors.divider(isDarkMode)),
            ],
          ),
        );
      },
    );
  }

  Color _getValueColor(String value, {required bool isDarkMode}) {
    if (value == 'نعم') return Colors.green;
    if (value == 'لا') return Colors.red;
    return AppColors.textPrimary(isDarkMode);
  }

  Future<void> _makePhoneCall(String phone) async {
    final p = _sanitizePhone(phone);
    if (p.isEmpty) {
      Get.snackbar('خطأ', 'رقم الهاتف غير متوفر');
      return;
    }
    final url = 'tel:$p';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر إجراء المكالمة');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final p = _sanitizePhone(phone);
    if (p.isEmpty) {
      Get.snackbar('خطأ', 'رقم الواتساب غير متوفر');
      return;
    }
    final url = 'https://wa.me/$p';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر فتح واتساب');
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// ✅ Web PlatformView: إصلاح الفيديو + إطفاء الصوت عند الخروج/الرجوع
// ─────────────────────────────────────────────────────────────────────────────

const String _kWebVideoViewType = 'taapuu-web-video-dialog';

bool _webFactoryRegistered = false;
bool _webDialogOpen = false;

// ✅ تخزين URL مؤقت لتمريره للفيديو
String? _pendingVideoUrl;

// ✅ إطفاء/تفريغ أي فيديو عالق في DOM (حل مشكلة استمرار الصوت)
void _stopAllWebVideos({bool aggressive = true}) {
  if (!kIsWeb) return;

  // ✅ أوقف أي <video> موجود
  try {
    final vids = html.document.querySelectorAll('video');
    for (final el in vids) {
      if (el is html.VideoElement) {
        try { el.pause(); } catch (_) {}
        try { el.muted = true; } catch (_) {}
        try { el.src = ''; } catch (_) {}
        try { el.load(); } catch (_) {}
      }
    }
  } catch (_) {}

  if (!aggressive) return;

  // ✅ امسح wrappers الخاصة بنا (لو بقيت بالـ DOM)
  try {
    final wrappers = html.document.querySelectorAll(
      '.taapuu-video-outer, .taapuu-video-wrapper, .taapuu-video-element',
    );
    for (final w in wrappers) {
      try { w.remove(); } catch (_) {}
    }
  } catch (_) {}
}

void _ensureWebVideoFactoryRegistered() {
  if (_webFactoryRegistered) return;

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(_kWebVideoViewType, (int id) {
    final v = html.VideoElement()
      ..controls = true
      ..autoplay = false
      ..muted = false
      ..preload = 'metadata'
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..setAttribute('controlsList', 'nodownload');

    // ✅ أنماط كافية
    v.style
      ..display = 'block'
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'contain'
      ..backgroundColor = 'black'
      ..maxWidth = '100%'
      ..maxHeight = '100%';

    // ✅ class للتعرف على الفيديو
    v.className = 'taapuu-video-element';

    // ✅ تمرير URL إذا كان موجوداً
    if (_pendingVideoUrl != null && _pendingVideoUrl!.isNotEmpty) {
      try {
        v.src = _pendingVideoUrl!;
        v.load();
      } catch (e) {
        debugPrint('❌ Failed to set video src in factory: $e');
      }
    }

    final wrapper = html.DivElement()
      ..className = 'taapuu-video-wrapper'
      ..style.cssText = '''
        position: absolute;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        background-color: black;
        overflow: hidden;
        width: 100%;
        height: 100%;
      ''';

    final outer = html.DivElement()
      ..className = 'taapuu-video-outer'
      ..style.cssText = '''
        width: 100%;
        height: 100%;
        position: relative;
        overflow: hidden;
        background-color: black;
        contain: strict;
      ''';

    wrapper.append(v);
    outer.append(wrapper);

    // ✅ مستمع للتأكد
    v.onLoadedMetadata.listen((_) {
      debugPrint('✅ Video metadata loaded in factory');
      try {
        if (!v.paused) return;
        Future.delayed(const Duration(milliseconds: 250), () {
          try { v.play(); } catch (_) {}
        });
      } catch (_) {}
    });

    v.onError.listen((_) {
      debugPrint('❌ Video error in factory: ${v.error?.message}');
    });

    return outer;
  });

  _webFactoryRegistered = true;
}

void _webKickHard() {
  try { html.window.dispatchEvent(html.Event('resize')); } catch (_) {}

  Future.delayed(const Duration(milliseconds: 50), () {
    try { html.window.dispatchEvent(html.Event('resize')); } catch (_) {}
  });
}

Future<void> _openWebVideoDialog(String url) async {
  if (!kIsWeb) return;
  if (_webDialogOpen) return;

  _webDialogOpen = true;
  _pendingVideoUrl = url;

  debugPrint('🎬 Opening web video dialog for: $url');

  // ✅ اقفل أي فيديو سابق قبل فتح الجديد
  _stopAllWebVideos();

  try {
    _ensureWebVideoFactoryRegistered();

    await Get.generalDialog(
      barrierLabel: 'video',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: Duration.zero,
      transitionBuilder: (context, a1, a2, child) => child,
      pageBuilder: (context, a1, a2) {
        return _WebVideoDialog(
          viewType: _kWebVideoViewType,
          videoUrl: url,
          onKick: _webKickHard,
        );
      },
    );
  } catch (e) {
    debugPrint('❌ Web dialog error: $e');
    try { html.window.open(url, '_blank'); } catch (_) {}
  } finally {
    _pendingVideoUrl = null;
    _webDialogOpen = false;

    // ✅ اقفل/امسح فورًا بعد الإغلاق (بدون تأخير)
    _stopAllWebVideos();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─── معرض الوسائط (الصور والفيديوهات) ───────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _MediaGallery extends StatefulWidget {
  final Ad ad;
  final bool isDarkMode;

  const _MediaGallery({
    Key? key,
    required this.ad,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  __MediaGalleryState createState() => __MediaGalleryState();
}

class __MediaGalleryState extends State<_MediaGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  // (موجودة كما كانت)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  String? _currentVideoUrl;
  bool _isInitializing = false;
  bool _videoError = false;
  String? _videoErrorMessage;

  bool _isWebVideoDialogOpen = false;

  List<MediaItem> get _mediaItems {
    return [
      ...widget.ad.images.map((url) => MediaItem(type: MediaType.image, url: url)),
      ...widget.ad.videos.map((url) => MediaItem(type: MediaType.video, url: url)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  // ✅ مهم: عند الانتقال لواجهة ثانية (Back/Push) اطفي الفيديو على الويب
  @override
  void deactivate() {
    if (kIsWeb) _stopAllWebVideos();
    super.deactivate();
  }

  @override
  void dispose() {
    if (kIsWeb) _stopAllWebVideos();
    _disposeVideoControllers();
    _pageController.dispose();
    super.dispose();
  }

  void _disposeVideoControllers() {
    if (kIsWeb) {
      // ✅ بدل return الفاضي: اطفي أي فيديو عالق
      _stopAllWebVideos();
      _currentVideoUrl = null;
      _isInitializing = false;
      _videoError = false;
      _videoErrorMessage = null;
      return;
    }

    try { _chewieController?.dispose(); } catch (_) {}
    try { _videoController?.dispose(); } catch (_) {}

    _chewieController = null;
    _videoController = null;
    _currentVideoUrl = null;
    _isInitializing = false;
    _videoError = false;
    _videoErrorMessage = null;
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return '${'قبل'.tr} ${diff.inHours} ${'ساعة'.tr}';
    if (diff.inMinutes > 0) return '${'قبل'.tr} ${diff.inMinutes} ${'دقيقة'.tr}';
    return 'الآن'.tr;
  }

  Future<void> _openHtml5VideoDialogWeb(String url) async {
    if (_isWebVideoDialogOpen) return;
    _isWebVideoDialogOpen = true;

    try {
      await _openWebVideoDialog(url);
    } finally {
      _isWebVideoDialogOpen = false;
    }
  }

  Future<void> _openOrPlayVideo(String url) async {
    debugPrint('🎥 Play video => $url');

    if (kIsWeb) {
      await _openHtml5VideoDialogWeb(url);
      return;
    }

    if (_currentVideoUrl == url &&
        _videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoError) {
      if (_videoController!.value.isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
      if (mounted) setState(() {});
      return;
    }

    _disposeVideoControllers();
    setState(() {
      _currentVideoUrl = url;
      _isInitializing = true;
      _videoError = false;
      _videoErrorMessage = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;

      controller.addListener(() {
        if (!mounted) return;
        final val = controller.value;
        if (val.hasError && !_videoError) {
          setState(() {
            _videoError = true;
            _isInitializing = false;
            _videoErrorMessage = val.errorDescription;
          });
        }
      });

      await controller.initialize();
      if (!mounted) return;

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
        showControls: true,
        errorBuilder: (_, __) => _buildVideoErrorState(url),
      );

      setState(() {
        _chewieController = chewie;
        _isInitializing = false;
        _videoError = false;
        _videoErrorMessage = null;
      });

      controller.play();
    } catch (e) {
      debugPrint('🎥 Video init error: $e');
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _videoError = true;
        _videoErrorMessage = e.toString();
      });
    }
  }

  void _pauseAnyVideo() {
    if (kIsWeb) return;
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = _mediaItems;

    if (mediaItems.isEmpty) {
      return Center(child: Icon(Icons.image, size: 100.w, color: Colors.grey));
    }

    return Column(
      children: [
        Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: AppColors.card(widget.isDarkMode),
            borderRadius: BorderRadius.circular(16.r),
          ),
          clipBehavior: Clip.hardEdge,
          child: _buildMainMediaDisplay(mediaItems),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${_currentIndex + 1}/${mediaItems.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextStyles.medium,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 90.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            itemCount: mediaItems.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              final item = mediaItems[index];
              final selected = index == _currentIndex;

              return GestureDetector(
                onTap: () async {
                  setState(() => _currentIndex = index);

                  if (item.type == MediaType.video) {
                    await _openOrPlayVideo(item.url);
                  } else {
                    _pauseAnyVideo();
                  }
                },
                child: Container(
                  width: 110.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 2.w,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _buildThumbnail(item),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20.h),
        Divider(color: AppColors.divider(widget.isDarkMode)),
        SizedBox(height: 20.h),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18.sp, color: AppColors.grey),
            SizedBox(width: 8.w),
            Text(
              '${'تاريخ النشر:'.tr} ${_formatDate(widget.ad.createdAt)}',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Icon(Icons.location_on, size: 18.sp, color: AppColors.textSecondary(widget.isDarkMode)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${widget.ad.city?.name ?? ""}, ${widget.ad.area?.name ?? ""}',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textSecondary(widget.isDarkMode),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMediaDisplay(List<MediaItem> mediaItems) {
    final safeIndex = _currentIndex.clamp(0, mediaItems.length - 1);
    final item = mediaItems[safeIndex];

    if (item.type == MediaType.video) {
      if (kIsWeb) return _buildVideoThumbnailMain(item.url);

      if (_videoError) return _buildVideoErrorState(item.url);
      if (_isInitializing) return _buildVideoLoadingState();

      if (_currentVideoUrl == item.url &&
          _chewieController != null &&
          _videoController != null &&
          _videoController!.value.isInitialized) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black, child: Chewie(controller: _chewieController!)),
            Positioned(top: 15.h, right: 15.w, child: _videoBadge()),
          ],
        );
      }

      return _buildVideoThumbnailMain(item.url);
    }

    return _buildImageDisplay(item.url);
  }

  Widget _videoBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.videocam, size: 16.w, color: Colors.white),
          SizedBox(width: 5.w),
          Text('فيديو'.tr, style: TextStyle(color: Colors.white, fontSize: AppTextStyles.medium)),
        ],
      ),
    );
  }

  Widget _buildVideoLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20.h),
            Text(
              'جاري تحميل الفيديو...'.tr,
              style: TextStyle(fontSize: AppTextStyles.medium, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoErrorState(String url) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.w, color: Colors.red),
            SizedBox(height: 20.h),
            Text(
              'حدث خطأ في تحميل الفيديو'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xlarge,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            if (_videoErrorMessage != null) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  _videoErrorMessage!,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    color: Colors.grey[300],
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text('إعادة المحاولة'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              ),
              onPressed: () => _openOrPlayVideo(url),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnailMain(String url) {
    return GestureDetector(
      onTap: () => _openOrPlayVideo(url),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.play_circle_fill, size: 64.w, color: Colors.white),
            ),
          ),
          Positioned(top: 15.h, right: 15.w, child: _videoBadge()),
          if (kIsWeb)
            Positioned(
              bottom: 12.h,
              left: 12.w,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'اضغط للتشغيل'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.type == MediaType.video) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black87,
            child: Center(
              child: Icon(Icons.play_circle_fill, size: 28.w, color: Colors.white),
            ),
          ),
          Positioned(
            top: 4.h,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text('فيديو'.tr, style: TextStyle(color: Colors.white, fontSize: 9.sp)),
            ),
          ),
        ],
      );
    }

    return Image.network(
      item.url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 26.w, color: Colors.grey),
      ),
    );
  }

  Widget _buildImageDisplay(String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50.w, color: Colors.grey),
              SizedBox(height: 10.h),
              Text('تعذر تحميل الصورة'.tr),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Web Dialog Widget
// ─────────────────────────────────────────────────────────────────────────────

class _WebVideoDialog extends StatefulWidget {
  final String viewType;
  final String videoUrl;
  final VoidCallback onKick;

  const _WebVideoDialog({
    Key? key,
    required this.viewType,
    required this.videoUrl,
    required this.onKick,
  }) : super(key: key);

  @override
  State<_WebVideoDialog> createState() => _WebVideoDialogState();
}

class _WebVideoDialogState extends State<_WebVideoDialog> {
  Timer? _kickTimer;
  int _kicks = 0;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) widget.onKick();
    });

    _kickTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_kicks >= 4) {
        t.cancel();
        return;
      }
      _kicks++;
      widget.onKick();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _videoReady = true);
    });
  }

  @override
  void dispose() {
    try { _kickTimer?.cancel(); } catch (_) {}
    // ✅ ضمان نهائي لإطفاء الصوت/الفيديو عند إغلاق الدايلوج
    _stopAllWebVideos();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;

    final maxW = math.min(sz.width * 0.86, 860.0).clamp(320.0, 860.0);
    final maxH = math.min(sz.height * 0.82, 580.0).clamp(280.0, 580.0);

    const topBarH = 48.0;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: maxW,
            height: maxH,
            child: Material(
              color: Colors.black,
              elevation: 18,
              borderRadius: BorderRadius.circular(16.r),
              child: Column(
                children: [
                  Container(
                    height: topBarH,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    color: Colors.black.withOpacity(0.55),
                    child: Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'فيديو'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            // ✅ اطفي قبل الخروج
                            _stopAllWebVideos();
                            Get.back();
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox.expand(
                      child: Stack(
                        children: [
                          // ✅ HtmlElementView للفيديو (key ثابت لمنع غرائب platform-view)
                          HtmlElementView(
                            key: ValueKey(widget.viewType),
                            viewType: widget.viewType,
                          ),

                          if (!_videoReady)
                            Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'جاري تحضير الفيديو...'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: AppTextStyles.medium,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  MediaItem({required this.type, required this.url});
}




