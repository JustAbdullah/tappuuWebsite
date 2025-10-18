// SendCompanyInvitesScreenDeskTop (WEB - Desktop/Large Screens)
// نسخة سطح المكتب لواجهة إرسال وعرض الدعوات، بنفس روح تصاميم الديسكتوب (Top/Secondary AppBars)
// تحافظ على نفس المنطق الموجود في نسخة الموبايل (CompanyInvitesController) دون تغيير هوية التعامل معه.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/CompanyInvitesController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/CompanySummary.dart';
import '../../../core/data/model/company_invite.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const AlwaysScrollableScrollPhysics();
}

class SendCompanyInvitesScreenDeskTop extends StatefulWidget {
  const SendCompanyInvitesScreenDeskTop({Key? key}) : super(key: key);

  @override
  State<SendCompanyInvitesScreenDeskTop> createState() => _SendCompanyInvitesScreenDeskTopState();
}

class _SendCompanyInvitesScreenDeskTopState extends State<SendCompanyInvitesScreenDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final CompanyInvitesController c = Get.put(CompanyInvitesController(), permanent: true);

  final _emailCtrl = TextEditingController();
  final _emailNode = FocusNode();

  final RxString _role = 'publisher'.obs;
  final Rxn<CompanySummary> _selectedCompany = Rxn<CompanySummary>();
  final RxString _email = ''.obs;

  @override
  void initState() {
    super.initState();

    _emailCtrl.addListener(() {
      _email.value = _emailCtrl.text.trim().toLowerCase();
    });

    final userId = loadingC.currentUser?.id ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await c.fetchMyCompanies(userId: userId, scope: 'owner');
      if (c.myCompanies.isNotEmpty) {
        _selectedCompany.value ??= c.myCompanies.first;
        await c.fetchCompanyInvites(_selectedCompany.value!.id);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) {
    final s = v.trim().toLowerCase();
    return s.contains('@') && s.contains('.') && s.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeC.isDarkMode.value;
    final HomeController homeC = Get.find<HomeController>();

    return Scaffold(
      endDrawer: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: homeC.isServicesOrSettings.value
            ? const SettingsDrawerDeskTop(key: ValueKey(1))
            : const DesktopServicesDrawer(key: ValueKey(2)),
      ),
      backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [
           TopAppBarDeskTop(),
           SecondaryAppBarDeskTop(),
          Expanded(
            child: ScrollConfiguration(
              behavior: NoScrollbarScrollBehavior(),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 1100.w),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                      child: Obx(() {
                        final canSend = _selectedCompany.value != null &&
                            _isValidEmail(_email.value) &&
                            !c.isSaving.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DesktopHeader(isDark: isDark),
                            SizedBox(height: 16.h),

                            // صف من عمودين: اختيار الشركة + نموذج الدعوة
                            LayoutBuilder(
                              builder: (_, cs) {
                                final isWide = cs.maxWidth >= 900;
                                return isWide
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: _CompanyPicker(
                                              isDark: isDark,
                                              selected: _selectedCompany,
                                              companies: c.myCompanies,
                                              onChanged: (co) async {
                                                _selectedCompany.value = co;
                                                if (co != null) {
                                                  await c.fetchCompanyInvites(co.id);
                                                }
                                              },
                                              onRefresh: () async {
                                                final userId = loadingC.currentUser?.id ?? 0;
                                                await c.fetchMyCompanies(userId: userId, scope: 'owner');

                                                if (_selectedCompany.value != null) {
                                                  final exist = c.myCompanies.any((x) => x.id == _selectedCompany.value!.id);
                                                  if (!exist && c.myCompanies.isNotEmpty) {
                                                    _selectedCompany.value = c.myCompanies.first;
                                                  }
                                                } else if (c.myCompanies.isNotEmpty) {
                                                  _selectedCompany.value = c.myCompanies.first;
                                                }

                                                if (_selectedCompany.value != null) {
                                                  await c.fetchCompanyInvites(_selectedCompany.value!.id);
                                                }
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            flex: 7,
                                            child: _InviteFormCard(
                                              isDark: isDark,
                                              role: _role,
                                              emailCtrl: _emailCtrl,
                                              onRoleChanged: (r) => _role.value = r,
                                              onSend: canSend
                                                  ? () async {
                                                      final company = _selectedCompany.value;
                                                      if (company == null) return;
                                                      final userId = loadingC.currentUser?.id ?? 0;

                                                      final ok = await c.createInvite(
                                                        companyId: company.id,
                                                        inviterUserId: userId,
                                                        inviteeEmail: _email.value,
                                                        role: _role.value,
                                                      );

                                                      if (ok) {
                                                        _emailCtrl.clear();
                                                        _emailNode.unfocus();
                                                        Get.snackbar('تم الإرسال'.tr, 'تم إرسال الدعوة بنجاح'.tr,
                                                            snackPosition: SnackPosition.BOTTOM,
                                                            duration: const Duration(seconds: 2));
                                                      } else {
                                                        Get.snackbar('تعذّر الإرسال'.tr, 'تحقق من صحة البريد والصلاحيات'.tr,
                                                            snackPosition: SnackPosition.BOTTOM);
                                                      }
                                                    }
                                                  : null,
                                              isSending: c.isSaving.value,
                                              canSend: canSend,
                                              emailFocusNode: _emailNode,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _CompanyPicker(
                                            isDark: isDark,
                                            selected: _selectedCompany,
                                            companies: c.myCompanies,
                                            onChanged: (co) async {
                                              _selectedCompany.value = co;
                                              if (co != null) {
                                                await c.fetchCompanyInvites(co.id);
                                              }
                                            },
                                            onRefresh: () async {
                                              final userId = loadingC.currentUser?.id ?? 0;
                                              await c.fetchMyCompanies(userId: userId, scope: 'owner');

                                              if (_selectedCompany.value != null) {
                                                final exist = c.myCompanies.any((x) => x.id == _selectedCompany.value!.id);
                                                if (!exist && c.myCompanies.isNotEmpty) {
                                                  _selectedCompany.value = c.myCompanies.first;
                                                }
                                              } else if (c.myCompanies.isNotEmpty) {
                                                _selectedCompany.value = c.myCompanies.first;
                                              }

                                              if (_selectedCompany.value != null) {
                                                await c.fetchCompanyInvites(_selectedCompany.value!.id);
                                              }
                                            },
                                          ),
                                          SizedBox(height: 16.h),
                                          _InviteFormCard(
                                            isDark: isDark,
                                            role: _role,
                                            emailCtrl: _emailCtrl,
                                            onRoleChanged: (r) => _role.value = r,
                                            onSend: canSend
                                                ? () async {
                                                    final company = _selectedCompany.value;
                                                    if (company == null) return;
                                                    final userId = loadingC.currentUser?.id ?? 0;

                                                    final ok = await c.createInvite(
                                                      companyId: company.id,
                                                      inviterUserId: userId,
                                                      inviteeEmail: _email.value,
                                                      role: _role.value,
                                                    );

                                                    if (ok) {
                                                      _emailCtrl.clear();
                                                      _emailNode.unfocus();
                                                      Get.snackbar('تم الإرسال'.tr, 'تم إرسال الدعوة بنجاح'.tr,
                                                          snackPosition: SnackPosition.BOTTOM,
                                                          duration: const Duration(seconds: 2));
                                                    } else {
                                                      Get.snackbar('تعذّر الإرسال'.tr, 'تحقق من صحة البريد والصلاحيات'.tr,
                                                          snackPosition: SnackPosition.BOTTOM);
                                                    }
                                                  }
                                                : null,
                                            isSending: c.isSaving.value,
                                            canSend: canSend,
                                            emailFocusNode: _emailNode,
                                          ),
                                        ],
                                      );
                              },
                            ),

                            SizedBox(height: 22.h),

                            Row(
                              children: [
                                Text(
                                  'دعوات الشركة الحالية'.tr,
                                  style: TextStyle(
                                    fontSize: AppTextStyles.xlarge,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary(isDark),
                                    fontFamily: AppTextStyles.appFontFamily,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedCompany.value != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(isDark),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: AppColors.divider(isDark)),
                                    ),
                                    child: Text(
                                      '#${_selectedCompany.value!.id}',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.medium,
                                        color: AppColors.textSecondary(isDark),
                                        fontFamily: AppTextStyles.appFontFamily,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12.h),

                            if (_selectedCompany.value == null)
                              _EmptyHint(isDark: isDark, text: 'اختر شركة أولاً'.tr)
                            else if (c.isLoading.value && c.invites.isEmpty)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 24.h),
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              )
                            else if (c.invites.isEmpty)
                              _EmptyHint(isDark: isDark, text: 'لا توجد دعوات بعد'.tr)
                            else
                              _InvitesTable(
                                isDark: isDark,
                                invites: c.invites,
                                onChangeRole: (invite, newRole) async {
                                  if (invite.status != 'pending') {
                                    Get.snackbar('غير متاح'.tr, 'لا يمكن تعديل دعوة منتهية'.tr,
                                        snackPosition: SnackPosition.BOTTOM);
                                    return;
                                  }
                                  final company = _selectedCompany.value!;
                                  final userId = loadingC.currentUser?.id ?? 0;
                                  final ok = await c.updateInvite(
                                    companyId: company.id,
                                    inviteId: invite.id!,
                                    actorUserId: userId,
                                    role: newRole,
                                  );
                                  if (!ok) {
                                    Get.snackbar('لم يتم التعديل'.tr, 'تحقق من صلاحياتك'.tr,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                                onCancel: (invite) async {
                                  final company = _selectedCompany.value!;
                                  final userId = loadingC.currentUser?.id ?? 0;
                                  final ok = await c.deleteInvite(
                                    companyId: company.id,
                                    inviteId: invite.id!,
                                    actorUserId: userId,
                                  );
                                  if (!ok) {
                                    Get.snackbar('تعذّر الإلغاء'.tr, 'حاول مجدداً'.tr,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                              ),

                            SizedBox(height: 24.h),
                          ],
                        );
                      }),
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
}

/* ================== Widgets ================== */

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.group_add_rounded, color: AppColors.primary, size: 26.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'أرسل دعوات الانضمام إلى شركتك وحدد دور المدعو'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                height: 1.35,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _RefreshButton(isDark: isDark),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final CompanyInvitesController c = Get.find<CompanyInvitesController>();
    final LoadingController loadingC = Get.find<LoadingController>();

    return IconButton(
      tooltip: 'تحديث'.tr,
      onPressed: () async {
        final userId = loadingC.currentUser?.id ?? 0;
        await c.fetchMyCompanies(userId: userId, scope: 'owner');
      },
      icon: Icon(Icons.refresh_rounded, size: 24.w, color: AppColors.primary),
    );
  }
}

class _CompanyPicker extends StatelessWidget {
  const _CompanyPicker({
    required this.isDark,
    required this.selected,
    required this.companies,
    required this.onChanged,
    required this.onRefresh,
  });

  final bool isDark;
  final Rxn<CompanySummary> selected;
  final List<CompanySummary> companies;
  final ValueChanged<CompanySummary?> onChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasValue = selected.value != null && companies.any((e) => e.id == selected.value!.id);
      final value = hasValue ? selected.value : null;

      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('اختر الشركة'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDark),
                      fontFamily: AppTextStyles.appFontFamily,
                    )),
                const Spacer(),
                IconButton(
                  tooltip: 'تحديث الشركات'.tr,
                  onPressed: onRefresh,
                  icon: Icon(Icons.sync, color: AppColors.primary, size: 22.w),
                )
              ],
            ),
            SizedBox(height: 10.h),
            DropdownButtonHideUnderline(
              child: DropdownButton<CompanySummary>(
                isExpanded: true,
                value: value,
                hint: Text(
                  companies.isEmpty ? 'لا توجد شركات'.tr : 'اختر...'.tr,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                items: companies.map((co) {
                  return DropdownMenuItem<CompanySummary>(
                    value: co,
                    child: Row(
                      children: [
                        _CompanyAvatar(url: co.logo),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(co.name ?? 'بدون اسم',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.large,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary(isDark),
                                    fontFamily: AppTextStyles.appFontFamily,
                                  )),
                              SizedBox(height: 2.h),
                              Text(
                                'أعضاء: ${co.membersCount} • دعوات معلّقة: ${co.pendingInvitesCount}',
                                style: TextStyle(
                                  fontSize: AppTextStyles.small,
                                  color: AppColors.textSecondary(isDark),
                                  fontFamily: AppTextStyles.appFontFamily,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary(isDark)),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18.w,
      backgroundColor: Colors.black12,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.apartment_rounded, size: 18.w, color: Colors.white)
          : null,
    );
  }
}

class _InviteFormCard extends StatelessWidget {
  const _InviteFormCard({
    required this.isDark,
    required this.role,
    required this.emailCtrl,
    required this.onRoleChanged,
    required this.onSend,
    required this.isSending,
    required this.canSend,
    required this.emailFocusNode,
  });

  final bool isDark;
  final RxString role;
  final TextEditingController emailCtrl;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback? onSend;
  final bool isSending;
  final bool canSend;
  final FocusNode emailFocusNode;

  @override
  Widget build(BuildContext context) {
    final btnColor = canSend ? Colors.amber : AppColors.textSecondary(isDark).withOpacity(.25);
    final btnFg = canSend ? Colors.black : AppColors.textSecondary(isDark);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .18 : .08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الدعوة'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              )),
          SizedBox(height: 14.h),
          TextFormField(
            controller: emailCtrl,
            focusNode: emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) {
              if (onSend != null) onSend!();
            },
            decoration: InputDecoration(
              labelText: 'بريد المدعو'.tr,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              filled: true,
              fillColor: AppColors.surface(isDark),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.25)),
              ),
            ),
            style: TextStyle(
              fontSize: AppTextStyles.large,
              color: AppColors.textPrimary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 14.h),
          Text('الدور'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              )),
          SizedBox(height: 10.h),
          Obx(() {
            return Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                _RoleChip(
                  label: 'ناشر'.tr,
                  selected: role.value == 'publisher',
                  icon: Icons.campaign_rounded,
                  onTap: () => onRoleChanged('publisher'),
                ),
              
              ],
            );
          }),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: canSend ? onSend : null,
              icon: isSending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                isSending ? 'جار الإرسال...'.tr : 'إرسال الدعوة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: canSend ? btnFg : AppColors.onPrimary.withOpacity(.6),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: btnFg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: canSend ? 2 : 0,
                shadowColor: Colors.black12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.deepPurple.withOpacity(.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.deepPurple.withOpacity(selected ? .0 : .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.w, color: selected ? Colors.white : Colors.deepPurple),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppTextStyles.medium,
                color: selected ? Colors.white : Colors.deepPurple,
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitesTable extends StatelessWidget {
  const _InvitesTable({
    required this.isDark,
    required this.invites,
    required this.onChangeRole,
    required this.onCancel,
  });

  final bool isDark;
  final List<CompanyInvite> invites;
  final Function(CompanyInvite invite, String newRole) onChangeRole;
  final Function(CompanyInvite invite) onCancel;

  Color _statusColor(String? s) {
    switch (s) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface(isDark)),
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
            DataColumn(label: Text('البريد'.tr)),
            DataColumn(label: Text('الدور'.tr)),
            DataColumn(label: Text('الحالة'.tr)),
            DataColumn(label: Text('إجراءات'.tr)),
          ],
          rows: invites.map((invite) {
            final status = invite.status ?? 'pending';
            final statusColor = _statusColor(status);
            return DataRow(
              cells: [
                DataCell(Text(invite.inviteeEmail ?? '-')),
                DataCell(Text(invite.role == 'viewer' ? 'عارض'.tr : 'ناشر'.tr)),
                DataCell(Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: statusColor.withOpacity(.4)),
                  ),
                  child: Text(
                    status.tr,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: AppTextStyles.small,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                )),
                DataCell(Row(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: 'تعديل الدور / إلغاء'.tr,
                      icon: Icon(Icons.more_horiz, color: AppColors.textSecondary(isDark)),
                      onSelected: (val) async {
                        if (val == 'publisher' || val == 'viewer') {
                          if (invite.status != 'pending') {
                            Get.snackbar('غير متاح'.tr, 'لا يمكن تعديل دعوة منتهية'.tr,
                                snackPosition: SnackPosition.BOTTOM);
                            return;
                          }
                          onChangeRole(invite, val);
                        } else if (val == 'cancel') {
                          onCancel(invite);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: 'publisher',
                          child: Row(
                            children: [
                              const Icon(Icons.campaign_rounded),
                              SizedBox(width: 8.w),
                              Text('تحويل إلى ناشر'.tr),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'viewer',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_rounded),
                              SizedBox(width: 8.w),
                              Text('تحويل إلى عارض'.tr),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'cancel',
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded, color: Colors.redAccent),
                              SizedBox(width: 8.w),
                              Text('إلغاء الدعوة'.tr,
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.isDark, required this.text});
  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
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
              text,
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
