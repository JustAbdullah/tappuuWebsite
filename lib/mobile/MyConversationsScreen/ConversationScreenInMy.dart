import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/ChatController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/Message.dart';
import '../../core/data/model/conversation.dart';
import '../HomeScreen/menubar.dart';

// ======== نماذج مساعدة لسياق الاتصال ========
enum ContactMode { individual, companyOnly, companyWithMember }

class ContactContext {
  final ContactMode mode;
  final String? companyName;
  final String? memberName;
  final String? personName;
  // الأرقام التي ستُعرض فعلياً للمستخدم
  final String? primaryTel;
  final String? primaryWaChat;
  final String? primaryWaCall;

  ContactContext({
    required this.mode,
    this.companyName,
    this.memberName,
    this.personName,
    this.primaryTel,
    this.primaryWaChat,
    this.primaryWaCall,
  });
}

// helper صغير بدل firstWhereOrNull لتفادي أي اعتماديات إضافية
T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final x in items) {
    if (test(x)) return x;
  }
  return null;
}

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ChatController _chatController = Get.put(ChatController());
  final LoadingController _loadingController = Get.find<LoadingController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingMessageId;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  final Map<int, Duration> _messageDurations = {};
  final FocusNode _messageFocusNode = FocusNode();

  static const _receiptGrey = Color(0xFF9AA0A6);

  bool _autoStickToBottom = true;
  late Worker _messagesWorker;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final nearBottom = _isNearBottom();
      if (nearBottom && !_autoStickToBottom) {
        _autoStickToBottom = true;
      } else if (!nearBottom && _autoStickToBottom) {
        _autoStickToBottom = false;
      }
    });

    _messagesWorker = ever<List<Message>>(
      _chatController.messagesList,
      (_) {
        if (!mounted) return;
        if (_autoStickToBottom) _scrollToBottom();
      },
    );

    _loadMessages();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingMessageId = null;
        _currentPosition = Duration.zero;
      });
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _currentPosition = p);
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _currentDuration = d);
    });

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    try {
      _messagesWorker.dispose();
      _audioPlayer.dispose();
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _messageFocusNode.dispose();
    super.dispose();
  }
  bool _isNearBottom({double threshold = 200}) {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    return (max - cur) <= threshold;
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!mounted) return;
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(immediate: immediate));
      return;
    }
    final target = _scrollController.position.maxScrollExtent + 80;
    if (immediate) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _loadMessages() {
    final user = _loadingController.currentUser;
    if (user != null) {
      _chatController
          .fetchMessages(
        userId: user.id ?? 0,
        partnerId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
      )
          .then((_) async {
        if (!mounted) return;
        await _autoMarkIncomingAsRead();

        if (!_didInitialScroll) {
          _didInitialScroll = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(immediate: true));
        } else {
          _scrollToBottom();
        }
      });
    }
  }

  Future<void> _autoMarkIncomingAsRead() async {
    final user = _loadingController.currentUser;
    if (user == null) return;

    for (final m in _chatController.messagesList) {
      final isIncoming = m.recipientId == user.id;
      if (isIncoming && m.isRead == false) {
        final ok = await _chatController.markAsRead(m.id);
        if (ok) {
          final idx = _chatController.messagesList.indexWhere((x) => x.id == m.id);
          if (idx >= 0) {
            final old = _chatController.messagesList[idx];
            _chatController.messagesList[idx] = Message(
              id: old.id,
              senderId: old.senderId,
              senderEmail: old.senderEmail,
              recipientId: old.recipientId,
              recipientEmail: old.recipientEmail,
              body: old.body,
              isVoice: old.isVoice,
              voiceUrl: old.voiceUrl,
              isRead: true,
              createdAt: old.createdAt,
              readAt: DateTime.now(),
              updatedAt: old.updatedAt,
              adId: old.adId,
              adNumber: old.adNumber,
              adTitleAr: old.adTitleAr,
              adTitleEn: old.adTitleEn,
              adSlug: old.adSlug,
              adDescriptionAr: old.adDescriptionAr,
              adDescriptionEn: old.adDescriptionEn,
              adPrice: old.adPrice,
              adShowTime: old.adShowTime,
              adCreatedAt: old.adCreatedAt,
              adImages: old.adImages,
              advertiserProfileId: old.advertiserProfileId,
              advertiserUserId: old.advertiserUserId,
              advertiserName: old.advertiserName,
              advertiserLogo: old.advertiserLogo,
              advertiserDescription: old.advertiserDescription,
              advertiserContactPhone: old.advertiserContactPhone,
              advertiserWhatsappPhone: old.advertiserWhatsappPhone,
              advertiserWhatsappCallNumber: old.advertiserWhatsappCallNumber,
              advertiserWhatsappUrl: old.advertiserWhatsappUrl,
              advertiserTelUrl: old.advertiserTelUrl,
              advertiserLatitude: old.advertiserLatitude,
              advertiserLongitude: old.advertiserLongitude,
            );
          }
        }
      }
    }
  }

  void _sendMessage() {
    final user = _loading_controller_user();
    if (user != null && _messageController.text.trim().isNotEmpty) {
      final text = _messageController.text.trim();
      _messageController.clear();

      _chatController
          .sendMessage(
        senderId: user.id ?? 0,
        recipientId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
        body: text,
      )
          .then((success) {
        if (success) {
          _loadMessages();
        } else {
          _messageController.text = text;
          Get.snackbar('خطأ', 'فشل إرسال الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
        }
      });
    }
  }

  // ========== نافذة: الميزة متاحة في تطبيقات الجوال فقط ==========
  Future<void> _showVoiceFeatureAppOnlyDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off_rounded, size: 48.w, color: Colors.redAccent),
              SizedBox(height: 12.h),
              Text(
                'الميزة غير متاحة هنا',
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,
                  fontFamily: AppTextStyles.appFontFamily,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'إرسال الرسائل الصوتية متاح في تطبيقات الجوال فقط حالياً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.grey,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('حسناً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تشغيل/إيقاف تشغيل رسائل الصوت (قراءة فقط)
  Future<void> _playPauseVoice(Message message) async {
    final url = message.voiceUrl;
    if (url == null || url.isEmpty) return;

    if (_playingMessageId == message.id) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _playingMessageId = null);
    } else {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        if (!mounted) return;
        setState(() => _playingMessageId = message.id);
      } catch (e) {
        Get.snackbar('خطأ', 'لا يمكن تشغيل الصوت', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _ensureMessageDuration(Message message) async {
    if (_messageDurations.containsKey(message.id)) return;

    final player = AudioPlayer();
    try {
      if (message.voiceUrl == null || message.voiceUrl!.isEmpty) return;
      await player.setSourceUrl(message.voiceUrl!);

      final duration = await player.getDuration().timeout(const Duration(seconds: 10));
      if (duration != null && duration.inMilliseconds > 0) {
        _messageDurations[message.id] = duration;
        if (mounted) setState(() {});
      }
    } on TimeoutException {
      // ignore
    } catch (e) {
      // ignore
    } finally {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _confirmAndDeleteMessage(Message message) async {
    final user = _loading_controller_user();
    if (user == null) return;

    final isMine = message.senderId == (user.id);
    if (!isMine) {
      Get.snackbar('تنبيه', 'لا يمكنك حذف رسالة ليست لك', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final ok = await _chatController.deleteMessage(message.id);
    if (ok) {
      if (!mounted) return;
      setState(() {});
      Get.snackbar('تم', 'تم حذف الرسالة', backgroundColor: Colors.green, colorText: Colors.white);
      _scrollToBottom();
    } else {
      Get.snackbar('خطأ', 'فشل حذف الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // =========== تنسيق التاريخ / السعر ===========
  String _formatDateTimeFull(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$day/$month/$year  ${formattedHour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatPrice(num value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }

  // =======================
  // منطق تحديد جهة الاتصال المعروضة
  // =======================
  ContactContext _resolveContactContext() {
    final adv = widget.advertiser;
    CompanyMemberMessage? member;

    if (_chatController.messagesList.isNotEmpty) {
      member = _firstWhereOrNull<Message>(
        _chatController.messagesList,
        (m) => m.adCompanyMember != null,
      )?.adCompanyMember;
    }

    final accountType = adv?.accountType?.toLowerCase().trim();
    final isCompany = (accountType == 'company' || accountType == 'business' || member != null);

    if (isCompany && member != null) {
      return ContactContext(
        mode: ContactMode.companyWithMember,
        companyName: adv?.name,
        memberName: member.displayName,
        primaryTel: member.contactPhone,
        primaryWaChat: member.whatsappPhone,
        primaryWaCall: member.whatsappCallNumber,
      );
    }

    if (isCompany && member == null) {
      return ContactContext(
        mode: ContactMode.companyOnly,
        companyName: adv?.name,
        primaryTel: adv?.contactPhone,
        primaryWaChat: adv?.whatsappPhone,
        primaryWaCall: adv?.whatsappCallNumber,
      );
    }

    return ContactContext(
      mode: ContactMode.individual,
      personName: adv?.name,
      primaryTel: adv?.contactPhone,
      primaryWaChat: adv?.whatsappPhone,
      primaryWaCall: adv?.whatsappCallNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _theme_controller_value();
    final cardColor = AppColors.background(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);

    const whatsappLightGreen = Color(0xFFDCF8C6);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    final ctx = _resolveContactContext();
    final appBarSubtitlePhone = ctx.primaryTel?.isNotEmpty == true
        ? ctx.primaryTel
        : (ctx.primaryWaChat?.isNotEmpty == true ? ctx.primaryWaChat : '');

    return Scaffold(
      key: _scaffoldKey,
      drawer: Menubar(),
      backgroundColor: AppColors.background(isDarkMode),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildCustomAppBar(isDarkMode, ctx, appBarSubtitlePhone),
                if (widget.ad != null && widget.advertiser != null)
                  _buildAdMiniCard(cardColor, textPrimary, textSecondary)
                else
                  _buildNoAdNotice(cardColor, textPrimary),

                Expanded(
                  child: Obx(() {
                    if (_chat_controller_isLoading()) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    final serverMessages = _chatController.messagesList;

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(bottom: viewInsetsBottom + 160.h, top: 12.h),
                      itemCount: serverMessages.length,
                      itemBuilder: (context, idx) {
                        final message = serverMessages[idx];
                        final currentUser = _loading_controller_user();
                        final isCurrentUser = currentUser != null && (currentUser.id == message.senderId);

                        if (message.isVoice == true && (message.voiceUrl ?? '').isNotEmpty) {
                          _ensureMessageDuration(message);
                        }

                        return _buildMessageBubbleWithDelete(
                          message,
                          isDarkMode,
                          isCurrentUser,
                          widget.advertiser,
                          whatsappLightGreen,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),

            // شريط الإدخال العائم
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: viewInsetsBottom + 12.h,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // لا يوجد شريط تسجيل نهائياً
                    _buildFloatingInput(isDarkMode, cardColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCustomAppBar(bool isDarkMode, ContactContext ctx, String? subtitlePhone) {
    final adv = widget.advertiser;
    final titleText = () {
      switch (ctx.mode) {
        case ContactMode.individual:
          return adv?.name ?? 'معلن';
        case ContactMode.companyOnly:
        case ContactMode.companyWithMember:
          return adv?.name ?? 'شركة';
      }
    }();

    return Container(
      height: 60.h,
      color: AppColors.appBar(isDarkMode),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: () => Get.back(), child: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 22.w)),
            ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(onTap: () => _scaffoldKey.currentState?.openDrawer(), child: Icon(Icons.menu, color: AppColors.onPrimary, size: 22.w)),
            ),
            SizedBox(width: 12.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 200.w,
                child: Text(
                  titleText,
                  style: TextStyle(color: AppColors.onPrimary, fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitlePhone ?? '',
                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: AppColors.onPrimary.withOpacity(0.9), fontWeight: FontWeight.w600),
              ),
            ]),
          ]),
          Row(children: [
            if ((subtitlePhone ?? '').isNotEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                child: InkWell(
                  onTap: _openContactSideSheet,
                  child: Icon(Icons.phone, color: AppColors.onPrimary, size: 22.w),
                ),
              ),
            SizedBox(width: 2.w),
            Container(
              padding: EdgeInsets.all(4.w),
              child: InkWell(
                onTap: _openContactSideSheet,
                child: Icon(Icons.more_vert, color: AppColors.onPrimary, size: 22.w),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildFloatingInput(bool isDarkMode, Color cardColor) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(28.r),
      color: cardColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28.r), color: cardColor),
        child: Row(
          children: [
            // زر المايك: لا تسجيل — يعرض نافذة فقط
            GestureDetector(
              onTap: _showVoiceFeatureAppOnlyDialog,
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.buttonAndLinksColor,
                ),
                child: const Icon(Icons.mic_off, color: Colors.white),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Container(
                height: 48.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(color: AppColors.border(isDarkMode), borderRadius: BorderRadius.circular(20.r)),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      focusNode: _messageFocusNode,
                      controller: _messageController,
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, color: AppColors.textPrimary(isDarkMode)),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...'.tr,
                        hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      onTap: _scrollToBottom,
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(width: 8.w),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: AppColors.buttonAndLinksColor,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdMiniCard(Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 6.h),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(0.r)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.ad?.images.isNotEmpty == true)
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                widget.ad!.images[0],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppColors.greyLight, child: Icon(Icons.image, size: 30.sp)),
              ),
            ),
          ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.ad?.title ?? 'اعلان', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 24, 117, 232))),
            SizedBox(height: 6.h),
            if (widget.ad?.price != null)
              Text(
                '${_formatPrice(widget.ad!.price!)}${" ليرة سورية".tr}',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(_theme_controller_value()),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildNoAdNotice(Color cardColor, Color textPrimary) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12.r)),
      child: Row(children: [
        Icon(Icons.info_outline, color: AppColors.primary, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(child: Text('هذه المحادثة تتم بدون أي إعلان ذي صلة بين المعلن والمتحدث'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: textPrimary))),
      ]),
    );
  }

  Widget _buildMessageBubbleWithDelete(
    Message message,
    bool isDarkMode,
    bool isCurrentUser,
    Advertiser? advertiser,
    Color userBubbleColor,
  ) {
    final otherBubbleColor = AppColors.card(isDarkMode);
    final textColor = isCurrentUser ? Colors.black : AppColors.textPrimary(isDarkMode);
    final align = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    final isVoice = message.isVoice == true;
    final dur = (_messageDurations.containsKey(message.id)) ? _messageDurations[message.id]! : Duration.zero;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(crossAxisAlignment: align, children: [
        Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Row(
            mainAxisAlignment: mainAxis,
            children: [
              if (isCurrentUser)
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.background(_theme_controller_value()),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        title: Text('حذف الرسالة', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold, color: AppColors.textPrimary(_theme_controller_value())), textAlign: TextAlign.center),
                        content: Text('هل تريد حذف هذه الرسالة؟', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.textSecondary(_theme_controller_value())), textAlign: TextAlign.center),
                        actions: [
                          Row(children: [
                            Expanded(child: TextButton(onPressed: () => Navigator.of(context).pop(false), style: TextButton.styleFrom(backgroundColor: Colors.grey[300], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('لا', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: Colors.black87, fontWeight: FontWeight.bold)))),
                            SizedBox(width: 16.w),
                            Expanded(child: TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), padding: EdgeInsets.symmetric(vertical: 12.h)), child: Text('نعم', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: Colors.white, fontWeight: FontWeight.bold)))),
                          ]),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _confirmAndDeleteMessage(message);
                    }
                  },
                  child: Container(padding: EdgeInsets.all(6.r), child: Icon(Icons.more_vert, size: 18.sp, color: AppColors.textSecondary(isDarkMode))),
                ),
            ],
          ),
        ),
        Row(mainAxisAlignment: mainAxis, children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 300.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isCurrentUser ? userBubbleColor : otherBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCurrentUser ? 16.r : 6.r),
                  topRight: Radius.circular(isCurrentUser ? 6.r : 16.r),
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isVoice)
                  _buildVoiceBubbleContent(message, dur, isCurrentUser)
                else
                  Text(message.body ?? '', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, color: textColor, height: 1.4)),
                SizedBox(height: 6.h),
                Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  Text(_formatDateTimeFull(message.createdAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 10.sp, color: isCurrentUser ? Colors.black.withOpacity(0.6) : AppColors.textSecondary(isDarkMode))),
                  _readReceiptIcon(message, isCurrentUser, isDarkMode),
                ]),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildVoiceBubbleContent(Message message, Duration? cachedDuration, bool isCurrentUser) {
    final totalDur = cachedDuration ?? Duration.zero;
    final playing = _playingMessageId == message.id;
    final currentPos = playing ? _currentPosition : Duration.zero;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          onPressed: () => _playPauseVoice(message),
          icon: Icon(
            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 30.sp,
            color: isCurrentUser ? Colors.black : AppColors.primary,
          ),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (playing || (totalDur.inSeconds > 0))
              Column(children: [
                Slider(
                  value: currentPos.inMilliseconds.toDouble().clamp(0, (totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds : 1).toDouble()),
                  max: (totalDur.inMilliseconds > 0 ? totalDur.inMilliseconds.toDouble() : 1.0),
                  onChanged: (v) async {
                    try {
                      await _audioPlayer.seek(Duration(milliseconds: v.toInt()));
                    } catch (e) {}
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_formatRecDuration(currentPos), style: TextStyle(fontSize: 11.sp)),
                  Text(_formatRecDuration(totalDur), style: TextStyle(fontSize: 11.sp)),
                ]),
              ])
            else
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('00:00', style: TextStyle(fontSize: 11)),
                Text(_formatRecDuration(totalDur), style: const TextStyle(fontSize: 11)),
              ]),
          ]),
        ),
      ]),
    ]);
  }

  // ========= القائمة الجانبية للتواصل =========
  void _openContactSideSheet() {
    final ctx = _resolveContactContext();
    final isDark = _theme_controller_value();

    final bg = AppColors.card(isDark);
    final titleStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: 16.sp, color: AppColors.textPrimary(isDark));
    final labelStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 12.sp, color: AppColors.textSecondary(isDark));
    final valueStyle = TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 13.sp, color: AppColors.textPrimary(isDark));

    showGeneralDialog(
      context: context,
      barrierLabel: 'contact-sheet',
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.86,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // رأس
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(child: Text('التواصل', style: titleStyle)),
                          IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ctx.mode == ContactMode.individual) ...[
                              _sectionHeader('بيانات المعلن'),
                              SizedBox(height: 8.h),
                              _kv('الاسم', ctx.personName ?? '-', labelStyle, valueStyle),
                              if ((ctx.primaryTel ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال هاتفي', ctx.primaryTel!, onTap: () => _launchPhoneCall(ctx.primaryTel)),
                              ],
                              if ((ctx.primaryWaChat ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('واتساب', ctx.primaryWaChat!, onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                              ],
                              if ((ctx.primaryWaCall ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال واتساب', ctx.primaryWaCall!, onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                              ],

                              SizedBox(height: 20.h),
                              _sectionHeader('اختصارات سريعة'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if ((ctx.primaryTel ?? '').isNotEmpty) _quickActionChip(icon: Icons.call, label: 'اتصال', onTap: () => _launchPhoneCall(ctx.primaryTel)),
                                  if ((ctx.primaryWaChat ?? '').isNotEmpty) _quickActionChip(icon: Icons.chat, label: 'واتساب', onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                                  if ((ctx.primaryWaCall ?? '').isNotEmpty) _quickActionChip(icon: Icons.call, label: 'اتصال واتساب', onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                                ],
                              ),
                            ],

                            if (ctx.mode == ContactMode.companyWithMember) ...[
                              _sectionHeader('بيانات الشركة'),
                              SizedBox(height: 8.h),
                              _kv('اسم الشركة', ctx.companyName ?? '-', labelStyle, valueStyle),
                              SizedBox(height: 16.h),
                              _sectionHeader('الممثل في المحادثة'),
                              SizedBox(height: 8.h),
                              _kv('الاسم', ctx.memberName ?? '-', labelStyle, valueStyle),

                              if ((ctx.primaryTel ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال هاتفي (العضو)', ctx.primaryTel!, onTap: () => _launchPhoneCall(ctx.primaryTel)),
                              ],
                              if ((ctx.primaryWaChat ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('واتساب (العضو)', ctx.primaryWaChat!, onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                              ],
                              if ((ctx.primaryWaCall ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال واتساب (العضو)', ctx.primaryWaCall!, onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                              ],

                              SizedBox(height: 20.h),
                              _sectionHeader('اختصارات سريعة'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if ((ctx.primaryTel ?? '').isNotEmpty) _quickActionChip(icon: Icons.person, label: 'اتصال بالعضو', onTap: () => _launchPhoneCall(ctx.primaryTel)),
                                  if ((ctx.primaryWaChat ?? '').isNotEmpty) _quickActionChip(icon: Icons.chat, label: 'واتساب العضو', onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                                  if ((ctx.primaryWaCall ?? '').isNotEmpty) _quickActionChip(icon: Icons.call, label: 'اتصال واتساب', onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                                ],
                              ),
                            ],

                            if (ctx.mode == ContactMode.companyOnly) ...[
                              _sectionHeader('بيانات الشركة'),
                              SizedBox(height: 8.h),
                              _kv('اسم الشركة', ctx.companyName ?? '-', labelStyle, valueStyle),

                              if ((ctx.primaryTel ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال هاتفي (الشركة)', ctx.primaryTel!, onTap: () => _launchPhoneCall(ctx.primaryTel)),
                              ],
                              if ((ctx.primaryWaChat ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('واتساب (الشركة)', ctx.primaryWaChat!, onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                              ],
                              if ((ctx.primaryWaCall ?? '').isNotEmpty) ...[
                                SizedBox(height: 6.h),
                                _contactTile('اتصال واتساب (الشركة)', ctx.primaryWaCall!, onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                              ],

                              SizedBox(height: 20.h),
                              _sectionHeader('اختصارات سريعة'),
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  if ((ctx.primaryTel ?? '').isNotEmpty) _quickActionChip(icon: Icons.call, label: 'اتصال بالشركة', onTap: () => _launchPhoneCall(ctx.primaryTel)),
                                  if ((ctx.primaryWaChat ?? '').isNotEmpty) _quickActionChip(icon: Icons.chat, label: 'واتساب الشركة', onTap: () => _launchWhatsAppChat(ctx.primaryWaChat)),
                                  if ((ctx.primaryWaCall ?? '').isNotEmpty) _quickActionChip(icon: Icons.call, label: 'اتصال واتساب', onTap: () => _launchWhatsAppChat(ctx.primaryWaCall)),
                                ],
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
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
    );
  }

  Widget _sectionHeader(String title) {
    final isDark = _theme_controller_value();
    return Row(
      children: [
        Icon(Icons.info, color: AppColors.primary, size: 18.sp),
        SizedBox(width: 6.w),
        Text(title, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: 14.sp, color: AppColors.textPrimary(isDark))),
      ],
    );
  }

  Widget _kv(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Row(
      children: [
        SizedBox(width: 120.w, child: Text(label, style: labelStyle)),
        Expanded(child: Text(value, style: valueStyle, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _contactTile(String title, String phone, {required VoidCallback onTap}) {
    final isDark = _theme_controller_value();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.call),
      title: Text(title, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
      subtitle: Text(phone, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      tileColor: AppColors.border(isDark).withOpacity(0.4),
    );
  }

  Widget _quickActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: AppColors.primary.withOpacity(0.08),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
          ],
        ),
      ),
    );
  }

  String _roleArabic(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'المالك';
      case 'publisher':
        return 'ناشر';
      case 'viewer':
        return 'مشاهد';
      default:
        return role;
    }
  }

  // إطلاق واتساب / اتصال
  Future<void> _launchWhatsAppChat(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Get.snackbar('خطأ', 'رقم غير متاح', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final cleaned = _cleanPhoneNumber(phone);
    final Uri url = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح واتساب', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _launchPhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      Get.snackbar('خطأ', 'رقم غير متاح', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final cleaned = _cleanPhoneNumber(phone);
    final Uri url = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'لا يمكن فتح تطبيق الهاتف', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // حالات القراءة
  Widget _readReceiptIcon(Message message, bool isCurrentUser, bool isDarkMode) {
    if (!isCurrentUser) return const SizedBox(width: 0, height: 0);
    final read = message.isRead == true;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 6.w),
      child: Icon(read ? Icons.done_all : Icons.check, size: 16.sp, color: read ? Color(0xFF34B7F1) : _receiptGrey),
    );
  }

  // اختصارات
  bool _chat_controller_isLoading() => _chatController.isLoadingMessages.value;
  bool _theme_controller_value() => _themeController.isDarkMode.value;
  dynamic _loading_controller_user() => _loadingController.currentUser;

  // تنسيق مدة الصوت (قراءة فقط)
  String _formatRecDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
