// DesktopConversationsListScreen.dart — واجهة قائمة المحادثات (ويب/حاسوب)
// تصميم موحد مع تطبيق الهاتف:
// • صورة الإعلان مربعة في اليمين
// • اسم المعلن (فرد أو عضو داخل شركة) + نوعه (شركة/فردي)
// • عنوان الإعلان بخط غامق عند وجود رسائل غير مقروءة
// • تاريخ الإعلان في الأسفل
// • شارة دائرة صغيرة لعدم المقروئية + مؤشر مقروئية (✓✓) لآخر رسالة مني
// • واجهة منقسمة: القائمة يسار + تفاصيل يمين (Responsive)

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
  State<DesktopConversationsListScreen> createState() =>
      _DesktopConversationsListScreenState();
}

class _DesktopConversationsListScreenState
    extends State<DesktopConversationsListScreen> {
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

  // حجم صورة الإعلان (مربع)
  static const double _thumbSize = 80.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  void _loadConversations() {
    final currentUser = _loadingController.currentUser;
    if (currentUser == null) return;
    _chatController.fetchConversations(
      userId: currentUser.id ?? 0,
      type: 'all',
    );
  }

  // تنسيق ذكي للوقت (ما زال ممكن استخدامه إن احتجناه)
  String _formatTimeSmart(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(thatDay).inDays;

    if (diffDays == 0) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final formattedHour =
          (hour == 0) ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${formattedHour.toString().padLeft(2, '0')}:$minute $period';
    } else if (diffDays == 1) {
      return 'أمس';
    } else if (dt.year == now.year) {
      return '${dt.day}/${dt.month}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  // تنسيق تاريخ بسيط dd/MM/yyyy لتاريخ الإعلان
  String _formatAdDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  String _truncate(String? text, {int max = 34}) {
    final t = (text ?? '').trim();
    if (t.isEmpty || t.length <= max) return t;
    return '${t.substring(0, max - 3)}...';
  }

  bool _isRecent(DateTime dt) =>
      DateTime.now().difference(dt) <= const Duration(hours: 24);

  // ================== Helpers خاصة بتصميم الموبايل (منسوخة ومعدلة للويب) ==================

  // محاولة جلب صورة للإعلان
  String? _resolveAdImageUrl(dynamic ad) {
    if (ad == null) return null;
    try {
      final imgs = (ad.images as List?)?.cast();
      if (imgs != null && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is String && first.isNotEmpty) return first;
        if (first is Map &&
            (first['url'] is String) &&
            first['url'].toString().isNotEmpty) {
          return first['url'].toString();
        }
      }
    } catch (_) {}
    try {
      final url = (ad as dynamic).imageUrl;
      if (url is String && url.isNotEmpty) return url;
    } catch (_) {}
    return null;
  }

  // تاريخ الإعلان (createdAt) أو fallback لآخر رسالة
  DateTime _resolveAdDate(Conversation c) {
    try {
      final ad = c.ad;
      if (ad != null) {
        final dynamic createdAt = (ad as dynamic).createdAt;
        if (createdAt is DateTime) return createdAt;
        if (createdAt is String) {
          final parsed = DateTime.tryParse(createdAt);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {}
    return c.lastMessageAt;
  }

  /// اسم المعلن (اسم البروفايل نفسه: فرد أو شركة) مع fallback على المستعلم (inquirer)
  String _resolveAdvertiserMainName(Conversation c) {
    final adv = c.advertiser;
    if (adv != null) {
      try {
        final name = ((adv as dynamic).name ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      } catch (_) {}
    }

    try {
      final inqName = (c.inquirer.name ?? '').toString().trim();
      if (inqName.isNotEmpty) return inqName;
    } catch (_) {}

    try {
      final email = c.inquirer.email ?? '';
      if (email.isNotEmpty) return email;
    } catch (_) {}

    return '';
  }

  /// نوع المعلن (شركة / فردي) إن توفر
  String? _resolveAdvertiserTypeLabel(Conversation c) {
    final adv = c.advertiser;
    if (adv == null) return null;
    try {
      final t =
          ((adv as dynamic).accountType ?? '').toString().toLowerCase().trim();
      if (t == 'company') return 'شركة';
      if (t == 'individual') return 'فردي';
    } catch (_) {}
    return null;
  }

  bool _isCompany(Conversation c) {
    final adv = c.advertiser;
    if (adv == null) return false;
    try {
      final t =
          ((adv as dynamic).accountType ?? '').toString().toLowerCase().trim();
      return t == 'company';
    } catch (_) {
      return false;
    }
  }

  /// اسم الفرد داخل الشركة (CompanyMember.displayName) إن وجد
  String _resolveCompanyMemberName(Conversation c) {
    final ad = c.ad;
    if (ad == null) return '';
    try {
      final cm = (ad as dynamic).companyMember;
      final name = (cm?.displayName ?? '').toString().trim();
      return name;
    } catch (_) {
      return '';
    }
  }

  // مؤشر ✓✓ لآخر رسالة مني
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                  tooltip: 'تحديث',
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingConversations.value) {
                return Center(
                  child: CircularProgressIndicator(color: primary),
                );
              }

              final list = [..._chatController.conversationsList]
                ..sort(
                  (a, b) => b.lastMessageAt.compareTo(a.lastMessageAt),
                );

              if (list.isEmpty) {
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
                    width: 430,
                    decoration: BoxDecoration(
                      color: card,
                      border: Border(
                        right: BorderSide(color: divider, width: 1),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async => _loadConversations(),
                      color: primary,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.only(top: 8, bottom: 12),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: divider,
                          indent: 80,
                          endIndent: 16,
                        ),
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
                                key: ValueKey(
                                  'conv-${_selectedConversation!.advertiser.id}-${_selectedConversation!.ad?.id ?? 0}',
                                ),
                                advertiser: _selectedConversation!.advertiser,
                                ad: _selectedConversation?.ad,
                                idAdv: _selectedConversation!
                                    .advertiser.id,
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
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: textSecondary.withOpacity(0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'اختر محادثة لعرضها',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 18,
              color: textSecondary,
            ),
          ),
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
    final hasUnread = (conversation.unreadCount > 0);

    final isSelected = (_selectedConversation != null) &&
        (_selectedConversation?.inquirer == conversation.inquirer) &&
        (_selectedConversation?.advertiser?.id ==
            conversation.advertiser?.id) &&
        ((_selectedConversation?.ad?.id ?? 0) ==
            (conversation.ad?.id ?? 0));

    final bg = isSelected
        ? primary.withOpacity(isDark ? 0.14 : 0.10)
        : (hasUnread
            ? primary.withOpacity(isDark ? 0.12 : 0.08)
            : (_isRecent(conversation.lastMessageAt)
                ? primary.withOpacity(isDark ? 0.08 : 0.05)
                : baseCard));

    // صورة الإعلان
    final adThumbUrl = _resolveAdImageUrl(conversation.ad);

    // هل شركة؟
    final isCompany = _isCompany(conversation);

    // اسم المعلن (بروفايل رئيسي)
    final rawAdvertiserName = _resolveAdvertiserMainName(conversation);

    // اسم الفرد داخل الشركة إن وجد
    final memberName = _resolveCompanyMemberName(conversation);

    // نوع المعلن (شركة / فردي)
    final advertiserType = _resolveAdvertiserTypeLabel(conversation);

    // الاسم الذي سيُعرض في السطر الأول
    String mainName = rawAdvertiserName;

    // سطر ثانوي لاسم الشركة إذا كان شركة
    String? companyNameSubline;

    if (isCompany) {
      if (memberName.isNotEmpty) {
        // نعرض اسم الفرد داخل الشركة كسطر رئيسي
        mainName = memberName;
        // واسم الشركة تحت لو موجود
        if (rawAdvertiserName.isNotEmpty) {
          companyNameSubline = rawAdvertiserName;
        }
      } else {
        mainName = rawAdvertiserName;
      }
    }

    if (mainName.trim().isEmpty) {
      // احتياط إضافي لو فشل كل شيء
      mainName = rawAdvertiserName;
    }

    // عنوان الإعلان
    final adTitle = conversation.ad?.title ?? '';

    // تاريخ الإعلان
    final adDate = _resolveAdDate(conversation);

    return InkWell(
      onTap: () {
        _chatController.messagesList.clear();
        if (isWide) {
          setState(() => _selectedConversation = conversation);
        } else {
          Get.to(
            () => DesktopConversationScreenInMy(
              key: ValueKey(
                'conv-${conversation.advertiser.id}-${conversation.ad?.id ?? 0}',
              ),
              advertiser: conversation.advertiser,
              ad: conversation.ad,
              idAdv: conversation.advertiser.id,
            ),
          );
        }
      },
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          // نفس منطق الموبايل: الصورة في اليمين، النص في اليسار
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAdThumbSquare(adThumbUrl),
            const SizedBox(width: 12),
            // النصوص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السطر الأول: اسم المعلن (أو العضو داخل الشركة) + نوعه
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          mainName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (advertiserType != null &&
                          advertiserType.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCompany
                                ? Colors.orange.withOpacity(0.12)
                                : Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            advertiserType,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.small,
                              color:
                                  isCompany ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // لو شركة وعندنا اسم شركة نعرضه كسطر ثانوي
                  if (isCompany && companyNameSubline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        companyNameSubline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // عنوان الإعلان
                  Text(
                    _truncate(adTitle, max: 80),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      fontWeight: hasUnread
                          ? FontWeight.w800
                          : FontWeight.w400,
                      color: hasUnread ? textPrimary : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // التاريخ + مؤشر المقروئية
                  Row(
                    children: [
                      _conversationReadReceipt(
                          conversation, currentUserId),
                      Text(
                        _formatAdDate(adDate),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: _receiptGrey
                              .withOpacity(isDark ? 0.9 : 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // دائرة unread + سهم، مثل الموبايل
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUnread)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // صورة إعلان مربّعة كاملة في اليمين (نفس منطق الهاتف تقريباً)
  Widget _buildAdThumbSquare(String? url) {
    return Container(
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(0),
      ),
      clipBehavior: Clip.hardEdge,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, _) =>
                  const _AdThumbPlaceholder(isLoading: true),
              errorWidget: (context, _, __) =>
                  const _AdThumbPlaceholder(),
            )
          : const _AdThumbPlaceholder(),
    );
  }
}

class _AdThumbPlaceholder extends StatelessWidget {
  final bool isLoading;
  const _AdThumbPlaceholder({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        isLoading ? Icons.downloading_rounded : Icons.image_outlined,
        size: 22,
        color: Colors.grey.shade500,
      ),
    );
  }
}
