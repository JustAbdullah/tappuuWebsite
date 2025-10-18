import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_website/controllers/AdsManageSearchController.dart';
import 'package:tappuu_website/controllers/sharedController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:html' as html; // أضف هذا الاستيراد

import '../../controllers/CurrencyController.dart';
import '../../controllers/FavoriteSellerController.dart';
import '../../controllers/FavoritesController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/ViewsController.dart';
import '../../controllers/ad_report_controller.dart';
import '../../controllers/areaController.dart';

import '../../controllers/favorite_groups_controller.dart';
import '../../core/data/model/AdResponse.dart';
import '../../core/data/model/favorite.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../customWidgets/EditableTextWidget.dart';
import '../AdvertiserAdsScreen/AdvertiserAdsScreen.dart';
import '../HomeScreen/menubar.dart';
import 'AdsScreen.dart';
import 'ConversationScreen.dart';

class AdDetailsScreen extends StatefulWidget {
  final Ad ad;
  final String? categorySlug;
  final String? subCategorySlug;
  final String? subTwoCategorySlug;

  const AdDetailsScreen({
    super.key, 
    required this.ad,
    this.categorySlug,
    this.subCategorySlug,
    this.subTwoCategorySlug,
  });

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
    final ScrollController _scrollController = ScrollController();
      final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showAdvertiserDialog = false;
  final AdReportController _reportController = Get.put(AdReportController());
  final ViewsController _viewsController = Get.put(ViewsController());
  final FavoritesController _favoritesController = Get.put(FavoritesController());
  final FavoriteGroupsController _favoriteGroupsController = Get.put(FavoriteGroupsController());
  final AdsController _adsController = Get.put(AdsController());
  final LoadingController _loadingController = Get.put(LoadingController());
  FavoriteSellerController favoriteSellerController = Get.put(FavoriteSellerController());
  bool _isFavorite = false;
  bool _viewLogged = false;
  int _selectedTabIndex = 0;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoPlaying = false;
  String? _playingVideoUrl;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _safeCloseDialogOne();
    if (!_viewLogged) {
      _viewsController.checkIsHaveAccount(widget.ad.id);
      _adsController.incrementViews(widget.ad.id);
      _viewLogged = true;
    }
    
    // تحديث رابط المتصفح بعد تحميل البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBrowserUrl();
    });
  }

  void _updateBrowserUrl() {
    final adId = widget.ad.id;
    final adSlug = widget.ad.slug; // افترضنا أن في نموذج Ad هناك حقل slug
    
    String urlPath = '/ad/$adId';
    if (adSlug != null && adSlug.isNotEmpty) {
      urlPath += '-$adSlug';
    }
    
    html.window.history.replaceState({}, '', urlPath);
  }


void _safeCloseDialogOne() {
  try {
    if (Get.isDialogOpen ?? false) {
      // أغلق الـ Snackbar أولاً إذا كان مفتوحاً
      if (Get.isSnackbarOpen ?? false) {
        Get.closeAllSnackbars();
      }
      // أغلق الـ Dialog باستخدام Navigator العادي
      Navigator.of(context).pop();
    }
  } catch (e) {
    debugPrint('Error closing dialog: $e');
  }
}
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    final sharedController = Get.put(SharedController());
    sharedController.markDeepLinkHandled();
            _scrollController.dispose();

    sharedController.isNavigatingToAd.value = false;
    super.dispose();
  }


  Future<void> _scrollToBottomAnimated({Duration duration = const Duration(milliseconds: 500)}) async {
    try {
      // تأكد أن الـ controller جاهز
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      // animateTo سيصعد أو ينزل بحسب القيمة
      await _scrollController.animateTo(
        max,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      // تجاهل الأخطاء الخفيفة (مثل: no scroll attached yet)
      // print('scroll error: $e');
    }
  }
  void _cleanUpVideoControllers() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    if (mounted) {
      setState(() {
        _isVideoPlaying = false;
        _playingVideoUrl = null;
        _videoError = false;
      });
    }
  }

  void _initializeVideoPlayer(String videoUrl) async {
    _cleanUpVideoControllers();

    setState(() {
      _isVideoPlaying = false;
      _videoError = false;
      _playingVideoUrl = videoUrl;
    });

    try {
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoController!.value.aspectRatio,
        showControls: true,
      );

      setState(() {
        _isVideoPlaying = true;
      });
    } catch (e) {
      setState(() {
        _videoError = true;
      });
    }
  }




//////////المفضلة////
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
    } catch (e) {
      return null;
    }
  }
  return null;
}

// ---------- الدوال المعدّلة بالكامل (انسخ ولصق داخل State) ----------

void _checkFavoriteStatus() {
  _favoritesController.checkIsHaveAccountFavorite(widget.ad.id);
  setState(() {});
}

void _toggleFavorite() async {
  final userId = _loadingController.currentUser?.id;
  if (userId == null) {
    Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول لإضافة إلى المفضلة'.tr,
        snackPosition: SnackPosition.BOTTOM);
    return;
  }

  if (_isFavorite) {
    // محاولة إزالة من المفضلة (optimistic UI)
    setState(() {
      _isFavorite = false;
    });

    try {
      await _favoritesController.removeFavorite(
        userId: userId,
        adId: widget.ad.id,
      );
      final loading = Get.find<LoadingController>();
      await loading.unsubscribeFromTopicPublic('AdId_${widget.ad.id}');
      Get.rawSnackbar(title: 'نجاح', message: 'تمت الإزالة من المفضلة', duration: Duration(seconds: 2));
    } catch (e) {
      setState(() {
        _isFavorite = true;
      });
      Get.rawSnackbar(title: 'خطأ', message: 'فشل إزالة الإعلان من المفضلة', duration: Duration(seconds: 2));
      debugPrint('removeFavorite error: $e');
    }
  } else {
    // افتح اختيار المجموعة — الإضافة الفعلية تُجرى لاحقاً بعد تأكيد إعدادات الإشعارات
    _showFavoriteGroups();
  }
}

void _showFavoriteGroups() async {
  final userId = _loadingController.currentUser?.id;
  if (userId == null) return;

  await _favoriteGroupsController.fetchGroups(userId: userId);

  final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.surface(isDarkMode);
  final dividerColor = AppColors.divider(isDarkMode);

  // استخدم builder context داخل Get.dialog، ونستخدم Navigator.pop(context) داخلياً لإغلاق دون تعارض
  Get.dialog(
    Builder(builder: (ctx) {
      return Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.85,
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
                // زر الإغلاق باستخدام السياق المحلي
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
                    child: Text('احفظ في قائمة المفضلة',
                        style: TextStyle(
                            fontSize: AppTextStyles.medium,

                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily)),
                  ),
                ),

                Divider(height: 1.h, thickness: 0.8, color: dividerColor),
                SizedBox(height: 16.h),

                Obx(() {
                  if (_favoriteGroupsController.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (_favoriteGroupsController.groups.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Text('لا توجد مجموعات مفضلة', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                    );
                  }

                  return Container(
                    constraints: BoxConstraints(maxHeight: 200.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _favoriteGroupsController.groups.length,
                      itemBuilder: (context, index) {
                        final group = _favoriteGroupsController.groups[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                          title: Center(
                            child: Text(group.name,
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16.sp)),
                          ),
                          onTap: () {
                            // close current dialog via local context, then show notification dialog
                            Navigator.of(ctx).pop();
                            final double? currentPrice = _parsePriceDynamic(widget.ad.price);
                            _showPriceNotificationDialog(userId, group.id, currentPrice: currentPrice);
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
                    _createNewGroup(userId);
                  },
                  child: Text('إنشاء قائمة جديدة',
                      style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,

                          color: AppColors.buttonAndLinksColor,
                          fontWeight: FontWeight.bold)),
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
/// عرض دياج إنشاء مجموعة جديدة (نفس تصميم الدياج الحديث)
Future<void> _createNewGroup(int userId) async {
  final nameController = TextEditingController();
  final isDark = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.card(isDark);
  final textColor = AppColors.textPrimary(isDark);

  await Get.dialog(
    Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
                  onPressed: () => Get.back(), // إغلاق الدياج
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
                        duration: Duration(seconds: 2));
                      return;
                    }

                    // اغلق الدياج أولاً
                    Get.back();

                    // انشئ المجموعة عبر الكنترولر
                    try {
                      final newGroup = await _favoriteGroupsController.createGroup(
                        userId: userId,
                        name: name,
                      );

                      if (newGroup != null) {
                        // عرض سناك نجاح قصير
                        Get.snackbar('نجاح'.tr, 'تم إنشاء مجموعة جديدة'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 2));

                        // أعد تحميل المجموعات ثم افتح دياج المجموعات
                        await _favoriteGroupsController.fetchGroups(userId: userId);

                        // افتح قائمة المجموعات ليختار المستخدم (أو ليرى المجموعة المضافة)
                        // استدعاء دالة عرض القوائم الموجودة عندك
                        _showFavoriteGroups();
                      } else {
                        // لو لم تُنشأ رغم عدم رمي استثناء
                        Get.snackbar('خطأ'.tr, 'فشل إنشاء المجموعة'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 2));
                      }
                    } catch (e, st) {
                      debugPrint('createGroup error: $e\n$st');
                      Get.snackbar('خطأ'.tr, 'حدث خطأ أثناء الإنشاء'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: Duration(seconds: 2));
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
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
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
    barrierDismissible: true,
  );
}

/// دياج الإعدادات قبل الإضافة — يعرض السعر كما هو (ل.س) ويتيح "اعلام دائماً" أو الذهاب لصفحة تحديد السعر
void _showPriceNotificationDialog(int userId, int groupId, {double? currentPrice}) {
  final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.surface(isDarkMode);
  final textColor = AppColors.textPrimary(isDarkMode);
  final dividerColor = AppColors.divider(isDarkMode);

  final displayPrice = currentPrice != null ? NumberFormat('#,###', 'en_US').format(currentPrice) : (widget.ad.price?.toString() ?? '-');

  Get.dialog(
    Builder(builder: (ctx) {
      return Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.85,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: Offset(0, 6))],
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
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w700, color: textColor),
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
                      _showSetPriceDialog(userId, groupId, currentPrice: currentPrice);
                    },
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h), side: BorderSide(color: AppColors.primary, width: 1.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)), backgroundColor: Colors.transparent),
                    child: Text('أعلمني عندما ينخفض السعر إلى ما دون السعر المحدد', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),

                SizedBox(height: 12.h),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // "اعلام دائماً": اضف المفضلة الآن مع notifyEmail=true notifyPush=true notifyOnAnyChange=true
                      Navigator.of(ctx).pop();
                      final notif = NotificationSettings(
                        notifyEmail: true,
                        notifyPush: true,
                        notifyOnAnyChange: true,
                        minPrice: null,
                        lastNotifiedPrice: null,
                      );

                      final success = await _favoritesController.addFavorite(
                        userId: userId,
                        adId: widget.ad.id,
                        favoriteGroupId: groupId,
                        notificationSettings: notif,
                      );

                      final loading = Get.find<LoadingController>();
                      final topic = 'AdId_${widget.ad.id}';

                      if (success) {
                        await loading.subscribeToTopicPublic(topic);
                        setState(() {
                          _isFavorite = true;
                        });
                        Get.rawSnackbar(title: 'تم التفعيل', message: 'تمت الإضافة للمفضلة وتفعيل الإشعارات', duration: Duration(seconds: 2));
                      } else {
                        Get.rawSnackbar(title: 'خطأ', message: 'فشل حفظ التفضيلات', duration: Duration(seconds: 2));
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14.h), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)), backgroundColor: AppColors.buttonAndLinksColor),
                    child: Text('اعلام دائماً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w700, color: Colors.white)),
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

/// شاشة تحديد السعر — تفاعلية، تستخدم سياق builder محلي لكل زر إغلاق/حفظ
void _showSetPriceDialog(int userId, int groupId, {double? currentPrice}) {
  final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.surface(isDarkMode);
  final textColor = AppColors.textPrimary(isDarkMode);
  final dividerColor = AppColors.divider(isDarkMode);

  final priceController = TextEditingController();
  if (currentPrice != null) {
    // عرض السعر كما هو (بدون ضرب ×10)
    priceController.text = NumberFormat('#,###', 'en_US').format(currentPrice);
  }

  Get.dialog(
    Builder(builder: (ctx) {
      // المتغيرات تُعرف هنا (خارج StatefulBuilder) حتى لا تُعاد تهيئتها عند كل rebuild
      int selectedRadio = 2; // 1=every change, 2=below target, 3=mute
      bool notifyEmail = true;
      bool notifyMobile = true;

      bool showTargetInput() => selectedRadio == 2;

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.86,
            height: MediaQuery.of(ctx).size.height * 0.72,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(8.r)),
            child: StatefulBuilder(builder: (context, setState) {
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Header: Title + Close
                Row(children: [
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
                    child: Padding(padding: EdgeInsets.all(6.w), child: Icon(Icons.close, size: 22.w, color: textColor)),
                  ),
                ]),

                SizedBox(height: 10.h),
                Container(height: 8.h, color: dividerColor.withOpacity(0.25)),
                SizedBox(height: 10.h),

                // Body (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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

                      // Radio 1: كل مرة
                      InkWell(
                        onTap: () => setState(() => selectedRadio = 1),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 1,
                              groupValue: selectedRadio,
                              onChanged: (v) => setState(() => selectedRadio = v ?? selectedRadio),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                'أعلمني في كل مرة يتغير فيها السعر',
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Radio 2: سعر محدد
                      InkWell(
                        onTap: () => setState(() => selectedRadio = 2),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 2,
                              groupValue: selectedRadio,
                              onChanged: (v) => setState(() => selectedRadio = v ?? selectedRadio),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                'أعلمني عندما ينخفض السعر إلى ما دون السعر المحدد',
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Text(
                        'السعر الحالي (ل.س)',
                        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w700, color: textColor),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: currentPrice != null ? NumberFormat('#,###', 'en_US').format(currentPrice) : (widget.ad.price?.toString() ?? '-'),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.grey.shade100,
                          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // الحقل الظاهر فقط لو اخترنا السعر المحدد
                      if (showTargetInput()) ...[
                        Text(
                          'السعر الذي حددته (ل.س)',
                          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w700, color: textColor),
                        ),
                        SizedBox(height: 8.h),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                          decoration: InputDecoration(hintText: 'أدخل السعر الذي حددته', border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r))),
                        ),
                        SizedBox(height: 12.h),
                      ],

                      // Radio 3: كتم
                      InkWell(
                        onTap: () => setState(() => selectedRadio = 3),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: 3,
                              groupValue: selectedRadio,
                              onChanged: (v) => setState(() => selectedRadio = v ?? selectedRadio),
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                'كتم إشعارات الأسعار',
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),
                      Divider(height: 1.h, thickness: 0.8, color: dividerColor),
                      SizedBox(height: 12.h),

                      Text('قناة الإشعارات', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.w700, color: textColor)),
                      SizedBox(height: 10.h),

                      // Email checkbox
                      GestureDetector(
                        onTap: () => setState(() => notifyEmail = !notifyEmail),
                        child: Row(
                          children: [
                            Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(color: AppColors.textSecondary(isDarkMode), width: 1.2),
                                color: notifyEmail ? AppColors.primary : Colors.transparent,
                              ),
                              child: notifyEmail ? Icon(Icons.check, size: 18.w, color: Colors.white) : SizedBox.shrink(),
                            ),
                            SizedBox(width: 10.w),
                            Text('إشعار البريد الإلكتروني', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: textColor)),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Mobile checkbox
                      GestureDetector(
                        onTap: () => setState(() => notifyMobile = !notifyMobile),
                        child: Row(
                          children: [
                            Container(
                              width: 28.w,
                              height: 28.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(color: AppColors.buttonAndLinksColor, width: 1.2),
                                color: notifyMobile ? AppColors.buttonAndLinksColor : Colors.transparent,
                              ),
                              child: notifyMobile ? Icon(Icons.check, size: 18.w, color: Colors.white) : SizedBox.shrink(),
                            ),
                            SizedBox(width: 10.w),
                            Text('إشعارات الهاتف المحمول', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: textColor)),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),
                    ]),
                  ),
                ),

                // Footer buttons
                SizedBox(height: 8.h),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.buttonAndLinksColor, width: 1.4), padding: EdgeInsets.symmetric(vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      child: Text('إلغاء', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.buttonAndLinksColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                     onPressed: () async {
  // تحقق إدخال السعر لو وضع target
  if (selectedRadio == 2 && priceController.text.trim().isEmpty) {
    Get.snackbar('', 'من فضلك أدخل السعر الذي تريده', snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      backgroundColor: Colors.black87, colorText: Colors.white, duration: Duration(seconds: 2));
    return;
  }

  // parse targetPrice (المستخدم يدخل بالل.س مباشرة)
  double? targetPrice;
  if (priceController.text.trim().isNotEmpty) {
    final normalized = priceController.text.replaceAll('.', '').replaceAll(',', '').trim();
    try {
      targetPrice = double.parse(normalized);
    } catch (e) {
      targetPrice = null;
    }
  }

  // قرّر وضع الحفظ (mode) والقيم التي نمرّرها للدالة الموحدة
  final mode = selectedRadio; // 1,2,3
  bool passNotifyEmail;
  bool passNotifyMobile;

  if (mode == 3) {
    passNotifyEmail = false;
    passNotifyMobile = false;
  } else if (mode == 1) {
    passNotifyEmail = true;
    passNotifyMobile = true;
  } else {
    // mode == 2 -> نمرر ما اختاره المستخدم في الشيكبوكس
    passNotifyEmail = notifyEmail;
    passNotifyMobile = notifyMobile;
  }

  // استدعي الدالة الموحدة
  final bool ok = await _setNotificationPreference(
    userId,
    groupId,
    targetPrice,
    mode: mode,
    notifyEmail: passNotifyEmail,
    notifyMobile: passNotifyMobile,
  );

  if (ok) {
    Navigator.of(ctx).pop(); // أغلق الدياج بعد النجاح
  } else {
    // الدالة عرضت سناك خطأ؛ يمكنك هنا إبقاء الدياج مفتوح للسماح للمستخدم بالمحاولة
  }
},

                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonAndLinksColor, padding: EdgeInsets.symmetric(vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
                      child: Text('حفظ', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ]);
            }),
          ),
        ),
      );
    }),
    barrierDismissible: true,
  );
}


// دالة منفصلة تبقى متاحة إذا أردت استدعاء تحديث لاحقاً
/// ------------ دالة موحّدة لحفظ/تحديث تفضيلات الإشعار وإدارة الاشتراكات ------------
Future<bool> _setNotificationPreference(int userId, int groupId, double? targetPrice, {
  required int mode, // 1=every change,2=when below target,3=mute
  required bool notifyEmail,
  required bool notifyMobile,
}) async {
  final notif = NotificationSettings(
    notifyEmail: notifyEmail,
    notifyPush: notifyMobile,
    notifyOnAnyChange: mode == 1,
    minPrice: mode == 2 ? targetPrice : null,
    lastNotifiedPrice: null,
  );

  try {
    final success = await _favoritesController.addFavorite(
      userId: userId,
      adId: widget.ad.id,
      favoriteGroupId: groupId,
      notificationSettings: notif,
    );

    final loading = Get.find<LoadingController>();
    final topic = 'AdId_${widget.ad.id}';

    if (!success) {
      Get.rawSnackbar(title: 'خطأ', message: 'فشل حفظ تفضيلات الإشعارات', duration: Duration(seconds: 2));
      return false;
    }

    // إدارة اشتراكات FCM
    if (mode == 3) {
      // كتم → إلغاء الاشتراك من القناة
      await loading.unsubscribeFromTopicPublic(topic);
    } else {
      if (notifyMobile) {
        await loading.subscribeToTopicPublic(topic);
      } else {
        await loading.unsubscribeFromTopicPublic(topic);
      }
    }

    // تحديث الواجهة محليًا
    setState(() {
      _isFavorite = true;
    });

    Get.rawSnackbar(title: 'تم الحفظ', message: 'تم تعيين تفضيلات الإشعارات بنجاح', duration: Duration(seconds: 2));
    return true;
  } catch (e, st) {
    debugPrint('Exception in _setNotificationPreference: $e\n$st');
    Get.rawSnackbar(title: 'خطأ', message: 'حدث خطأ أثناء حفظ التفضيلات', duration: Duration(seconds: 2));
    return false;
  }
}


//////////
  void _stopVideo() {
    if (_chewieController != null && _chewieController!.isPlaying) {
      _chewieController!.pause();
    }
    setState(() {
      _isVideoPlaying = false;
      _playingVideoUrl = null;
    });
  }


///////////////

void _handleReportAd() {
  final user = Get.find<LoadingController>().currentUser;
  if (user == null) {
    Get.snackbar(
      'تنبيه'.tr, 
      'يجب تسجيل الدخول لتقديم بلاغ'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 3),
    );
    return;
  }
  
  // إذا كان المستخدم مسجلاً، اعرض نموذج الإبلاغ
  _showReportDialog();
}

void _showReportDialog() {
  final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.surface(isDarkMode);
  final textColor = AppColors.textPrimary(isDarkMode);
  final successColor = Colors.green;
  final errorColor = Colors.red;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        // نقل المتغيرات داخل StatefulBuilder
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
              'ad_id': widget.ad.id,
              'reason': selectedReason,
              'details': detailsController.text,
              'reporter_id': Get.find<LoadingController>().currentUser?.id,
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
              await Future.delayed(Duration(seconds: 2));
              if (context.mounted) {
                Get.back();
                Get.snackbar(
                  'شكراً لك'.tr,
                  'تم استلام بلاغك وسيتم مراجعته'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: successColor,
                  colorText: Colors.white,
                  duration: Duration(seconds: 3),
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
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 5,
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
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
                
                // سبب الإبلاغ
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
                
                // قائمة أسباب الإبلاغ - تم إصلاح مشكلة التحديث
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
                
                // تفاصيل الإبلاغ
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
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
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
                
                // رسالة النتيجة
                if (message != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSuccess ? successColor.withOpacity(0.15) : errorColor.withOpacity(0.15),
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
                
                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الإلغاء
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
                        child: Text('إلغاء'.tr,
                            style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily)),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    
                    // زر الإرسال
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
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('إرسال البلاغ'.tr,
                                style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    color: Colors.white)),
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


//////
  @override
  Widget build(BuildContext context) {
    AreaController areaController = Get.put(AreaController());
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final cardColor = AppColors.surface(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);
    final areaName = areaController.getAreaNameById(widget.ad.areaId);
    final CurrencyController currencyController = Get.put(CurrencyController());
    SharedController _sharedCtrl = Get.put(SharedController());

    return WillPopScope(
      onWillPop: () async {
        _cleanUpVideoControllers();
        _stopVideo();
        try {
          final shared = Get.find<SharedController>();
          shared.isNavigatingToAd.value = false;
        } catch (_) {}
        return true;
      },
      child: Scaffold(
         key: _scaffoldKey,
      drawer: Menubar(),
        backgroundColor: AppColors.background(isDarkMode),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: SafeArea(
            child: Stack(children: [
                 Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(horizontal: 7.w),
                color: AppColors.appBar(isDarkMode),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   Flexible(
                      flex: 2,
                      child: Row(
                        children: [
                          SizedBox(width:10.w,),
                          InkWell(
                            onTap: (){
                              _cleanUpVideoControllers();
                              _stopVideo();
                               // أغلق أي Snackbar مفتوح أولاً
                              if (Get.isSnackbarOpen ?? false) {
                                Get.closeAllSnackbars();
                              }
                              
                              // ثم ارجع للخلف
                              Get.back();
                            },
                            child: Icon(
                             Icons.arrow_back_ios
                             ,
                              color: AppColors.onPrimary,
                              size: 20.w,
                            ),
                           
                          ),
                                      Container(padding: EdgeInsets.all(4.w), child: InkWell(onTap: () => _scaffoldKey.currentState?.openDrawer(), child: Icon(Icons.menu, color: AppColors.onPrimary, size: 22.w))),
                    
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: Text(
                        'تفاصيل الإعلان'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,

                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Row(
                        children: [
                          InkWell(
                           onTap: _toggleFavorite,
                            child: Icon(Icons.star, 
                                color: _isFavorite ? Colors.yellow : AppColors.onPrimary, 
                                size: 20.w),
                          ),
                          SizedBox(width: 7.w),
                          InkWell(
                            onTap: () => _sharedCtrl.shareAd(widget.ad.id),
                            child: Icon(Icons.share, color: AppColors.onPrimary, size: 20.w),
                          ),

                            SizedBox(width: 7.w),
      // زر الإبلاغ الجديد
      InkWell(
        onTap: _handleReportAd,
        child: Icon(Icons.report, color: AppColors.onPrimary, size: 20.w),
      ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        body: CustomScrollView(
            controller: _scrollController, // <-- حطّه هنا

          slivers: [
            
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 3.h),
                child: Text(
                  widget.ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 15.7.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250.h,
                width: double.infinity,
                child: _MediaGallery(
                  images: widget.ad.images,
                  videos: widget.ad.videos,
                  width: double.infinity,
                  height: 250.h,
                  onVideoTap: (videoUrl) => _initializeVideoPlayer(videoUrl),
                  playingVideoUrl: _playingVideoUrl,
                  isVideoPlaying: _isVideoPlaying,
                  videoError: _videoError,
                  ad: widget.ad,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 5.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: InkWell(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 200),
                            pageBuilder: (_, __, ___) {
                              return Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    padding: EdgeInsets.all(20.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: GestureDetector(
                                            onTap: () => Navigator.of(context).pop(),
                                            child: Icon(Icons.close, size: 24),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'المعاملات'.tr,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.appFontFamily,
                                              fontSize: AppTextStyles.large,

                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: InkWell(
                                            onTap: () {
                                              favoriteSellerController.toggleFavoriteByIds(
                                                userId: _loadingController.currentUser?.id ?? 0,
                                                advertiserProfileId: widget.ad.idAdvertiser,
                                              );
                                            },
                                            child: Text(
                                              'متابعة مالك الإعلان'.tr,
                                              style: TextStyle(
                                                fontFamily: AppTextStyles.appFontFamily,
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
                                            Get.to(() => AdvertiserAdsScreen(
                                                  advertiser: widget.ad.advertiser,
                                                  idAdv: widget.ad.idAdvertiser,
                                                ));
                                          },
                                          child: Text(
                                            '${'جميع إعلانات '.tr}${widget.ad.advertiser.name.toString()}',
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.appFontFamily,
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
                          widget.ad.advertiser.name.toString(),
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 15.7.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonAndLinksColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                       Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                        
                       Text(
  "تاريخ إنشاء الحساب: ${_formatDateTime(widget.ad.advertiser.createdAt!)}",
  style: TextStyle(
    fontFamily: AppTextStyles.appFontFamily,
    fontSize: AppTextStyles.small,
    color: AppColors.grey500,
    height: 1.4,
  ),
  textAlign: TextAlign.center,
),
                       ],
                     ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() => AdsScreen(
                                  titleOfpage: widget.ad.category!.name,
                                  categoryId: widget.ad.category.id,
                                  nameOfMain: widget.ad.category.name,
                                  countofAds: 0,
                                ));
                          },
                          child: Text(
                            widget.ad.category.name,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,

                              fontWeight: FontWeight.w600,
                              color: AppColors.buttonAndLinksColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_right, size: 12.sp, color: AppColors.buttonAndLinksColor),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: () {
                            Get.to(() => AdsScreen(
                                  titleOfpage: widget.ad.subCategoryLevelOne!.name,
                                  categoryId: widget.ad.category.id,
                                  nameOfMain: widget.ad.category.name,
                                  countofAds: 0,
                                  subCategoryId: widget.ad.subCategoryLevelOne.id,
                                  nameOFsub: widget.ad.subCategoryLevelOne.name,
                                ));
                          },
                          child: Text(
                            widget.ad.subCategoryLevelOne.name,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,

                              fontWeight: FontWeight.w600,
                              color: AppColors.buttonAndLinksColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_right, size: 12.sp, color: AppColors.buttonAndLinksColor),
                        SizedBox(width: 4.w),
                        if (widget.ad.subCategoryLevelTwo != null)
                          InkWell(
                            onTap: () {
                              Get.to(() => AdsScreen(
                                    titleOfpage: widget.ad.subCategoryLevelTwo!.name,
                                    categoryId: widget.ad.category.id,
                                    nameOfMain: widget.ad.category.name,
                                    countofAds: 0,
                                    subCategoryId: widget.ad.subCategoryLevelOne.id,
                                    nameOFsub: widget.ad.subCategoryLevelOne.name,
                                    subTwoCategoryId: widget.ad.subCategoryLevelTwo!.id,
                                    nameOFsubTwo: widget.ad.subCategoryLevelTwo!.name,
                                  ));
                            },
                            child: Text(
                              widget.ad.subCategoryLevelTwo!.name,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.small,

                                fontWeight: FontWeight.w600,
                                color: AppColors.buttonAndLinksColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Divider(height: 1, thickness: 0.3, color: AppColors.grey500.withOpacity(0.7)),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() => AdsScreen(titleOfpage: widget.ad.city!.name!, categoryId: null, cityId: widget.ad.city!.id));
                          },
                          child:Text(
                            widget.ad.city!.name.toString(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,

                                  color: AppColors.grey500,

                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                         Text(
                          "/",
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.small,

                            fontWeight: FontWeight.w600,
                              color: AppColors.grey500,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: () {
                          
                            Get.to(() => AdsScreen(titleOfpage: widget.ad.area!.name.toString(), categoryId: null, areaId: widget.ad.area!.id,));
                          },
                          child: Text(
                             widget.ad.area!.name.toString(),
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,

                            
                              color: AppColors.grey500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.background(isDarkMode), borderRadius: BorderRadius.circular(12.r)),
                        child: Row(
                          children: [
                            _buildTabButton(0, 'tabTitle_info'.tr, isDarkMode),
                            _buildTabButton(1, 'tabTitle_desc'.tr, isDarkMode),
                            _buildTabButton(2, 'tabTitle_location'.tr, isDarkMode),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, thickness: 1.8, color: AppColors.yellow),
                    SizedBox(height: 4.h),
                    _buildSelectedTabContent(isDarkMode, textPrimary, textSecondary, cardColor, dividerColor, areaName),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
       bottomNavigationBar:  Obx(() => 
       Visibility(
        visible:!_adsController.showMap.value,
         child: SafeArea(
           minimum: EdgeInsets.only(bottom: 10.h), // مسافة أمنية من الأسفل
           child: _buildContactButtons(widget.ad.advertiser, isDarkMode),
         ),
       ),
      ),
    ));
  }

  Widget _buildTabButton(int index, String title, bool isDarkMode) {
    final bool isSelected = _selectedTabIndex == index;
    final Color bgColor = isSelected
        ? AppColors.yellow
        : isDarkMode
            ? Colors.grey[850]!
            : AppColors.backgroundLight;
    final Color textColor = isDarkMode
        ? Colors.grey[300]!
        : Colors.black;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedTabIndex = index);
 // 2) نفّذ التمرير ب
 //عد الإطار الحالي عشان الـ layout يكون جاهز
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // لو محتوى القسم يحمل من API عند الضغط، استبدل هذا السطر باستدعاء الدالة اللي تجلب البيانات ثم نفّذ _scrollToBottomAnimated بعد اكتمالها.
          await _scrollToBottomAnimated();
        });
          } 
          ,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(minHeight: 40.h),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(0.r),
              border: Border.all(
                color: isSelected ? AppColors.yellow : Colors.black,
                width: isSelected ? 0.w : 0,
              ),
            ),
            child: Center(
              child: EditableTextWidget(
  keyName:title,
  textAlign: TextAlign.center,
  fontWeight: FontWeight.w500,
),
              
            
            ),
          ),
        ),
      ),
    );
  }
String _formatDateTime(DateTime dateTime) {
  // تنسيق التاريخ إلى yyyy/mm/dd
  String year = dateTime.year.toString();
  String month = dateTime.month.toString().padLeft(2, '0');
  String day = dateTime.day.toString().padLeft(2, '0');
  
  return '$year/$month/$day';
}
  Widget _buildSelectedTabContent(
    bool isDarkMode, 
    Color textPrimary, 
    Color textSecondary, 
    Color cardColor, 
    Color dividerColor, 
    String? areaName
  ) {
    switch (_selectedTabIndex) {
      case 0: // معلومات الإعلان
        return _buildAdInformationSection(isDarkMode, textPrimary, textSecondary, cardColor, dividerColor, areaName);
      case 1: // معلومات المعلن
        return _buildAdvertiserSection(widget.ad, isDarkMode);
      case 2: // الموقع الجغرافي
        return _buildLocationSection(isDarkMode, textPrimary);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildAdInformationSection(
    bool isDarkMode, 
    Color textPrimary, 
    Color textSecondary, 
    Color cardColor, 
    Color dividerColor, 
    String? areaName
  ) {
    return _buildAttributesList(
      widget.ad.attributes,
      widget.ad.price ?? 0,
      widget.ad.createdAt,
      widget.ad.ad_number,
      cardColor,
      textPrimary,
      textSecondary
    );
  }

  Widget _buildAdvertiserSection(Ad ad, bool isDarkMode) {
      _adsController.showMap.value =false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Text(
            textAlign: TextAlign.center,
            ad.description,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
      ],
    );
  }
// -----------------------------
// _buildLocationSection + map
// -----------------------------
Widget _buildLocationSection(bool isDarkMode, Color textPrimary) {
  _adsController.showMap.value = true;
  if (widget.ad.latitude == null || widget.ad.longitude == null) {
    return Center(
      child: Text(
        'لا يتوفر موقع جغرافي'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.xlarge,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
    );
  }

  // ارتفاع الخريطة: 80% من ارتفاع الشاشة
  final height = MediaQuery.of(context).size.height * 0.85;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    child: _buildInteractiveMap(widget.ad.latitude!, widget.ad.longitude!, height),
  );
}

Widget _buildInteractiveMap(double latitude, double longitude, double mapHeight) {
  return Container(
    height: mapHeight,
    margin: EdgeInsets.only(bottom: 16.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 1,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        children: [
          // *** الحل: إضافة InteractiveViewer للتحكم في التمرير ***
          InteractiveViewer(
            boundaryMargin: EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.stayinme.app',
                  tileDisplay: const TileDisplay.fadeIn(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude),
                      width: 50.w,
                      height: 50.h,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40.w,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // زر فتح Google Maps
          Positioned(
            bottom: 12.h,
            right: 12.w,
            child: FloatingActionButton.extended(
              heroTag: 'open_google_maps_only_destination',
              backgroundColor: AppColors.primary,
              onPressed: () => _openInGoogleMaps(widget.ad.latitude!, widget.ad.longitude!),
              icon: Icon(Icons.map, size: 18.w),
              label: Text(
                'جوجل',
                style: TextStyle(fontSize: 14.sp, fontFamily: AppTextStyles.appFontFamily),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// -----------------------------
// دالة فتح Google Maps (تمرير إحداثيات الإعلان فقط)
// -----------------------------
Future<void> _openInGoogleMaps(double lat, double lng) async {
  final q = Uri.encodeComponent('$lat,$lng');
  final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  if (await canLaunchUrl(googleMapsUrl)) {
    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    return;
  }

  // فشل، حاول استخدام geo: كبديل
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  if (await canLaunchUrl(geo)) {
    await launchUrl(geo, mode: LaunchMode.externalApplication);
    return;
  }

  Get.snackbar('خطأ', 'تعذر فتح خرائط. تأكد من وجود متصفح أو تطبيق خرائط.', backgroundColor: Colors.red);
}


 Widget _buildAttributesList(
  List<AttributeValue> attributes,
  double price,
  DateTime createdAt,
  String ad_number,
  Color cardColor,
  Color textPrimary,
  Color textSecondary,
) {
  final extraItems = <Map<String, String>>[
    {
      'name': 'السعر'.tr,
      'value': price != 0 ? Get.find<CurrencyController>().formatPrice(price) : '-',
    },
    {
      'name': 'تاريخ النشر'.tr,
      'value': _formatNumericDate(createdAt),
    },
    {
      'name': 'رقم الإعلان'.tr,
      'value': _convertArabicNumbersToEnglish(ad_number.toString()),
    },
  ];

  final totalCount = extraItems.length + attributes.length;
  _adsController.showMap.value = false;

  return Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      separatorBuilder: (_, __) => Divider(
        height: 1.h,
        thickness: 0.8,
        color: Colors.grey.shade300,
        indent: 24.w,
        endIndent: 24.w,
      ),
      itemBuilder: (context, index) {
        String name = extraItems.length > index
            ? extraItems[index]['name']!
            : attributes[index - extraItems.length].name;
        String value = extraItems.length > index
            ? extraItems[index]['value']!
            : _convertArabicNumbersToEnglish(attributes[index - extraItems.length].value);

        Color valueColor;
        if (name == 'السعر'.tr) {
          valueColor = AppColors.buttonAndLinksColor;
        } else if (name == 'رقم الإعلان'.tr) {
          valueColor = AppColors.redId;
        } else if (value.toLowerCase() == 'نعم' || value.toLowerCase() == 'لا') {
          valueColor = value.toLowerCase() == 'نعم' ? Colors.green : Colors.red;
        } else {
          valueColor = textSecondary;
        }

        // إذا كان هذا هو عنصر السعر، نضيف أيقونة الساعة
        if (name == 'السعر'.tr) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {
                          _showPriceInfoDialog(context);
                        },
                        child:  Icon(
                            Icons.access_time_rounded,
                            color: Colors.blue.shade600,
                            size: 18.w,
                          ),
                       
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // العناصر الأخرى بدون أيقونة الساعة
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
void _showPriceInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الساعة
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: Colors.blue.shade600,
                  size: 32.w,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // النص الجديد: أنت الآن تشاهد أحدث سعر لهذا الإعلان
              Text(
                'أنت الآن تشاهد أحدث سعر لهذا الإعلان'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // الخط الفاصل
              Divider(
                height: 1.h,
                thickness: 1.0,
                color: Colors.grey.shade400,
                indent: 16.w,
                endIndent: 16.w,
              ),
              
              SizedBox(height: 16.h),
              
              // العنوان الأصلي
              Text(
                'تتبع تغيرات سعر الإعلان'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.large,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // الرسالة التوضيحية
              Text(
                'يمكنك تتبع أحدث سعر لهذا الإعلان وتلقي إشعارات عند تغيير السعر من خلال تفعيل التنبيهات في قائمة المفضلة. أضف الإعلان إلى المفضلة واشغل التنبيهات لتبقى على اطلاع بجميع التحديثات.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // زر الإضافة إلى المفضلة
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // هنا يمكنك إضافة دالة إضافة إلى المفضلة
                    _toggleFavorite();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'أضف إلى المفضلة'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // زر الإغلاق
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'حسناً'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildContactButtons(Advertiser advertiser, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: AppColors.surface(isDarkMode),
        border: Border(top: BorderSide(color: AppColors.divider(isDarkMode), width: 1),
      )),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              label: Text(
                'إرسال رسالة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.small,

                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonAndLinksColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.r),
                ),
              ),
              onPressed: () {
                final userId = Get.find<LoadingController>().currentUser?.id;
                if (userId == null) {
                  Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                  return;
                } else {
                  Get.to(() => ConversationScreen(
                    ad: widget.ad,
                    advertiser: advertiser,
                    idAdv: widget.ad.idAdvertiser,
                  ));
                }
              },
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton.icon(
              label: EditableTextWidget(
  keyName: 'functionCell_contact',
  textAlign: TextAlign.center,
  fontWeight: FontWeight.w500,
  height: 0.5.h,
),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonAndLinksColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.r),
                ),
              ),
              onPressed: _showContactBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

void _showContactBottomSheet() {
  final themeController = Get.find<ThemeController>();
  final isDarkMode = themeController.isDarkMode.value;
  final textPrimary = AppColors.textPrimary(isDarkMode);
  final cardColor = AppColors.surface(isDarkMode);

  final ad = widget.ad;
  final advertiser = ad.advertiser;
  final member = ad.companyMember;

  // هل المعلن شركة؟
  final bool isCompany = (advertiser.accountType.toLowerCase() == 'company');

  // أرقام التواصل حسب الشرط:
  // لو شركة: كل الأرقام من العضو فقط.
  // غير ذلك: من المعلن (فردي).
  String? _prefer(String? v) => (v != null && v.trim().isNotEmpty) ? v.trim() : null;

  final String? whatsappChatNumber =
      isCompany ? _prefer(member?.whatsappPhone) : _prefer(advertiser.whatsappPhone);

  final String? phoneCallNumber =
      isCompany ? _prefer(member?.contactPhone) : _prefer(advertiser.contactPhone);

  // اتصال واتساب: نفضّل رقم اتصال واتساب الخاص بالعضو، وإن لم يتوفر نستخدم رقم واتساب العضو،
  // أما في الحساب الفردي فنبقيها على رقم واتساب المعلن.
  final String? whatsappCallNumber = isCompany
      ? (_prefer(member?.whatsappCallNumber) ?? _prefer(member?.whatsappPhone))
      : _prefer(advertiser.whatsappPhone);

  showModalBottomSheet(
    context: context,
    backgroundColor: cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
    ),
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط العنوان + بادج بريميوم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ad.is_premium == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD7D7D6), Color(0xFFEBEBE1), Color(0xFFD7D7D6)],
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Premium offer',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    ad.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // معلومات المعلن (شركة: اسم شركة + عضو / فردي: اسم المعلن)
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: (advertiser.logo.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.network(
                            advertiser.logo,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.apartment, size: 30.w, color: AppColors.primary),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: isCompany
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // اسم الشركة
                            Text(
                              advertiser.name ?? 'شركة',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.xlarge,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            // اسم العضو (لو موجود)
                            if ((member?.displayName ?? '').isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16.sp, color: AppColors.textSecondary(isDarkMode)),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      member!.displayName,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        color: AppColors.textSecondary(isDarkMode),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        )
                      : Text(
                          advertiser.name ?? 'معلن',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.xlarge,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // أزرار التواصل (كلها تعتمد على العضو عند الشركة)
            Column(
              children: [
                // زر محادثة واتساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.message, color: Colors.white, size: 24.w),
                    label: Text(
                      'محادثة واتساب'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: (whatsappChatNumber == null)
                        ? null
                        : () => _launchWhatsAppChat(whatsappChatNumber),
                  ),
                ),

                SizedBox(height: 12.h),

                // زر الاتصال المباشر
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone, color: Colors.white, size: 24.w),
                    label: Text(
                      'اتصال مباشر'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonAndLinksColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: (phoneCallNumber == null)
                        ? null
                        : () => _makePhoneCall(phoneCallNumber),
                  ),
                ),

                SizedBox(height: 12.h),

                // زر الاتصال عبر واتساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone_in_talk, color: Colors.white, size: 24.w),
                    label: Text(
                      'اتصال واتساب'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: (whatsappCallNumber == null)
                        ? null
                        : () => _launchWhatsAppCall(whatsappCallNumber),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),
          ],
        ),
      );
    },
  );
}

// دالة لتحويل الأرقام العربية إلى إنجليزية
String _convertArabicNumbersToEnglish(String input) {
  const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  
  String result = input;
  for (int i = 0; i < arabicNumbers.length; i++) {
    result = result.replaceAll(arabicNumbers[i], englishNumbers[i]);
  }
  return result;
}

// دالة لتنسيق التاريخ بالأرقام الإنجليزية
String _formatNumericDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$year-$month-$day';
}

// دالة لفتح محادثة واتساب
Future<void> _launchWhatsAppChat(String phone) async {
  final url = 'https://wa.me/$phone';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    Get.snackbar('خطأ'.tr, 'تعذر فتح واتساب'.tr);
  }
}

// دالة لفتح اتصال واتساب مباشر
Future<void> _launchWhatsAppCall(String phone) async {
  final url = 'https://wa.me/$phone?text=${Uri.encodeComponent('')}';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    Get.snackbar('خطأ'.tr, 'تعذر فتح واتساب'.tr);
  }
}

Future<void> _makePhoneCall(String phone) async {
  final url = 'tel:$phone';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    Get.snackbar('خطأ'.tr, 'تعذر إجراء المكالمة'.tr);
  }
}}

class _MediaGallery extends StatefulWidget {
  final List<String> images;
  final List<String> videos;
  final double width;
  final double height;
  final Function(String) onVideoTap;
  final String? playingVideoUrl;
  final bool isVideoPlaying;
  final bool videoError;
  final Ad ad;

  const _MediaGallery({
    required this.images,
    required this.videos,
    required this.width,
    required this.height,
    required this.onVideoTap,
    this.playingVideoUrl,
    this.isVideoPlaying = false,
    this.videoError = false,
    required this.ad,
  });

  @override
  _MediaGalleryState createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<_MediaGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<MediaItem> get _mediaItems {
    return [
      ...widget.images.map((url) => MediaItem(type: MediaType.image, url: url)),
      ...widget.videos.map((url) => MediaItem(type: MediaType.video, url: url)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final items = _mediaItems;
    if (items.isEmpty) {
      return Center(child: Icon(Icons.image, size: 100.w, color: Colors.grey));
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: items.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (ctx, index) {
            final item = items[index];

            if (widget.playingVideoUrl == item.url) {
              if (widget.videoError) {
                return _buildVideoErrorState(item.url);
              } else if (widget.isVideoPlaying) {
                return Chewie(
                  controller: ChewieController(
                    videoPlayerController: VideoPlayerController.network(item.url),
                    autoPlay: true,
                    looping: false,
                    allowFullScreen: true,
                    aspectRatio: 16 / 9,
                    showControls: true,
                    materialProgressColors: ChewieProgressColors(
                      playedColor: AppColors.primary,
                      handleColor: AppColors.primary,
                      backgroundColor: Colors.grey[700]!,
                      bufferedColor: Colors.grey[500]!,
                    ),
                    placeholder: Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __) => _buildVideoErrorState(item.url),
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                      SizedBox(height: 16.h),
                      Text('جاري تحميل الفيديو...', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                    ],
                  ),
                );
              }
            }

            return item.type == MediaType.video
                ? _buildVideoThumbnail(item.url)
                : _buildImageDisplay(item.url);
          },
        ),

        Positioned(
          bottom: 10.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${_currentIndex + 1}/${items.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTextStyles.medium,

                  fontFamily: AppTextStyles.appFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0.h,
          right: 0.w,
          left: 0.w,
          child: Divider(
            height: 5,
            thickness: 10,
            color: Color(0XFF40485D),
          ),
        ),
        Positioned(
          bottom: 0.h,
          right: 12.w,
          child: _buildPremiumBadge(widget.ad),
        ),
      ],
    );
  }

  Widget _buildPremiumBadge(Ad ad) {
    if (ad.is_premium != true) {
      return Container();
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(215, 219, 219, 218),
            const Color.fromARGB(246, 235, 235, 225),
            const Color.fromARGB(215, 219, 219, 218),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(0.r),
      ),
      child: Text(
        'Premium offer',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: 9.5.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String url) {
    return GestureDetector(
      onTap: () => widget.onVideoTap(url),
      child: Stack(fit: StackFit.expand, children: [
        Image.network(
          _getVideoThumbnail(url),
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
          loadingBuilder: (c, child, prog) {
            if (prog == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: prog.expectedTotalBytes != null
                    ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[800],
            child: Center(child: Icon(Icons.videocam_off, size: 50.w, color: Colors.grey)),
          ),
        ),
        Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: Icon(Icons.play_arrow, size: 50.w, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  Widget _buildImageDisplay(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (c, child, prog) {
        if (prog == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: prog.expectedTotalBytes != null
                ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                : null,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.broken_image, size: 50.w, color: Colors.grey),
            SizedBox(height: 10.h),
            Text('تعذر تحميل الصورة', style: TextStyle(fontSize: 16.sp)),
          ]),
        ),
      ),
    );
  }

  Widget _buildVideoErrorState(String url) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 60.w, color: Colors.red),
          SizedBox(height: 20.h),
          Text('حدث خطأ في تحميل الفيديو',
              style: TextStyle(fontSize: AppTextStyles.xlarge,
 color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
            ),
            onPressed: () => widget.onVideoTap(url),
          ),
        ]),
      ),
    );
  }

  String _getVideoThumbnail(String url) =>
      'https://img.freepik.com/free-photo/abstract-blur-empty-green-gradient-studio-well-use-as-background-website-template-frame-business-report_1258-54622.jpg';
}

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;
  MediaItem({required this.type, required this.url});
}