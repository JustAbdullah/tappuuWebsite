// lib/core/recaptcha/recaptcha_v2_dialog.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaV2Dialog extends StatefulWidget {
  final String pageUrl;   // مثال: https://testing.arabiagroup.net/recaptcha-v2.html
  final String siteKey;   // مفتاح v2 (site key)

  const RecaptchaV2Dialog({
    super.key,
    required this.pageUrl,
    required this.siteKey,
  });

  @override
  State<RecaptchaV2Dialog> createState() => _RecaptchaV2DialogState();
}

class _RecaptchaV2DialogState extends State<RecaptchaV2Dialog> {
  late final WebViewController _ctrl;
  bool _loading = true;

  Uri _buildUrl() {
    return Uri.parse(widget.pageUrl).replace(queryParameters: {
      'site_key': widget.siteKey,
    });
  }

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      // UA كروم حديث لتفادي قيود Google على WebView
      ..setUserAgent(
        'Mozilla/5.0 (${kIsWeb ? "X11; Linux x86_64" : (Platform.isIOS ? "iPhone; CPU iPhone OS 15_0 like Mac OS X" : "Linux; Android 13")}) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/119.0.0.0 Safari/537.36',
      )
      ..addJavaScriptChannel('Recaptcha', onMessageReceived: (msg) {
        final token = msg.message;
        if (token.isNotEmpty) {
          Navigator.of(context).pop(token); // رجّع التوكن للمتصل
        }
      })
      ..addJavaScriptChannel('recaptcha', onMessageReceived: (msg) {
        final token = msg.message;
        if (token.isNotEmpty) {
          Navigator.of(context).pop(token);
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(_buildUrl());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحقق: أنا لست روبوت (reCAPTCHA v2)'),
          actions: [
            IconButton(
              tooltip: 'إعادة التحميل',
              onPressed: () => _ctrl.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _ctrl)),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
