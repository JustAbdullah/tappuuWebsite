import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../../controllers/BankAccountController.dart';
import '../../../controllers/CardPaymentController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/TransferProofController.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import '../../../core/data/model/BankAccountModel.dart';
import '../../ServicesDrawerWeb/ServicesDrawerWeb.dart';
import '../../secondary_app_bar_desktop.dart';
import '../../top_app_bar_desktop.dart';
import '../SettingsDrawerDeskTop.dart';

class WalletChargeDesktopScreen extends StatefulWidget {
  final UserWallet wallet;
  const WalletChargeDesktopScreen({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletChargeDesktopScreen> createState() => _WalletChargeDesktopScreenState();
}

class _WalletChargeDesktopScreenState extends State<WalletChargeDesktopScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.find<UserWalletController>();
  final BankAccountController bankAccountController = Get.put(BankAccountController());
  final TransferProofController _transferProofController = Get.put(TransferProofController());
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController());
  final HomeController _homeController = Get.find<HomeController>();

  final _formKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  final amountCtrl = TextEditingController();
  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();
  final userAccountNumberCtrl = TextEditingController();

  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'bank';
  }
  
  String selectedPaymentMethod = 'bank';
  BankAccountModel? selectedBankAccount;
  Uint8List? transferProofImageBytes;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    bankAccountController.fetchAccounts();
    selectedPaymentMethod = initialPaymentMethod;
    _cardPaymentController.fetchSetting();
    
    amountCtrl.addListener(_updateButtonState);
    cardNumberCtrl.addListener(_updateButtonState);
    nameCtrl.addListener(_updateButtonState);
    expiryCtrl.addListener(_updateButtonState);
    cvvCtrl.addListener(_updateButtonState);
    userAccountNumberCtrl.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    if (amountCtrl.text.isEmpty || double.tryParse(amountCtrl.text) == null) {
      return false;
    }

    if (selectedPaymentMethod == 'card') {
      return _formKey.currentState?.validate() ?? false;
    } else if (selectedPaymentMethod == 'bank') {
      return selectedBankAccount != null &&
          userAccountNumberCtrl.text.isNotEmpty &&
          transferProofImageBytes != null;
    }
    return false;
  }

  @override
  void dispose() {
    amountCtrl.removeListener(_updateButtonState);
    cardNumberCtrl.removeListener(_updateButtonState);
    nameCtrl.removeListener(_updateButtonState);
    expiryCtrl.removeListener(_updateButtonState);
    cvvCtrl.removeListener(_updateButtonState);
    userAccountNumberCtrl.removeListener(_updateButtonState);
    
    amountCtrl.dispose();
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    userAccountNumberCtrl.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value =
          TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          transferProofImageBytes = bytes;
          _updateButtonState();
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'خطأ',
        'فشل في اختيار الصورة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ رقم الحساب إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    if (selectedPaymentMethod == 'bank') {
      if (selectedBankAccount == null) {
        Get.snackbar(
          'خطأ', 
          'الرجاء اختيار حساب بنكي', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }

      if (transferProofImageBytes == null) {
        Get.snackbar(
          'خطأ', 
          'الرجاء رفع صورة إثبات التحويل', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }

      if (userAccountNumberCtrl.text.isEmpty) {
        Get.snackbar(
          'خطأ', 
          'الرجاء إدخال رقم حسابك', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }
    }

    setState(() => isProcessing = true);

    try {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      
      if (selectedPaymentMethod == 'card') {
        await Future.delayed(Duration(seconds: 2));
        
        if (amount > 0) {
          walletController.creditWallet(
            walletUuid: widget.wallet.uuid,
            amount: amount,
            note: "شحن محفظة:${widget.wallet.uuid}, مبلغ الشحن هو:$amount"
          );
        }
        
        Get.snackbar(
          'نجاح', 
          'تم شحن المحفظة بمبلغ ${amountCtrl.text} ل.س',
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.green, 
          colorText: Colors.white
        );
        Get.back();
        
      } else if (selectedPaymentMethod == 'bank') {
        // استخدم الـ controller الموجود بدلاً من إنشاء واحد جديد
        _transferProofController.imageBytes.value = transferProofImageBytes;
        
        final bool success = await _transferProofController.createProof(
          bankAccountId: selectedBankAccount!.id,
          walletId: int.parse(widget.wallet.id.toString()),
          amount: amount,
          sourceAccountNumber: userAccountNumberCtrl.text,
        );

        setState(() => isProcessing = false);

        if (success) {
          await Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تم إرسال إثبات التحويل بنجاح',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'عزيزي المستخدم',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'لقد تم إرسال إثبات عملية التحويل بنجاح. سيتم التحقق منها وإبلاغك في النتيجة خلال 24 ساعة.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary(themeController.isDarkMode.value),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'رقم العملية: ${DateTime.now().millisecondsSinceEpoch}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 10.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    ),
                    child: Text(
                      'موافق',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.only(bottom: 16.h),
            ),
            barrierDismissible: false,
          );
        } else {
          Get.snackbar(
            'خطأ', 
            'فشل في إرسال إثبات التحويل. يرجى المحاولة مرة أخرى.',
            snackPosition: SnackPosition.BOTTOM, 
            backgroundColor: Colors.red, 
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      setState(() => isProcessing = false);
      
      Get.snackbar(
        'خطأ', 
        'حدث خطأ غير متوقع: $e',
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }

  Widget _buildBankTransferSection(bool isDark) {
    return Form(
      key: _bankFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      'تعليمات التحويل البنكي',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'قم بتحويل مالي من خلال اختيار اسم البنك المتوفر مع إثبات دليل التحويل. سيتم التحقق من عملية التحويل ثم شحن المحفظة.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 12.sp,
                    color: AppColors.textSecondary(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          
          Text(
            'اختر الحساب البنكي للتحويل',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600, 
              color: AppColors.textSecondary(themeController.isDarkMode.value),
            ),
          ),
          SizedBox(height: 8.h),
          
          Obx(() {
            if (bankAccountController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: DropdownButton<BankAccountModel>(
                value: selectedBankAccount,
                isExpanded: true,
                underline: SizedBox(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                hint: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text('اختر الحساب البنكي', style: TextStyle(fontSize: 12.sp)),
                ),
                items: bankAccountController.accounts.map((BankAccountModel account) {
                  return DropdownMenuItem<BankAccountModel>(
                    value: account,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.bankName,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          account.accountNumber,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 10.sp,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (BankAccountModel? newValue) {
                  setState(() {
                    selectedBankAccount = newValue;
                    _updateButtonState();
                  });
                },
              ),
            );
          }),
          
          if (selectedBankAccount != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رقم الحساب للتحويل:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(selectedBankAccount!.accountNumber),
                        icon: Icon(Icons.copy, color: Colors.green, size: 18.r),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    selectedBankAccount!.accountNumber,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${selectedBankAccount!.bankName}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 12.sp,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 16.h),
          
          TextFormField(
            controller: userAccountNumberCtrl,
            decoration: InputDecoration(
              labelText: 'رقم حسابك للمرجع',
              hintText: 'أدخل رقم حسابك الذي ستقوم بالتحويل منه',
              filled: true,
              fillColor: AppColors.card(isDark),
              prefixIcon: Icon(Icons.account_balance, color: AppColors.primary, size: 18.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              labelStyle: TextStyle(fontSize: 12.sp),
              hintStyle: TextStyle(fontSize: 12.sp),
            ),
            style: TextStyle(fontSize: 12.sp),
            validator: selectedPaymentMethod == 'bank' ? (v) {
              if (v == null || v.isEmpty) return 'الرجاء إدخال رقم حسابك';
              return null;
            } : null,
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'إثبات التحويل',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          
          // تصميم محسّن لرفع الصور يعمل في الويب
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: transferProofImageBytes == null ? Colors.grey : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: transferProofImageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 32.r, color: Colors.grey),
                              SizedBox(height: 8.h),
                              Text('انقر لرفع صورة إثبات التحويل',
                                  style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                              SizedBox(height: 4.h),
                              Text(
                                'يمكنك سحب وإفلات الصورة هنا أو النقر للاختيار',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.memory(
                                  transferProofImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8.h,
                                right: 8.w,
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                  child: Icon(Icons.check_circle, color: Colors.white, size: 16.r),
                                ),
                              ),
                              Positioned(
                                bottom: 8.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'إثبات التحويل',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                if (transferProofImageBytes != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.edit, size: 14.r),
                        label: Text('تغيير الصورة', style: TextStyle(fontSize: 10.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            transferProofImageBytes = null;
                            _updateButtonState();
                          });
                        },
                        icon: Icon(Icons.delete, size: 14.r, color: Colors.red),
                        label: Text('حذف', style: TextStyle(fontSize: 10.sp, color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      'الدفع الآمن بالبطاقة',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 12.sp,
                    color: AppColors.textSecondary(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          TextFormField(
            controller: cardNumberCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onCardNumberChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
            decoration: InputDecoration(
              labelText: 'رقم البطاقة', 
              hintText: 'xxxx xxxx xxxx xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.credit_card, color: AppColors.primary, size: 18.r), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              labelStyle: TextStyle(fontSize: 12.sp),
              hintStyle: TextStyle(fontSize: 12.sp),
            ),
            style: TextStyle(fontSize: 12.sp),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة';
              if (digits.length < 12) return 'رقم البطاقة غير صحيح';
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          TextFormField(
            controller: nameCtrl, 
            keyboardType: TextInputType.name, 
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة', 
              hintText: 'أدخل الاسم كما هو مدون على البطاقة', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary, size: 18.r), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              labelStyle: TextStyle(fontSize: 12.sp),
              hintStyle: TextStyle(fontSize: 12.sp),
            ), 
            style: TextStyle(fontSize: 12.sp),
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم' : null
          ),
          SizedBox(height: 16.h),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'انتهاء الصلاحية (MMYY)', 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    labelStyle: TextStyle(fontSize: 12.sp),
                  ), 
                  style: TextStyle(fontSize: 12.sp),
                  validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح' : null
                ),
              ),
              SizedBox(width: 16.w),
              SizedBox(
                width: 120.w, 
                child: TextFormField(
                  controller: cvvCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'CVV', 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    labelStyle: TextStyle(fontSize: 12.sp),
                  ), 
                  style: TextStyle(fontSize: 12.sp),
                  obscureText: true, 
                  validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح' : null
                ),
              ),
            ]
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;

    return Scaffold(     
      endDrawer: _homeController.isServicesOrSettings.value
        ? SettingsDrawerDeskTop(key: const ValueKey(1))
        : DesktopServicesDrawer(key: const ValueKey(2)),
        
      backgroundColor: AppColors.background(isDark),
      body: Column(
        children: [
          TopAppBarDeskTop(),
          SecondaryAppBarDeskTop(),
          SizedBox(height: 16.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العمود الأيسر: ملخص العملية
                  Expanded(
                    flex: 1,
                    child: Card(
                      color: AppColors.card(isDark),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'ملخص عملية الشحن',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Divider(),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'المحفظة:',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  widget.wallet.uuid,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الرصيد الحالي:',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  '${widget.wallet.balance} ${widget.wallet.currency}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Divider(),
                            SizedBox(height: 16.h),
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'مبلغ الشحن',
                                hintText: 'أدخل المبلغ المراد شحنه',
                                filled: true,
                                fillColor: AppColors.background(isDark),
                                prefixIcon: Icon(Icons.attach_money, color: AppColors.primary, size: 18.r),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                              ),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 12.sp,
                              ),
                              validator: (v) {
                                final amount = double.tryParse(v ?? '');
                                if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح';
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإجمالي:',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${amountCtrl.text.isNotEmpty ? amountCtrl.text : '0'} ${widget.wallet.currency}',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  
                  // العمود الأيمن: طرق الدفع والنماذج
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختر طريقة الشحن',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // طرق الدفع
                          Obx(() {
                            final isCardEnabled = _cardPaymentController.isEnabled.value;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.card(isDark),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.account_balance, color: AppColors.primary, size: 20.r),
                                    title: Text(
                                      'تحويل بنكي',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'تحويل مالي مع إثبات التحويل',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary(isDark),
                                      ),
                                    ),
                                    trailing: Radio(
                                      value: 'bank',
                                      groupValue: selectedPaymentMethod,
                                      onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()),
                                      activeColor: AppColors.primary,
                                    ),
                                    onTap: () => setState(() => selectedPaymentMethod = 'bank'),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                  
                                  if (isCardEnabled)
                                  ListTile(
                                    leading: Icon(Icons.credit_card, color: AppColors.primary, size: 20.r),
                                    title: Text(
                                      'بطاقة ائتمان',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'دفع آمن عبر البطاقة الائتمانية',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 11.sp,
                                        color: AppColors.textSecondary(isDark),
                                      ),
                                    ),
                                    trailing: Radio(
                                      value: 'card',
                                      groupValue: selectedPaymentMethod,
                                      onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()),
                                      activeColor: AppColors.primary,
                                    ),
                                    onTap: () => setState(() => selectedPaymentMethod = 'card'),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                  
                                  if (!isCardEnabled)
                                  ListTile(
                                    leading: Icon(Icons.credit_card_off, color: Colors.grey, size: 20.r),
                                    title: Text(
                                      'الدفع بالبطاقة غير متاح حالياً',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'يرجى استخدام التحويل البنكي للشحن',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 11.sp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 24.h),

                          // عرض القسم المناسب بناءً على طريقة الدفع المختارة
                          if (selectedPaymentMethod == 'card')
                            _buildCreditCardSection(isDark),

                          if (selectedPaymentMethod == 'bank')
                            _buildBankTransferSection(isDark),

                          SizedBox(height: 24.h),

                          // زر الدفع النهائي
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isFormValid && !isProcessing ? _processPayment : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid ? AppColors.primary : Colors.grey,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                elevation: 3,
                              ),
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.h,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'إتمام الشحن',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                            ),
                          ),
                          
                          if (!_isFormValid) ...[
                            SizedBox(height: 16.h),
                            Center(
                              child: Text(
                                'يرجى ملء جميع الحقول المطلوبة',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 12.sp,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}