// conversation.dart
import 'message.dart';

class Conversation {
  final User inquirer; // يقرأ من 'inquirer' أو 'partner'
  final Ad? ad; // اختياري
  final Advertiser advertiser;
  final Message? lastMessage;
  final Message? firstMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  final bool isUserInitiated;
  final String? direction;

  Conversation({
    required this.inquirer,
    this.ad,
    required this.advertiser,
    this.lastMessage,
    this.firstMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.isUserInitiated,
    this.direction,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // دعم 'inquirer' أو 'partner'
    final userJson = (json['inquirer'] ?? json['partner']) as Map<String, dynamic>?;
    if (userJson == null) {
      throw FormatException('Missing inquirer/partner in conversation JSON');
    }
    final inquirer = User.fromJson(userJson);

    Ad? ad;
    if (json['ad'] is Map<String, dynamic>) {
      ad = Ad.fromJson(json['ad'] as Map<String, dynamic>);
    } else {
      ad = null;
    }

    final advertiserJson = (json['advertiser'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final advertiser = Advertiser.fromJson(advertiserJson);

    Message? lastMessage;
    if (json['last_message'] is Map<String, dynamic>) {
      try {
        lastMessage = Message.fromJson(json['last_message'] as Map<String, dynamic>);
      } catch (_) {
        // fallback: build minimal Message using public parsers
        final lm = json['last_message'] as Map<String, dynamic>;
        lastMessage = Message(
          id: Message.parseInt(lm['id']),
          senderId: Message.parseInt(lm['sender_id']),
          senderEmail: lm['sender_email']?.toString(),
          recipientId: Message.parseInt(lm['recipient_id']),
          recipientEmail: lm['recipient_email']?.toString(),
          body: lm['body']?.toString(),
          isRead: Message.parseBool(lm['is_read']),
          createdAt: Message.parseDateTime(lm['created_at']),
          readAt: lm['read_at'] != null ? Message.parseDateTime(lm['read_at']) : null,
          updatedAt: lm['updated_at'] != null ? Message.parseDateTime(lm['updated_at']) : null,
          adId: lm['ad_id'] != null ? Message.parseInt(lm['ad_id']) : 0,
          adTitle: lm['ad_title']?.toString() ?? '',
          adPrice: lm['ad_price'] != null ? Message.parseDouble(lm['ad_price']) : 0.0,
          advertiserProfileId: lm['advertiser_profile_id'] != null ? Message.parseInt(lm['advertiser_profile_id']) : 0,
          advertiserUserId: lm['advertiser_user_id'] != null ? Message.parseInt(lm['advertiser_user_id']) : 0,
          advertiserName: lm['advertiser_name']?.toString() ?? '',
          advertiserLogo: lm['advertiser_logo']?.toString() ?? '',
        );
      }
    }

    Message? firstMessage;
    if (json['first_message'] is Map<String, dynamic>) {
      try {
        firstMessage = Message.fromJson(json['first_message'] as Map<String, dynamic>);
      } catch (_) {
        final fm = json['first_message'] as Map<String, dynamic>;
        firstMessage = Message(
          id: Message.parseInt(fm['id']),
          senderId: Message.parseInt(fm['sender_id']),
          senderEmail: fm['sender_email']?.toString(),
          recipientId: Message.parseInt(fm['recipient_id']),
          recipientEmail: fm['recipient_email']?.toString(),
          body: fm['body']?.toString(),
          isRead: Message.parseBool(fm['is_read']),
          createdAt: Message.parseDateTime(fm['created_at']),
          readAt: fm['read_at'] != null ? Message.parseDateTime(fm['read_at']) : null,
          updatedAt: fm['updated_at'] != null ? Message.parseDateTime(fm['updated_at']) : null,
          adId: fm['ad_id'] != null ? Message.parseInt(fm['ad_id']) : 0,
          adTitle: fm['ad_title']?.toString() ?? '',
          adPrice: fm['ad_price'] != null ? Message.parseDouble(fm['ad_price']) : 0.0,
          advertiserProfileId: fm['advertiser_profile_id'] != null ? Message.parseInt(fm['advertiser_profile_id']) : 0,
          advertiserUserId: fm['advertiser_user_id'] != null ? Message.parseInt(fm['advertiser_user_id']) : 0,
          advertiserName: fm['advertiser_name']?.toString() ?? '',
          advertiserLogo: fm['advertiser_logo']?.toString() ?? '',
        );
      }
    }

    final unread = Message.parseInt(json['unread_count']);

    // last_message_at قد تكون "YYYY-MM-DD HH:MM:SS" أو ISO => حاول التحويل، fallbacks
    DateTime lastAt;
    if (json['last_message_at'] != null) {
      lastAt = Message.parseDateTime(json['last_message_at']);
    } else if (lastMessage != null) {
      lastAt = lastMessage.createdAt;
    } else {
      lastAt = DateTime.now();
    }

    final isUserInitiated = (json['is_user_initiated'] == true) || (json['is_user_initiated']?.toString() == '1');
    final direction = json['direction']?.toString();

    return Conversation(
      inquirer: inquirer,
      ad: ad,
      advertiser: advertiser,
      lastMessage: lastMessage,
      firstMessage: firstMessage,
      unreadCount: unread,
      lastMessageAt: lastAt,
      isUserInitiated: isUserInitiated,
      direction: direction,
    );
  }
}

// ====== Sub models: User, Ad, Advertiser ======
class User {
  final int id;
  final String email;
  final String? name;

  User({required this.id, required this.email, this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: Message.parseInt(json['id']),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class Ad {
  final int id;
  final String title;
  final int userId;
  final List<String> images;
  final double price;

  Ad({
    required this.id,
    required this.title,
    required this.userId,
    required this.images,
    required this.price,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List).map((e) => e?.toString() ?? '').toList();
    }
    final title = json['title_ar']?.toString() ?? json['title']?.toString() ?? '';
    return Ad(
      id: Message.parseInt(json['id']),
      title: title,
      userId: Message.parseInt(json['user_id']),
      images: images,
      price: Message.parseDouble(json['price']),
    );
  }
}

class Advertiser {
  final int id;
  final String name;
  final String logo;

  Advertiser({required this.id, required this.name, required this.logo});

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      id: Message.parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
    );
  }
}
