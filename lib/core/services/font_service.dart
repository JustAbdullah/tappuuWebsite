// === file: lib/core/services/font_service.dart (Web-only) ===
// Web-only FontService: downloads active font metadata from your API
// and injects @font-face rules into the DOM using remote URLs from the
// server (assumes the font URLs are reachable and CORS allows usage).
//
// Usage:
//   import 'package:your_app/core/services/font_service.dart';
//   await FontService.instance.init();
//
// Notes:
// - This file is web-only and must be used when your app targets web.
// - The server must permit CORS for font files (Access-Control-Allow-Origin).
// - If fonts fail to load due to network/CORS, add a fallback font-family in Theme.

import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteWeight {
  final int id;
  final int weightValue;
  final String assetPath;

  RemoteWeight({required this.id, required this.weightValue, required this.assetPath});

  factory RemoteWeight.fromJson(Map<String, dynamic> j) =>
      RemoteWeight(
        id: int.parse(j['id'].toString()),
        weightValue: int.parse(j['weight_value'].toString()),
        assetPath: j['asset_path'] ?? '',
      );
}

class RemoteFont {
  final int id;
  final String familyName;
  final List<RemoteWeight> weights;

  RemoteFont({required this.id, required this.familyName, required this.weights});

  factory RemoteFont.fromJson(Map<String, dynamic> j) => RemoteFont(
        id: int.parse(j['id'].toString()),
        familyName: j['family_name'].toString(),
        weights: (j['weights'] as List<dynamic>?)
                ?.map((e) => RemoteWeight.fromJson(e as Map<String, dynamic>)).toList() ??
            [],
      );
}

class FontService {
  FontService._private();
  static final FontService instance = FontService._private();

  // Point to your API base
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // prefs keys
  static const _kPrefsKeyFontMap = 'font_family_local_map';
  static const _kPrefsKeyActiveFamily = 'font_active_family';
  static const _kPrefsKeyRemoteRaw = 'font_remote_raw';

  // in-memory map: family -> (weight -> remoteUrl)
  Map<String, Map<int, String>> _familyLocalMap = {};
  String? activeFamily;
  final Set<String> _registeredFamilies = {};

  /// Initialize: loads cache and tries fetching remote active font.
  /// Call during app startup (web).
  Future<void> init({bool forceRefresh = false}) async {
    if (!kIsWeb) {
      debugPrint('FontService.init called on non-web platform — this file is web-only.');
      return;
    }

    await _loadPrefs();

    if (!forceRefresh && activeFamily != null && _registeredFamilies.contains(activeFamily)) {
      _fetchAndSyncInBackground();
      return;
    }

    await _fetchAndSync(force: forceRefresh);
  }

  Future<void> refresh() async {
    await _fetchAndSync(force: true);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMap = prefs.getString(_kPrefsKeyFontMap);
    final active = prefs.getString(_kPrefsKeyActiveFamily);

    if (rawMap != null) {
      try {
        final decoded = json.decode(rawMap) as Map<String, dynamic>;
        _familyLocalMap = decoded.map((family, m) {
          final map = (m as Map).map((k, v) => MapEntry(int.parse(k.toString()), v.toString()));
          return MapEntry(family, map);
        });
      } catch (e) {
        if (kDebugMode) debugPrint('FontService._loadPrefs decode error: $e');
        _familyLocalMap = {};
      }
    } else {
      _familyLocalMap = {};
    }
    activeFamily = active;
    for (final family in _familyLocalMap.keys) {
      _registeredFamilies.add(family);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _familyLocalMap.map((family, m) {
      return MapEntry(family, m.map((k, v) => MapEntry(k.toString(), v)));
    });
    await prefs.setString(_kPrefsKeyFontMap, json.encode(encoded));
    if (activeFamily != null) await prefs.setString(_kPrefsKeyActiveFamily, activeFamily!);
  }

  void _fetchAndSyncInBackground() {
    _fetchAndSync().catchError((e) {
      if (kDebugMode) debugPrint('FontService background _fetchAndSync error: $e');
    });
  }

  Future<void> _fetchAndSync({bool force = false}) async {
    final uri = Uri.parse('$_baseUrl/fonts/active');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('FontService HTTP ${res.statusCode}');
        return;
      }
      final raw = res.body;
      final prefs = await SharedPreferences.getInstance();
      final prevRaw = prefs.getString(_kPrefsKeyRemoteRaw);

      if (!force && prevRaw != null && prevRaw == raw) {
        if (kDebugMode) debugPrint('FontService: remote fonts unchanged.');
        return;
      }

      final body = json.decode(raw);
      if (body is Map<String, dynamic> && body['success'] == true && body['data'] != null) {
        final remote = RemoteFont.fromJson(body['data'] as Map<String, dynamic>);
        await _downloadAndRegister(remote);
        await prefs.setString(_kPrefsKeyRemoteRaw, raw);
      } else {
        if (kDebugMode) debugPrint('FontService: invalid remote payload.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('FontService._fetchAndSync error: $e');
    }
  }

  /// Web semantics: we don't download font files locally — we inject CSS that points to remote URLs.
  Future<void> _downloadAndRegister(RemoteFont remote) async {
    final family = remote.familyName;
    final Map<int, String> weightToRemote = {};

    final buffer = StringBuffer();

    for (final w in remote.weights) {
      final url = w.assetPath;
      if (url.isEmpty) continue;

      // Build @font-face entry using remote url.
      // Note: format detection could be improved; many servers serve woff/ttf.
      buffer.writeln("""
@font-face {
  font-family: '$family';
  src: url('$url') format('truetype');
  font-weight: ${w.weightValue};
  font-style: normal;
  font-display: swap;
}
""");

      weightToRemote[w.weightValue] = url;
    }

    if (weightToRemote.isEmpty) {
      if (kDebugMode) debugPrint('FontService: no weights available for family $family -> skipping');
      return;
    }

    try {
      final styleId = 'fontservice-${family.replaceAll(' ', '_')}';
      final existing = html.document.getElementById(styleId);
      existing?.remove();

      final style = html.StyleElement()
        ..id = styleId
        ..appendText(buffer.toString());
      html.document.head!.append(style);

      _familyLocalMap[family] = weightToRemote;
      activeFamily = family;
      _registeredFamilies.add(family);
      await _savePrefs();

      if (kDebugMode) debugPrint('FontService (web): registered family $family with weights ${weightToRemote.keys.toList()}');
    } catch (e) {
      if (kDebugMode) debugPrint('FontService (web): error injecting css -> $e');
    }
  }

  // Public helpers
  String? getActiveFamily() => activeFamily;
  bool isFamilyRegistered(String family) => _registeredFamilies.contains(family);
  String? getRemoteUrlForWeight(String family, int weightValue) {
    final m = _familyLocalMap[family];
    if (m == null) return null;
    return m[weightValue];
  }

  Map<String, Map<int, String>> getFamilyLocalMap() => Map.unmodifiable(_familyLocalMap);

  static FontWeight weightValueToFontWeight(int w) {
    switch (w) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }
}

// === end of file ===
