import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/CardPaymentController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/user_wallet_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/PremiumPackage.dart';
import '../../core/data/model/UserWallet.dart';
import '../HomeScreenDeskTop/home_web_desktop_screen.dart';

class PaymentScreen extends StatefulWidget {
  final dynamic package;
  final String adTitle;
  final String adPrice; // لم نعد نستخدمه في الواجهة لكن نتركه لو أنك تستخدمه في مكان آخر

  const PaymentScreen({
    Key? key,
    required this.package,
    required this.adTitle,
    required this.adPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ManageAdController adController = Get.find<ManageAdController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.put(UserWalletController());
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController =
      Get.put(CardPaymentController());

  final _formKey = GlobalKey<FormState>();

  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  String selectedPaymentMethod = 'card';
  bool isProcessing = false;
  UserWallet? selectedWallet;

  final NumberFormat _priceFormatEn = NumberFormat('#,##0', 'en_US');
  final NumberFormat _priceFormatAr = NumberFormat('#,##0', 'ar');

  @override
  void initState() {
    super.initState();
    _fetchUserWallets();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCardEnabled = _cardPaymentController.isEnabled.value;
      if (!isCardEnabled && selectedPaymentMethod == 'card') {
        setState(() {
          selectedPaymentMethod = 'wallet';
        });
      }
    });
  }

  // ================== Helpers فورمات ==================

  String _formatSyrianEn(num value) {
    return '${_priceFormatEn.format(value)} ل.س';
  }

  String _formatSyrianArabic(num value) {
    try {
      return '${_priceFormatAr.format(value)} ليرة سورية';
    } catch (_) {
      return '${value.toStringAsFixed(0)} ليرة سورية';
    }
  }

  // ================== تحميل محافظ ==================

  Future<void> _fetchUserWallets() async {
    final userId = loadingController.currentUser?.id;
    if (userId != null) {
      await walletController.fetchUserWallets(userId);
      if (walletController.userWallets.isNotEmpty && selectedWallet == null) {
        setState(() {
          selectedWallet = walletController.userWallets.first;
        });
      }
    }
  }

  // ================== بيانات الباقات ==================

  List<PremiumPackage> _packageListFromWidget() {
    final p = widget.package;
    final out = <PremiumPackage>[];
    try {
      if (p == null) return out;
      if (p is List) {
        for (var e in p) {
          if (e == null) continue;
          if (e is PremiumPackage) out.add(e);
        }
        return out;
      }
      if (p is PremiumPackage) {
        out.add(p);
        return out;
      }
    } catch (e) {
      print('⚠️ _packageListFromWidget parse error: $e');
    }
    return out;
  }

  List<int> _extractPackageIdsFromWidgetPackage() {
    return _packageListFromWidget()
        .map((e) => e.id ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  double _totalPriceOfSelected() {
    final list = _packageListFromWidget();
    return list.fold(0.0, (p, e) => p + (e.price ?? 0));
  }

  String _typesOfSelected() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    return list.map((e) => e.type?.name ?? '-').toSet().join(' • ');
  }

  String _durationText() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    if (list.length == 1) return '${list.first.durationDays ?? '-'} يوم';
    final durations = list.map((e) => e.durationDays ?? 0).toSet();
    if (durations.length == 1) return '${durations.first} يوم';
    return 'متعددة';
  }

  double _walletBalance(UserWallet wallet) {
    final b = wallet.balance ?? 0;
    if (b is int) return b.toDouble();
    if (b is double) return b;
    return double.tryParse(b.toString()) ?? 0.0;
  }

  // ================== عملية الدفع ==================

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    final totalPrice = _totalPriceOfSelected();

    // التحقق من حالة تفعيل البطاقة
    final isCardEnabled = _cardPaymentController.isEnabled.value;
    if (selectedPaymentMethod == 'card' && !isCardEnabled) {
      Get.snackbar(
        'خطأ',
        'الدفع بالبطاقة غير متاح حالياً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // تحقق حقول البطاقة
    if (selectedPaymentMethod == 'card') {
      if (!_formKey.currentState!.validate()) return;
    }

    // تحقق المحفظة (التحقق الأساسي – التجميد نفسه يتم عند الزر)
    if (selectedPaymentMethod == 'wallet') {
      if (selectedWallet == null) {
        Get.snackbar(
          'خطأ',
          'يرجى اختيار محفظة للدفع',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if ((selectedWallet!.status ?? '')
              .toString()
              .toLowerCase()
              .trim() !=
          'active') {
        Get.snackbar(
          'خطأ',
          'لا يمكن استخدام هذه المحفظة لأنها ليست نشطة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final walletBalance = _walletBalance(selectedWallet!);
      if (walletBalance < totalPrice) {
        final formattedBalance = _formatSyrianArabic(walletBalance);
        final formattedTotal = _formatSyrianArabic(totalPrice);
        Get.snackbar(
          'رصيد غير كافٍ',
          'رصيد محفظتك ($formattedBalance) أقل من المبلغ المطلوب ($formattedTotal). يرجى شحن المحفظة أو اختيار طريقة دفع أخرى.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        return;
      }
    }

    setState(() => isProcessing = true);
    final packageIds = _extractPackageIdsFromWidgetPackage();
    if (packageIds.isEmpty) {
      Get.snackbar(
        'خطأ',
        'لا توجد باقات صالحة للاشتراك',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => isProcessing = false);
      return;
    }

    try {
      final isSingle = _packageListFromWidget().length == 1;
      final PremiumPackage? firstPkg =
          isSingle ? _packageListFromWidget().first : null;

      if (selectedPaymentMethod == 'wallet') {
        final int? createdAdId = await _submitAdAndGetId(
          forPackage: firstPkg,
          isSinglePackage: isSingle,
        );
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        final result = await walletController.purchasePremium(
          walletUuid: selectedWallet!.uuid,
          adId: createdAdId,
          packageIds: packageIds,
        );

        if (result != null && result['success'] == true) {
          Get.snackbar(
            'نجاح',
            'تمت عملية الدفع من المحفظة وإنشاء الإعلان بنجاح',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          final body = result != null ? result['body'] : null;
          final message = body != null && body['message'] != null
              ? body['message']
              : 'فشل شراء/تجديد الباقات';
          Get.snackbar(
            'خطأ',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }

        if (Navigator.canPop(context)) Navigator.pop(context);
        Get.offAll(HomeWebDeskTopScreen());
      } else {
        // بطاقة (محاكاة)
        await Future.delayed(const Duration(seconds: 2));
        Get.snackbar(
          'نجاح',
          'تمت عملية الدفع بالبطاقة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        final int? createdAdId = await _submitAdAndGetId(
          forPackage: firstPkg,
          isSinglePackage: isSingle,
        );
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        if (!isSingle) {
          Get.snackbar(
            'ملاحظة',
            'تم الدفع بالبطاقة وإنشاء الإعلان. لربط أكثر من باقة يفضّل استخدام المحفظة أو التواصل مع الدعم.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
          );
        } else {
          Get.snackbar(
            'نجاح',
            'تم إنشاء الإعلان بنجاح وهو قيد المراجعة',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }

        if (Navigator.canPop(context)) Navigator.pop(context);
        Get.offAll(HomeWebDeskTopScreen());
      }
    } catch (e, st) {
      print('⚠️ _processPayment exception: $e\n$st');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء عملية الدفع: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // ================== Helpers لإنشاء الإعلان ==================

  Future<int?> _parseCreatedAdId(dynamic result) async {
    try {
      if (result == null) return null;

      if (result is int) return result;
      if (result is String) {
        final val = int.tryParse(result);
        if (val != null) return val;
      }
      if (result is Map) {
        final keys = [
          'id',
          'ad_id',
          'created_ad_id',
          'createdId',
          'data',
          'result'
        ];
        for (var k in keys) {
          if (result.containsKey(k)) {
            final v = result[k];
            if (v is int) return v;
            if (v is String) {
              final val = int.tryParse(v);
              if (val != null) return val;
            }
            if (v is Map) {
              final nested = await _parseCreatedAdId(v);
              if (nested != null) return nested;
            }
          }
        }
        for (var entry in result.entries) {
          final v = entry.value;
          if (v is int) return v;
          if (v is String) {
            final val = int.tryParse(v);
            if (val != null) return val;
          }
        }
      }

      try {
        final dynamic c = adController;
        if (c != null) {
          if ((c as dynamic).createdAdId != null) {
            final v = (c).createdAdId;
            if (v is int) return v;
            if (v is String) return int.tryParse(v);
          }
        }
      } catch (_) {}
    } catch (e) {
      print('⚠️ _parseCreatedAdId error: $e');
    }
    return null;
  }

  Future<int?> _submitAdAndGetId({
    required PremiumPackage? forPackage,
    required bool isSinglePackage,
  }) async {
    _showAdCreationDialog();
    try {
      dynamic rawResult;
      if (isSinglePackage && forPackage != null) {
        rawResult = await adController.submitAd();
      } else {
        rawResult = await adController.submitAd(isPay: false);
      }

      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final int? parsedId = await _parseCreatedAdId(rawResult);
      if (parsedId != null) return parsedId;

      try {
        final dynamic c = adController;
        if (c != null) {
          try {
            final maybe = (c).createdAdId;
            if (maybe != null) {
              if (maybe is int) return maybe;
              if (maybe is String) return int.tryParse(maybe);
            }
          } catch (_) {}
          try {
            final maybe2 = (c).adId;
            if (maybe2 != null) {
              if (maybe2 is int) return maybe2;
              if (maybe2 is String) return int.tryParse(maybe2);
            }
          } catch (_) {}
        }
      } catch (_) {}

      if (adController.hasError.value) {
        Get.snackbar(
          'خطأ',
          'فشل إنشاء الإعلان',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'لم يتم استلام معرف الإعلان من الخادم',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      return null;
    } catch (e) {
      print('⚠️ _submitAdAndGetId exception: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إنشاء الإعلان: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _hideAdCreationDialog();
    }
  }

  void _showAdCreationDialog() {
    final isDark = themeController.isDarkMode.value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'جاري إنشاء/معالجة الإعلان...',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'يرجى الانتظار قليلاً',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 13,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideAdCreationDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ================== Misc ==================

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(
          i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
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

  // ================== واجهة الشاشة ==================

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
    final selectedPackages = _packageListFromWidget();
    final totalPrice = _totalPriceOfSelected();
    final typesText = _typesOfSelected();
    final durationText = _durationText();
    final priceTextEn = _formatSyrianEn(totalPrice);
    final priceTextAr = _formatSyrianArabic(totalPrice);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'إتمام الشراء',
          style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double maxWidth = 1100;
            final double contentWidth = constraints.maxWidth > maxWidth
                ? maxWidth
                : constraints.maxWidth - 32;
            final bool isWide = contentWidth > 800;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(
                        isDark: isDark,
                        selectedPackages: selectedPackages,
                        typesText: typesText,
                        durationText: durationText,
                        priceTextEn: priceTextEn,
                      ),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildPaymentMethodsCard(isDark),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _buildMethodDetailsCard(
                                isDark: isDark,
                                totalPrice: totalPrice,
                                priceTextAr: priceTextAr,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildPaymentMethodsCard(isDark),
                        const SizedBox(height: 20),
                        _buildMethodDetailsCard(
                          isDark: isDark,
                          totalPrice: totalPrice,
                          priceTextAr: priceTextAr,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildPayButton(isDark, totalPrice, priceTextAr),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================== Widgets فرعية ==================

  Widget _buildSummaryCard({
    required bool isDark,
    required List<PremiumPackage> selectedPackages,
    required String typesText,
    required String durationText,
    required String priceTextEn,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'ملخص طلبك',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          if (selectedPackages.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedPackages.map((pkg) {
                final pkgPrice = _formatSyrianEn(pkg.price ?? 0);
                final pkgDuration = pkg.durationDays ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.name ?? '-',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'المدة: $pkgDuration يوم — السعر: $pkgPrice',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 12,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'لم يتم اختيار أي باقة مميزة.',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          const SizedBox(height: 12),

          _summaryRow(
            isDark,
            'عدد الباقات:',
            selectedPackages.length.toString(),
          ),
          const SizedBox(height: 6),
          _summaryRow(isDark, 'نوع الباقات:', typesText),
          const SizedBox(height: 6),
          _summaryRow(isDark, 'المدة:', durationText),
          const SizedBox(height: 6),

          // عرض عنوان الإعلان فقط
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عنوان الإعلان:',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.adTitle,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _summaryRow(
            isDark,
            'إجمالي قيمة الباقات:',
            priceTextEn,
            isMain: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(bool isDark, String label, String value,
      {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: isMain ? FontWeight.w800 : FontWeight.w700,
              fontSize: isMain ? AppTextStyles.medium : 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر طريقة الدفع',
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final isCardEnabled = _cardPaymentController.isEnabled.value;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                )
              ],
            ),
            child: Column(
              children: [
                if (isCardEnabled)
                  ListTile(
                    leading: Icon(Icons.credit_card, color: AppColors.primary),
                    title: Text(
                      'بطاقة ائتمان',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                    subtitle: Text(
                      'دفع مباشر بالبطاقة البنكية',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    trailing: Radio(
                      value: 'card',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) => setState(
                        () => selectedPaymentMethod = value.toString(),
                      ),
                      activeColor: AppColors.primary,
                    ),
                    onTap: () =>
                        setState(() => selectedPaymentMethod = 'card'),
                  ),
                ListTile(
                  leading: Icon(Icons.account_balance_wallet,
                      color: AppColors.primary),
                  title: Text(
                    'المحفظة الإلكترونية',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  subtitle: Text(
                    'السحب من رصيد محفظتك داخل النظام',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                  trailing: Radio(
                    value: 'wallet',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) =>
                        setState(() => selectedPaymentMethod = value.toString()),
                    activeColor: AppColors.primary,
                  ),
                  onTap: () =>
                      setState(() => selectedPaymentMethod = 'wallet'),
                ),
                if (!isCardEnabled)
                  ListTile(
                    leading:
                        const Icon(Icons.credit_card_off, color: Colors.grey),
                    title: Text(
                      'الدفع بالبطاقة غير متاح حالياً',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMethodDetailsCard({
    required bool isDark,
    required double totalPrice,
    required String priceTextAr,
  }) {
    if (selectedPaymentMethod == 'wallet') {
      return _buildWalletSection(isDark, totalPrice, priceTextAr);
    } else {
      return _buildCardFormSection(isDark);
    }
  }

  Widget _buildWalletSection(
      bool isDark, double totalPrice, String priceTextAr) {
    return Obx(() {
      if (walletController.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      }

      if (walletController.userWallets.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'لا توجد لديك محافظ متاحة حالياً.',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        );
      }

      final bool hasSelectedWallet =
          selectedWallet != null &&
              walletController.userWallets.contains(selectedWallet);
      final UserWallet? wallet =
          hasSelectedWallet ? selectedWallet : walletController.userWallets[0];
      if (!hasSelectedWallet) {
        selectedWallet = wallet;
      }

      final walletBalance = wallet != null ? _walletBalance(wallet) : 0.0;
      final bool hasEnoughBalance = walletBalance >= totalPrice;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الدفع من المحفظة',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<UserWallet>(
            value: wallet,
            items: walletController.userWallets.map((w) {
              return DropdownMenuItem<UserWallet>(
                value: w,
                child: Text(
                  w.uuid ?? '',
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                ),
              );
            }).toList(),
            onChanged: (w) {
              setState(() {
                selectedWallet = w;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelText: 'اختر المحفظة',
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
          ),
          const SizedBox(height: 16),
          if (wallet != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider(isDark),
                  width: 0.7,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المحفظة',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    isDark,
                    'معرّف المحفظة:',
                    wallet.uuid ?? '-',
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الرصيد المتاح:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatSyrianArabic(walletBalance),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قيمة الباقات:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        priceTextAr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (hasEnoughBalance)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الرصيد بعد الدفع (تقريباً):',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatSyrianArabic(walletBalance - totalPrice),
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasEnoughBalance
                          ? Colors.green.withOpacity(0.08)
                          : Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasEnoughBalance
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 18,
                          color: hasEnoughBalance ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasEnoughBalance
                                ? 'رصيد محفظتك كافٍ لإتمام عملية الدفع.'
                                : 'رصيد محفظتك غير كافٍ، يمكنك شحن المحفظة أو اختيار طريقة دفع أخرى.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 12,
                              color: hasEnoughBalance
                                  ? Colors.green[900]
                                  : Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'الحالة:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getWalletStatusText(wallet.status),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: _getWalletStatusColor(wallet.status),
                          fontWeight: FontWeight.bold,
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

  Widget _buildCardFormSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات البطاقة',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cardNumberCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onCardNumberChanged,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
            ],
            decoration: InputDecoration(
              labelText: 'رقم البطاقة',
              hintText: 'xxxx xxxx xxxx xxxx',
              filled: true,
              fillColor: AppColors.card(isDark),
              prefixIcon: Icon(Icons.credit_card, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة';
              if (digits.length < 12) return 'رقم البطاقة غير صحيح';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: nameCtrl,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة',
              filled: true,
              fillColor: AppColors.card(isDark),
              prefixIcon:
                  Icon(Icons.person_outline, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'انتهاء الصلاحية (MMYY)',
                    filled: true,
                    fillColor: AppColors.card(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 4 ? 'تاريخ غير صحيح' : null,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: cvvCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    filled: true,
                    fillColor: AppColors.card(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      (v ?? '').length < 3 ? 'CVV غير صحيح' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(
      bool isDark, double totalPrice, String priceTextAr) {
    final bool isWallet = selectedPaymentMethod == 'wallet';

    bool walletOk = true;
    String footerText;

    if (isWallet) {
      if (walletController.userWallets.isEmpty) {
        walletOk = false;
        footerText =
            'لا توجد لديك أي محفظة حالياً، لا يمكن الدفع بالمحفظة. يرجى اختيار طريقة دفع أخرى.';
      } else if (selectedWallet == null) {
        walletOk = false;
        footerText = 'يرجى اختيار محفظة أولاً لإتمام الدفع.';
      } else if ((selectedWallet!.status ?? '')
              .toString()
              .toLowerCase()
              .trim() !=
          'active') {
        walletOk = false;
        footerText = 'هذه المحفظة غير نشطة، لا يمكن استخدامها للدفع.';
      } else {
        final balance = _walletBalance(selectedWallet!);
        final hasEnoughBalance = balance >= totalPrice;
        if (!hasEnoughBalance) {
          walletOk = false;
          footerText =
              'رصيد محفظتك الحالي ${_formatSyrianArabic(balance)} أقل من قيمة الباقات ${_formatSyrianArabic(totalPrice)}. يرجى شحن المحفظة أو اختيار طريقة أخرى.';
        } else {
          footerText =
              'سيتم خصم $priceTextAr من رصيد محفظتك عند نجاح إنشاء الإعلان.';
        }
      }
    } else {
      footerText =
          'سيتم تنفيذ عملية الدفع بالبطاقة البنكية وإنشاء الإعلان في خطوة واحدة.';
    }

    final bool canPress = !isProcessing && (!isWallet || walletOk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: canPress ? _processPayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'الدفع وإنشاء الإعلان الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          footerText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 11,
            color: AppColors.textSecondary(isDark),
          ),
        ),
      ],
    );
  }
}
