import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/ChatController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/conversation.dart';
import 'DesktopConversationScreenInMy.dart';

class DesktopConversationsListScreen extends StatefulWidget {
  const DesktopConversationsListScreen({super.key});

  @override
  State<DesktopConversationsListScreen> createState() => _DesktopConversationsListScreenState();
}

class _DesktopConversationsListScreenState extends State<DesktopConversationsListScreen>
    with SingleTickerProviderStateMixin {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  Conversation? _selectedConversation;

  late TabController _tabController;
  // خرائط نوع التاب إلى باراميتر الـ API
  final Map<int, String> _tabType = {
    0: 'incoming', // عرض رسائل المستخدمين لي (حد تواصل معي)
    1: 'outgoing', // عرض رسائلي للمعلنين (أنا بادي)
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // جلب أول صفحة (تاب افتراضي 0 -> incoming)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return; // نتجنب النداء أثناء التحويل الداخلي
    _loadConversations();
    setState(() {
      _selectedConversation = null; // إعادة تعيين المحادثة المحددة عند تغيير التبويب
    });
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser != null) {
      final type = _tabType[_tabController.index] ?? 'all';
      _chatController.fetchConversations(userId: currentUser?.id??0, type: type);
    }
  }

  // تنسيق الوقت (/م)
  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour < 12 ? 'ص' : 'م';
    final formattedHour = (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _truncateText(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // شريط العنوان المخصص للحاسوب
          Container(
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
                  'المحادثات'.tr,
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.onPrimary),
                  onPressed: _loadConversations,
                ),
              ],
            ),
          ),
          
          // تبويبات المحادثات
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.appBar(isDarkMode),
              border: Border(bottom: BorderSide(color: dividerColor, width: 1.0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.onPrimary,
              unselectedLabelColor: AppColors.onPrimary.withOpacity(0.8),
              tabs: [
                Tab(
                  child: Text(
                    'عرض رسائل المستخدمين لي',
                    style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.appFontFamily),
                  ),
                ),
                Tab(
                  child: Text(
                    'عرض رسائلي للمعلنين',
                    style: TextStyle(fontSize: 13, fontFamily: AppTextStyles.appFontFamily),
                  ),
                ),
              ],
            ),
          ),
          
          // محتوى المحادثات
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingConversations.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (_chatController.conversationsList.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد محادثات'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة المحادثات
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border(right: BorderSide(color: dividerColor, width: 1.0)),
                    ),
                    child: Column(
                      children: [
                        // قائمة المحادثات
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: _chatController.conversationsList.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: dividerColor,
                              indent: 80,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final conversation = _chatController.conversationsList[index];
                              return _buildConversationItem(
                                conversation,
                                isDarkMode,
                                cardColor,
                                textPrimary,
                                textSecondary,
                                primaryColor,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // منطقة تفاصيل المحادثة
                  Expanded(
                    child: _selectedConversation != null
                      ? DesktopConversationScreenInMy(
                          advertiser: _selectedConversation!.advertiser,
                          ad: _selectedConversation?.ad,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat, size: 60, color: textSecondary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'اختر محادثة لعرضها'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 18,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
    Conversation conversation,
    bool isDarkMode,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
  ) {
    final isSelected = _selectedConversation?.inquirer == conversation.inquirer;
    final bgColor = isSelected 
      ? primaryColor.withOpacity(0.1) 
      : cardColor;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedConversation = conversation;
        });
      },
      onLongPress: () {
        // إجراءات إضافية مثل حذف المحادثة
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: bgColor,
        child: Row(
          children: [
            // صورة المعلن
            _buildAdvertiserAvatar(conversation.advertiser.logo),
            const SizedBox(width: 16),
            
            // محتوى المحادثة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم المعلن والوقت
                  Row(
                    children: [
                      SizedBox(
                        width: 180,
                        child: Text(
                          conversation.advertiser.name,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // عنوان الإعلان
                  if (conversation.ad != null) ...[
                    Text(
                      conversation.ad!.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // آخر رسالة
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage != null
                              ? _truncateText(conversation.lastMessage!.body ?? '')
                              : 'بدء محادثة جديدة'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style:  TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 18, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvertiserAvatar(String? logoUrl) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.greyLight,
      ),
      child: ClipOval(
        child: logoUrl != null && logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  color: AppColors.greyDark,
                  size: 24,
                ),
              )
            : Icon(
                Icons.person,
                size: 24,
                color: AppColors.greyDark,
              ),
      ),
    );
  }
}