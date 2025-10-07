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
import 'dart:html' as html;
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
  int _selectedBottomTab = 0;
  bool _isFavorite = false;
  final LoadingController _loadingController = Get.put(LoadingController());
  FavoriteSellerController favoriteSellerController = Get.put(FavoriteSellerController());
  final FavoritesController _favoritesController = Get.put(FavoritesController());
  final FavoriteGroupsController _favoriteGroupsController = Get.put(FavoriteGroupsController());
  bool _isSeoDataLoading = false;

  @override
  void initState() {
    super.initState();
    // نحاول الحصول على الإعلان من الوسيطات إذا لم يتم توفيره في constructor
    _ad = widget.ad ?? Get.arguments?['ad'];
    if (_ad == null) {
      // إذا لم يكن الإعلان متوفرًا، نعود للشاشة السابقة
      Get.back();
      Get.snackbar('خطأ', 'لم يتم العثور على تفاصيل الإعلان');
      return;
    }

    
    _updateBrowserUrl();
    _loadSeoData(); // تحميل بيانات SEO
  }

  // دالة جديدة لتحميل بيانات SEO
  Future<void> _loadSeoData() async {
    setState(() {
      _isSeoDataLoading = true;
    });
    
    try {
      final seoData = await _adsController.fetchSeoData(_ad!.id);
      if (seoData.isNotEmpty && seoData['metaTitle'] != null) {
        _adsController.updateDocumentHead(seoData);
      } else {
        // إذا كانت بيانات SEO فارغة أو غير متوفرة
        _adsController.handleMissingSeoData();
      }
    } catch (e) {
      debugPrint('Error loading SEO data: $e');
      _adsController.handleMissingSeoData();
    } finally {
      setState(() {
        _isSeoDataLoading = false;
      });
    }
  }

  // دالة لتحديث رابط المتصفح
  void _updateBrowserUrl() {
    if (_ad == null) return;
    
    final newUrl = '/ad/${_ad!.id}-${_ad!.slug}';
    final currentPath = html.window.location.pathname;
    
    // فقط قم بالتحديث إذا كان الرابط الحالي مختلف
    if (currentPath != newUrl) {
      html.window.history.replaceState({}, '', newUrl);
    }
  }



  // دالة للحصول على رابط المشاركة
  String get shareableUrl {
    if (_ad == null) return '';
    final baseUrl = html.window.location.origin;
    return '$baseUrl/ad/${_ad!.id}-${_ad!.slug}';
  }

  // أضف زر المشاركة في الواجهة
  Widget _buildShareButton(bool isDarkMode) {
    return IconButton(
      icon: Icon(Icons.share, size: 22.w),
      onPressed: () {
        // نسخ الرابط إلى الحافظة
        Clipboard.setData(ClipboardData(text: shareableUrl));
        Get.snackbar('تم النسخ', 'تم نسخ رابط الإعلان إلى الحافظة');
      },
      tooltip: 'مشاركة الرابط',
    );
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
  _favoritesController.checkIsHaveAccountFavorite(widget.ad!.id);
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
        adId: widget.ad!.id,
      );
      final loading = Get.find<LoadingController>();
      await loading.unsubscribeFromTopicPublic('AdId_${widget.ad!.id}');
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
                            final double? currentPrice = _parsePriceDynamic(widget.ad!.price);
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
                    _createNewGroup(userId,ctx);
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
Future<void> _createNewGroup(int userId, BuildContext ctx) async {
  final nameController = TextEditingController();
  final isDark = Get.find<ThemeController>().isDarkMode.value;
  final cardColor = AppColors.card(isDark);
  final textColor = AppColors.textPrimary(isDark);

  await Get.dialog(
    Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h), // مسافة من الحواف
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(ctx).size.width * 0.3, // 👈 30% من عرض الشاشة
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
                          duration: Duration(seconds: 2));
                        return;
                      }

                      Get.back();

                      try {
                        final newGroup = await _favoriteGroupsController.createGroup(
                          userId: userId,
                          name: name,
                        );

                        if (newGroup != null) {
                          Get.snackbar('نجاح'.tr, 'تم إنشاء مجموعة جديدة'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: Duration(seconds: 2));

                          await _favoriteGroupsController.fetchGroups(userId: userId);
                          _showFavoriteGroups();
                        } else {
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

  final displayPrice = currentPrice != null ? NumberFormat('#,###', 'en_US').format(currentPrice) : (widget.ad!.price?.toString() ?? '-');

  Get.dialog(
    Builder(builder: (ctx) {
      return Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.30,
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
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w700, color: textColor),
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
                    child: Text('أعلمني عندما ينخفض السعر إلى ما دون السعر المحدد', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                        adId: widget.ad!.id,
                        favoriteGroupId: groupId,
                        notificationSettings: notif,
                      );

                      final loading = Get.find<LoadingController>();
                      final topic = 'AdId_${widget.ad!.id}';

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
                    child: Text('اعلام دائماً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w700, color: Colors.white)),
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
            width: MediaQuery.of(ctx).size.width * 0.46,
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
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: textColor),
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
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Text(
                        'السعر الحالي (ل.س)',
                        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: currentPrice != null ? NumberFormat('#,###', 'en_US').format(currentPrice) : (widget.ad!.price?.toString() ?? '-'),
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
                          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w700, color: textColor),
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
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12.h),
                      Divider(height: 1.h, thickness: 0.8, color: dividerColor),
                      SizedBox(height: 12.h),

                      Text('قناة الإشعارات', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w700, color: textColor)),
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
                            Text('إشعار البريد الإلكتروني', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: textColor)),
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
                            Text('إشعارات الهاتف المحمول', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: textColor)),
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
                      child: Text('إلغاء', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.buttonAndLinksColor, fontWeight: FontWeight.w600)),
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
                      child: Text('حفظ', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: Colors.white, fontWeight: FontWeight.w700)),
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
      adId: widget.ad!.id,
      favoriteGroupId: groupId,
      notificationSettings: notif,
    );

    final loading = Get.find<LoadingController>();
    final topic = 'AdId_${widget.ad!.id}';

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
}void _handleReportAd() {
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
  final AdReportController _reportController = Get.put(AdReportController());


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
              'ad_id': widget.ad?.id??0,
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


//////////////


  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final HomeController _homeController = Get.find<HomeController>();
  final FavoritesController _favoritesController = Get.put(FavoritesController());


 



    return Obx(() {
      return Scaffold(
        endDrawer: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _homeController.isServicesOrSettings.value
              ? SettingsDrawerDeskTop(key: const ValueKey(1))
              : DesktopServicesDrawer(key: const ValueKey(2)),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        body: Column(
          children: [
            // القوائم العلوية
            TopAppBarDeskTop(),
            SecondaryAppBarDeskTop(),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── الصف الرئيسي (الصور - الخصائص - المعلن) ────────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.ad!.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkMode),
                            ),
                          ),
                          Row(
                            children: [

                         
                              InkWell(
                                                 onTap: _toggleFavorite,

                                child: Text(
                                _isFavorite?"ازل من المفضلة":

                                  "اضف إلى مفضلتي".tr,
                                  style: TextStyle(
                                   fontSize: AppTextStyles.medium,
                                    fontWeight: FontWeight.bold,
                                    color:_isFavorite?Colors.red:
                                     AppColors.buttonAndLinksColor,
                                  ),
                                ),
                              ),
                              Icon( _isFavorite?Icons.favorite:
                                Icons.star, 
                                  color: AppColors.textSecondary(isDarkMode),
                                  size: 12.sp),
                                  
                                  SizedBox(width: 10.w,),
                                        SizedBox(
          width:150.w,
          child: ElevatedButton(
            onPressed: (){

                   final userId =  Get.find<LoadingController>().currentUser?.id;
    if (userId == null) {
      Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول للبلاغ '.tr);
      return;
    }
    _handleReportAd();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonAndLinksColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
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
                        // ─── الجزء الأيمن: معرض الوسائط ─────────────────────
                        Expanded(
                          flex: 4,
                          child: _buildMediaGallery(isDarkMode, widget.ad!)
                        ),
                        SizedBox(width: 40.w),

                        // ─── الجزء الأوسط: خصائص الإعلان ──────────────────
                        Expanded(
                          flex: 3,
                          child: _buildAdProperties(isDarkMode, widget.ad!),
                        ),
                        SizedBox(width: 40.w),

                        // ─── الجزء الأيسر: معلومات المعلن ──────────────────
                        Expanded(
                          flex: 3,
                          child: _buildAdvertiserInfo(isDarkMode, widget.ad!),
                        ),
                      ],
                    ),

                    SizedBox(height: 50.h),

                    // ─── تبويبات أسفل المحتوى ─────────────────────────────
                    _buildBottomTabs(isDarkMode),

                    // الفوتر (في نهاية المحتوى وقابل للتمرير)
                    SizedBox(height: 40.h),
                    Footer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── معرض الوسائط (الصور والفيديوهات) ───────────────────────────────────
  Widget _buildMediaGallery(bool isDarkMode, Ad ad) {
    return _MediaGallery(ad: ad, isDarkMode: isDarkMode);
  }

  // ─── خصائص الإعلان ───────────────────────────────────────────────────
  Widget _buildAdProperties(bool isDarkMode, Ad ad) {   
    final currency = Get.put(CurrencyController());

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
                  currency.formatPrice(widget.ad!.price!),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.medium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),   Divider(color: AppColors.divider(isDarkMode)),
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
               widget.ad!.ad_number,
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

          // الفئات (التسلسل الهرمي الجديد)
          _buildCategoryHierarchy(isDarkMode, ad),
        
          Divider(color: AppColors.divider(isDarkMode)),
          
          _buildAttributesList(ad.attributes, isDarkMode),
        ],
      ),
    );
  }

  // ─── بناء التسلسل الهرمي للفئات ──────────────────────────────────────
 // ─── بناء التسلسل الهرمي للفئات ──────────────────────────────────────
Widget _buildCategoryHierarchy(bool isDarkMode, Ad ad) {
  // التصنيفات
  final mainCategory = ad.category;
  final subCategory = ad.subCategoryLevelOne;
  final subTwoCategory = ad.subCategoryLevelTwo;

  List<Widget> categoriesWidgets = [];

  // المستوى الأول
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

  // المستوى الثاني
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

  // المستوى الثالث
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
              'subCategoryId': subCategory.id,
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

  // ─── معلومات المعلن ──────────────────────────────────────────────────
  Widget _buildAdvertiserInfo(bool isDarkMode, Ad ad) {
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
              // صورة المعلن
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background(isDarkMode),
                ),
                child: advertiser.logo.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          advertiser.logo,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40.w);
                          },
                        ),
                      )
                    : Icon(Icons.person, size: 40.w),
              ),
              SizedBox(width: 20.w),

              // اسم ووصف المعلن
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap:   (){ showGeneralDialog(
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
                                    width: MediaQuery.of(context).size.width * 0.40,
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
                                              
                   final userId =  Get.find<LoadingController>().currentUser?.id;
    if (userId == null) {
      Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول لإضافة إلى المفضلة'.tr);
      return;
    }
                                              favoriteSellerController.toggleFavoriteByIds(
                                                userId: _loadingController.currentUser?.id ?? 0,
                                                advertiserProfileId: widget.ad!.idAdvertiser,
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
                                            Get.to(() => AdvertiserAdsScreenDesktop(
                                                  advertiser: widget.ad!.advertiser,
                                                  idAdv: widget.ad!.idAdvertiser,
                                                ));
                                          },
                                          child: Text(
                                            '${'جميع إعلانات '.tr}${widget.ad!.advertiser.name.toString()}',
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
                      advertiser.description,
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

          // أزرار التواصل
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.phone, size: 20.w),
                  label: Text('اتصال'.tr,style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
            ),),
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
                  label: Text('واتساب'.tr,style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
            ),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF25D366),
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
            label: Text('إرسال رسالة'.tr,style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
            ),),
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

                final userId = Get.find<LoadingController>().currentUser?.id;
    if (userId == null) {
      Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
      return;
    }else{
               Get.to(()=> DesktopConversationScreen(ad: ad,advertiser: advertiser, idAdv: ad.idAdvertiser,));
            }} 
          ),
        ],
      ),
    );
  }

  // ─── تبويبات أسفل المحتوى ────────────────────────────────────────────
  Widget _buildBottomTabs(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تبويبات الاختيار
        Row(
          children: [
                _buildBottomTab(0, 'tabTitle_info'.tr, ),
                            _buildBottomTab(1, 'tabTitle_desc'.tr, ),
                            _buildBottomTab(2, 'tabTitle_location'.tr, ),
         
          ],
        ),
        SizedBox(height: 30.h),

        // محتوى التبويب المحدد
        if (_selectedBottomTab == 0) _buildAdDescription(isDarkMode, widget.ad!),
        if (_selectedBottomTab == 1) _buildLocationMap(isDarkMode, widget.ad!),
        if (_selectedBottomTab == 2) _buildAdditionalAdvertiserInfo(isDarkMode, widget.ad!),
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
  keyName:title,
  textAlign: TextAlign.center,
  fontWeight: FontWeight.w500,
),
          ),
        ),
      ),
    );
  }

  // ─── وصف الإعلان ────────────────────────────────────────────────────
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

  // ─── الخريطة ────────────────────────────────────────────────────────
  Widget _buildLocationMap(bool isDarkMode, Ad ad) {
    if (ad.latitude == null || ad.longitude == null) {
      return Center(
        child: Text(
          'لا يتوفر موقع جغرافي'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 12.sp
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
                    size: 40.w, 
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── معلومات إضافية عن المعلن ────────────────────────────────────────
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

          // معلومات الاتصال
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
              value,
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

  // ─── قائمة الخصائص ──────────────────────────────────────────────────
  Widget _buildAttributesList(List<AttributeValue> attributes, bool isDarkMode) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
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

  // ─── مساعدات الوظائف ────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return '${'قبل'.tr} ${diff.inHours} ${'ساعة'.tr}';
    if (diff.inMinutes > 0) return '${'قبل'.tr} ${diff.inMinutes} ${'دقيقة'.tr}';
    return 'الآن';
  }

  Color _getValueColor(String value, {required bool isDarkMode}) {
    if (value == 'نعم') return Colors.green;
    if (value == 'لا') return Colors.red;
    return AppColors.textPrimary(isDarkMode);
  }

  Future<void> _makePhoneCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر إجراء المكالمة');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ', 'تعذر فتح واتساب');
    }
  }
}

// ─── معرض الوسائط (الصور والفيديوهات) ───────────────────────────────────────
class _MediaGallery extends StatefulWidget {
  final Ad ad;
  final bool isDarkMode;
  const _MediaGallery({ Key? key, required this.ad, required this.isDarkMode }) : super(key: key);

  @override
  __MediaGalleryState createState() => __MediaGalleryState();
}

class __MediaGalleryState extends State<_MediaGallery> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _selectedIndex = 0;
  static const int _perPage = 10; // 2 rows × 5 cols
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoPlaying = false;
  bool _isVideoInitialized = false;
  bool _videoError = false;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // تهيئة مشغل الفيديو الأول إذا كان هناك فيديو
    if (widget.ad.videos.isNotEmpty) {
      _currentVideoUrl = widget.ad.videos[0];
      _initializeVideoPlayer(widget.ad.videos[0]);
      
    }
  }
 // دالة لتحديث رابط المتصفح
  
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // تنظيف المشغلات السابقة
    _cleanUpVideoControllers();
    
    setState(() {
      _isVideoInitialized = false;
      _videoError = false;
      _isVideoPlaying = false;
    });

    try {
      _videoController = VideoPlayerController.network(videoUrl);
      
      // انتظار تهيئة الفيديو
      await _videoController!.initialize().then((_) {
        if (!mounted) return;
        
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          aspectRatio: _videoController!.value.aspectRatio,
          showControls: true,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'خطأ في تحميل الفيديو',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        );
        
        setState(() {
          _isVideoInitialized = true;
          _isVideoPlaying = false;
          _currentVideoUrl = videoUrl;
        });
      });
      
      // متعقب حالة التشغيل
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isVideoPlaying = _videoController!.value.isPlaying;
          });
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _videoError = true;
      });
    }
  }

  void _cleanUpVideoControllers() {
    if (_videoController != null) {
      _videoController!.removeListener(() {});
      _videoController!.dispose();
      _videoController = null;
    }
    
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
  }

  @override
  void dispose() {
    _cleanUpVideoControllers();
    _pageController.dispose();
    super.dispose();
  }

  // إنشاء قائمة الوسائط (صور + فيديوهات)
  List<MediaItem> get _mediaItems {
    List<MediaItem> items = [];
    
    // إضافة الفيديوهات أولاً
    for (var video in widget.ad.videos) {
      items.add(MediaItem(type: MediaType.video, url: video));
    }
    
    // إضافة الصور
    for (var image in widget.ad.images) {
      items.add(MediaItem(type: MediaType.image, url: image));
    }
    
    return items;
  }

  int get _pageCount => (_mediaItems.length / _perPage).ceil();

  List<MediaItem> _itemsForPage(int page) {
    final start = page * _perPage;
    return _mediaItems.sublist(
      start,
      (start + _perPage).clamp(0, _mediaItems.length),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return  '${'قبل'.tr} ${diff.inHours} ${'ساعة'.tr}';
    if (diff.inMinutes > 0) return '${'قبل'.tr} ${diff.inMinutes} ${'دقيقة'.tr}';
    return 'الآن';
  }

  void _playVideo(String videoUrl) {
    if (_currentVideoUrl == videoUrl && _isVideoInitialized) {
      // نفس الفيديو، تبديل التشغيل/الإيقاف
      setState(() {
        if (_isVideoPlaying) {
          _chewieController?.pause();
          _isVideoPlaying = false;
        } else {
          _chewieController?.play();
          _isVideoPlaying = true;
        }
      });
    } else {
      // فيديو جديد، تهيئة المشغل
      _initializeVideoPlayer(videoUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaName = Get.find<AreaController>().getAreaNameById(widget.ad.areaId);
    return Column(
      children: [
        // المنطقة الرئيسية (فيديو أو صورة)
        Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: AppColors.card(widget.isDarkMode),
            borderRadius: BorderRadius.circular(16.r),
          ),
          clipBehavior: Clip.hardEdge,
          child: _buildMainMediaDisplay(),
        ),
        SizedBox(height: 20.h),

        // شبكة المصغرات + أسهم التنقل
        SizedBox(
          height: 2 * 100.h + 10.h,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (p) {
                  setState(() => _currentPage = p);
                },
                itemBuilder: (_, page) {
                  final items = _itemsForPage(page);
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 5.h,
                      crossAxisSpacing: 5.w,
                      childAspectRatio: 1,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, idx) {
                      final globalIdx = page * _perPage + idx;
                      final selected = globalIdx == _selectedIndex;
                      final item = items[idx];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedIndex = globalIdx);
                          if (item.type == MediaType.video) {
                            _playVideo(item.url);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? AppColors.primary : Colors.transparent,
                              width: 2.w,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // الصورة المصغرة
                              if (item.type == MediaType.image)
                                Image.network(
                                  item.url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                          : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.broken_image, size: 30.w, color: Colors.grey),
                                    );
                                  },
                                ),
                              
                              // فيديو مصغر
                              if (item.type == MediaType.video)
                                Image.network(
                                  _getVideoThumbnail(item.url),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                          : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(Icons.broken_image, size: 30.w, color: Colors.grey),
                                    );
                                  },
                                ),
                              
                              // أيقونة فيديو
                              if (item.type == MediaType.video)
                                Positioned(
                                  bottom: 5.h,
                                  right: 5.w,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      size: 14.w,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              if (_currentPage > 0)
                Positioned(
                  left: 0,
                  top: (2 * 100.h + 10.h) / 2 - 16.w,
                  child: IconButton(
                    icon: Icon(Icons.chevron_left, size: 32.w),
                    onPressed: () => _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.ease,
                    ),
                  ),
                ),
              if (_currentPage < _pageCount - 1)
                Positioned(
                  right: 0,
                  top: (2 * 100.h + 10.h) / 2 - 16.w,
                  child: IconButton(
                    icon: Icon(Icons.chevron_right, size: 32.w),
                    onPressed: () => _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.ease,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // مؤشرات الصفحات + معلومات
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _pageCount; i++) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentPage
                      ? AppColors.primary
                      : AppColors.textSecondary(widget.isDarkMode),
                ),
              ),
            ],
            SizedBox(width: 12.w),
            Text(
              '${_mediaItems.where((i) => i.type == MediaType.image).length} ${'صورة'.tr}',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
               fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(widget.isDarkMode),
              ),
            ),
            if (widget.ad.videos.isNotEmpty) ...[
              SizedBox(width: 10.w),
              Text(
                '${widget.ad.videos.length} ${'فيديو'.tr}',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                 fontSize: AppTextStyles.medium,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),

        Divider(color: AppColors.divider(widget.isDarkMode)),
        SizedBox(height: 20.h),

        // معلومات الإعلان
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
            Icon(Icons.location_on, size: 18.sp,
                color: AppColors.textSecondary(widget.isDarkMode)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                                              '${widget.ad.city?.name??""}, ${widget.ad.area?.name??""}',

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

  Widget _buildMainMediaDisplay() {
    if (_mediaItems.isEmpty) {
      return Center(
        child: Icon(Icons.image, size: 100.w, color: Colors.grey),
      );
    }

    final selectedItem = _mediaItems[_selectedIndex];
    
    if (selectedItem.type == MediaType.video) {
      return _buildVideoDisplay(selectedItem.url);
    } else {
      return _buildImageDisplay(selectedItem.url);
    }
  }

  Widget _buildVideoDisplay(String videoUrl) {
    if (_videoError) {
      return _buildVideoErrorState();
    }
    
    if (!_isVideoInitialized || _chewieController == null) {
      return _buildVideoLoadingState();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // مشغل الفيديو
        Chewie(controller: _chewieController!),
        
        // زر التشغيل/الإيقاف
        if (!_isVideoPlaying)
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _chewieController?.play();
                  _isVideoPlaying = true;
                });
              },
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 50.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        
        // مؤشر الفيديو
        Positioned(
          top: 15.h,
          right: 15.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(Icons.videocam, size: 16.w, color: Colors.white),
                SizedBox(width: 5.w),
                Text(
                  'فيديو'.tr,
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
    );
  }

  Widget _buildVideoLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20.h),
          Text(
            'جاري تحميل الفيديو...'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: Colors.white
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 50.w, color: Colors.red),
          SizedBox(height: 20.h),
          Text(
            'تعذر تحميل الفيديو'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: Colors.white
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () => _initializeVideoPlayer(widget.ad.videos[_selectedIndex]),
            child: Text('إعادة المحاولة'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / 
                loadingProgress.expectedTotalBytes!
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

  String _getVideoThumbnail(String videoUrl) {
    // يمكن استبدال هذا بمنطق لاستخراج صورة مصغرة من الفيديو
    return 'https://img.freepik.com/free-photo/abstract-blur-empty-green-gradient-studio-well-use-as-background-website-template-frame-business-report_1258-54622.jpg';
  }
}

enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;

  MediaItem({required this.type, required this.url});
}