// message.dart
class Message {
  final int id;
  final int senderId;
  final String? senderEmail;
  final int recipientId;
  final String? recipientEmail;
  final String? body;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? updatedAt;
  final int adId;
  final String adTitle;
  final double adPrice;
  final int advertiserProfileId;
  final int advertiserUserId;
  final String advertiserName;
  final String advertiserLogo;

  Message({
    required this.id,
    required this.senderId,
    this.senderEmail,
    required this.recipientId,
    this.recipientEmail,
    this.body,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.updatedAt,
    required this.adId,
    required this.adTitle,
    required this.adPrice,
    required this.advertiserProfileId,
    required this.advertiserUserId,
    required this.advertiserName,
    required this.advertiserLogo,
  });

  /// مصنع التحويل من JSON -> Message
  factory Message.fromJson(Map<String, dynamic> json) {
    // ad قد يأتي كمجال متداخل أو كحقول علوية
    final adMap = (json['ad'] is Map<String, dynamic>) ? json['ad'] as Map<String, dynamic> : <String, dynamic>{};
    final topAdId = Message.parseInt(json['ad_id']);
    final topAdTitle = json['ad_title']?.toString() ?? '';
    final topAdPrice = Message.parseDouble(json['ad_price']);

    final int adId = adMap.isNotEmpty ? Message.parseInt(adMap['id']) : (topAdId != 0 ? topAdId : 0);

    final String adTitle = adMap.isNotEmpty
        ? (adMap['title_ar']?.toString() ?? adMap['title']?.toString() ?? '')
        : topAdTitle;

    final double adPrice = adMap.isNotEmpty ? Message.parseDouble(adMap['price']) : topAdPrice;

    // advertiser profile قد يأتي تحت 'advertiser_profile' أو 'advertiser' أو كحقول علوية
    Map<String, dynamic> advMap = {};
    if (json['advertiser_profile'] is Map<String, dynamic>) {
      advMap = json['advertiser_profile'] as Map<String, dynamic>;
    } else if (json['advertiser'] is Map<String, dynamic>) {
      advMap = json['advertiser'] as Map<String, dynamic>;
    } else {
      advMap = {
        'id': json['advertiser_profile_id'] ?? json['advertiser_id'],
        'user_id': json['advertiser_user_id'] ?? json['advertiser_user'],
        'name': json['advertiser_name'] ?? json['advertiser_profile_name'],
        'logo': json['advertiser_logo'] ?? json['advertiser_profile_logo'],
      };
    }

    return Message(
      id: Message.parseInt(json['id']),
      senderId: Message.parseInt(json['sender_id']),
      senderEmail: json['sender_email']?.toString(),
      recipientId: Message.parseInt(json['recipient_id']),
      recipientEmail: json['recipient_email']?.toString(),
      body: json['body']?.toString(),
      isRead: Message.parseBool(json['is_read']),
      createdAt: Message.parseDateTime(json['created_at']),
      readAt: json['read_at'] != null ? Message.parseDateTime(json['read_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      adId: adId,
      adTitle: adTitle,
      adPrice: adPrice,
      advertiserProfileId: Message.parseInt(advMap['id']),
      advertiserUserId: Message.parseInt(advMap['user_id']),
      advertiserName: advMap['name']?.toString() ?? '',
      advertiserLogo: advMap['logo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_email': senderEmail,
        'recipient_id': recipientId,
        'recipient_email': recipientEmail,
        'body': body,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'ad': {
          'id': adId,
          'title_ar': adTitle,
          'price': adPrice,
        },
        'advertiser_profile': {
          'id': advertiserProfileId,
          'user_id': advertiserUserId,
          'name': advertiserName,
          'logo': advertiserLogo,
        },
      };

  // ================= Helpers (public) =================
  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      // unix seconds or milliseconds
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      String s = value;
      // إزالة suffix مايكرو/زمن زائد مثل .000000Z
      s = s.replaceAll(RegExp(r'\.0+Z$'), 'Z');
      // تحويل "YYYY-MM-DD HH:MM:SS" إلى ISO
      if (!s.contains('T') && s.contains(' ')) s = s.replaceFirst(' ', 'T');
      try {
        return DateTime.parse(s);
      } catch (_) {
        // محاولة تحويلي بسيطة بدون timezone
        try {
          if (s.length >= 19) return DateTime.parse(s.substring(0, 19));
        } catch (_) {}
      }
    }
    return DateTime.now();
  }
}
