import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/Message.dart';
import '../core/data/model/conversation.dart';

/// Controller لإدارة جميع عمليات المحادثات والرسائل عبر API
/// يتضمن:
/// 1. جلب قائمة المحادثات مع بيانات الإعلان والمُعلن
/// 2. جلب الرسائل لمحادثة محددة (مستخدم ↔️ شريك ↔️ إعلان ↔️ ملف معلن)
/// 3. إرسال رسالة جديدة برابط الإعلان وملف المُعلن
/// 4. تعليم رسالة كمقروءة
/// 5. حذف رسالة
class ChatController extends GetxController {
  /// قاعدة عنوان الـ API
  final String _baseUrl = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api/messages";
  /// قائمة المحادثات المحملة
  var conversationsList = <Conversation>[].obs;
  var isLoadingConversations = false.obs;
// تحديث داخل ملف ChatController.dart — استبدل دالتك الحالية بهذه النسخة
Future<void> fetchConversations({
  required int userId,
  String type = 'all', // 'incoming', 'outgoing' or 'all'
}) async {
  isLoadingConversations.value = true;
  try {
    // أضفنا query param للفلتر
    final uri = Uri.parse('$_baseUrl/conversations/$userId')
        .replace(queryParameters: type == 'all' ? null : {'type': type});
    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        final rawList = data['conversations'] as List<dynamic>? ?? [];

        final list = rawList.map((e) {
          try {
            // نحاول استعمال موديل Conversation.fromJson
            return Conversation.fromJson(e as Map<String, dynamic>);
          } catch (err, stack) {
            // طباعة المشكلة لكن لا نكسر التطبيق
            print('Error parsing conversation: $err');
            print(stack);
            print('Problematic JSON: ${json.encode(e)}');
            return null;
          }
        }).whereType<Conversation>().toList();

        // تأكد من وجود lastMessageAt قبل الترتيب — استخدم تاريخ افتراضي لو غاب
        list.sort((a, b) {
          final aDt = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDt.compareTo(aDt);
        });

        conversationsList.value = list;
      } else {
        print('fetchConversations: success flag is false');
        Get.snackbar('خطأ', 'فشل في جلب المحادثات',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } else {
      print('fetchConversations failed: status=${res.statusCode}, body=${res.body}');
      Get.snackbar('خطأ', 'خادم الاستجابة ${res.statusCode}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  } catch (e, st) {
    print('Exception in fetchConversations: $e\n$st');
    Get.snackbar('خطأ', 'فشل في تحميل المحادثات: ${e.toString()}',
        backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    isLoadingConversations.value = false;
  }
}

  //================================================================================
  /// 2) جلب الرسائل في محادثة محددة
  ///
  /// يجب تمرير:
  /// - userId: معرف المستخدم الحالي
  /// - partnerId: معرف الطرف الآخر
  /// - adId: معرف الإعلان
  /// - advertiserProfileId: ملف المعلن
  ///
  /// يدعم فصل المحادثات بناءً على الإعلان وملف المعلن.
 
 
  /// قائمة الرسائل المحملة للمحادثة الحالية
  var messagesList = <Message>[].obs;
  var isLoadingMessages = false.obs;
  Future<void> fetchMessages({
  required int userId,
  required int partnerId,
  int? adId,
  required int advertiserProfileId,
}) async {
  isLoadingMessages.value = true;
  messagesList.clear();
  try {
    // تحويل null إلى 0
    final adIdParam = adId ?? 0;
    
    final uri = Uri.parse(
      '$_baseUrl/$userId/$partnerId/$adIdParam/$advertiserProfileId'
    );
    print(uri);
    
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        print("Response JSON: ${res.body}");

        final list = (data['messages'] as List)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
        messagesList.value = list;
      } else {
        print('fetchMessages: success flag is false');
      }
    } else {
      print('fetchMessages failed: status=${res.statusCode}, body=${res.body}');
    }
  } catch (e) {
    print('Exception in fetchMessages: $e');
  } finally {
    isLoadingMessages.value = false;
  }
}

  //================================================================================
  /// 3) إرسال رسالة جديدة
  ///
  /// يجب تضمين الحقول:
  /// - sender_id: المعرف المرسل
  /// - recipient_id: المعرف المستقبل
  /// - ad_id: معرف الإعلان
  /// - advertiser_profile_id: ملف المعلن
  /// - body: نص الرسالة
  ///
  /// POST /api/messages
  Future<bool> sendMessage({
    required int senderId,
    required int recipientId,
     int ?adId,
    required int advertiserProfileId,
    required String body,
  }) async {
    final uri = Uri.parse('$_baseUrl');

    print(uri);
    try {
      final payload = {
        'sender_id': senderId,
        'recipient_id': recipientId,
        'ad_id': adId,
        'advertiser_profile_id': advertiserProfileId,
        'body': body,
      };
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print('sendMessage payload: $payload');

      if (res.statusCode == 201) {
        // نجح الإنشاء
        return true;
      } else {
        print('sendMessage failed: status=${res.statusCode}, body=${res.body}');
        return false;
      }
    } catch (e, st) {
      print('Exception in sendMessage: $e\n$st');
      return false;
    }
  }

  //================================================================================
  /// 4) تعليم رسالة كمُقروءة
  ///
  /// PATCH /api/messages/{message_id}/read
  /// يعيد true عند نجاح العملية (status 200)
 /* Future<bool> markAsRead(int messageId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$messageId/read');
      final res = await http.patch(uri);
      if (res.statusCode == 200) {
        // تحديث الحالة محلياً إذا أردت:
        final idx = messagesList.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          messagesList[idx].isRead = true;
          messagesList[idx].readAt = DateTime.now();
          messagesList.refresh();
        }
        return true;
      } else {
        print('markAsRead failed: status=${res.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception in markAsRead: $e');
      return false;
    }
  }*/

  //================================================================================
  /// 5) حذف رسالة
  ///
  /// DELETE /api/messages/{message_id}
  /// يعيد true عند نجاح (status 200)
  Future<bool> deleteMessage(int messageId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$messageId');
      final res = await http.delete(uri);

      if (res.statusCode == 200) {
        // إزالة الرسالة من القائمة محلياً
        messagesList.removeWhere((m) => m.id == messageId);
        return true;
      } else {
        print('deleteMessage failed: status=${res.statusCode}, body=${res.body}');
        return false;
      }
    } catch (e) {
      print('Exception in deleteMessage: $e');
      return false;
    }
  }
}
