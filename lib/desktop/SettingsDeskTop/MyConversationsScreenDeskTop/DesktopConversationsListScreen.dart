// DesktopConversationsListScreen.dart — واجهة قائمة المحادثات (ويب/حاسوب)
// • قائمة موحّدة مرتبة "الأحدث أولاً"
// • تحديث يدوي + سحب للتحديث
// • عناصر غنية + شارة غير مقروء + مؤشر مقروئية (✓✓) لآخر رسالة مني
// • واجهة منقسمة: القائمة يسار + تفاصيل يمين (Responsive)
// • عند اختيار محادثة ثم أخرى: تنظيف رسائل القديمة لضمان التحديث الفوري

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

class _DesktopConversationsListScreenState extends State<DesktopConversationsListScreen> {
  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  Conversation? _selectedConversation;

  static const _receiptGrey = Color(0xFF9AA0A6);
  Color get _readBlue {
    try {
      return AppColors.buttonAndLinksColor;
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser == null) return;
    _chatController.fetchConversations(userId: currentUser.id ?? 0, type: 'all');
  }

  String _formatTimeSmart(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(thatDay).inDays;

    if (diffDays == 0) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final formattedHour = (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } else if (diffDays == 1) {
      return 'أمس';
    } else if (dt.year == now.year) {
      return '${dt.day}/${dt.month}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _truncate(String? text, {int max = 34}) {
    final t = (text ?? '').trim();
    if (t.isEmpty || t.length <= max) return t;
    return '${t.substring(0, max - 3)}...';
  }

  bool _isRecent(DateTime dt) => DateTime.now().difference(dt) <= const Duration(hours: 24);

  Widget _conversationReadReceipt(Conversation c, int? currentUserId) {
    final last = c.lastMessage;
    if (last == null) return const SizedBox.shrink();
    final isMine = (currentUserId != null) && last.senderId == currentUserId;
    if (!isMine) return const SizedBox.shrink();
    final read = (c.unreadCount == 0);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Icon(
        Icons.done_all_rounded,
        size: 16,
        color: read ? _readBlue : _receiptGrey.withOpacity(0.85),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeController.isDarkMode.value;
    final bg = AppColors.background(isDark);
    final card = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final divider = AppColors.divider(isDark);
    final primary = AppColors.primary;

    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.appBar(isDark),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.arrow_back, color: AppColors.onPrimary), onPressed: () => Get.back()),
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
                IconButton(icon: Icon(Icons.refresh, color: AppColors.onPrimary), onPressed: _loadConversations, tooltip: 'تحديث'),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingConversations.value) {
                return Center(child: CircularProgressIndicator(color: primary));
              }

              final list = [..._chatController.conversationsList]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

              if (list.isEmpty) {
                return Center(
                  child: Text('لا توجد محادثات'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16, color: textSecondary)),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة المحادثات
                  Container(
                    width: 430,
                    decoration: BoxDecoration(color: card, border: Border(right: BorderSide(color: divider, width: 1))),
                    child: RefreshIndicator(
                      onRefresh: () async => _loadConversations(),
                      color: primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: divider, indent: 80, endIndent: 16),
                        itemBuilder: (context, index) {
                          final conversation = list[index];
                          return _buildConversationTile(
                            conversation: conversation,
                            isDark: isDark,
                            baseCard: card,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            divider: divider,
                            primary: primary,
                            isWide: isWide,
                          );
                        },
                      ),
                    ),
                  ),

                  // تفاصيل المحادثة
                  Expanded(
                    child: isWide
                        ? (_selectedConversation != null
                            ? DesktopConversationScreenInMy(
                                key: ValueKey('conv-${_selectedConversation!.advertiser.id}-${_selectedConversation!.ad?.id ?? 0}'),
                                advertiser: _selectedConversation!.advertiser,
                                ad: _selectedConversation?.ad,
                                idAdv: _selectedConversation!.advertiser.id,
                              )
                            : _emptyState(textSecondary))
                        : Container(color: bg),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: textSecondary.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text('اختر محادثة لعرضها', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildConversationTile({
    required Conversation conversation,
    required bool isDark,
    required Color baseCard,
    required Color textPrimary,
    required Color textSecondary,
    required Color divider,
    required Color primary,
    required bool isWide,
  }) {
    final currentUserId = _loadingController.currentUser?.id;
    final lastMsg = conversation.lastMessage;
    final hasUnread = (conversation.unreadCount > 0);

    final isSelected = (_selectedConversation != null) &&
        (_selectedConversation?.inquirer == conversation.inquirer) &&
        (_selectedConversation?.advertiser?.id == conversation.advertiser?.id) &&
        ((_selectedConversation?.ad?.id ?? 0) == (conversation.ad?.id ?? 0));

    final bg = isSelected
        ? primary.withOpacity(isDark ? 0.14 : 0.10)
        : (hasUnread
            ? primary.withOpacity(isDark ? 0.12 : 0.08)
            : (_isRecent(conversation.lastMessageAt)
                ? primary.withOpacity(isDark ? 0.08 : 0.05)
                : baseCard));

    final lastSnippet = lastMsg == null
        ? 'بدء محادثة جديدة'
        : (lastMsg.isVoice ? '[صوت]' : (lastMsg.body ?? ''));

    return InkWell(
      onTap: () {
        // تنظيف الرسائل القديمة لضمان تحديث التفاصيل فورًا
        _chatController.messagesList.clear();
        if (isWide) {
          setState(() => _selectedConversation = conversation);
        } else {
          Get.to(() => DesktopConversationScreenInMy(
                key: ValueKey('conv-${conversation.advertiser.id}-${conversation.ad?.id ?? 0}'),
                advertiser: conversation.advertiser,
                ad: conversation.ad,
                idAdv: conversation.advertiser.id,
              ));
        }
      },
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _advertiserAvatar(conversation.advertiser?.logo),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      conversation.advertiser?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ),
                  _conversationReadReceipt(conversation, currentUserId),
                  Text(_formatTimeSmart(conversation.lastMessageAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 12, color: textSecondary)),
                ]),
                const SizedBox(height: 4),

                if (conversation.ad != null) ...[
                  Text(
                    conversation.ad!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (lastMsg?.isVoice == true) ...[
                            Icon(Icons.mic, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              _truncate(lastSnippet),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 13,
                                color: hasUnread ? textPrimary : textSecondary,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
                        child: Text(conversation.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 18, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _advertiserAvatar(String? url) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.greyLight),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                errorWidget: (context, _, __) => Icon(Icons.person, color: AppColors.greyDark, size: 24),
              )
            : Icon(Icons.person, size: 24, color: AppColors.greyDark),
      ),
    );
  }
}
