import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'recaptcha_token_cache.dart';

class RecaptchaMiniWebView extends StatefulWidget {
  final String baseUrl; // مثل: https://testing.arabiagroup.net/recaptcha.html
  final String action;  // مثل: login | signup | reset_password
  final ValueChanged<String>? onToken;
  final bool invisible; // 1×1 شبه مخفي

  const RecaptchaMiniWebView({
    super.key,
    required this.baseUrl,
    required this.action,
    this.onToken,
    this.invisible = true,
  });

  @override
  State<RecaptchaMiniWebView> createState() => _RecaptchaMiniWebViewState();
}

class _RecaptchaMiniWebViewState extends State<RecaptchaMiniWebView> {
  WebViewController? _ctrl;
  bool _enabled = true;
  bool _fixedOnce = false; // حارس لمنع إعادة التحميل المتكرر

  Uri _withParams() {
    return Uri.parse(widget.baseUrl).replace(queryParameters: {
      'action': widget.action,
    });
  }

  @override
  void initState() {
    super.initState();

    try {
      // 🔹 على الويب يجب تهيئة الـ WebViewController بنفس الطريقة
      _ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'Recaptcha',
          onMessageReceived: _onJsMessage,
        )
        ..addJavaScriptChannel(
          'recaptcha',
          onMessageReceived: _onJsMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) async {
              // أصلِح مرة واحدة فقط لو اختفت action= بسبب ريدايـركت
              if (!_fixedOnce && !url.contains('action=')) {
                _fixedOnce = true;
                _ctrl?.loadRequest(_withParams());
              }
            },
          ),
        );

      // أول تحميل للصفحة
      _ctrl!.loadRequest(_withParams());

      debugPrint(
          '✅ [RecaptchaMiniWebView] WebView initialized (kIsWeb=$kIsWeb)');
    } catch (e, st) {
      // لو وصلنا هنا → المنصة ما تدعم WebView (أو الـ plugin مش مركّب)
      debugPrint(
          '❌ RecaptchaMiniWebView: WebView not supported on this platform: $e');
      debugPrint('$st');
      _enabled = false;
      _ctrl = null;
    }
  }

  void _onJsMessage(JavaScriptMessage msg) {
    final token = msg.message.trim();
    if (token.isNotEmpty) {
      RecaptchaTokenCache.set(token);
      widget.onToken?.call(token);
      debugPrint(
          '✅ [RecaptchaMiniWebView] token received (len=${token.length}) for action=${widget.action}');
    } else {
      debugPrint('⚠️ [RecaptchaMiniWebView] empty token message from JS');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled || _ctrl == null) {
      // ما في WebView → لا نرمي خطأ، بس نرجّع Widget فاضي
      return const SizedBox.shrink();
    }

    final view = WebViewWidget(controller: _ctrl!);

    if (!widget.invisible) {
      // وضع مرئي للتشخيص
      return SizedBox(width: 300, height: 300, child: view);
    }

    // وضع 1×1 شبه مخفي — مهم جدًا يكون الـ WebView نفسه معروض
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: 0.001,
          child: SizedBox(width: 1, height: 1, child: view),
        ),
      ),
    );
  }
}
