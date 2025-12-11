// MyCompanyInvitesScreenDeskTop (WEB - Desktop/Large Screens)
// واجهة عرض دعوات الانضمام الخاصة بي بأسلوب سطح المكتب (Top/Secondary AppBars + Drawer)
// تحافظ على نفس المنطق والتعامل مع CompanyInvitesController دون تغيير.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/CompanyInvitesController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/company_invite.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'AcceptInviteDetailsScreen.dart';

class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const AlwaysScrollableScrollPhysics();
}

class MyCompanyInvitesScreenDeskTop extends StatefulWidget {
  const MyCompanyInvitesScreenDeskTop({Key? key}) : super(key: key);

  @override
  State<MyCompanyInvitesScreenDeskTop> createState() => _MyCompanyInvitesScreenDeskTopState();
}

class _MyCompanyInvitesScreenDeskTopState extends State<MyCompanyInvitesScreenDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final CompanyInvitesController c = Get.put(CompanyInvitesController(), permanent: true);

  // فلتر الحالة الحالي
  final RxString _statusFilter = 'pending'.obs; // pending | accepted | rejected | any

  @override
  void initState() {
    super.initState();
    final userId = loadingC.currentUser?.id ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.fetchMyInvites(userId: userId); // افتراضي: pending
    });
  }

  // ====== تعريب و ألوان ======
  String _statusAr(String? s) {
    switch ((s ?? 'pending').toLowerCase()) {
      case 'accepted':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return 'معلّقة';
    }
  }

  Color _statusColor(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _roleAr(String? r) {
    switch ((r ?? 'publisher').toLowerCase()) {
      case 'viewer':
        return 'عارض';
      default:
        return 'ناشر';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeC.isDarkMode.value;
    final HomeController homeC = Get.find<HomeController>();
           final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
       key: _scaffoldKey,
    endDrawer: Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: homeC.drawerType.value == DrawerType.settings
            ? const SettingsDrawerDeskTop(key: ValueKey('settings'))
            : const DesktopServicesDrawer(key: ValueKey('services')),
      ),
    ),
      backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [
           TopAppBarDeskTop(),
           SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey,),
          Expanded(
            child: ScrollConfiguration(
              behavior: NoScrollbarScrollBehavior(),
              child: RefreshIndicator(
                onRefresh: () async {
                  final userId = loadingC.currentUser?.id ?? 0;
                  await c.fetchMyInvites(
                    userId: userId,
                    status: _statusFilter.value == 'any' ? null : _statusFilter.value,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1100.w),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                        child: Obx(() {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeaderBar(
                                isDark: isDark,
                                statusFilter: _statusFilter,
                                totalCount: c.myInvitesList.length,
                                onChangeFilter: (val) async {
                                  _statusFilter.value = val;
                                  final userId = loadingC.currentUser?.id ?? 0;
                                  await c.fetchMyInvites(
                                    userId: userId,
                                    status: val == 'any' ? null : val,
                                  );
                                },
                                onRefresh: () async {
                                  final userId = loadingC.currentUser?.id ?? 0;
                                  await c.fetchMyInvites(
                                    userId: userId,
                                    status: _statusFilter.value == 'any' ? null : _statusFilter.value,
                                  );
                                },
                              ),
                              SizedBox(height: 16.h),

                              if (c.isLoading.value && c.myInvitesList.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 40.h),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              else if (c.myInvitesList.isEmpty)
                                _EmptyState(isDark: isDark)
                              else
                                _InvitesDataTable(
                                  isDark: isDark,
                                  invites: c.myInvitesList,
                                  statusAr: _statusAr,
                                  statusColor: _statusColor,
                                  roleAr: _roleAr,
                                  onAccept: (invite) async {
                                    final userId = loadingC.currentUser?.id ?? 0;
                                    await Get.to(() => AcceptInviteDetailsScreenDeskTop(
                                          inviteId: invite.id,
                                          companyName: invite.companyName ?? 'شركة',
                                          roleLabel: _roleAr(invite.role),
                                          userId: userId,
                                        ));
                                    await c.fetchMyInvites(
                                      userId: userId,
                                      status: _statusFilter.value == 'any' ? null : _statusFilter.value,
                                    );
                                  },
                                  onReject: (invite) async {
                                    final yes = await _confirmReject(context, isDark: isDark);
                                    if (yes != true) return;
                                    final userId = loadingC.currentUser?.id ?? 0;
                                    final ok = await c.rejectInvite(inviteId: invite.id, userId: userId);
                                    if (!ok) {
                                      Get.snackbar('لم يتم الرفض'.tr, 'حاول مجدداً'.tr,
                                          snackPosition: SnackPosition.BOTTOM);
                                    } else {
                                      await c.fetchMyInvites(
                                        userId: userId,
                                        status: _statusFilter.value == 'any' ? null : _statusFilter.value,
                                      );
                                    }
                                  },
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReject(BuildContext context, {required bool isDark}) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text('رفض الدعوة؟',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w800,
            )),
        content: Text('هل تريد بالتأكيد رفض هذه الدعوة؟',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('تراجع',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}

/* ================== رأس الشاشة (فلتر + عدد + تحديث) ================== */
class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.isDark,
    required this.statusFilter,
    required this.totalCount,
    required this.onChangeFilter,
    required this.onRefresh,
  });

  final bool isDark;
  final RxString statusFilter;
  final int totalCount;
  final ValueChanged<String> onChangeFilter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.mail_outline_rounded, size: 22.w, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text(
            'دعواتي'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.divider(isDark)),
            ),
            child: Text(
              'العدد: $totalCount',
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
          const Spacer(),
          Obx(() {
            final sel = statusFilter.value;
            return SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'pending', label: Text('معلّقة'.tr)),
                ButtonSegment(value: 'accepted', label: Text('مقبولة'.tr)),
                ButtonSegment(value: 'rejected', label: Text('مرفوضة'.tr)),
                ButtonSegment(value: 'any', label: Text('الكل'.tr)),
              ],
              selected: {sel},
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor:
                    WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary.withOpacity(.15) : AppColors.surface(isDark)),
              ),
              onSelectionChanged: (set) {
                if (set.isNotEmpty) onChangeFilter(set.first);
              },
            );
          }),
          SizedBox(width: 8.w),
          IconButton(
            tooltip: 'تحديث'.tr,
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 24.w),
          ),
        ],
      ),
    );
  }
}

/* ================== جدول الدعوات ================== */
class _InvitesDataTable extends StatelessWidget {
  const _InvitesDataTable({
    required this.isDark,
    required this.invites,
    required this.statusAr,
    required this.statusColor,
    required this.roleAr,
    required this.onAccept,
    required this.onReject,
  });

  final bool isDark;
  final List<CompanyInvite> invites;
  final String Function(String? s) statusAr;
  final Color Function(String? s) statusColor;
  final String Function(String? r) roleAr;
  final Future<void> Function(CompanyInvite invite) onAccept;
  final Future<void> Function(CompanyInvite invite) onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface(isDark)),
          dataRowMinHeight: 56.h,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(isDark),
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
          ),
          dataTextStyle: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: AppTextStyles.medium,
            fontFamily: AppTextStyles.appFontFamily,
          ),
          columns: [
            DataColumn(label: Text('الشركة'.tr)),
            DataColumn(label: Text('الدور'.tr)),
            DataColumn(label: Text('الحالة'.tr)),
            DataColumn(label: Text('التاريخ'.tr)),
            DataColumn(label: Text('إجراءات'.tr)),
          ],
          rows: invites.map((inv) {
            final isPending = (inv.status ?? 'pending').toLowerCase() == 'pending';
            final stColor = statusColor(inv.status);
            return DataRow(
              cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 16.w,
                      backgroundColor: Colors.indigo.withOpacity(.12),
                      child: Icon(Icons.apartment_rounded, color: Colors.indigo, size: 16.w),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        inv.companyName ?? 'شركة',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )),
                DataCell(Text(roleAr(inv.role))),
                DataCell(Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: stColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: stColor.withOpacity(.5)),
                  ),
                  child: Text(
                    statusAr(inv.status),
                    style: TextStyle(
                      color: stColor,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTextStyles.small,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                )),
                DataCell(Text(
                  inv.createdAt?.toString().split('.').first ?? '-',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                )),
                DataCell(Row(
                  children: [
                    if (isPending) ...[
                      OutlinedButton.icon(
                        onPressed: () => onReject(inv),
                        icon: const Icon(Icons.close_rounded),
                        label: Text('رفض'.tr),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          foregroundColor: Colors.redAccent,
                          minimumSize: Size(90.w, 38.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton.icon(
                        onPressed: () => onAccept(inv),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text('قبول'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(90.w, 38.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                      ),
                    ] else
                      Text(
                        'تمت المعالجة'.tr,
                        style: TextStyle(color: AppColors.textSecondary(isDark)),
                      ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/* ================== حالات فارغة ================== */
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 40.h),
      padding: EdgeInsets.all(16.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary(isDark)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'لا توجد دعوات حالياً'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                color: AppColors.textSecondary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
