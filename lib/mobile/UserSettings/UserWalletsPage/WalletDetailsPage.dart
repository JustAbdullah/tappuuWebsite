import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Import your controllers
import '../../../controllers/BankAccountController.dart';
import '../../../controllers/CardPaymentController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/TransferProofController.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import '../../../core/data/model/BankAccountModel.dart';

class WalletDetailsPage extends StatefulWidget {
  final UserWallet wallet;
  const WalletDetailsPage({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletDetailsPage> createState() => _WalletDetailsPageWebState();
}

class _WalletDetailsPageWebState extends State<WalletDetailsPage> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.find<UserWalletController>();
  final BankAccountController bankAccountController = Get.put(BankAccountController());
  final TransferProofController _transferProofController = Get.put(TransferProofController());
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController());

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
  File? transferProofImage;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    bankAccountController.fetchAccounts();
    selectedPaymentMethod = initialPaymentMethod;
    
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
          transferProofImage != null;
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        transferProofImage = File(image.path);
        _updateButtonState();
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ'.tr,
      'تم نسخ رقم الحساب إلى الحافظة'.tr,
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

      if (transferProofImage == null) {
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
        final TransferProofController proofController = Get.find<TransferProofController>();
        
        final bool success = await proofController.createProof(
          bankAccountId: selectedBankAccount!.id,
          walletId: int.parse(widget.wallet.id.toString()),
          amount: amount,
          sourceAccountNumber: userAccountNumberCtrl.text,
          proofFile: transferProofImage,
        );

        setState(() => isProcessing = false);

        if (success) {
          await Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'تم إرسال إثبات التحويل بنجاح'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 24.sp,
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
                    'عزيزي المستخدم'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'لقد تم إرسال إثبات عملية التحويل بنجاح. سيتم التحقق منها وإبلاغك في النتيجة خلال 24 ساعة.'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16.sp,
                      color: AppColors.textSecondary(themeController.isDarkMode.value),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'رقم العملية: ${DateTime.now().millisecondsSinceEpoch}'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 14.sp,
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
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                    ),
                    child: Text(
                      'موافق'.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.only(bottom: 20.h),
            ),
            barrierDismissible: false,
          );
        } else {
          Get.snackbar(
            'خطأ', 
            'فشل في إرسال إثبات التحويل. يرجى المحاولة مرة أخرى.'.tr,
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
        'حدث خطأ غير متوقع: $e'.tr,
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
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 24.r),
                    SizedBox(width: 12.w),
                    Text(
                      'تعليمات التحويل البنكي'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'قم بتحويل مالي من خلال اختيار اسم البنك المتوفر مع إثبات دليل التحويل. سيتم التحقق من عملية التحويل ثم شحن المحفظة. ملاحظة: تأكد من المبلغ ورقم حسابك واختيار صورة الدليل بشكل واضح.'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 16.sp,
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          Text(
            'اختر الحساب البنكي للتحويل'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600, 
              color: AppColors.textSecondary(themeController.isDarkMode.value),
            ),
          ),
          SizedBox(height: 12.h),
          
          Obx(() {
            if (bankAccountController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: DropdownButton<BankAccountModel>(
                value: selectedBankAccount,
                isExpanded: true,
                underline: SizedBox(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                hint: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text('اختر الحساب البنكي'.tr, style: TextStyle(fontSize: 16.sp)),
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          account.accountNumber,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 14.sp,
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
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رقم الحساب للتحويل:'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(selectedBankAccount!.accountNumber),
                        icon: Icon(Icons.copy, color: Colors.green, size: 24.r),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    selectedBankAccount!.accountNumber,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${selectedBankAccount!.bankName}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16.sp,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 20.h),
          
          TextFormField(
            controller: userAccountNumberCtrl,
            decoration: InputDecoration(
              labelText: 'رقم حسابك للمرجع'.tr,
              hintText: 'أدخل رقم حسابك الذي ستقوم بالتحويل منه',
              filled: true,
              fillColor: AppColors.card(isDark),
              prefixIcon: Icon(Icons.account_balance, color: AppColors.primary, size: 24.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              labelStyle: TextStyle(fontSize: 16.sp),
              hintStyle: TextStyle(fontSize: 16.sp),
            ),
            style: TextStyle(fontSize: 16.sp),
            validator: selectedPaymentMethod == 'bank' ? (v) {
              if (v == null || v.isEmpty) return 'الرجاء إدخال رقم حسابك'.tr;
              return null;
            } : null,
          ),
          
          SizedBox(height: 20.h),
          
          Text(
            'إثبات التحويل'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          
          // تصميم ويب محسّن لرفع الصور
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: transferProofImage == null ? Colors.grey : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: transferProofImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 48.r, color: Colors.grey),
                              SizedBox(height: 16.h),
                              Text('انقر لرفع صورة إثبات التحويل'.tr,
                                  style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                              SizedBox(height: 8.h),
                              Text(
                                'يمكنك سحب وإفلات الصورة هنا أو النقر للاختيار'.tr,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.file(
                                  transferProofImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 12.h,
                                right: 12.w,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Icon(Icons.check_circle, color: Colors.white, size: 24.r),
                                ),
                              ),
                              Positioned(
                                bottom: 12.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'إثبات التحويل'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
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
                
                if (transferProofImage != null) ...[
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.edit, size: 18.r),
                        label: Text('تغيير الصورة'.tr, style: TextStyle(fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            transferProofImage = null;
                            _updateButtonState();
                          });
                        },
                        icon: Icon(Icons.delete, size: 18.r, color: Colors.red),
                        label: Text('حذف'.tr, style: TextStyle(fontSize: 14.sp, color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 24.r),
                    SizedBox(width: 12.w),
                    Text(
                      'الدفع الآمن بالبطاقة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 16.sp,
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          TextFormField(
            controller: cardNumberCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onCardNumberChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
            decoration: InputDecoration(
              labelText: 'رقم البطاقة'.tr, 
              hintText: 'xxxx xxxx xxxx xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.credit_card, color: AppColors.primary, size: 24.r), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              labelStyle: TextStyle(fontSize: 16.sp),
              hintStyle: TextStyle(fontSize: 16.sp),
            ),
            style: TextStyle(fontSize: 16.sp),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة'.tr;
              if (digits.length < 12) return 'رقم البطاقة غير صحيح'.tr;
              return null;
            },
          ),
          SizedBox(height: 20.h),
          
          TextFormField(
            controller: nameCtrl, 
            keyboardType: TextInputType.name, 
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة'.tr, 
              hintText: 'xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary, size: 24.r), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              labelStyle: TextStyle(fontSize: 16.sp),
              hintStyle: TextStyle(fontSize: 16.sp),
            ), 
            style: TextStyle(fontSize: 16.sp),
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null
          ),
          SizedBox(height: 20.h),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'انتهاء الصلاحية (MMYY)'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    labelStyle: TextStyle(fontSize: 16.sp),
                  ), 
                  style: TextStyle(fontSize: 16.sp),
                  validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null
                ),
              ),
              SizedBox(width: 20.w),
              SizedBox(
                width: 150.w, 
                child: TextFormField(
                  controller: cvvCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'CVV'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    labelStyle: TextStyle(fontSize: 16.sp),
                  ), 
                  style: TextStyle(fontSize: 16.sp),
                  obscureText: true, 
                  validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null
                ),
              ),
            ]
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text('شحن المحفظة'.tr, 
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 24.sp,
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold
          )),
        leading: IconButton(
          onPressed: () => Get.back(), 
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 28.r)
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                // Order summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                    Center(
                      child: Text(
                        'ملخص عملية الشحن'.tr, 
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily, 
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800
                        )
                      )
                    ),
                    SizedBox(height: 20.h),
                    Divider(),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                      Text('المحفظة:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark), fontSize: 16.sp)),
                      Text(widget.wallet.uuid, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: 16.sp,)),
                    ]),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                      Text('الرصيد الحالي:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark), fontSize: 16.sp)),
                      Text('${widget.wallet.balance} ${widget.wallet.currency}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: 16.sp)),
                    ]),
                    SizedBox(height: 16.h),
                    Divider(),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'مبلغ الشحن'.tr,
                        hintText: 'أدخل المبلغ المراد شحنه',
                        filled: true,
                        fillColor: AppColors.background(isDark),
                        prefixIcon: Icon(Icons.attach_money, color: AppColors.primary, size: 24.r),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                        labelStyle: TextStyle(fontSize: 16.sp),
                        hintStyle: TextStyle(fontSize: 16.sp),
                      ),
                      style: TextStyle(fontSize: 16.sp),
                      validator: (v) {
                        final amount = double.tryParse(v ?? '');
                        if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح'.tr;
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                      Text('الإجمالي:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 18.sp, fontWeight: FontWeight.w800)),
                      Text('${amountCtrl.text.isNotEmpty ? amountCtrl.text : '0'} ${widget.wallet.currency}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ]),
                  ]),
                ),
                SizedBox(height: 32.h),

                // Payment methods
                Text('اختر طريقة الشحن'.tr, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, fontFamily: AppTextStyles.appFontFamily)),
                SizedBox(height: 20.h),

                Obx(() {
                  final isCardEnabled = _cardPaymentController.isEnabled.value;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.card(isDark), 
                      borderRadius: BorderRadius.circular(20.r)
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.account_balance, color: AppColors.primary, size: 28.r),
                          title: Text('تحويل بنكي'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 18.sp)),
                          trailing: Radio(
                            value: 'bank', 
                            groupValue: selectedPaymentMethod, 
                            onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                            activeColor: AppColors.primary
                          ),
                          onTap: () => setState(() => selectedPaymentMethod = 'bank'),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        ),
                        
                        if (isCardEnabled) 
                        ListTile(
                          leading: Icon(Icons.credit_card, color: AppColors.primary, size: 28.r),
                          title: Text('بطاقة ائتمان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 18.sp)),
                          trailing: Radio(
                            value: 'card', 
                            groupValue: selectedPaymentMethod, 
                            onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                            activeColor: AppColors.primary
                          ),
                          onTap: () => setState(() => selectedPaymentMethod = 'card'),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        ),
                        
                        if (!isCardEnabled) 
                        ListTile(
                          leading: Icon(Icons.credit_card_off, color: Colors.grey, size: 28.r),
                          title: Text(
                            'الدفع بالبطاقة غير متاح حالياً'.tr, 
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily, 
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              fontSize: 16.sp,
                            )
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 32.h),

                // Show appropriate form based on selection
                if (selectedPaymentMethod == 'card') 
                  _buildCreditCardSection(isDark),

                if (selectedPaymentMethod == 'bank') 
                  _buildBankTransferSection(isDark),

                // Payment button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid && !isProcessing ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid ? AppColors.primary : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 20.h), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r))
                    ),
                    child: isProcessing 
                        ? SizedBox(
                            height: 24.h, 
                            width: 24.h, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          ) 
                        : Text(
                            'إتمام الشحن'.tr, 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w900, 
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 18.sp
                            )
                          ),
                  ),
                ),
                
                if (!_isFormValid) ...[
                  SizedBox(height: 20.h),
                  Center(
                    child: Text(
                      'يرجى ملء جميع الحقول المطلوبة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 16.sp,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}