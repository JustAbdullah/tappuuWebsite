import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/ChatController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/Message.dart';
import '../../../core/data/model/conversation.dart';

class DesktopConversationScreenInMy extends StatefulWidget {
  final Advertiser? advertiser;
  final Ad? ad;
  final int idAdv;

  const DesktopConversationScreenInMy({
    super.key,
    required this.advertiser,
    this.ad,
    required this.idAdv,
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

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingMessageId;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;

  final Map<int, Duration> _messageDurations = {};

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _currentPosition = p;
      });
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() {
        _currentDuration = d;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  void _loadMessages() {
    final user = _loadingController.currentUser;
    if (user != null) {
      _chatController.fetchMessages(
        userId: user.id ?? 0,
        partnerId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
      ).then((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          });
        }
      });
    }
  }

  void _sendMessage() {
    final user = _loadingController.currentUser;
    if (user != null && _messageController.text.trim().isNotEmpty) {
      final text = _messageController.text.trim();
      _messageController.clear();

      _chatController.sendMessage(
        senderId: user.id ?? 0,
        recipientId: widget.ad?.userId ?? widget.idAdv,
        adId: widget.ad?.id,
        advertiserProfileId: widget.idAdv,
        body: text,
      ).then((success) {
        if (success) {
          _loadMessages();
        } else {
          _messageController.text = text;
          Get.snackbar('خطأ', 'فشل إرسال الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
        }
      });
    }
  }

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
        print('خطأ في تشغيل الصوت: $e');
        Get.snackbar(
          'خطأ', 
          'لا يمكن تشغيل الصوت',
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
      }
    }
  }

  Future<void> _ensureMessageDuration(Message message) async {
    if (message.id == null) return;
    if (_messageDurations.containsKey(message.id)) return;

    final player = AudioPlayer();
    try {
      if (message.voiceUrl == null || message.voiceUrl!.isEmpty) return;
      await player.setSourceUrl(message.voiceUrl!);
      
      final duration = await player.getDuration().timeout(const Duration(seconds: 10));
      if (duration != null && duration.inMilliseconds > 0) {
        _messageDurations[message.id!] = duration;
        if (mounted) setState(() {});
      }
    } on TimeoutException {
      print('Timeout getting duration for message ${message.id}');
    } catch (e) {
      print('ensureMessageDuration error: $e');
    } finally {
      player.dispose();
    }
  }

  Future<void> _confirmAndDeleteMessage(Message message) async {
    final user = _loadingController.currentUser;
    if (user == null) return;

    final isMine = message.senderId == user.id;
    if (!isMine) {
      Get.snackbar('تنبيه', 'لا يمكنك حذف رسالة ليست لك', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background(_themeController.isDarkMode.value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف الرسالة',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(_themeController.isDarkMode.value),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف هذه الرسالة؟',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 16,
            color: AppColors.textSecondary(_themeController.isDarkMode.value),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'لا',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'نعم',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _chatController.deleteMessage(message.id ?? 0);
    if (ok) {
      if (!mounted) return;
      setState(() {});
      Get.snackbar('تم', 'تم حذف الرسالة', backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('خطأ', 'فشل حذف الرسالة', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

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

  Future<void> _launchWhatsAppCall(String? phone) async {
    await _launchWhatsAppChat(phone);
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

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف';
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeController.isDarkMode.value;
    final cardColor = AppColors.card(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    const whatsappLightGreen = Color(0xFFDCF8C6);

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: Column(
        children: [
          // شريط العنوان - نفس تصميم الموبايل
          _buildCustomAppBar(isDarkMode),
          
          // محتوى المحادثة
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // لوحة معلومات الإعلان (جانبية)
                _buildAdInfoPanel(isDarkMode, cardColor, textPrimary, textSecondary),
                
                // منطقة المحادثة الرئيسية
                Expanded(
                  child: _buildConversationArea(isDarkMode, cardColor, textPrimary, textSecondary, dividerColor, whatsappLightGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDarkMode) {
    final adv = widget.advertiser;
    return Container(
      color: AppColors.appBar(isDarkMode),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Get.back(), 
                child: Icon(Icons.arrow_back, color: AppColors.onPrimary, size: 24)
              )
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 300,
                child: Text(
                  adv?.name ?? 'معلن',
                  style: TextStyle(
                    color: AppColors.onPrimary, 
                    fontFamily: AppTextStyles.appFontFamily, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                adv?.contactPhone ?? '',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily, 
                  fontSize: 14, 
                  color: AppColors.onPrimary.withOpacity(0.9), 
                  fontWeight: FontWeight.w600
                ),
              ),
            ]),
          ]),
          Row(children: [
            if ((adv?.contactPhone ?? '').isNotEmpty) 
              Container(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () => _launchPhoneCall(adv?.contactPhone), 
                  child: Icon(Icons.phone, color: AppColors.onPrimary, size: 24)
                )
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: _showTopContactMenu, 
                child: Icon(Icons.more_vert, color: AppColors.onPrimary, size: 24)
              )
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAdInfoPanel(bool isDarkMode, Color cardColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(right: BorderSide(color: AppColors.border(isDarkMode), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الإعلان',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 18,
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
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
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
                '${_formatPrice(widget.ad!.price!)} ليرة سورية',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildNoAdNotice(Color cardColor, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'هذه المحادثة تتم بدون أي إعلان ذي صلة بين المعلن والمتحدث',
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

  Widget _buildConversationArea(bool isDarkMode, Color cardColor, Color textPrimary, Color textSecondary, Color dividerColor, Color userBubbleColor) {
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

              final serverMessages = _chatController.messagesList;
              
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100, top: 16),
                itemCount: serverMessages.length,
                itemBuilder: (context, idx) {
                  final message = serverMessages[idx];
                  final currentUser = _loadingController.currentUser;
                  final isCurrentUser = currentUser != null && (currentUser.id == message.senderId);

                  if (message.isVoice == true && message.voiceUrl != null && message.voiceUrl!.isNotEmpty) {
                    _ensureMessageDuration(message);
                  }

                  return _buildMessageBubble(
                    message,
                    isDarkMode,
                    isCurrentUser,
                    widget.advertiser,
                    userBubbleColor,
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

  Widget _buildMessageBubble(
    Message message,
    bool isDarkMode,
    bool isCurrentUser,
    Advertiser? advertiser,
    Color userBubbleColor,
  ) {
    final otherBubbleColor = AppColors.card(isDarkMode);
    final textColor = isCurrentUser ? Colors.black : AppColors.textPrimary(isDarkMode);
    final timeColor = isCurrentUser ? Colors.black.withOpacity(0.6) : AppColors.textSecondary(isDarkMode);
    final align = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start;

    final isVoice = message.isVoice == true;
    final dur = (message.id != null && _messageDurations.containsKey(message.id)) 
        ? _messageDurations[message.id] 
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: align, 
        children: [
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: mainAxis,
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.background(isDarkMode),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(
                            'حذف الرسالة',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkMode),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          content: Text(
                            'هل تريد حذف هذه الرسالة؟',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 16,
                              color: AppColors.textSecondary(isDarkMode),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text(
                                      'لا',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text(
                                      'نعم',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _confirmAndDeleteMessage(message);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary(isDarkMode)),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: mainAxis, 
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? userBubbleColor : otherBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isCurrentUser ? 16 : 6),
                      topRight: Radius.circular(isCurrentUser ? 6 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03), 
                        blurRadius: 6, 
                        offset: const Offset(0, 2)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      if (isVoice)
                        _buildVoiceBubbleContent(message, dur, isCurrentUser)
                      else
                        Text(
                          message.body ?? '', 
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily, 
                            fontSize: 16, 
                            color: textColor, 
                            height: 1.4
                          )
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight, 
                        child: Text(
                          _formatDateTimeFull(message.createdAt), 
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily, 
                            fontSize: 12, 
                            color: timeColor
                          )
                        )
                      ),
                    ]
                  ),
                ),
              ),
            ]
          ),
        ]
      ),
    );
  }

  Widget _buildVoiceBubbleContent(Message message, Duration? cachedDuration, bool isCurrentUser) {
    final playing = _playingMessageId == message.id;
    final currentPos = playing ? _currentPosition : Duration.zero;
    final totalDur = playing ? (_currentDuration > Duration.zero ? _currentDuration : (cachedDuration ?? Duration.zero)) : (cachedDuration ?? Duration.zero);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Row(children: [
          IconButton(
            onPressed: () => _playPauseVoice(message), 
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_filled, 
              size: 32, 
              color: isCurrentUser ? Colors.black : AppColors.primary
            )
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(_formatDuration(currentPos), style: const TextStyle(fontSize: 12)),
                        Text(_formatDuration(totalDur), style: const TextStyle(fontSize: 12)),
                      ]
                    ),
                  ])
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text('00:00', style: const TextStyle(fontSize: 12)),
                      Text(_formatDuration(cachedDuration ?? Duration.zero), style: const TextStyle(fontSize: 12)),
                    ]
                  ),
              ]
            ),
          ),
        ]),
      ]
    );
  }

  Widget _buildMessageInput(bool isDarkMode, Color cardColor, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // زر الميكروفون المعدل
          GestureDetector(
            onTap: () {
              Get.snackbar(
                'الميزة غير متاحة',
                'التسجيل الصوتي متاح حصرياً في تطبيق الجوال',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.buttonAndLinksColor,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.border(isDarkMode),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: TextStyle(color: AppColors.textSecondary(isDarkMode)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            backgroundColor: AppColors.buttonAndLinksColor,
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  void _showTopContactMenu() {
    final adv = widget.advertiser;
    if (adv == null) return;
    final width = MediaQuery.of(context).size.width;
    final top = kToolbarHeight + MediaQuery.of(context).padding.top;
    final relativeRect = RelativeRect.fromLTRB(16, top + 8, width - 16, 0);
    showMenu<int>(
      context: context, 
      position: relativeRect, 
      items: [
        PopupMenuItem(
          value: 0, 
          child: ListTile(
            leading: const Icon(Icons.chat, color: Colors.green), 
            title: Text('محادثة واتساب')
          )
        ),
        PopupMenuItem(
          value: 1, 
          child: ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Colors.green), 
            title: Text('اتصال واتساب')
          )
        ),
        PopupMenuItem(
          value: 2, 
          child: ListTile(
            leading: const Icon(Icons.call, color: Colors.blue), 
            title: Text('اتصال هاتفي')
          )
        ),
      ]
    ).then((value) {
      if (value == null) return;
      if (value == 0) _launchWhatsAppChat(adv.whatsappPhone?.isNotEmpty == true ? adv.whatsappPhone : adv.whatsappCallNumber);
      if (value == 1) _launchWhatsAppCall(adv.whatsappCallNumber?.isNotEmpty == true ? adv.whatsappCallNumber : adv.whatsappPhone);
      if (value == 2) _launchPhoneCall(adv.contactPhone);
    });
  }
}