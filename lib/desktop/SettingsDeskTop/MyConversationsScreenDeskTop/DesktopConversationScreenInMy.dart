import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/ChatController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/Message.dart';
import '../../../core/data/model/conversation.dart';

class DesktopConversationScreenInMy extends StatefulWidget {
  final Advertiser advertiser;
  final Ad? ad;
  
  const DesktopConversationScreenInMy({
    super.key,
    required this.advertiser,
    this.ad,
  });

  @override
  State<DesktopConversationScreenInMy> createState() => _DesktopConversationScreenInMyState();
}

class _DesktopConversationScreenInMyState extends State<DesktopConversationScreenInMy> {
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
        userId: _loadingController.currentUser?.id??0,
        partnerId: widget.ad?.userId ?? widget.advertiser.id,
        adId: widget.ad?.id,
        advertiserProfileId: widget.advertiser.id
      ).then((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _sendMessage() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null && _messageController.text.isNotEmpty) {
      _chatController.sendMessage(
        senderId: _loadingController.currentUser?.id??0,
        recipientId: widget.ad?.userId ?? widget.advertiser.id,
        adId: widget.ad?.id,
        advertiserProfileId: widget.advertiser.id,
        body: _messageController.text,
      ).then((success) {
        if (success) {
          _messageController.clear();
          _loadMessages();
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
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
      body: Column(
        children: [
          // شريط العنوان المخصص للحاسوب
          _buildDesktopAppBar(isDarkMode),
          
          // محتوى المحادثة
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // لوحة معلومات الإعلان (جانبية)
                _buildAdInfoPanel(isDarkMode, cardColor, textPrimary, textSecondary),
                
                // منطقة المحادثة الرئيسية
                Expanded(
                  child: _buildConversationArea(isDarkMode, cardColor, textPrimary, textSecondary, dividerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAppBar(bool isDarkMode) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.appBar(isDarkMode),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => Get.back(),
          ),
          Text(
            'المحادثة - ${widget.advertiser.name ?? 'معلن'}',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.onPrimary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdInfoPanel(bool isDarkMode, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(right: BorderSide(color: AppColors.border(isDarkMode), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الإعلان'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // تنبيه عند عدم وجود إعلان
          if (widget.ad == null)
            _buildNoAdNotice(cardColor, textPrimary),
          
          // معلومات الإعلان إذا كان موجوداً
          if (widget.ad != null) ...[
            if (widget.ad!.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.ad!.images[0],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.greyLight,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.greyLight,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            Text(
              widget.ad!.title,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            if (widget.ad!.price != null)
              Text(
                '${_formatPrice(widget.ad!.price!)} ${'ليرة سورية'.tr}',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 16),
          ],
          
          Text(
            'المعلن'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              // صورة المعلن المحسنة
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: widget.advertiser.logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: widget.advertiser.logo!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 24,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.advertiser.name ?? 'معلن'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getProtectedEmail(widget.advertiser.name ?? ''),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // تنبيه عدم وجود إعلان
  Widget _buildNoAdNotice(Color cardColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'هذه المحادثة تتم بدون أي إعلان ذي صلة بين المعلن والمتحدث'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: 14,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationArea(bool isDarkMode, Color cardColor, Color textPrimary, Color textSecondary, Color dividerColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(isDarkMode),
      ),
      child: Column(
        children: [
          // منطقة الرسائل
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }
              
              if (_chatController.messagesList.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد رسائل بعد'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                itemCount: _chatController.messagesList.length,
                itemBuilder: (context, index) {
                  final message = _chatController.messagesList[index];
                  return _buildMessageBubble(
                    message,
                    isDarkMode,
                    _loadingController.currentUser?.id == message.senderId,
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

  Widget _buildMessageBubble(Message message, bool isDarkMode, bool isCurrentUser) {
    final bgColor = isCurrentUser 
      ? AppColors.primary.withOpacity(0.9)
      : AppColors.card(isDarkMode);
    
    final textColor = isCurrentUser 
      ? Colors.white 
      : AppColors.textPrimary(isDarkMode);
    
    final timeColor = isCurrentUser 
      ? Colors.white.withOpacity(0.7)
      : AppColors.textSecondary(isDarkMode);
    
    final senderName = isCurrentUser 
      ? 'أنا'.tr 
      : widget.advertiser.name ?? 'معلن'.tr;
    
    final senderEmail = isCurrentUser 
      ? _getProtectedEmail(_loadingController.currentUser?.email ?? '')
      : _getProtectedEmail(widget.advertiser.name ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          child: Column(
            crossAxisAlignment: isCurrentUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
            children: [
              // معلومات المرسل
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.border(isDarkMode),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // صورة المرسل المصغرة
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: isCurrentUser
                        ? _buildUserAvatar()
                        : _buildAdvertiserAvatar(),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary(isDarkMode)
                          ),
                        ),
                        Text(
                          senderEmail,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 10,
                            color: AppColors.textSecondary(isDarkMode).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              
              // فقاعة الرسالة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 0),
                    bottomRight: Radius.circular(isCurrentUser ? 0 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                        fontSize: 14,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 10,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return const Icon(Icons.person, size: 16, color: Colors.blue);
  }

  Widget _buildAdvertiserAvatar() {
    return widget.advertiser.logo != null
      ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.advertiser.logo!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey),
            errorWidget: (context, url, error) => const Icon(Icons.person, size: 16),
          ),
        )
      : const Icon(Icons.business, size: 16, color: Colors.green);
  }

  Widget _buildMessageInput(bool isDarkMode, Color cardColor, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          
          IconButton(
            icon: Icon(Icons.insert_emoticon, 
              color: AppColors.textSecondary(isDarkMode)),
            onPressed: () {},
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.border(isDarkMode),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 14,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...'.tr,
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ));
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
    final period = hour < 12 ? 'ص'.tr : 'م'.tr;
    final formattedHour = hour > 12 ? hour - 12 : hour;
    
    return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}