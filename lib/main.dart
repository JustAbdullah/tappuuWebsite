// lib/main.dart
import 'dart:async';
import 'dart:html' as html;

// ✅ بدل dart:js_util
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

// WebView for web
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'package:tappuu_website/app_routes.dart';
import 'package:tappuu_website/firebase_options.dart';
import 'MyCustomScrollBehavior.dart';
import 'controllers/AdsManageController.dart';
import 'controllers/AdsManageSearchController.dart';
import 'controllers/ColorController.dart';
import 'controllers/LoadingController.dart';
import 'controllers/ThemeController.dart';
import 'controllers/editable_text_controller.dart';
import 'controllers/home_controller.dart';
import 'core/localization/AppTranslation.dart';
import 'core/localization/changelanguage.dart';
import 'core/services/appservices.dart';
import 'core/services/font_service.dart';
import 'core/services/font_size_service.dart';
import 'enhanced_navigator_observer.dart';

final GlobalKey<NavigatorState> navigatorKey = Get.key;
bool _allowExit = false;

/// Firebase init in background
Future<void> _initializeFirebaseServices() async {
  try {
    await initializeFirebase();
  } catch (e) {
    debugPrint("⚠️ Firebase init skipped: $e");
  }
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
}

/// نسجل فقط الأشياء الخفيفة دائمًا، والباقي lazy
void registerPersistentControllers() {
  // Theme + Loading مهمين لكل التطبيق
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
    debugPrint('Main -> ThemeController registered permanent');
  }
  if (!Get.isRegistered<LoadingController>()) {
    Get.put(LoadingController(), permanent: true);
    debugPrint('Main -> LoadingController registered permanent');
  }

  // باقي الكنترولات نسجلها lazy عشان ما تنشأ إلا عند استخدامها
  if (!Get.isRegistered<HomeController>()) {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    debugPrint('Main -> HomeController registered lazy');
  }
  if (!Get.isRegistered<ManageAdController>()) {
    Get.lazyPut<ManageAdController>(() => ManageAdController(), fenix: true);
    debugPrint('Main -> ManageAdController registered lazy');
  }
  if (!Get.isRegistered<AdsController>()) {
    Get.lazyPut<AdsController>(() => AdsController(), fenix: true);
    debugPrint('Main -> AdsController registered lazy');
  }

  // EditableTextController يُسجَّل من AppServices.init في الخلفية
}

/// -------- BrowserHistorySync --------
class BrowserHistorySync extends NavigatorObserver {
  final List<String> _stack = [];
  bool _syncingFromBrowser = false;
  bool _suppressPush = false;
  bool _isHandlingPopState = false;

  List<String> get stack => List.unmodifiable(_stack);
  bool get isHandlingPopState => _isHandlingPopState;

  void initWith(String initialRoute) {
    _stack.clear();
    _stack.add(initialRoute);
    try {
      html.window.history.replaceState(
        {'route': initialRoute, 'index': 0},
        '',
        initialRoute,
      );
    } catch (e) {
      debugPrint('HistorySync init error: $e');
    }
  }

  String current() => _stack.isNotEmpty ? _stack.last : '/';
  String? previous() => _stack.length > 1 ? _stack[_stack.length - 2] : null;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    if (_syncingFromBrowser) {
      _syncingFromBrowser = false;
      return;
    }
    if (_suppressPush) {
      _suppressPush = false;
      return;
    }

    final name = _extractRouteName(route);
    _stack.add(name);

    try {
      final url = _routeToUrl(name);
      html.window.history.pushState(
        {'route': name, 'index': _stack.length - 1},
        '',
        url,
      );
    } catch (e) {
      debugPrint('HistorySync pushState error: $e');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (_stack.isNotEmpty) _stack.removeLast();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = newRoute != null ? _extractRouteName(newRoute) : '/';
    didReplaceRoute(newName);
  }

  void didReplaceRoute(String newRoute) {
    if (_stack.isNotEmpty) _stack.removeLast();
    _stack.add(newRoute);

    try {
      final url = _routeToUrl(newRoute);
      html.window.history.replaceState(
        {'route': newRoute, 'index': _stack.length - 1},
        '',
        url,
      );
    } catch (e) {
      debugPrint('HistorySync replaceState error: $e');
    }
  }

  String _extractRouteName(Route route) {
    final settingsName = route.settings.name;
    if (settingsName != null && settingsName.isNotEmpty) return settingsName;
    final cur = Get.currentRoute;
    return (cur.isNotEmpty) ? cur : '/';
  }

  String _routeToUrl(String routeName) {
    if (routeName.startsWith('/')) return routeName;
    return '/$routeName';
  }

  Future<bool> handleBrowserBack() async {
    if (_isHandlingPopState) return true;
    _isHandlingPopState = true;

    try {
      if (_stack.length > 1) {
        _syncingFromBrowser = true;
        try {
          Get.back();
        } catch (e) {
          debugPrint('HistorySync handleBrowserBack Get.back error: $e');
        }
        return true;
      }
      return false;
    } finally {
      _isHandlingPopState = false;
    }
  }

  void handleOffNavigation(String newRoute) {
    didReplaceRoute(newRoute);
  }

  void handleOffAllNavigation(String newRoute) {
    _stack.clear();
    _stack.add(newRoute);

    try {
      final url = _routeToUrl(newRoute);
      html.window.history.pushState(
        {'route': newRoute, 'index': 0},
        '',
        url,
      );
    } catch (e) {
      debugPrint('HistorySync handleOffAllNavigation error: $e');
    }
  }
}

final BrowserHistorySync historyObserver = BrowserHistorySync();

String _normalizePath(String rawPath) {
  if (rawPath.isEmpty) return '/';

  // ✅ توحيد /index.html و /index إلى /
  if (rawPath == '/index.html' || rawPath == '/index') {
    return '/';
  }

  // ✅ توحيد /web و /web/ إلى /
  if (rawPath == '/web' || rawPath == '/web/') {
    return '/';
  }

  // ✅ إذا الرابط يبدأ بـ /web/ نشيل /web
  if (rawPath.startsWith('/web/')) {
    return rawPath.substring(4); // /web/ads/... -> /ads/...
  }

  return rawPath;
}

/// AppServices + SharedPreferences + editable-texts (background)
Future<void> _initializeEssentialServices() async {
  try {
    final appServices = await Future.any<AppServices?>([
      AppServices.init(),
      Future.delayed(const Duration(seconds: 5), () => null),
    ]);

    if (appServices != null) {
      if (!Get.isRegistered<AppServices>()) {
        Get.put(appServices, permanent: true);
      }
      debugPrint('✅ AppServices initialized');
    } else {
      debugPrint('⚠️ AppServices init timeout, will continue without it');
    }
  } catch (e) {
    debugPrint("❌ AppServices error: $e");
  }
}

/// الخدمات الثقيلة بعد أول Frame
void _initializeHeavyServices() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('🚀 Starting heavy services initialization...');

    AppServices? appServices;
    try {
      if (Get.isRegistered<AppServices>()) {
        appServices = Get.find<AppServices>();
      }
    } catch (_) {
      appServices = null;
    }

    final List<Future<void> Function()> heavyServices = [];

    if (appServices != null) {
      heavyServices.addAll([
        () async {
          try {
            await Future.any([
              appServices!.fetchAndStoreAppLogo(),
              Future.delayed(const Duration(seconds: 2)),
            ]);
            debugPrint('✅ App logo fetched');
          } catch (e) {
            debugPrint('❌ App logo error: $e');
          }
        },
        () async {
          try {
            await Future.any([
              appServices!.fetchAndStoreWaitingScreen(),
              Future.delayed(const Duration(seconds: 2)),
            ]);
            debugPrint('✅ Waiting screen fetched');
          } catch (e) {
            debugPrint('❌ Waiting screen error: $e');
          }
        },
      ]);
    }

    heavyServices.addAll([
      () async {
        try {
          await Future.any([
            FontSizeService.instance.init(),
            Future.delayed(const Duration(milliseconds: 1500)),
          ]);
          debugPrint('✅ Font sizes initialized');
        } catch (e) {
          debugPrint('❌ Font sizes error: $e');
        }
      },
      () async {
        try {
          await Future.any([
            FontService.instance.init(),
            Future.delayed(const Duration(seconds: 3)),
          ]);
          debugPrint('✅ Fonts loaded');
        } catch (e) {
          debugPrint('❌ Fonts error: $e');
        }
      },
    ]);

    await Future.wait(heavyServices.map((service) => service()));
    debugPrint('🎉 All heavy services completed');
  });
}

void _setupSystemUiAndOrientation() {
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).catchError((e) {
    debugPrint('❌ Orientation setup error: $e');
  });
}

void _setupBrowserHooks() {
  try {
    final rawInitialPath = html.window.location.pathname ?? '/';
    final initialPath = _normalizePath(rawInitialPath);
    historyObserver.initWith(initialPath);
    debugPrint('📍 Initial path: $initialPath');
  } catch (e) {
    debugPrint('❌ History observer error: $e');
  }

  try {
    html.window.onBeforeUnload.listen((html.Event event) {
      try {
        event.preventDefault();
        (event as dynamic).returnValue = '';
      } catch (e) {
        debugPrint('❌ Beforeunload error: $e');
      }
    });
  } catch (e) {
    debugPrint('❌ Beforeunload setup error: $e');
  }

  html.window.onPopState.listen((event) async {
    if (historyObserver.isHandlingPopState) return;
    final handled = await historyObserver.handleBrowserBack();
    if (!handled) {
      await _confirmOrCancelExit();
    }
  });
}

/// ColorController + primaryColor في الخلفية
Future<void> _initColorControllerAndFetchPrimary() async {
  try {
    if (!Get.isRegistered<ColorController>()) {
      await Get.putAsync(() async => ColorController());
    }
    final colorController = Get.find<ColorController>();
    await Future.any([
      colorController.fetchPrimaryColor(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    debugPrint('✅ Primary color fetched');
  } catch (e) {
    debugPrint('❌ Primary color error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // كتم debugPrint في نسخة release
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // WebView للويب
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
    debugPrint('✅ WebViewPlatform initialized for Web');
  }

  // URL strategy + System UI
  setUrlStrategy(PathUrlStrategy());
  _setupSystemUiAndOrientation();

  // اللغة + الكنترولرات الأساسية
  if (!Get.isRegistered<ChangeLanguageController>()) {
    Get.put(ChangeLanguageController(), permanent: true);
  }
  registerPersistentControllers();

  // شغّل التطبيق بسرعة
  runApp(const MyApp());

  // بعد تشغيل التطبيق
  if (kIsWeb) {
    _setupBrowserHooks();
  }

  // background
  unawaited(_initializeEssentialServices());
  unawaited(_initializeFirebaseServices());
  unawaited(_initColorControllerAndFetchPrimary());
  _initializeHeavyServices();
}

Future<void> _confirmOrCancelExit() async {
  if (_allowExit) {
    _allowExit = false;
    return;
  }

  try {
    final bool? shouldExit = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل تريد الخروج من الموقع؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('نعم'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (shouldExit == true) {
      _allowExit = true;
      html.window.history.back();
    } else {
      try {
        html.window.history.pushState({}, '', html.window.location.href);
      } catch (e) {
        debugPrint('❌ PushState error: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Exit dialog error: $e');
    try {
      html.window.history.pushState({}, '', html.window.location.href);
    } catch (_) {}
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialUriHandled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialUriHandled) {
        _initialUriHandled = true;
        _handleInitialDeepLink();
      }
    });
  }

  void _handleInitialDeepLink() {
    try {
      // 1) بيانات الإعلان من window.__AD_DATA__ (seo-inject.php)
      try {
        final JSAny? adDataAny = globalContext['__AD_DATA__'];

        Object? adData;
        try {
          adData = adDataAny == null ? null : adDataAny.dartify();
        } catch (_) {
          adData = null;
        }

        if (adData is Map) {
          final id = adData['id'];
          final slug = adData['slug'];

          String raw = '';
          if (id != null) {
            raw = id.toString();
            if (slug != null && slug.toString().trim().isNotEmpty) {
              raw = '$raw-${slug.toString()}';
            }
          } else if (slug != null) {
            raw = slug.toString();
          }

          if (raw.isNotEmpty) {
            debugPrint('🎯 Found window.__AD_DATA__ -> navigating to /ad/$raw');
            Get.offAllNamed('/ad/$raw');
            return;
          }
        }
      } catch (e) {
        debugPrint('❌ __AD_DATA__ error: $e');
      }

      // 2) الروابط العميقة /ads/... و /ad/...
      final rawPath = html.window.location.pathname ?? '/';
      final path = _normalizePath(rawPath);

      final queryParams = html.window.location.search ?? '';
      debugPrint('🔗 Handling deep link: $path$queryParams');

      if (path.startsWith('/ads/')) {
        _handleAdsScreenDeepLink(path, queryParams);
      } else if (path.startsWith('/ad/')) {
        _handleAdDetailsDeepLink(path);
      }
    } catch (e) {
      debugPrint('❌ Deep link error: $e');
    }
  }

  void _handleAdsScreenDeepLink(String path, String queryParams) {
    try {
      final uri = Uri.parse('https://example.com$path');
      final segments =
          uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

      final Map<String, dynamic> arguments = {};

      final adsIndex = segments.indexWhere((segment) => segment == 'ads');
      final effectiveSegments =
          adsIndex >= 0 ? segments.sublist(adsIndex + 1) : segments;

      if (effectiveSegments.isNotEmpty) {
        arguments['categorySlug'] = effectiveSegments[0];
      }
      if (effectiveSegments.length > 1) {
        arguments['subCategorySlug'] = effectiveSegments[1];
      }
      if (effectiveSegments.length > 2) {
        arguments['subTwoCategorySlug'] = effectiveSegments[2];
      }

      final qp = queryParams.startsWith('?')
          ? queryParams.substring(1)
          : queryParams;

      if (qp.isNotEmpty) {
        final params = Uri.splitQueryString(qp);

        if (params.containsKey('timeframe')) {
          arguments['currentTimeframe'] = params['timeframe'];
        }
        if (params.containsKey('featured')) {
          final featuredValue = params['featured']?.toLowerCase();
          arguments['onlyFeatured'] =
              featuredValue == 'true' || featuredValue == '1';
        }
      }

      Get.offAllNamed(
        AppRoutes.adsLoading,
        arguments: arguments,
      );
    } catch (e) {
      debugPrint('❌ Ads deep link error: $e');
      Get.offAllNamed(AppRoutes.adsScreen);
    }
  }

  void _handleAdDetailsDeepLink(String path) {
    try {
      final match = RegExp(r'^/ad/(.+)$').firstMatch(path);
      if (match != null) {
        final raw = match.group(1)!;
        Get.offAllNamed('/ad/$raw');
      }
    } catch (e) {
      debugPrint('❌ Ad details deep link error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: GetMaterialApp(
            theme: ThemeData(
              fontFamily: 'Tajawal',
              textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: 'Tajawal',
                    bodyColor: Colors.black,
                    displayColor: Colors.black,
                  ),
            ),
            darkTheme: ThemeData.dark().copyWith(),
            navigatorKey: navigatorKey,
            scrollBehavior: MyCustomScrollBehavior(),
            debugShowCheckedModeBanner: false,
            title: 'طابوو',
            translations: AppTranslation(),
            locale: const Locale('ar'),
            fallbackLocale: const Locale('ar'),
            initialRoute: AppRoutes.initial,
            getPages: AppRoutes.pages,
            initialBinding: BindingsBuilder(() {
              if (!Get.isRegistered<AdsController>()) {
                Get.put(AdsController(), permanent: false);
              }
            }),
            navigatorObservers: [
              historyObserver,
              EnhancedNavigatorObserver(),
            ],
          ),
        );
      },
    );
  }
}
