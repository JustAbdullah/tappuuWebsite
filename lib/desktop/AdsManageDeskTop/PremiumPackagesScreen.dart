import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_website/desktop/AdsManageDeskTop/PackageCard.dart';
import 'package:tappuu_website/desktop/AdsManageDeskTop/PaymentScreen.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/PremiumPackageController.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/PremiumPackage.dart';
import '../HomeScreenDeskTop/home_web_desktop_screen.dart';

class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({Key? key}) : super(key: key);

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final ManageAdController adController = Get.find<ManageAdController>();
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');

  /// لكل نوع باقة نخزّن الـ id المختار
  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
  }

  // ================== تجميع الباقات حسب النوع ==================

  Map<String, List<PremiumPackage>> _groupPackagesByType(
      List<PremiumPackage> packages) {
    final Map<String, List<PremiumPackage>> groupedPackages = {};

    for (var package in packages) {
      if (package.isActive == true) {
        final String typeName = package.type?.name ?? 'باقات أخرى';
        groupedPackages.putIfAbsent(typeName, () => []);
        groupedPackages[typeName]!.add(package);
      }
    }

    // ترتيب الباقات داخل كل نوع حسب السعر
    groupedPackages.forEach((key, value) {
      value.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    });

    return groupedPackages;
  }

  void _togglePackageSelection(String typeName, int packageId) {
    setState(() {
      if (selectedPackagesByType[typeName] == packageId) {
        selectedPackagesByType.remove(typeName);
      } else {
        selectedPackagesByType[typeName] = packageId;
      }
    });
  }

  Set<int> get selectedPackageIds => selectedPackagesByType.values.toSet();

  List<PremiumPackage> get _selectedPackages {
    return controller.packagesList
        .where((p) => selectedPackageIds.contains(p.id))
        .toList();
  }

  double get _totalPrice {
    return _selectedPackages.fold(
        0.0, (sum, package) => sum + (package.price ?? 0));
  }

  String get _selectedTypes {
    return _selectedPackages
        .map((p) => p.type?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(' • ');
  }

  String get _selectedDurations {
    return _selectedPackages
        .map((p) => '${p.durationDays ?? 0} يوم')
        .toSet()
        .join(' • ');
  }

  // ================== إنشاء إعلان دون باقة ==================

  Future<void> _submitAdWithoutPremium() async {
    try {
      _showLoadingDialog();
      await Future.delayed(const Duration(milliseconds: 100));
      await adController.submitAd();

      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      print('⚠️ _submitAdWithoutPremium exception: $e');
    } finally {
      Get.offAll(() => HomeWebDeskTopScreen());
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
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
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(20),
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
                    const Icon(Icons.hourglass_top, size: 70),
                    const SizedBox(height: 16),
                    Text(
                      'جاري إنشاء إعلانك...',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.xlarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى الانتظار قليلاً، هذا قد يستغرق بعض الوقت',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      backgroundColor: AppColors.divider(isDark),
                      color: AppColors.primary,
                      minHeight: 6,
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

  void _confirmCreateWithoutPackage() {
    final isDark = themeController.isDarkMode.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDark),
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'هل تريد إنشاء الإعلان دون أي باقة مميزة؟',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDark),
            fontSize: AppTextStyles.medium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAdWithoutPremium();
            },
            child: Text(
              'تأكيد',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== واجهة الشاشة ==================

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final activePackages = controller.packagesList
          .where((pkg) => pkg.isActive == true)
          .toList();
      final groupedPackages = _groupPackagesByType(activePackages);

      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          title: Text(
            'الباقات المميزة',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.onPrimary,
              fontSize: AppTextStyles.xxlarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double maxContentWidth = 1100.0;
              final double contentWidth = constraints.maxWidth > maxContentWidth
                  ? maxContentWidth
                  : constraints.maxWidth - 32;

              return Center(
                child: Container(
                  width: contentWidth,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      _buildHeaderBanner(isDark),
                      const SizedBox(height: 18),
                      Expanded(
                        child: controller.isLoadingPackages.value
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.primary),
                                ),
                              )
                            : activePackages.isEmpty
                                ? _noActivePackagesState(isDark)
                                : ListView(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            220), // مساحة كافية تحت للـ FAB
                                    children: [
                                      ...groupedPackages.entries.map(
                                        (entry) => _buildPackageGroupSection(
                                          context: context,
                                          isDark: isDark,
                                          typeName: entry.key,
                                          packages: entry.value,
                                          maxWidth: contentWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // شريط التحكم السفلي (المجموع + الدفع + إنشاء دون باقة)
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildBottomActionBar(context, isDark),
      );
    });
  }

  // ================== أجزاء الواجهة ==================

  Widget _buildHeaderBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'اختر الباقات المناسبة لإبراز إعلانك في أعلى النتائج وجذب المزيد من المشاهدات.',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGroupSection({
    required BuildContext context,
    required bool isDark,
    required String typeName,
    required List<PremiumPackage> packages,
    required double maxWidth,
  }) {
    int crossAxisCount = 3;
    if (maxWidth < 700) {
      crossAxisCount = 1;
    } else if (maxWidth < 950) {
      crossAxisCount = 2;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.divider(isDark),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان + عدد الباقات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeName,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${packages.length} باقة',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اختر باقة واحدة من هذا النوع فقط، يمكنك دمجها مع أنواع أخرى.',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),

          // Grid الباقات
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              final isSelected =
                  selectedPackagesByType[typeName] == pkg.id;

              return PackageCard(
                pkg: pkg,
                isDark: isDark,
                priceText: '${_fmt.format(pkg.price ?? 0)} ل.س',
                isSelected: isSelected,
                onSelect: () => _togglePackageSelection(
                    typeName, pkg.id ?? 0),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, bool isDark) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedPackageIds.isNotEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.divider(isDark),
                      width: 0.7,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // النوع والمدة
                      Row(
                        children: [
                          Icon(Icons.local_offer_outlined,
                              size: 20,
                              color: AppColors.textSecondary(isDark)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'نوع الباقة: $_selectedTypes',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 18,
                              color: AppColors.textSecondary(isDark)),
                          const SizedBox(width: 6),
                          Text(
                            'المدة: $_selectedDurations',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // المجموع + زر الدفع
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'المجموع: ${_fmt.format(_totalPrice)} ل.س',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 190,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.to(
                                  () => PaymentScreen(
                                    package: _selectedPackages,
                                    adTitle:
                                        adController.titleArController.text,
                                    adPrice:
                                        '${adController.priceController.text} ل.س',
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'الدفع الآن',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTextStyles.medium,
                                ),
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

          // زر إنشاء دون باقة
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                width: double.infinity,
                child: FloatingActionButton.extended(
                  heroTag: 'create_no_pkg',
                  onPressed: _confirmCreateWithoutPackage,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  label: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'إنشاء الإعلان دون باقة',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.post_add_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== حالة عدم وجود باقات ==================

  Widget _noActivePackagesState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.primary.withOpacity(0.9),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد باقات نشطة حاليًا',
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى التحقق لاحقًا أو التواصل مع الدعم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
