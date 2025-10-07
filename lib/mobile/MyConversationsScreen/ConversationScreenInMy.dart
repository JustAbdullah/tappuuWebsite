import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_website/controllers/ChatController.dart';
import 'package:tappuu_website/core/constant/appcolors.dart';
import 'package:tappuu_website/core/constant/app_text_styles.dart';

import 'package:tappuu_website/controllers/LoadingController.dart';
import 'package:tappuu_website/controllers/ThemeController.dart';

import '../../core/data/model/Message.dart';
import '../../core/data/model/conversation.dart'; // تم الحفاظ على استيراد المودل الأصلي

class ConversationScreenInMy extends StatefulWidget {
  final Advertiser? advertiser;
  final Ad? ad;
  final int idAdv;
  
  const ConversationScreenInMy({
    super.key,
    required this.advertiser,
    this.ad,
    required this.idAdv,
  });

  @override
  State<ConversationScreenInMy> createState() => _ConversationScreenInMyState();
}

class _ConversationScreenInMyState extends State<ConversationScreenInMy> {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null) {
      _chatController.fetchMessages(
        userId: currentUser?.id??0,
        partnerId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
      ).then((_) {
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          });
        }
      });
    }
  }

  void _sendMessage() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null && _messageController.text.isNotEmpty) {
      _chatController.sendMessage(
        senderId: currentUser?.id??0,
        recipientId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
        body: _messageController.text,
      ).then((success) {
        if (success) {
          _messageController.clear();
          _loadMessages();
        }
      });
    }
  }

  String _getProtectedEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length < 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 3) {
      return '${username.substring(0, 1)}***@$domain';
    }
    
    final visibleStart = username.substring(0, 2);
    final visibleEnd = username.substring(username.length - 1);
    return '$visibleStart***$visibleEnd@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final cardColor = AppColors.card(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'المحادثة'.tr,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBar(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // بطاقة الإعلان المصغرة (تظهر فقط إذا كان الإعلان موجوداً)
          if (widget.ad != null && widget.advertiser != null)
            _buildAdMiniCard(cardColor, textPrimary, textSecondary),
          
          // تنبيه عند عدم وجود إعلان
          if (widget.ad == null || widget.advertiser == null)
            _buildNoAdNotice(cardColor, textPrimary),
          
          // قائمة الرسائل
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }
              
              return ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: EdgeInsets.only(bottom: 16.h),
                itemCount: _chatController.messagesList.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messagesList[index];
                  return _buildMessageBubble(
                    message,
                    isDarkMode,
                    _loadingController.currentUser?.id == message.senderId,
                    widget.advertiser,
                  );
                },
              );
            }),
          ),
          
          // حقل إرسال الرسالة
          _buildMessageInput(isDarkMode, cardColor, dividerColor),
        ],
      ),
    );
  }

  // تنبيه عدم وجود إعلان
  Widget _buildNoAdNotice(Color cardColor, Color textPrimary) {
    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'هذه المحادثة تتم بدون أي إعلان ذي صلة بين المعلن والمتحدث'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdMiniCard(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.ad!.images.isNotEmpty)
            Container(
              width: 70.w,
              height: 70.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  widget.ad!.images[0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.greyLight,
                      child: Icon(Icons.image, size: 30.sp),
                    );
                  },
                ),
              ),
            ),
          SizedBox(width: 16.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.advertiser!.name ?? 'معلن',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                
                Text(
                  widget.ad!.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                
                if (widget.ad!.price != null)
                  Text(
                    '${_formatPrice(widget.ad!.price!)}${" ليرة سورية".tr}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message, 
    bool isDarkMode, 
    bool iscurrentUser,
    Advertiser? advertiser,
  ) {
    final bgColor = iscurrentUser 
      ? AppColors.primary.withOpacity(0.9)
      : AppColors.card(isDarkMode);
    
    final textColor = iscurrentUser 
      ? Colors.white 
      : AppColors.textPrimary(isDarkMode);
    
    final timeColor = iscurrentUser 
      ? Colors.white.withOpacity(0.7)
      : AppColors.textSecondary(isDarkMode);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: iscurrentUser 
          ? CrossAxisAlignment.end 
          : CrossAxisAlignment.start,
        children: [
          // عرض معلومات المرسل
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              mainAxisAlignment: iscurrentUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.border(isDarkMode),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المرسل
                      Text(
                        iscurrentUser ? 'أنا' : advertiser?.name ?? 'مستخدم',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,

                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      
                      // البريد الإلكتروني (مختصر)
                      Text(
                        _getProtectedEmail(
                          iscurrentUser 
                            ? (_loadingController.currentUser?.email ?? '')
                            : (advertiser?.name ?? '')
                        ),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                         fontSize: AppTextStyles.small,
                          color: AppColors.textSecondary(isDarkMode).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // فقاعة الرسالة
          Container(
            constraints: BoxConstraints(maxWidth: 280.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(iscurrentUser ? 16.r : 0),
                topRight: Radius.circular(iscurrentUser ? 0 : 16.r),
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.body.toString(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    color: textColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                   fontSize: AppTextStyles.small,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDarkMode, Color cardColor, Color dividerColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: dividerColor, width: 1))),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, 
              color: AppColors.textSecondary(isDarkMode)),
            onPressed: () {},
            ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.border(isDarkMode),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...'.tr,
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              padding: EdgeInsets.all(10.r),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} ${'مليون'.tr}';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ${'ألف'.tr}';
    }
    return price.toStringAsFixed(0);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? 'ص' : 'م';
    final formattedHour = hour > 12 ? hour - 12 : hour;
    
    return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}