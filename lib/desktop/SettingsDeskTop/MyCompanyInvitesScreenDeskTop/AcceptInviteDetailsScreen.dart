

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../controllers/CompanyInvitesController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class AcceptInviteDetailsScreenDeskTop extends StatefulWidget {
  const AcceptInviteDetailsScreenDeskTop({
    Key? key,
    required this.inviteId,
    required this.companyName,
    required this.roleLabel, // بالعربي: ناشر/عارض
    required this.userId,
  }) : super(key: key);

  final int inviteId;
  final String companyName;
  final String roleLabel; // نص عربي جاهز من الشاشة السابقة
  final int userId;

  @override
  State<AcceptInviteDetailsScreenDeskTop> createState() =>
      _AcceptInviteDetailsScreenDeskTopState();
}

class _AcceptInviteDetailsScreenDeskTopState
    extends State<AcceptInviteDetailsScreenDeskTop> {
  final ThemeController themeC = Get.find<ThemeController>();
  final CompanyInvitesController c = Get.find<CompanyInvitesController>();
  final HomeController homeC = Get.find<HomeController>();

  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _waPhoneCtrl = TextEditingController();
  final _waCallCtrl = TextEditingController();

  // === أفاتار العضو (اختياري) ===
  static const String _root = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  static const String _uploadApi = "$_root/upload";

  File? _avatarFile;
  String _uploadedAvatarUrl = ""; // ناتج /upload
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _waPhoneCtrl.dispose();
    _waCallCtrl.dispose();
    super.dispose();
  }

  String? _reqValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'حقل مطلوب';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final digits = v.replaceAll(RegExp(r'\D+'), '');
    if (digits.length < 7) return 'رقم غير صالح';
    return null;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _uploadedAvatarUrl = ""; // إعادة ضبط في حال تغيير الصورة
      });
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarFile = null;
      _uploadedAvatarUrl = "";
    });
  }

  Future<void> _uploadAvatarIfNeeded() async {
    if (_avatarFile == null || _uploadedAvatarUrl.isNotEmpty) return;
    setState(() => _uploadingAvatar = true);
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_uploadApi));
      req.files.add(await http.MultipartFile.fromPath('images[]', _avatarFile!.path));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 201) {
        final jsonBody = jsonDecode(body) as Map<String, dynamic>;
        final urls = List<String>.from(jsonBody['image_urls'] ?? const []);
        setState(() {
          _uploadedAvatarUrl = urls.isNotEmpty ? urls.first : "";
        });
      } else {
        Get.snackbar('فشل رفع الصورة', '(${resp.statusCode}) $body',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ في الرفع', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeC.isDarkMode.value;

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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 1100.w),
                  child: _buildContent(isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الصفحة العلوي
        Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded,
                color: AppColors.primary, size: 26.w),
            SizedBox(width: 10.w),
            Text(
              'إكمال بيانات قبول الدعوة',
              style: TextStyle(
                fontSize: AppTextStyles.xxlarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'إغلاق',
              onPressed: () => Get.back(),
              icon: Icon(Icons.close_rounded,
                  color: AppColors.textSecondary(isDark)),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // تخطيط بعمودين: (معلومات/ملخص) + (نموذج)
        LayoutBuilder(builder: (context, cons) {
          final isWide = cons.maxWidth >= 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العمود الأيسر: بطاقة الملخص والتوضيح
              Flexible(
                flex: isWide ? 4 : 0,
                child: _SummaryCard(
                  isDark: isDark,
                  companyName: widget.companyName,
                  roleLabel: widget.roleLabel,
                ),
              ),
              if (isWide) SizedBox(width: 20.w) else SizedBox(height: 16.h),

              // العمود الأيمن: بطاقة الصورة + نموذج الإدخال
              Flexible(
                flex: isWide ? 6 : 0,
                child: Column(
                  children: [
                    _AvatarCard(
                      isDark: isDark,
                      avatarFile: _avatarFile,
                      uploadedAvatarUrl: _uploadedAvatarUrl,
                      uploading: _uploadingAvatar,
                      onPick: _pickAvatar,
                      onRemove: _removeAvatar,
                      onUpload: _uploadAvatarIfNeeded,
                    ),
                    SizedBox(height: 16.h),
                    _FormCard(
                      isDark: isDark,
                      formKey: _formKey,
                      displayNameCtrl: _displayNameCtrl,
                      contactPhoneCtrl: _contactPhoneCtrl,
                      waPhoneCtrl: _waPhoneCtrl,
                      waCallCtrl: _waCallCtrl,
                      reqValidator: _reqValidator,
                      phoneValidator: _phoneValidator,
                      onSubmit: _onSubmit,
                      isSubmittingDisabled: _uploadingAvatar, // لا نرسل أثناء الرفع
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // لو فيه صورة مختارة ولم تُرفع بعد → ارفعها أولاً لتحصل على avatar_url
    if (_avatarFile != null && _uploadedAvatarUrl.isEmpty) {
      await _uploadAvatarIfNeeded();
      if (_uploadedAvatarUrl.isEmpty) {
        // فشل الرفع
        return;
      }
    }

    final ok = await c.acceptInvite(
      inviteId: widget.inviteId,
      userId: widget.userId,
      displayName: _displayNameCtrl.text.trim(),
      contactPhone:
          _contactPhoneCtrl.text.trim().isEmpty ? null : _contactPhoneCtrl.text.trim(),
      whatsappPhone:
          _waPhoneCtrl.text.trim().isEmpty ? null : _waPhoneCtrl.text.trim(),
      whatsappCallNumber:
          _waCallCtrl.text.trim().isEmpty ? null : _waCallCtrl.text.trim(),
      // الجديد:
      avatarUrl: _uploadedAvatarUrl.isNotEmpty ? _uploadedAvatarUrl : null,
    );

    if (ok) {
      Get.back();
      Get.snackbar('تم القبول', 'تمت إضافتك كعضو نشط في الشركة',
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
    } else {
      Get.snackbar('تعذر الإكمال', 'تحقق من صحة البيانات وحاول مجدداً',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

/* ================== Widgets ================== */

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isDark,
    required this.companyName,
    required this.roleLabel,
  });

  final bool isDark;
  final String companyName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primary.withOpacity(.16), Colors.transparent]
              : [AppColors.primary.withOpacity(.10), Colors.white],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .18 : .08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس مختصر للشركة
          Row(
            children: [
              CircleAvatar(
                radius: 22.w,
                backgroundColor: AppColors.primary.withOpacity(.12),
                child:
                    Icon(Icons.apartment_rounded, color: AppColors.primary, size: 22.w),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    fontSize: AppTextStyles.xlarge,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: AppColors.textSecondary(isDark).withOpacity(.18)),
          SizedBox(height: 12.h),

          // نص توضيحي
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: AppTextStyles.large,
                height: 1.5,
                color: AppColors.textPrimary(isDark),
                fontFamily: AppTextStyles.appFontFamily,
              ),
              children: [
                const TextSpan(text: 'أنت على وشك قبول دعوة للانضمام إلى شركة '),
                TextSpan(
                  text: companyName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const TextSpan(text: ' بدور '),
                TextSpan(
                  text: roleLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const TextSpan(text: '.\n\n'),
                const TextSpan(
                  text:
                      'يرجى إدخال بياناتك للملف الوظيفي داخل الشركة. يمكنك تعديل هذه البيانات لاحقاً من صفحة ملف الشركة.',
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
          _HintRow(
            isDark: isDark,
            icon: Icons.info_outline_rounded,
            text: 'الاسم الظاهر سيظهر لزملائك داخل الشركة.',
          ),
          SizedBox(height: 6.h),
          _HintRow(
            isDark: isDark,
            icon: Icons.lock_outline_rounded,
            text: 'لن نشارك رقم هاتفك خارج الشركة.',
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.isDark, required this.icon, required this.text});
  final bool isDark;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: AppColors.textSecondary(isDark)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDark),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.isDark,
    required this.avatarFile,
    required this.uploadedAvatarUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
    required this.onUpload,
  });

  final bool isDark;
  final File? avatarFile;
  final String uploadedAvatarUrl;
  final bool uploading;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;
  final Future<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.textSecondary(isDark).withOpacity(.18)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 36.r,
                backgroundColor: AppColors.textSecondary(isDark).withOpacity(.15),
                backgroundImage: avatarFile != null
                    ? FileImage(avatarFile!)
                    : (uploadedAvatarUrl.isNotEmpty
                        ? NetworkImage(uploadedAvatarUrl) as ImageProvider
                        : null),
                child: (avatarFile == null && uploadedAvatarUrl.isEmpty)
                    ? Icon(Icons.person_rounded,
                        size: 36.r, color: AppColors.textSecondary(isDark))
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16.r),
                  child: InkWell(
                    onTap: onPick,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.all(6.r),
                      child: Icon(Icons.edit_rounded,
                          size: 16.r, color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('صورة العضو (اختياري)',
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(isDark),
                    )),
                SizedBox(height: 6.h),
                Text(
                  avatarFile == null
                      ? (uploadedAvatarUrl.isNotEmpty
                          ? 'تم رفع صورة بالفعل، يمكنك استبدالها.'
                          : 'اختر صورة شخصية واضحة. بإمكانك المتابعة بدون صورة.')
                      : 'تحتاج لرفع الصورة قبل الحفظ.',
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    ElevatedButton.icon(
                      onPressed: (uploading || avatarFile == null) ? null : onUpload,
                      icon: uploading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(uploading ? 'جارِ الرفع...' : 'رفع الصورة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: Size(140.w, 40.h),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: (avatarFile != null || uploadedAvatarUrl.isNotEmpty)
                          ? onRemove
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('إزالة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.isDark,
    required this.formKey,
    required this.displayNameCtrl,
    required this.contactPhoneCtrl,
    required this.waPhoneCtrl,
    required this.waCallCtrl,
    required this.reqValidator,
    required this.phoneValidator,
    required this.onSubmit,
    this.isSubmittingDisabled = false,
  });

  final bool isDark;
  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameCtrl;
  final TextEditingController contactPhoneCtrl;
  final TextEditingController waPhoneCtrl;
  final TextEditingController waCallCtrl;
  final String? Function(String?) reqValidator;
  final String? Function(String?) phoneValidator;
  final Future<void> Function() onSubmit;
  final bool isSubmittingDisabled;

  @override
  Widget build(BuildContext context) {
    final CompanyInvitesController c = Get.find<CompanyInvitesController>();

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
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _LabeledField(
              isDark: isDark,
              label: 'الاسم الظاهر',
              child: TextFormField(
                controller: displayNameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(isDark, 'أدخل الاسم الظاهر', Icons.person_rounded),
                validator: reqValidator,
              ),
            ),
            SizedBox(height: 12.h),

            _LabeledField(
              isDark: isDark,
              label: 'هاتف التواصل',
              child: TextFormField(
                controller: contactPhoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(isDark, 'أدخل رقم الهاتف', Icons.phone_rounded),
                validator: phoneValidator,
              ),
            ),
            SizedBox(height: 12.h),

            _LabeledField(
              isDark: isDark,
              label: 'رقم واتساب',
              child: TextFormField(
                controller: waPhoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(isDark, 'أدخل رقم واتساب', Icons.chat_rounded),
                validator: phoneValidator,
              ),
            ),
            SizedBox(height: 12.h),

            _LabeledField(
              isDark: isDark,
              label: 'رقم واتساب للاتصال (wa.me)',
              child: TextFormField(
                controller: waCallCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    _inputDecoration(isDark, 'أدخل رقم wa.me', Icons.call_rounded),
                validator: phoneValidator,
              ),
            ),
            SizedBox(height: 16.h),

            Obx(() {
              final saving = c.isSaving.value;
              final disabled = saving || isSubmittingDisabled;
              return SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: disabled ? null : onSubmit,
                  icon: disabled
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    saving ? 'جارِ الحفظ...' : (isSubmittingDisabled ? 'انتظر قليلاً...' : 'تأكيد القبول'),
                    style: TextStyle(
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w800,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                    elevation: 3,
                    shadowColor: AppColors.primary.withOpacity(.22),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface(isDark),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.textSecondary(isDark).withOpacity(.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(.65), width: 1.2),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.isDark,
    required this.label,
    required this.child,
  });

  final bool isDark;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTextStyles.large,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(isDark),
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}
