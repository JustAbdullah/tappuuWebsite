import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../controllers/AdvertiserController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/AdvertiserProfile.dart';
import '../../AdvertiserManageDeskTop/AdvertiserDataScreenDesktop.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';
import 'EditAdvertiserScreenDeskTop.dart';

// سلوك تمرير بدون شريط تمرير
class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics();
  }
}

class AdvertiserProfilesScreenDeskTop extends StatefulWidget {
  const AdvertiserProfilesScreenDeskTop({Key? key}) : super(key: key);

  @override
  State<AdvertiserProfilesScreenDeskTop> createState() =>
      _AdvertiserProfilesScreenDeskTopState();
}

class _AdvertiserProfilesScreenDeskTopState
    extends State<AdvertiserProfilesScreenDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final AdvertiserController advC =
      Get.put(AdvertiserController(), permanent: true);
  final LoadingController loadingC = Get.find<LoadingController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // نقطة رفع الصورة (مطابقة لباقي الشاشات)
  static const String _root =
      "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  static const String _uploadApi = "$_root/upload";

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  void _fetchProfiles() {
    final userId = loadingC.currentUser?.id ?? 0;
    if (userId > 0) {
      advC.fetchProfiles(userId).then((_) => advC.resetSelection());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final HomeController homeC = Get.find<HomeController>();

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
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(scaffoldKey: _scaffoldKey),
          Expanded(
            child: ScrollConfiguration(
              behavior: NoScrollbarScrollBehavior(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    GetBuilder<AdvertiserController>(
                      builder: (controller) {
                        if (controller.isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 980.w),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24.w, vertical: 24.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'ملفات المعلنين الخاصة بك'.tr,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.xlarge,
                                        fontWeight: FontWeight.bold,
                                        fontFamily:
                                            AppTextStyles.appFontFamily,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  Center(
                                    child: Text(
                                      'اختر ملفًا لعرض تفاصيله أو قم بإنشاء ملف جديد'
                                          .tr,
                                      style: TextStyle(
                                        fontSize: AppTextStyles.medium,
                                        fontFamily:
                                            AppTextStyles.appFontFamily,
                                        color: AppColors.textSecondary(
                                            isDarkMode),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: 28.h),

                                  // القائمة المنسدلة
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(isDarkMode),
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.w, vertical: 6.h),
                                    child: _buildDropdown(
                                        controller, isDarkMode),
                                  ),

                                  SizedBox(height: 28.h),

                                  if (controller.selected.value != null)
                                    _ProfileAndMemberCardDesktop(
                                      profile: controller.selected.value!,
                                      isDark: isDarkMode,
                                      onEditCompany: () {
                                        controller.loadProfileForEdit(
                                            controller.selected.value!);
                                        Get.to(() =>
                                             EditAdvertiserScreenDeskTop());
                                      },
                                      onDeleteCompany: () async {
                                        final p =
                                            controller.selected.value!;
                                        if (p.id == null) return;
                                        final yes = await _confirm(
                                          context,
                                          isDarkMode,
                                          title: 'تأكيد الحذف',
                                          message:
                                              'هل أنت متأكد أنك تريد حذف هذا الملف؟',
                                        );
                                        if (yes == true) {
                                          await controller
                                              .deleteProfile(p.id!);
                                        }
                                      },
                                      onEditMember:
                                          (CompanyMemberLite member) async {
                                        // تعديل بيانات العضو + الصورة
                                        await _openMemberEditSheet(
                                            context, isDarkMode, member);
                                      },
                                      onLeaveCompany:
                                          (CompanyMemberLite member) async {
                                        final yes = await _confirm(
                                          context,
                                          isDarkMode,
                                          title: 'مغادرة الشركة',
                                          message:
                                              'هل تريد بالتأكيد مغادرة هذه الشركة؟',
                                        );
                                        if (yes == true) {
                                          final userId =
                                              loadingC.currentUser?.id ?? 0;
                                          await advC
                                              .removeMyCompanyMembership(
                                            companyId:
                                                member.advertiserProfileId!,
                                            memberId: member.id!,
                                            actorUserId: userId,
                                          );
                                          _fetchProfiles();
                                        }
                                      },
                                    ),

                                  SizedBox(height: 30.h),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        controller.resetSelection();
                                        Get.to(() =>
                                             AdvertiserDataScreenDeskTop());
                                      },
                                      icon: Icon(Icons.add, size: 20.w),
                                      label: Text(
                                        'إنشاء ملف جديد'.tr,
                                        style: TextStyle(
                                          color: AppColors.onPrimary,
                                          fontSize: AppTextStyles.medium,
                                          fontFamily:
                                              AppTextStyles.appFontFamily,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.onPrimary,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 32.w,
                                          vertical: 14.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      AdvertiserController controller, bool isDarkMode) {
    if (controller.profiles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: Text(
            'لا توجد ملفات متاحة'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
        ),
      );
    }

    return DropdownButton<AdvertiserProfile>(
      isExpanded: true,
      value: controller.selected.value,
      underline: const SizedBox(),
      dropdownColor: AppColors.surface(isDarkMode),
      icon: Icon(
        Icons.arrow_drop_down,
        color: AppColors.textPrimary(isDarkMode),
        size: 28.w,
      ),
      hint: Text(
        'اختر ملف المعلن'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.medium,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      items: controller.profiles.map((profile) {
        final title = profile.name ??
            profile.description ??
            '${'ملف بدون وصف (ID:'.tr} ${profile.id})';
        return DropdownMenuItem<AdvertiserProfile>(
          value: profile,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDarkMode),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      onChanged: (AdvertiserProfile? newValue) {
        controller.selected.value = newValue;
        controller.update();
      },
    );
  }

  Future<bool?> _confirm(
    BuildContext ctx,
    bool isDarkMode, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface(isDarkMode),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.textSecondary(isDarkMode),
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMemberEditSheet(
    BuildContext context,
    bool isDark,
    CompanyMemberLite member,
  ) async {
    final nameCtrl =
        TextEditingController(text: member.displayName ?? '');
    final phoneCtrl =
        TextEditingController(text: member.contactPhone ?? '');
    final waCtrl =
        TextEditingController(text: member.whatsappPhone ?? '');
    final waCallCtrl =
        TextEditingController(text: member.whatsappCallNumber ?? '');
    final formKey = GlobalKey<FormState>();
    final userId = loadingC.currentUser?.id ?? 0;

    // حالة محلية للأفاتار داخل الـ BottomSheet
    File? avatarFile;
    String uploadedAvatarUrl = member.avatarUrl ?? "";
    bool uploading = false;

    Future<void> pickAvatar() async {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        avatarFile = File(picked.path);
        uploadedAvatarUrl = ""; // إعادة الضبط لرفع الجديد
      }
    }

    void removeAvatar() {
      avatarFile = null;
      uploadedAvatarUrl = ""; // لن نرسل avatarUrl
    }

    Future<void> uploadAvatar(StateSetter setSBState) async {
      if (avatarFile == null) return;
      setSBState(() => uploading = true);
      try {
        final req =
            http.MultipartRequest('POST', Uri.parse(_uploadApi));
        req.files.add(await http.MultipartFile.fromPath(
            'images[]', avatarFile!.path));
        final resp = await req.send();
        final body = await resp.stream.bytesToString();
        if (resp.statusCode == 201) {
          final jsonBody =
              jsonDecode(body) as Map<String, dynamic>;
          final urls =
              List<String>.from(jsonBody['image_urls'] ?? const []);
          uploadedAvatarUrl =
              urls.isNotEmpty ? urls.first : "";
        } else {
          Get.snackbar(
            'فشل رفع الصورة',
            '(${resp.statusCode}) $body',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        Get.snackbar(
          'خطأ في الرفع',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        setSBState(() => uploading = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSBState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              top: 16.h,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تعديل بياناتي كعضو',
                    style: TextStyle(
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  // ====== أفاتار العضو ======
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40.r,
                            backgroundColor:
                                AppColors.textSecondary(isDark)
                                    .withOpacity(.15),
                            backgroundImage: avatarFile != null
                                ? FileImage(avatarFile!)
                                : (uploadedAvatarUrl.isNotEmpty
                                    ? NetworkImage(uploadedAvatarUrl)
                                        as ImageProvider
                                    : (member.avatarUrl != null &&
                                            member.avatarUrl!
                                                .isNotEmpty
                                        ? NetworkImage(member.avatarUrl!)
                                        : null)),
                            child: (avatarFile == null &&
                                    uploadedAvatarUrl.isEmpty &&
                                    (member.avatarUrl ?? '')
                                        .isEmpty)
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 36.r,
                                    color:
                                        AppColors.textSecondary(isDark),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(16.r),
                              child: InkWell(
                                onTap: () async {
                                  await pickAvatar();
                                  setSBState(() {});
                                },
                                borderRadius:
                                    BorderRadius.circular(16.r),
                                child: Padding(
                                  padding: EdgeInsets.all(6.r),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 16.r,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صورة العضو (اختياري)',
                              style: TextStyle(
                                fontSize: AppTextStyles.large,
                                fontFamily:
                                    AppTextStyles.appFontFamily,
                                fontWeight: FontWeight.w700,
                                color:
                                    AppColors.textPrimary(isDark),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              avatarFile == null
                                  ? 'يمكنك اختيار صورة جديدة أو تركها كما هي.'
                                  : 'تحتاج لرفع الصورة قبل الحفظ.',
                              style: TextStyle(
                                fontSize: AppTextStyles.small,
                                color: AppColors.textSecondary(
                                    isDark),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: uploading ||
                                          avatarFile == null
                                      ? null
                                      : () async {
                                          await uploadAvatar(
                                              setSBState);
                                        },
                                  icon: uploading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons
                                          .cloud_upload_rounded),
                                  label: Text(
                                    uploading
                                        ? 'جارِ الرفع...'
                                        : 'رفع الصورة',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primary,
                                    foregroundColor:
                                        AppColors.onPrimary,
                                    minimumSize:
                                        Size(140.w, 40.h),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: (avatarFile != null ||
                                          uploadedAvatarUrl
                                              .isNotEmpty ||
                                          (member.avatarUrl ?? '')
                                              .isNotEmpty)
                                      ? () {
                                          removeAvatar();
                                          setSBState(() {});
                                        }
                                      : null,
                                  icon: const Icon(Icons
                                      .delete_outline_rounded),
                                  label: const Text('إزالة'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الظاهر',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'حقل مطلوب'
                        : null,
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'هاتف التواصل',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: waCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم واتساب',
                      prefixIcon: Icon(Icons.chat),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: waCallCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'واتساب (للاتصال wa.me)',
                      prefixIcon: Icon(Icons.call),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ'),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        // في حال اختيار صورة ولم تُرفع بعد
                        if (avatarFile != null &&
                            uploadedAvatarUrl.isEmpty) {
                          await uploadAvatar(setSBState);
                          if (uploadedAvatarUrl.isEmpty) return;
                        }

                        await advC.updateMyCompanyMembership(
                          companyId:
                              member.advertiserProfileId!,
                          memberId: member.id!,
                          actorUserId: userId,
                          displayName:
                              nameCtrl.text.trim(),
                          contactPhone:
                              phoneCtrl.text.trim().isEmpty
                                  ? null
                                  : phoneCtrl.text.trim(),
                          whatsappPhone:
                              waCtrl.text.trim().isEmpty
                                  ? null
                                  : waCtrl.text.trim(),
                          whatsappCallNumber:
                              waCallCtrl.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : waCallCtrl.text.trim(),
                          avatarUrl:
                              uploadedAvatarUrl.isNotEmpty
                                  ? uploadedAvatarUrl
                                  : null,
                        );
                        Navigator.pop(context);
                        _fetchProfiles();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// كرت شامل: الشركة + معلومات العضو + إجراءات المالك/العضو
class _ProfileAndMemberCardDesktop extends StatelessWidget {
  const _ProfileAndMemberCardDesktop({
    required this.profile,
    required this.isDark,
    required this.onEditCompany,
    required this.onDeleteCompany,
    required this.onEditMember,
    required this.onLeaveCompany,
  });

  final AdvertiserProfile profile;
  final bool isDark;
  final VoidCallback onEditCompany;
  final VoidCallback onDeleteCompany;
  final void Function(CompanyMemberLite member) onEditMember;
  final void Function(CompanyMemberLite member) onLeaveCompany;

  /// helper صغير لتحويل المسار النسبي إلى رابط كامل
  String? _resolveUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // لو السيرفر يرجّع path نسبي مثل "uploads/advertisers/logo.png"
    return 'https://stayinme.arabiagroup.net/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = (profile.accountType == 'company');
    final isOwner = (profile.isOwner ?? false);
    final member = profile.companyMember; // قد يكون null

    final logoUrl = _resolveUrl(profile.logo);
    final memberAvatarUrl =
        member != null ? _resolveUrl(member.avatarUrl) : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======= رأس الشركة =======
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24.w,
                backgroundColor:
                    AppColors.textSecondary(isDark).withOpacity(.15),
                backgroundImage:
                    (logoUrl != null) ? NetworkImage(logoUrl) : null,
                child: logoUrl == null
                    ? Icon(
                        isCompany ? Icons.apartment : Icons.person,
                        color: isCompany ? Colors.blue : Colors.green,
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name ?? 'بدون اسم',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTextStyles.xxlarge,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if ((profile.description ?? '').isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        profile.description!,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color:
                      (isCompany ? Colors.blue : Colors.green)[700],
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isCompany ? 'شركة' : 'فردي',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),
          _info(
            icon: Icons.phone,
            label: 'رقم الاتصال',
            value: profile.contactPhone ?? 'غير محدد',
            isDark: isDark,
          ),
          _info(
            icon: Icons.chat,
            label: 'واتساب',
            value: profile.whatsappPhone ?? 'غير محدد',
            isDark: isDark,
          ),
          _info(
            icon: Icons.call,
            label: 'واتساب للاتصال',
            value: profile.whatsappCallNumber ?? 'غير محدد',
            isDark: isDark,
          ),

          SizedBox(height: 14.h),
          Divider(
            color:
                AppColors.textSecondary(isDark).withOpacity(.15),
          ),
          SizedBox(height: 8.h),

          // ======= إجراءات المالك للشركة/الفرد =======
          if (isOwner) _ownerCompanyActions(context) else const SizedBox.shrink(),

          // ======= قسم العضو (لو الشركة وبها عضوية للمستخدم) =======
          if (isCompany && member != null) ...[
            SizedBox(height: 18.h),
            Text(
              'بياناتي كعضو في الشركة',
              style: TextStyle(
                fontSize: AppTextStyles.xlarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            SizedBox(height: 8.h),

            // صورة العضو + الاسم
            Row(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor:
                      AppColors.textSecondary(isDark).withOpacity(.15),
                  backgroundImage: (memberAvatarUrl != null)
                      ? NetworkImage(memberAvatarUrl)
                      : null,
                  child: memberAvatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 28.r,
                          color: AppColors.textSecondary(isDark),
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    member.displayName ?? '—',
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            _info(
              icon: Icons.badge,
              label: 'الدور',
              value: _roleAr(member.role),
              isDark: isDark,
            ),
            _info(
              icon: Icons.phone,
              label: 'هاتف التواصل',
              value: member.contactPhone ?? 'غير محدد',
              isDark: isDark,
            ),
            _info(
              icon: Icons.chat,
              label: 'واتساب',
              value: member.whatsappPhone ?? 'غير محدد',
              isDark: isDark,
            ),
            _info(
              icon: Icons.call,
              label: 'واتساب للاتصال',
              value: member.whatsappCallNumber ?? 'غير محدد',
              isDark: isDark,
            ),

            SizedBox(height: 12.h),

            if (!isOwner)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onLeaveCompany(member),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('مغادرة الشركة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                        minimumSize: Size(140.w, 40.h),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => onEditMember(member),
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل بياناتي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: Size(160.w, 40.h),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _ownerCompanyActions(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Wrap(
        spacing: 10.w,
        children: [
          OutlinedButton.icon(
            onPressed: onDeleteCompany,
            icon: const Icon(Icons.delete),
            label: const Text('حذف الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[700]!),
              minimumSize: Size(140.w, 44.h),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onEditCompany,
            icon: const Icon(Icons.edit),
            label: const Text('تعديل الشركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.onSecondary,
              minimumSize: Size(160.w, 44.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _roleAr(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'owner':
        return 'مالك';
      case 'publisher':
        return 'ناشر';
      case 'viewer':
        return 'عارض';
      default:
        return role ?? 'غير محدد';
    }
  }
}
