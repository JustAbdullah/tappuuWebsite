import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart'; // reCAPTCHA v3 على الويب

import '../HomeDeciderView.dart';
import '../core/constant/appcolors.dart';
import '../core/data/model/user.dart' as users;
import '../core/localization/changelanguage.dart';

import 'BrowsingHistoryController.dart';
import 'FavoritesController.dart';
import 'LoadingController.dart';
import 'ViewsController.dart';

class AuthController extends GetxController {
  // ==================== [Config: reCAPTCHA] ====================

  /// مفتاح موقع reCAPTCHA v3 — نفس القيمة الموجودة في .env (RECAPTCHA_SITE)
  static const String kRecaptchaSiteKey =
      '6LeUpggsAAAAAGetn0JGpR0IraF9YBHCi7ovkKLh';

  /// صفحة reCAPTCHA v2 (HTML عادي في موقعك)
  static const String kRecaptchaV2PageUrl =
      'https://testing.arabiagroup.net/recaptcha-v2-web.html';

  /// site key لـ v2 (Checkbox) — نفس القيمة في .env (RECAPTCHA_V2_SITE_KEY)
  static const String kRecaptchaV2SiteKey =
      '6Lc13QgsAAAAADNKzZDu8yrNDrtQOhJAOpB97mw_';

  // ==================== [Observables] ====================

  RxInt currentStep = 0
      .obs; // 0 = البريد الإلكتروني, 1 = الكود, 2 = كلمة المرور
  RxBool isLoading = false.obs;
  RxBool codeSent = false.obs;
  RxBool isSendingCode = false.obs;
  RxBool isVerifying = false.obs;
  RxBool isLoggingIn = false.obs;
  final RxBool isPasswordValid = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool canCompleteLater = false.obs;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  final userFire.FirebaseAuth _auth = userFire.FirebaseAuth.instance;
  var user = Rxn<userFire.User>();

  /// جذر مسارات الـ API
  final String baseUrl =
      'https://stayinme.arabiagroup.net/lar_stayInMe/public/api/users';

  // ==================== [v2 Lock & Cache] ====================

  Completer<String?>? _v2Completer;
  String? _v2CachedToken;
  DateTime? _v2CachedAt;

  /// افتح reCAPTCHA v2 في نافذة متصفح (ويب فقط) مع كاش ≈ 110 ثانية
  Future<String?> _getV2Token() async {
    final now = DateTime.now();

    // كاش بسيط لـ ~110 ثانية
    if (_v2CachedToken != null &&
        _v2CachedAt != null &&
        now.difference(_v2CachedAt!).inSeconds < 110) {
      debugPrint(
          '✅ [reCAPTCHA v2] using cached token (age=${now.difference(_v2CachedAt!).inSeconds}s)');
      return _v2CachedToken;
    }

    // لو فيه عملية جارية، نرجع نفس الـ Future
    if (_v2Completer != null) {
      debugPrint(
          '⏳ [reCAPTCHA v2] wait for existing popup (another call is already running)');
      return _v2Completer!.future;
    }

    _v2Completer = Completer<String?>();
    try {
      if (!kIsWeb) {
        debugPrint(
            '⚠️ [_getV2Token] v2 popup only implemented for Web (kIsWeb=false).');
        _v2Completer!.complete(null);
      } else {
        debugPrint(
            '🧩 [_getV2Token] opening v2 popup url=$kRecaptchaV2PageUrl site_key=$kRecaptchaV2SiteKey');
        final token = await _openV2PopupAndWaitForToken();
        if (token != null && token.isNotEmpty) {
          _v2CachedToken = token;
          _v2CachedAt = DateTime.now();
          debugPrint(
              '✅ [reCAPTCHA v2] token received len=${token.length}, cachedAt=$_v2CachedAt');
        } else {
          debugPrint(
              '⚠️ [reCAPTCHA v2] popup closed without token or returned empty token');
        }
        _v2Completer!.complete(token);
      }
    } catch (e, st) {
      debugPrint('❌ [_getV2Token] exception: $e');
      debugPrint('❌ [_getV2Token] stack:\n$st');
      _v2Completer!.complete(null);
    } finally {
      _v2Completer = null;
    }

    return _v2CachedToken;
  }

  /// يفتح صفحة HTML خارجية (recaptcha-v2.html) وينتظر postMessage تحتوي التوكن
 Future<String?> _openV2PopupAndWaitForToken() async {
  final completer = Completer<String?>();

  final uri = Uri.parse(kRecaptchaV2PageUrl).replace(queryParameters: {
    'site_key': kRecaptchaV2SiteKey,
  });

  debugPrint('🌐 [_openV2PopupAndWaitForToken] open window: $uri');

  html.WindowBase? popup;
  try {
    popup = html.window.open(
      uri.toString(),
      'recaptcha_v2',
      // ❌ لا تكتب noopener هنا
      'width=480,height=640', // ممكن تزود options ثانية بس بدون noopener
    );
  } catch (e, st) {
    debugPrint('❌ [_openV2PopupAndWaitForToken] window.open exception: $e');
    debugPrint('❌ [_openV2PopupAndWaitForToken] stack:\n$st');
    completer.complete(null);
    return completer.future;
  }

  try {
    if (popup == null) {
      debugPrint(
          '⚠️ [reCAPTCHA v2] popup is null (probably blocked by browser).');
      completer.complete(null);
      return completer.future;
    }
  } catch (e, st) {
    debugPrint('⚠️ [reCAPTCHA v2] popup object invalid (blocked?): $e');
    debugPrint('⚠️ [reCAPTCHA v2] stack:\n$st');
    completer.complete(null);
    return completer.future;
  }

  late StreamSubscription<html.MessageEvent> sub;
  sub = html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      debugPrint(
          '📩 [reCAPTCHA v2] onMessage raw=${event.data} origin=${event.origin}');

      String? token;

      if (data is Map) {
        final type = data['type']?.toString();
        if (type == 'recaptcha_v2_token') {
          token = data['token']?.toString();
        }
      } else if (data is String && data.startsWith('recaptcha_v2:')) {
        token = data.substring('recaptcha_v2:'.length);
      }

      if (token != null && token.isNotEmpty && !completer.isCompleted) {
        debugPrint(
            '✅ [reCAPTCHA v2] token received from postMessage, len=${token.length}');
        completer.complete(token);
        sub.cancel();
        try {
          popup?.close();
        } catch (e, st) {
          debugPrint('⚠️ [reCAPTCHA v2] popup.close() threw: $e');
          debugPrint('⚠️ [reCAPTCHA v2] stack:\n$st');
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ [reCAPTCHA v2] onMessage parse error: $e');
      debugPrint('⚠️ [reCAPTCHA v2] stack:\n$st');
    }
  });

  Future.delayed(const Duration(seconds: 120), () {
    if (!completer.isCompleted) {
      debugPrint('⚠️ [reCAPTCHA v2] timeout waiting for token (120s passed)');
      completer.complete(null);
      sub.cancel();
      try {
        popup?.close();
      } catch (e, st) {
        debugPrint(
            '⚠️ [reCAPTCHA v2] popup.close() on timeout threw: $e');
        debugPrint('⚠️ [reCAPTCHA v2] stack:\n$st');
      }
    }
  });

  return completer.future;
}


  // ==================== [Lifecycle] ====================

  @override
  void onClose() {
    emailCtrl.dispose();
    codeCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  // ==================== [Helpers: reCAPTCHA] ====================

  void _logRecaptchaJsHint() {
    debugPrint('''
━━━━━━━━━━ 🧠 reCAPTCHA JS DEBUG HINT ━━━━━━━━━━
- الكود يعمل على الويب: kIsWeb=$kIsWeb
- لو تشوف في الـ Console المتصفح رسالة:
    "Error: Looks like reCaptcha js is not loaded yet. Try to add the recaptcha js to your html <head> tag (or before flutter.js)."
  فهذا يعني غالبًا:
    1) سكربت reCAPTCHA v3 غير مضاف في index.html داخل <head>.
    2) أو مضاف بعد flutter_bootstrap.js وليس قبله.
    3) أو فيه كاش قديم لملف index.html في المتصفح (جرّب Ctrl+F5 أو private window).
- تأكد من وجود شيء مثل:
    <script src="https://www.google.com/recaptcha/api.js?render=$kRecaptchaSiteKey" async defer></script>
  داخل <head> قبل:
    <script src="flutter_bootstrap.js" async></script>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }

  void _logRecaptchaStep({
    required String phase,
    required String action,
    bool? isWeb,
    bool? readyResult,
    bool? attached,
    String? note,
    Object? error,
    StackTrace? stack,
  }) {
    debugPrint('''
────────── 🔍 reCAPTCHA v3 DEBUG [$phase] ──────────
 action        : $action
 kIsWeb        : $isWeb
 ready()       : $readyResult
 attachedToken : $attached
 note          : ${note ?? '-'}
 errorType     : ${error != null ? error.runtimeType : '-'}
 error         : ${error ?? '-'}
 stack         : ${stack ?? '-'}
────────────────────────────────────────────────────
''');
  }

  /// يطلب توكن reCAPTCHA v3 من Google (عن طريق g_recaptcha_v3) ويضيفه للـ payload
  /// ويضيف المفتاح الداخلي _has_recaptcha لمعرفة إذا التوكن موجود أو لا (إجباري للويب).
  Future<Map<String, dynamic>> _withCaptcha(
    Map<String, dynamic> data,
    String action,
  ) async {
    bool attached = false;

    debugPrint(
        '🧪 [_withCaptcha] start for action="$action" (kIsWeb=$kIsWeb, siteKeyLen=${kRecaptchaSiteKey.length})');

    try {
      if (kIsWeb) {
        // أولاً نطبع Hint لو فيه مشكلة JS
        _logRecaptchaJsHint();

        bool ready;
        try {
          ready = await GRecaptchaV3.ready(kRecaptchaSiteKey);
        } catch (e, st) {
          _logRecaptchaStep(
            phase: 'ready-exception',
            action: action,
            isWeb: kIsWeb,
            readyResult: null,
            attached: false,
            note:
                'استثناء أثناء GRecaptchaV3.ready — في الغالب JS غير محمّل أو مكتبة g_recaptcha_v3 غير مهيئة.',
            error: e,
            stack: st,
          );
          data['_has_recaptcha'] = false;
          return data;
        }

        if (!ready) {
          _logRecaptchaStep(
            phase: 'ready-false',
            action: action,
            isWeb: kIsWeb,
            readyResult: false,
            attached: false,
            note:
                'GRecaptchaV3.ready رجعت false. هذا عادة يعني أن سكربت reCAPTCHA JS غير محمّل كما يجب. راجع index.html والـ Console.',
          );
        } else {
          _logRecaptchaStep(
            phase: 'ready-true',
            action: action,
            isWeb: kIsWeb,
            readyResult: true,
            attached: false,
            note: 'الآن سننفّذ GRecaptchaV3.execute للحصول على التوكن.',
          );

          String token = '';
          try {
            // ✅ هنا تم إصلاح الخطأ: execute ترجع Future<String?>
            token = (await GRecaptchaV3.execute(action)) ?? '';
          } catch (e, st) {
            _logRecaptchaStep(
              phase: 'execute-exception',
              action: action,
              isWeb: kIsWeb,
              readyResult: true,
              attached: false,
              note:
                  'استثناء أثناء GRecaptchaV3.execute. في الغالب فيه مشكلة JS أو Block من المتصفح.',
              error: e,
              stack: st,
            );
          }

          if (token.isNotEmpty) {
            data['recaptcha_token'] = token;
            data['recaptcha_version'] = 'v3';
            data['recaptcha_action'] = action;
            attached = true;
            _logRecaptchaStep(
              phase: 'execute-success',
              action: action,
              isWeb: kIsWeb,
              readyResult: true,
              attached: true,
              note: 'تم إرفاق التوكن بنجاح. len=${token.length}',
            );
          } else {
            _logRecaptchaStep(
              phase: 'execute-empty',
              action: action,
              isWeb: kIsWeb,
              readyResult: true,
              attached: false,
              note:
                  'GRecaptchaV3.execute رجعت توكن فارغ. لن نرسل أي reCAPTCHA للسيرفر.',
            );
          }
        }
      } else {
        _logRecaptchaStep(
          phase: 'non-web',
          action: action,
          isWeb: kIsWeb,
          readyResult: null,
          attached: false,
          note:
              'استدعاء _withCaptcha على منصة ليست Web. reCAPTCHA v3 غير مفعّل هنا.',
        );
      }
    } catch (e, st) {
      _logRecaptchaStep(
        phase: 'outer-exception',
        action: action,
        isWeb: kIsWeb,
        readyResult: null,
        attached: false,
        note:
            'استثناء عام داخل _withCaptcha. قد يكون من مكتبة g_recaptcha_v3 أو من JS side.',
        error: e,
        stack: st,
      );
    }

    // نستخدمه في كل request عشان نمنع أي API بدون توكن
    data['_has_recaptcha'] = attached;

    debugPrint(
        '🧪 [_withCaptcha] end for action="$action" => attached=$attached, keysInData=${data.keys.toList()}');

    return data;
  }

  Future<Map<String, String>> _jsonHeaders({String? recaptchaVersion}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (recaptchaVersion != null) {
      h['X-Recaptcha-Version'] = recaptchaVersion; // v2 عند الفولباك
    }
    return h;
  }

  bool _isJson(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    return ct.contains('application/json');
  }

  bool _shouldTriggerV2Fallback(http.Response res, Map<String, dynamic>? body) {
    final msg = (body?['message'] ?? body?['error'] ?? '').toString();
    final status = body?['status']?.toString() ?? '';
    debugPrint(
        '🤖 [_shouldTriggerV2Fallback] statusCode=${res.statusCode}, status=$status, message=$msg');

    // حالة require_v2 الصريحة من الباك اند (بناءً على score عالي الخطورة)
    if (status == 'require_v2') return true;

    // 422 غالباً خطأ تحقق reCAPTCHA / score سيء
    if (res.statusCode == 422) return true;

    // رسائل واضحة من الباك اند
    if (msg.contains('reCAPTCHA') || msg.contains('التحقق')) return true;

    return false;
  }

  // ==================== [Utilities] ====================

  void nextStep() => currentStep.value++;
  void prevStep() => currentStep.value--;

  void validatePassword(String value) {
    isPasswordValid.value = value.length >= 6;
    debugPrint(
        '🔐 [validatePassword] length=${value.length}, isValid=${isPasswordValid.value}');
  }

  Future<void> _persistUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(userMap));
    debugPrint(
        '💾 [_persistUser] user stored in SharedPreferences (id=${userMap['id']})');
  }

  Future<void> _afterAuthSuccess(users.User u, {bool navigate = true}) async {
    final langCode =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    final loadingCtrl = Get.find<LoadingController>();
    loadingCtrl.currentUser = u;
    loadingCtrl.setUser(u);

    debugPrint(
        '🎉 [_afterAuthSuccess] user id=${u.id}, email=${u.email}, navigate=$navigate, lang=$langCode');

    try {
      final viewsController = Get.find<ViewsController>();
      final favoritesController = Get.find<FavoritesController>();
      final browsingHistoryController =
          Get.find<BrowsingHistoryController>();

      await Future.wait([
        viewsController.fetchViews(
            userId: u.id ?? 0, perPage: 3, lang: langCode),
        favoritesController.fetchFavorites(
            userId: u.id ?? 0, perPage: 3, lang: langCode),
        browsingHistoryController.fetchRecommendedAds(
            userId: u.id ?? 0, lang: langCode),
      ]);
    } catch (e, st) {
      debugPrint('⚠️ [Post-auth fetch] error: $e');
      debugPrint('⚠️ [Post-auth fetch] stack:\n$st');
    }

    if (navigate) {
      Get.offAll(() => HomeDeciderView());
    }
  }

  // ==================== [Google Sign-In - Firebase + API] ====================

  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);

      final provider = userFire.GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});

      userFire.UserCredential userCredential;

      if (kIsWeb) {
        debugPrint('🌐 [signInWithGoogle] using signInWithPopup (Web)');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        debugPrint('📱 [signInWithGoogle] using signInWithRedirect (non-Web)');
        await _auth.signInWithRedirect(provider);
        final result = await _auth.getRedirectResult();
        userCredential = result;
      }

      final fbUser = userCredential.user;
      debugPrint(
          '✅ [signInWithGoogle] Firebase user: uid=${fbUser?.uid}, email=${fbUser?.email}');

      if (fbUser?.email != null) {
        user.value = fbUser;
        await _loginOrRegisterWithApi(fbUser!.email!);
      } else {
        Get.snackbar(
          'فشل تسجيل الدخول',
          'لم يتم استرجاع البريد الإلكتروني من Google.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on userFire.FirebaseAuthException catch (e, st) {
      debugPrint(
          '❌ [signInWithGoogle] FirebaseAuthException: ${e.code} – ${e.message}');
      debugPrint('Stack trace:\n$st');
      const errorMessages = {
        'account-exists-with-different-credential':
            'هذا الحساب مُسجل بالفعل بطريقة مختلفة، حاول تسجيل الدخول بطريقة أخرى.',
        'invalid-credential': 'بيانات الدخول غير صحيحة، يرجى المحاولة مرة أخرى.',
        'operation-not-allowed':
            'خاصية تسجيل الدخول عبر Google غير مفعلة حالياً.',
        'user-disabled': 'تم تعطيل هذا الحساب، يرجى التواصل مع الدعم.',
        'user-not-found': 'المستخدم غير موجود، تأكد من صحة بياناتك.',
        'popup-closed-by-user': 'تم إغلاق نافذة تسجيل الدخول قبل الإكمال.',
        'popup-blocked':
            'تعذر فتح نافذة تسجيل الدخول؛ تحقق من إعدادات المتصفح.',
        'network-request-failed':
            'هناك مشكلة في الاتصال بالإنترنت، تأكد من الشبكة وحاول مرة أخرى.',
      };
      final arabicMessage =
          errorMessages[e.code] ?? 'حدث خطأ في المصادقة (${e.code}).';

      Get.snackbar(
        'خطأ في تسجيل الدخول',
        arabicMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('❌ [signInWithGoogle] Unexpected error: $e');
      debugPrint('Stack trace:\n$st');
      Get.snackbar(
        'خطأ غير متوقع',
        'حصل خطأ أثناء العملية، اطلع على الـ logs لمعرفة التفاصيل.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _loginOrRegisterWithApi(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/google-signin');
      Map<String, dynamic> payload = {'email': email};
      debugPrint('🧪 [_loginOrRegisterWithApi] start for email=$email');
      payload = await _withCaptcha(payload, 'google_signin');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      if (kIsWeb && !hasCaptcha) {
        debugPrint(
            '❌ [_loginOrRegisterWithApi] missing reCAPTCHA token on Web, aborting API call.');
        Get.snackbar(
          'خطأ في التحقق البشري',
          'تعذر إنشاء توكن reCAPTCHA، حاول تحديث الصفحة ثم إعادة المحاولة.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [_loginOrRegisterWithApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (res.statusCode == 200 && body?['status'] == 'success') {
          final userMap = body!['user'] as Map<String, dynamic>;
          await _persistUser(userMap);
          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);
          Get.snackbar(
            'نجاح',
            body['message'] ?? 'تم تسجيل الدخول بنجاح',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );
            debugPrint(
                '🔐 [_loginOrRegisterWithApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);

            if (res.statusCode == 200 && body?['status'] == 'success') {
              final userMap = body!['user'] as Map<String, dynamic>;
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u);
              Get.snackbar(
                'نجاح',
                body['message'] ?? 'تم تسجيل الدخول بنجاح',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
          }
          Get.snackbar(
            'خطأ',
            body?['message'] ?? 'فشل reCAPTCHA.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          debugPrint(
              '❌ [_loginOrRegisterWithApi] backend error: status=${res.statusCode}, body=$body');
          Get.snackbar(
            'خطأ في الخادم',
            body?['message'] ?? 'تعذر إنشاء الحساب.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        debugPrint(
            '⚠️ [_loginOrRegisterWithApi] non-JSON response. status=${res.statusCode}, body=${res.body}');
        Get.snackbar(
          'خطأ في الخادم',
          'استجابة غير متوقعة من السيرفر.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, st) {
      debugPrint('❌ [_loginOrRegisterWithApi] API error: $e');
      debugPrint('❌ [_loginOrRegisterWithApi] stack:\n$st');
      Get.snackbar(
        'خطأ في الاتصال',
        'تعذر التواصل مع الخادم، تحقق من الإنترنت.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== [Sign out] ====================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    user.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (_) {}

    try {
      Get.find<LoadingController>().logout();
    } catch (_) {}

    Get.offAll(() => HomeDeciderView());
  }

  // ==================== [API Functions] ====================

  /// إرسال كود التحقق (تسجيل/استعادة) مع reCAPTCHA v3 + v2 fallback
  Future<Map<String, dynamic>> sendVerificationCodeApi({int force = 0}) async {
    isSendingCode(true);
    try {
      final uri = Uri.parse('$baseUrl/send-code');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'force': force,
      };
      debugPrint(
          '🧪 [sendVerificationCodeApi] start (force=$force, email=${payload['email']})');
      payload = await _withCaptcha(payload, 'signup_email');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      if (kIsWeb && !hasCaptcha) {
        debugPrint(
            '❌ [sendVerificationCodeApi] no reCAPTCHA token on Web. Aborting.');
        return {
          'statusCode': 0,
          'message':
              'فشل التحقق البشري، تأكد من إعداد reCAPTCHA ثم حاول مرة أخرى.',
        };
      }

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [sendVerificationCodeApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (res.statusCode == 200) {
          return {
            'statusCode': 200,
            'message': body!['message'] ?? 'تم الإرسال',
            'body': body,
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [sendVerificationCodeApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            if (res.statusCode == 200) {
              return {
                'statusCode': 200,
                'message': body!['message'] ?? 'تم الإرسال',
                'body': body,
              };
            }
          }
        }
        return {
          'statusCode': res.statusCode,
          'message': body?['message'] ??
              body?['error'] ??
              'خطأ غير متوقع في إرسال كود التحقق',
          'body': body,
        };
      } else {
        debugPrint(
            '⚠️ [sendVerificationCodeApi] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'statusCode': res.statusCode,
          'message': 'استجابة غير متوقعة من السيرفر. ربما HTML؟',
          'body': res.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [sendVerificationCodeApi] exception: $e');
      debugPrint('❌ [sendVerificationCodeApi] stack:\n$stackTrace');
      return {
        'statusCode': 0,
        'message': 'فشل في الاتصال بالخادم: ${e.toString()}',
      };
    } finally {
      isSendingCode(false);
    }
  }

  Future<Map<String, dynamic>> verifyCodeApi() async {
    isVerifying(true);
    try {
      final uri = Uri.parse('$baseUrl/verify-code');
      final Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'code': codeCtrl.text.trim()
      };

      debugPrint(
          '🧪 [verifyCodeApi] start (email=${payload['email']}, code=${payload['code']})');

      final headers = await _jsonHeaders();
      final res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (!_isJson(res)) {
        debugPrint(
            '⚠️ [verifyCodeApi] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {'status': false, 'message': 'استجابة غير JSON من الخادم'};
      }

      final body = jsonDecode(res.body);
      final bool success =
          (res.statusCode == 200 && body['status'] == 'success');
      return {
        'status': success,
        'message': body['message'] ?? 'فشل في التحقق',
      };
    } catch (e, st) {
      debugPrint('❌ [verifyCodeApi] exception: $e');
      debugPrint('❌ [verifyCodeApi] stack:\n$st');
      return {'status': false, 'message': 'فشل في الاتصال'};
    } finally {
      isVerifying(false);
    }
  }

  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      final uri = Uri.parse('$baseUrl/complete-signup');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
      };
      debugPrint(
          '🧪 [completeRegistration] start (email=${payload['email']}, code=${payload['code']}, passwordLen=${payload['password'].toString().length})');

      payload = await _withCaptcha(payload, 'signup_complete');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      if (kIsWeb && !hasCaptcha) {
        debugPrint(
            '❌ [completeRegistration] no reCAPTCHA token on Web. Aborting.');
        return {
          'status': false,
          'message': 'فشل التحقق البشري، حاول تحديث الصفحة ثم إعادة المحاولة.',
        };
      }

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [completeRegistration] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (body?['status'] == true) {
          final userMap = (body!['user'] as Map<String, dynamic>);
          await _persistUser(userMap);
          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u, navigate: false);
          return {
            'status': true,
            'message': body['message'] ?? 'تم',
            'user': body['user'],
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [completeRegistration][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            if (body?['status'] == true) {
              final userMap = (body!['user'] as Map<String, dynamic>);
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u, navigate: false);
              return {
                'status': true,
                'message': body['message'] ?? 'تم',
                'user': body['user'],
              };
            }
          }
        }
        return {
          'status': false,
          'message': body?['message'] ?? 'استجابة غير صالحة من السيرفر',
        };
      } else {
        debugPrint(
            '⚠️ [completeRegistration] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {'status': false, 'message': 'استجابة غير JSON من الخادم'};
      }
    } catch (e, st) {
      debugPrint('❌ [completeRegistration] exception: $e');
      debugPrint('❌ [completeRegistration] stack:\n$st');
      return {'status': false, 'message': 'فشل في الاتصال'};
    }
  }

    Future<Map<String, dynamic>> loginApi() async {
    isLoggingIn(true);
    try {
      final uri = Uri.parse('$baseUrl/login');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
      };

      debugPrint(
          '🧪 [loginApi] start (email=${payload['email']}, passwordLen=${payload['password'].toString().length}, kIsWeb=$kIsWeb)');

      payload = await _withCaptcha(payload, 'login');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      // 👇👇 التعديل هنا 👇👇
      if (kIsWeb && !hasCaptcha) {
        debugPrint(
          '⚠️ [loginApi] _has_recaptcha=false على الويب → سندع السيرفر يجاوب '
          '(غالباً 422) ثم نفعّل v2 fallback لاحقاً.',
        );
        // لا نرجع هنا، نخلي الطلب يروح للسيرفر
        // أول رد 422 سيُفعّل _shouldTriggerV2Fallback ويظهر صفحة v2
      }
      // ☝️☝️ انتهى التعديل ☝️☝️

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [loginApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        // ✅ نجاح v3 مباشرة
        if (res.statusCode == 200 &&
            (body?['status'] == 'success' || body?['status'] == true)) {
          final userMap = (body!['user'] as Map<String, dynamic>);
          await _persistUser(userMap);

          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u, navigate: false);

          return {
            'status': true,
            'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
            'user': body['user'],
          };
        }

        // ✅ هنا بيفعّل v2 لما السيرفر يرجّع 422 / require_v2
        else if (_shouldTriggerV2Fallback(res, body)) {
          debugPrint('🧪 [loginApi] triggering v2 fallback...');
          final v2 = await _getV2Token();

          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [loginApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);

            if (res.statusCode == 200 &&
                (body?['status'] == 'success' || body?['status'] == true)) {
              final userMap = (body!['user'] as Map<String, dynamic>);
              await _persistUser(userMap);

              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u, navigate: false);

              return {
                'status': true,
                'message': body['message'] ?? 'تم تسجيل الدخول',
                'user': body['user'],
              };
            }

            debugPrint(
                '❌ [loginApi][v2] failed even with v2 token. body=$body, statusCode=${res.statusCode}');
            return {
              'status': false,
              'message': body?['message'] ??
                  body?['error'] ??
                  'فشل في reCAPTCHA (v2 fallback).',
            };
          }

          debugPrint(
              '⚠️ [loginApi] v2 fallback did not return token (popup closed or exception).');
          return {
            'status': false,
            'message':
                'لم يكتمل التحقق البشري، يرجى المحاولة مرة أخرى وإكمال خطوة "لست روبوتاً".',
          };
        }

        // ❌ أي فشل آخر عادي (إيميل/كلمة مرور)
        else {
          debugPrint(
              '❌ [loginApi] logical failure. statusCode=${res.statusCode}, body=$body');
          return {
            'status': false,
            'message': body?['message'] ??
                'فشل في تسجيل الدخول (تحقق من البريد/كلمة المرور)',
          };
        }
      } else {
        final snippet =
            res.body.length > 2000 ? res.body.substring(0, 2000) : res.body;
        debugPrint(
            '⚠️ [loginApi] Non-JSON from server (login). Status ${res.statusCode}, body=$snippet');
        return {
          'status': false,
          'message': 'خطأ من الخادم (ليست JSON). افحص اللوج.',
        };
      }
    } catch (e, st) {
      debugPrint('❌ [loginApi] exception: $e');
      debugPrint('❌ [loginApi] stack:\n$st');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم (loginApi)',
      };
    } finally {
      isLoggingIn(false);
    }
  }


  Future<Map<String, dynamic>> googleSignInApi(String email) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/google-signin');
      Map<String, dynamic> payload = {'email': email};
      debugPrint('🧪 [googleSignInApi] start (email=$email)');
      payload = await _withCaptcha(payload, 'google_signin');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      if (kIsWeb && !hasCaptcha) {
        debugPrint(
            '❌ [googleSignInApi] no reCAPTCHA token on Web. Aborting API call.');
        return {
          'status': false,
          'message':
              'فشل التحقق البشري، تأكد من إعداد reCAPTCHA ثم حاول مرة أخرى.',
        };
      }

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [googleSignInApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (res.statusCode == 200 && body?['status'] == 'success') {
          final userMap = body!['user'] as Map<String, dynamic>;

          await _persistUser(userMap);

          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);

          return {
            'status': true,
            'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
            'user': userMap,
            'isNewUser':
                (body['message']?.toString().contains('إنشاء') ?? false),
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [googleSignInApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            if (res.statusCode == 200 && body?['status'] == 'success') {
              final userMap = body!['user'] as Map<String, dynamic>;
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u);
              return {
                'status': true,
                'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
                'user': userMap,
                'isNewUser':
                    (body['message']?.toString().contains('إنشاء') ?? false),
              };
            }
          }
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل reCAPTCHA في Google Sign-in',
          };
        } else {
          return {
            'status': false,
            'message':
                body?['message'] ?? 'فشل تسجيل الدخول عبر Google (من الخادم)',
          };
        }
      } else {
        debugPrint(
            '⚠️ [googleSignInApi] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم في Google Sign-in',
        };
      }
    } catch (e, st) {
      debugPrint('❌ [googleSignInApi] exception: $e');
      debugPrint('❌ [googleSignInApi] stack:\n$st');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم أثناء Google Sign-in',
      };
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetGooglePasswordApi({
    required String email,
    required String code,
    required String password,
  }) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/reset-google-password');
      Map<String, dynamic> payload = {
        'email': email,
        'code': code,
        'password': password,
      };
      debugPrint(
          '🧪 [resetGooglePasswordApi] start (email=$email, code=$code, passwordLen=${password.length})');

      payload = await _withCaptcha(payload, 'reset_google_password');
      final hasCaptcha = payload['_has_recaptcha'] == true;
      payload.remove('_has_recaptcha');

      if (kIsWeb && !hasCaptcha) {
        debugPrint(
            '❌ [resetGooglePasswordApi] no reCAPTCHA token on Web. Aborting.');
        return {
          'status': false,
          'message':
              'فشل التحقق البشري، تأكد من إعداد reCAPTCHA ثم حاول مرة أخرى.',
        };
      }

      var headers = await _jsonHeaders();
      var res =
          await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [resetGooglePasswordApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        final bool success =
            (res.statusCode == 200 && body?['status'] == 'success');
        if (success) {
          return {
            'status': true,
            'message': body!['message'] ?? 'تم التحديث بنجاح',
            'details': body.toString(),
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [resetGooglePasswordApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            final bool ok =
                (res.statusCode == 200 && body?['status'] == 'success');
            return {
              'status': ok,
              'message': body?['message'] ??
                  (ok ? 'تم التحديث' : 'فشل في التحديث'),
              'details': body.toString(),
            };
          }
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل reCAPTCHA في reset-password',
          };
        } else {
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل في التحديث (reset-password)',
          };
        }
      } else {
        debugPrint(
            '⚠️ [resetGooglePasswordApi] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم في reset-password',
        };
      }
    } catch (e, stack) {
      debugPrint('❌ [resetGooglePasswordApi] Exception: $e');
      debugPrint('❌ [resetGooglePasswordApi] stack:\n$stack');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم',
        'error': e.toString(),
        'stack': stack.toString(),
      };
    } finally {
      isLoading(false);
    }
  }

  // ==================== [UI Facade] ====================

  void sendVerificationCode() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading.value = true;
    final result = await sendVerificationCodeApi();
    isLoading.value = false;

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  void verifyCode() async {
    if (codeCtrl.text.isEmpty || codeCtrl.text.length != 6) {
      _showErrorSnackbar(
          'رمز غير صالح', 'يرجى إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    isLoading.value = true;
    final result = await verifyCodeApi();
    isLoading.value = false;

    if (result['status'] == true) {
      currentStep.value = 2;
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  void resendCode() {
    _showSuccessSnackbar('تم الإرسال!', 'تم إعادة إرسال رمز التحقق إلى بريدك');
  }

  Future<Map<String, dynamic>> resetGooglePassword({
    required String email,
    required String code,
    required String password,
  }) async {
    isLoading(true);
    try {
      final result = await resetGooglePasswordApi(
        email: email,
        code: code,
        password: password,
      );
      return result;
    } finally {
      isLoading(false);
    }
  }

  // ------ نوع الحساب ------

  void checkAccountType() {
    final currentUser = Get.find<LoadingController>().currentUser;
    if (currentUser == null) return;

    if (currentUser.signup_method == "email") {
      // حساب عادي
      debugPrint('[checkAccountType] normal email account.');
    } else {
      // حساب جوجل
      debugPrint(
          '[checkAccountType] google account → go to /reset-google-password');
      Get.toNamed('/reset-google-password');
    }
  }

  /// واجهة إرسال كود عند التسجيل
  void sendVerificationCodeForSignup() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 0);
    isLoading(false);

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  /// واجهة إرسال كود عند استعادة/تغيير كلمة المرور
  void sendVerificationCodeForReset() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 1);
    isLoading(false);

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar(
          'تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  // ==================== [Helpers] ====================

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withOpacity(0.2),
      colorText: AppColors.error,
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withOpacity(0.2),
      colorText: AppColors.success,
    );
  }

  // ------ جلب بيانات المستخدم للتحديث ------

  Future<Map<String, dynamic>> fetchUserDataApi(int userId) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/user-update/$userId');
      final headers = await _jsonHeaders();

      debugPrint('🧪 [fetchUserDataApi] GET $uri');

      final res = await http.get(uri, headers: headers);

      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint(
            '⚠️ [fetchUserDataApi] non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم',
        };
      }

      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['status'] == 'success') {
        final userMap = body['user'] as Map<String, dynamic>;
        final updatedUser = users.User.fromJson(userMap);

        await _persistUser(userMap);
        Get.find<LoadingController>().currentUser = updatedUser;

        debugPrint("✅ [fetchUserDataApi] تم تحديث بيانات المستخدم (id=$userId)");
        return {
          'status': true,
          'user': updatedUser,
          'freePostsExhausted':
              (body['free_posts_exhausted'] as bool?) ?? false,
          'accountStatus': (body['account_status'] as String?) ?? '',
        };
      } else {
        debugPrint("❌ [fetchUserDataApi] فشل: ${body['message']}");
        return {
          'status': false,
          'message': body['message'] ?? 'فشل في جلب بيانات المستخدم',
        };
      }
    } catch (e, st) {
      debugPrint("❌ [fetchUserDataApi] exception: $e");
      debugPrint("❌ [fetchUserDataApi] stack:\n$st");
      return {'status': false, 'message': 'فشل في الاتصال بالخادم'};
    } finally {
      isLoading(false);
    }
  }

  // ------ حذف المستخدم ------

  Future<void> deleteUser(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final headers = await _jsonHeaders();

      debugPrint('🗑️ [deleteUser] DELETE $uri');

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        _showSnackbar('نجاح', 'تم حذف المستخدم #$id بنجاح.', false);
        try {
          Get.find<LoadingController>().logout();
        } catch (_) {}
      } else if (response.statusCode == 404) {
        _showSnackbar('خطأ', 'المستخدم #$id غير موجود.', true);
      } else {
        _showSnackbar(
          'خطأ',
          'فشل في حذف المستخدم. رمز الحالة: ${response.statusCode}\n${response.body}',
          true,
        );
      }
    } catch (e, st) {
      debugPrint('❌ [deleteUser] exception: $e');
      debugPrint('❌ [deleteUser] stack:\n$st');
      _showSnackbar('استثناء', 'حدث خطأ أثناء الحذف: $e', true);
    }
  }

  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: const EdgeInsets.all(15),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle,
        color: Colors.white,
      ),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
