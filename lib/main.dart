// lib/main.dart
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

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

final GlobalKey<NavigatorState> navigatorKey = Get.key;
bool _allowExit = false;

void registerPersistentControllers() {
  if (!Get.isRegistered<HomeController>()) {
    Get.put(HomeController(), permanent: true);
    debugPrint('Main -> HomeController registered permanent');
  }
  if (!Get.isRegistered<ThemeController>()) {
    Get.put(ThemeController(), permanent: true);
    debugPrint('Main -> ThemeController registered permanent');
  }
  if (!Get.isRegistered<LoadingController>()) {
    Get.put(LoadingController(), permanent: true);
    debugPrint('Main -> LoadingController registered permanent');
  }
  if (!Get.isRegistered<ManageAdController>()) {
    Get.put(ManageAdController(), permanent: true);
    debugPrint('Main -> ManageAdController registered permanent');
  }
  if (!Get.isRegistered<AdsController>()) {
    Get.put(AdsController(), permanent: true);
    debugPrint('Main -> AdsController registered permanent');
  }

  // NEW: Register EditableTextController as a persistent controller
  if (!Get.isRegistered<EditableTextController>()) {
    Get.put(EditableTextController(), permanent: true);
    debugPrint('Main -> EditableTextController registered permanent');
  }
}

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
      html.window.history.replaceState({'route': initialRoute, 'index': 0}, '', initialRoute);
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
      html.window.history.pushState({'route': name, 'index': _stack.length - 1}, '', url);
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
      html.window.history.replaceState({'route': newRoute, 'index': _stack.length - 1}, '', url);
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
      html.window.history.pushState({'route': newRoute, 'index': 0}, '', url);
    } catch (e) {
      debugPrint('HistorySync handleOffAllNavigation error: $e');
    }
  }
}

final BrowserHistorySync historyObserver = BrowserHistorySync();

/// Normalize incoming path: remove leading `/web` if present.
/// Examples:
///   '/web/ads/x' -> '/ads/x'
///   '/web' -> '/'
///   '/' -> '/'
String _normalizePath(String rawPath) {
  if (rawPath.isEmpty) return '/';
  if (rawPath == '/web') return '/';
  if (rawPath.startsWith('/web/')) return rawPath.substring(4); // remove "/web"
  return rawPath;
}

// دالة مبسطة لتهيئة الخدمات الأساسية فقط
Future<void> _initializeEssentialServices() async {
  try {
    // 1) تهيئة AppServices الأساسية فقط (بدون جلب البيانات)
    final appServices = await AppServices.init();
    Get.put(appServices, permanent: true);
    debugPrint('✅ Basic AppServices initialized');

  } catch (e) {
    debugPrint("❌ Basic AppServices error: $e");
  }
}

// دالة منفصلة لجلب البيانات الثقيلة بعد تحميل التطبيق
void _initializeHeavyServices() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('🚀 Starting heavy services initialization...');

    final appServices = Get.find<AppServices>();

    // تشغيل جميع الخدمات الثقيلة بشكل متوازي مع مهلات قصيرة
    final heavyServices = [
      // 1) جلب اللوجو (أقصى وقت 2 ثانية)
      () async {
        try {
          await Future.any([
            appServices.fetchAndStoreAppLogo(),
            Future.delayed(const Duration(seconds: 2)),
          ]);
          debugPrint('✅ App logo fetched');
        } catch (e) {
          debugPrint('❌ App logo error: $e');
        }
      },

      // 2) جلب شاشة الانتظار (أقصى وقت 2 ثانية)
      () async {
        try {
          await Future.any([
            appServices.fetchAndStoreWaitingScreen(),
            Future.delayed(const Duration(seconds: 2)),
          ]);
          debugPrint('✅ Waiting screen fetched');
        } catch (e) {
          debugPrint('❌ Waiting screen error: $e');
        }
      },

      // 3) جلب أحجام الخطوط (أقصى وقت 1.5 ثانية)
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

      // 4) تحميل الخطوط (أقصى وقت 3 ثواني)
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

      // 5) NEW: جلب Editable Texts بشكل متزامن (أقصى وقت 4 ثواني)
      () async {
        try {
          if (Get.isRegistered<EditableTextController>()) {
            final editableCtrl = Get.find<EditableTextController>();
            await Future.any([
              editableCtrl.fetchAll(),
              Future.delayed(const Duration(seconds: 4)),
            ]);
            debugPrint('✅ Editable texts fetched (or timeout)');
          } else {
            debugPrint('ℹ️ EditableTextController not registered yet.');
          }
        } catch (e) {
          debugPrint('❌ Editable texts fetch error: $e');
        }
      },
    ];

    // تشغيل جميع الخدمات بشكل متوازي
    await Future.wait(heavyServices.map((service) => service()));
    debugPrint('🎉 All heavy services completed');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) تهيئة الخدمات الأساسية السريعة أولاً
  await _initializeEssentialServices();

  // 2) تسجيل الكونترولر الأساسية
  await Get.putAsync(() async => ColorController());
  final colorController = Get.find<ColorController>();

  // 3) تهيئة Firebase بشكل غير متزامن (لا ننتظره)
  unawaited(_initializeFirebaseServices());

  // 4) إعدادات النظام الأساسية
  setUrlStrategy(PathUrlStrategy());
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  // 5) تسجيل الكونترولر الإضافية
  if (!Get.isRegistered<ChangeLanguageController>()) {
    Get.put(ChangeLanguageController(), permanent: true);
  }

  registerPersistentControllers();

  // 6) إعدادات التاريخ والروابط
  try {
    final rawInitialPath = html.window.location.pathname ?? '/';
    final initialPath = _normalizePath(rawInitialPath);
    historyObserver.initWith(initialPath);
    debugPrint('📍 Initial path: $initialPath');
  } catch (e) {
    debugPrint('❌ History observer error: $e');
  }

  // 7) إعدادات المتصفح
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

  // 8) إعدادات التوجيه
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  // 9) جلب اللون الأساسي بسرعة (1.5 ثانية كحد أقصى)
  unawaited(Future.any([
    colorController.fetchPrimaryColor(),
    Future.delayed(const Duration(milliseconds: 1500)),
  ]).then((_) => debugPrint('✅ Primary color fetched')));

  // 10) تشغيل التطبيق فوراً
  runApp(const MyApp());

  // 11) بدء الخدمات الثقيلة بعد تحميل التطبيق
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
            child: const Text('لا')
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('نعم')
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
      // 1) معالجة بيانات الإعلان من window.__AD_DATA__
      try {
        final dynamic adData = js_util.getProperty(html.window, '__AD_DATA__');
        if (adData != null) {
          final dynamic id = js_util.getProperty(adData, 'id');
          final dynamic slug = js_util.getProperty(adData, 'slug');

          String raw = '';
          if (id != null) {
            raw = id.toString();
            if (slug != null && slug.toString().trim().isNotEmpty) {
              final cleanedSlug = slug.toString();
              raw = '$raw-$cleanedSlug';
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

      // 2) معالجة الروابط العميقة
      final rawPath = html.window.location.pathname ?? '/';
      final path = _normalizePath(rawPath);
      final queryParams = html.window.location.search;

      debugPrint('🔗 Handling deep link: $path$queryParams');

      if (path.startsWith('/ads/')) {
        _handleAdsScreenDeepLink(path, queryParams ?? '');
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
      final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

      final Map<String, dynamic> arguments = {};

      final adsIndex = segments.indexWhere((segment) => segment == 'ads');
      final effectiveSegments = adsIndex >= 0 ? segments.sublist(adsIndex + 1) : segments;

      if (effectiveSegments.isNotEmpty) arguments['categorySlug'] = effectiveSegments[0];
      if (effectiveSegments.length > 1) arguments['subCategorySlug'] = effectiveSegments[1];
      if (effectiveSegments.length > 2) arguments['subTwoCategorySlug'] = effectiveSegments[2];

      if (queryParams.isNotEmpty) {
        final params = Uri.splitQueryString(queryParams);

        if (params.containsKey('timeframe')) {
          arguments['currentTimeframe'] = params['timeframe'];
        }
        if (params.containsKey('featured')) {
          final featuredValue = params['featured']?.toLowerCase();
          arguments['onlyFeatured'] = featuredValue == 'true' || featuredValue == '1';
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
      // إضافة loading widget أثناء الانتظار
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
